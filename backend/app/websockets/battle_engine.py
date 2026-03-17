"""
Battle engine — runs as an asyncio task for each active match.

Calls broadcast(event_dict) to publish events to both players.
No Redis required.
"""
import asyncio
import random
from datetime import datetime, timezone
from typing import Callable, Dict, List, Optional, Tuple

from sqlalchemy import select

from ..database import AsyncSessionLocal
from ..models.match import Match, MatchAnswer
from ..models.question import Question
from ..models.user import User

QUESTION_COUNT = 10
QUESTION_TIMEOUT = 10.0
RESULT_PAUSE = 2.0
COINS_WIN = 30
COINS_LOSE = 10


async def run_battle_engine(
    match_id: str,
    broadcast: Callable[[dict], None],
    answer_queues: Dict[str, asyncio.Queue],
) -> None:
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(Match).where(Match.id == match_id))
        match = result.scalar_one_or_none()
        if match is None:
            return

        p1_id: str = match.player1_id
        p2_id: Optional[str] = match.player2_id
        category: str = match.category

        q_result = await db.execute(
            select(Question)
            .where(Question.category == category)
            .order_by(Question.id)
            .limit(QUESTION_COUNT)
        )
        questions = q_result.scalars().all()
        if not questions:
            q_result2 = await db.execute(select(Question).limit(QUESTION_COUNT))
            questions = q_result2.scalars().all()

        if not questions:
            await broadcast({"event": "error", "message": "No questions available"})
            return

        match.status = "playing"
        await db.commit()

    # Countdown
    for i in (3, 2, 1):
        await broadcast({"event": "countdown", "seconds": i})
        await asyncio.sleep(1.0)

    p1_score = 0
    p2_score = 0
    answers_to_save: List[dict] = []

    for idx, question in enumerate(questions):
        await broadcast({"event": "question", "question": question.to_dict(), "index": idx + 1})

        start = asyncio.get_event_loop().time()

        async def _collect(player_id: str) -> Tuple[Optional[str], float]:
            q = answer_queues.get(player_id)
            if q is None:
                return None, QUESTION_TIMEOUT * 1000
            remaining = QUESTION_TIMEOUT - (asyncio.get_event_loop().time() - start)
            try:
                msg = await asyncio.wait_for(q.get(), timeout=max(0.1, remaining))
                if msg.get("question_id") == question.id:
                    elapsed = (asyncio.get_event_loop().time() - start) * 1000
                    return msg.get("option"), elapsed
            except asyncio.TimeoutError:
                pass
            return None, QUESTION_TIMEOUT * 1000

        async def _bot_answer() -> Tuple[Optional[str], float]:
            # Bot answers after a random delay (1–7s), correct 60% of the time
            delay = random.uniform(1.0, 7.0)
            await asyncio.sleep(delay)
            if random.random() < 0.6:
                ans = question.correct_option
            else:
                wrong = [o for o in ["A", "B", "C", "D"] if o != question.correct_option]
                ans = random.choice(wrong)
            return ans, delay * 1000

        (p1_ans, p1_time), (p2_ans, p2_time) = await asyncio.gather(
            _collect(p1_id),
            _bot_answer() if p2_id is None else _collect(p2_id),
        )

        correct = question.correct_option
        p1_correct = p1_ans == correct
        p2_correct = p2_ans == correct

        if p1_correct:
            p1_score += 10
        if p2_correct:
            p2_score += 10

        answers_to_save.append({
            "match_id": match_id,
            "p1_id": p1_id, "p2_id": p2_id,
            "question_id": question.id,
            "p1_ans": p1_ans, "p2_ans": p2_ans,
            "p1_correct": p1_correct, "p2_correct": p2_correct,
            "p1_time": int(p1_time), "p2_time": int(p2_time),
        })

        await broadcast({
            "event": "result",
            "question_id": question.id,
            "correct_option": correct,
            "p1_correct": p1_correct,
            "p2_correct": p2_correct,
            "p1_score": p1_score,
            "p2_score": p2_score,
        })

        await asyncio.sleep(RESULT_PAUSE)

    winner_id: Optional[str] = None
    if p1_score > p2_score:
        winner_id = p1_id
    elif p2_score > p1_score:
        winner_id = p2_id

    await broadcast({
        "event": "game_over",
        "p1_score": p1_score,
        "p2_score": p2_score,
        "winner_id": winner_id,
        "p1_coins_earned": COINS_WIN if winner_id == p1_id else COINS_LOSE,
        "p2_coins_earned": COINS_WIN if winner_id == p2_id else COINS_LOSE,
        "xp_earned": 50,
    })

    # Persist results
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(Match).where(Match.id == match_id))
        match = result.scalar_one_or_none()
        if match:
            match.player1_score = p1_score
            match.player2_score = p2_score
            match.winner_id = winner_id
            match.status = "finished"
            match.finished_at = datetime.now(timezone.utc)

        for a in answers_to_save:
            for player_id, ans, correct, time_ms in [
                (a["p1_id"], a["p1_ans"], a["p1_correct"], a["p1_time"]),
                (a["p2_id"], a["p2_ans"], a["p2_correct"], a["p2_time"]),
            ]:
                if player_id:
                    db.add(MatchAnswer(
                        match_id=a["match_id"],
                        player_id=player_id,
                        question_id=a["question_id"],
                        selected_option=ans,
                        is_correct=correct,
                        time_taken_ms=time_ms,
                    ))

        for player_id, won in [(p1_id, winner_id == p1_id), (p2_id, winner_id == p2_id)]:
            if not player_id:
                continue
            u_result = await db.execute(select(User).where(User.id == player_id))
            user = u_result.scalar_one_or_none()
            if user:
                user.total_matches += 1
                user.coins = max(0, user.coins + (COINS_WIN if won else COINS_LOSE))
                if won:
                    user.wins += 1
                    user.win_streak += 1
                    user.best_streak = max(user.best_streak, user.win_streak)
                    user.weekly_score += 30
                else:
                    user.win_streak = 0

        await db.commit()
