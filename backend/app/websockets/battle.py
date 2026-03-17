"""
Battle WebSocket — ws/battle/{match_id}?token=xxx

Uses in-memory asyncio queues (no Redis required for single-process dev).
Bot matches (player2_id=None) start the engine as soon as player1 connects.
"""
import asyncio
import json
from typing import Dict, Optional, Set

from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from jose import JWTError
from sqlalchemy import select

from ..database import AsyncSessionLocal
from ..models.match import Match
from ..utils.jwt import decode_access_token
from .battle_engine import run_battle_engine

router = APIRouter()

_connected: Dict[str, Set[str]] = {}
_answer_queues: Dict[str, Dict[str, asyncio.Queue]] = {}
_broadcast_queues: Dict[str, list] = {}
_engine_started: Dict[str, bool] = {}


async def _is_bot_match(match_id: str) -> bool:
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(Match).where(Match.id == match_id))
        match = result.scalar_one_or_none()
        return match is not None and match.player2_id is None


@router.websocket("/ws/battle/{match_id}")
async def battle_ws(websocket: WebSocket, match_id: str):
    await websocket.accept()

    token = websocket.query_params.get("token", "")
    try:
        user_id = decode_access_token(token)
    except JWTError:
        await websocket.send_json({"event": "error", "message": "Invalid token"})
        await websocket.close()
        return

    if match_id not in _connected:
        _connected[match_id] = set()
        _answer_queues[match_id] = {}
        _broadcast_queues[match_id] = []
        _engine_started[match_id] = False

    _connected[match_id].add(user_id)

    # Tell the client which player slot they are (needed for score assignment)
    async with AsyncSessionLocal() as _db:
        _m = (await _db.execute(select(Match).where(Match.id == match_id))).scalar_one_or_none()
        if _m:
            await websocket.send_json({
                "event": "battle_info",
                "player1_id": _m.player1_id,
            })

    answer_q: asyncio.Queue = asyncio.Queue()
    _answer_queues[match_id][user_id] = answer_q

    recv_q: asyncio.Queue = asyncio.Queue()
    _broadcast_queues[match_id].append(recv_q)

    # Start engine when:
    # - 2 real players connected (PvP), OR
    # - 1 player connected and it's a bot match
    if not _engine_started[match_id]:
        bot = await _is_bot_match(match_id)
        should_start = (len(_connected[match_id]) >= 2) or bot
        if should_start:
            _engine_started[match_id] = True
            asyncio.create_task(_run_engine_and_broadcast(match_id))

    async def _receive_answers():
        try:
            while True:
                raw = await websocket.receive_text()
                msg = json.loads(raw)
                if msg.get("event") == "answer":
                    await answer_q.put(msg)
        except (WebSocketDisconnect, Exception):
            pass

    recv_task = asyncio.create_task(_receive_answers())

    try:
        while True:
            event = await recv_q.get()
            try:
                await websocket.send_json(event)
            except Exception:
                break
            if event.get("event") == "game_over":
                break
    except WebSocketDisconnect:
        pass
    finally:
        recv_task.cancel()
        _connected.get(match_id, set()).discard(user_id)
        _answer_queues.get(match_id, {}).pop(user_id, None)
        try:
            _broadcast_queues.get(match_id, []).remove(recv_q)
        except ValueError:
            pass
        if not _connected.get(match_id):
            _connected.pop(match_id, None)
            _answer_queues.pop(match_id, None)
            _broadcast_queues.pop(match_id, None)
            _engine_started.pop(match_id, None)


async def _run_engine_and_broadcast(match_id: str) -> None:
    answer_queues = _answer_queues.get(match_id, {})

    async def _broadcast(event: dict) -> None:
        for q in list(_broadcast_queues.get(match_id, [])):
            await q.put(event)

    await run_battle_engine(match_id, _broadcast, answer_queues)
