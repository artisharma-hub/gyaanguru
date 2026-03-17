"""
Matchmaking WebSocket — ws/match/{user_id}?category=xxx&token=xxx

Uses in-memory asyncio queues for local dev (no Redis required).
When both players are in the same process (single uvicorn worker), this works perfectly.
"""
import asyncio
import json
from typing import Dict, Optional

from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from jose import JWTError
from sqlalchemy import select

from ..database import AsyncSessionLocal
from ..models.match import Match
from ..models.user import User
from ..utils.jwt import decode_access_token

router = APIRouter()

# category -> list of (user_id, asyncio.Queue) waiting to be paired
_waiting: Dict[str, list] = {}
_waiting_lock = asyncio.Lock()


@router.websocket("/ws/match/{user_id}")
async def matchmaking_ws(websocket: WebSocket, user_id: str):
    await websocket.accept()

    token = websocket.query_params.get("token", "")
    category = websocket.query_params.get("category", "cricket")

    try:
        claimed_id = decode_access_token(token)
        if claimed_id != user_id:
            await websocket.send_json({"event": "error", "message": "Token mismatch"})
            await websocket.close()
            return
    except JWTError:
        await websocket.send_json({"event": "error", "message": "Invalid token"})
        await websocket.close()
        return

    await websocket.send_json({"event": "searching"})

    notify_queue: asyncio.Queue = asyncio.Queue()

    async with _waiting_lock:
        if category not in _waiting:
            _waiting[category] = []
        _waiting[category].append((user_id, notify_queue))

        # If two players are now waiting, pair them immediately
        if len(_waiting[category]) >= 2:
            (p1_id, p1_q) = _waiting[category].pop(0)
            (p2_id, p2_q) = _waiting[category].pop(0)
            asyncio.create_task(_pair_and_notify(p1_id, p1_q, p2_id, p2_q, category))

    # Wait for the matched event (or disconnect)
    try:
        matched_data = await asyncio.wait_for(notify_queue.get(), timeout=60.0)
        await websocket.send_json(matched_data)
        # Hold connection briefly so Flutter can read the event
        try:
            await asyncio.wait_for(websocket.receive_text(), timeout=3.0)
        except Exception:
            pass
    except asyncio.TimeoutError:
        # Remove from waiting list first
        async with _waiting_lock:
            if category in _waiting:
                _waiting[category] = [
                    (uid, q) for uid, q in _waiting[category] if uid != user_id
                ]
        # Client may have already disconnected (e.g. chose bot) — ignore send errors
        try:
            await websocket.send_json({"event": "error", "message": "No opponent found. Try again."})
        except Exception:
            pass
    except WebSocketDisconnect:
        async with _waiting_lock:
            if category in _waiting:
                _waiting[category] = [
                    (uid, q) for uid, q in _waiting[category] if uid != user_id
                ]


async def _pair_and_notify(
    p1_id: str,
    p1_q: asyncio.Queue,
    p2_id: str,
    p2_q: asyncio.Queue,
    category: str,
) -> None:
    async with AsyncSessionLocal() as db:
        match = Match(
            player1_id=p1_id,
            player2_id=p2_id,
            category=category,
            status="waiting",
        )
        db.add(match)
        await db.commit()
        await db.refresh(match)
        match_id = match.id

        r1 = await db.execute(select(User).where(User.id == p1_id))
        r2 = await db.execute(select(User).where(User.id == p2_id))
        u1 = r1.scalar_one_or_none()
        u2 = r2.scalar_one_or_none()

    def _opponent_dict(u: Optional[User]) -> dict:
        return {
            "id": u.id if u else "",
            "name": u.name if u else "Opponent",
            "avatar_color": u.avatar_color if u else "#6C63FF",
        }

    await p1_q.put({
        "event": "matched",
        "match_id": match_id,
        "player1_id": p1_id,
        "opponent": _opponent_dict(u2),
    })
    await p2_q.put({
        "event": "matched",
        "match_id": match_id,
        "player1_id": p1_id,
        "opponent": _opponent_dict(u1),
    })
