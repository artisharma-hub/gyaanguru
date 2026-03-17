import json
from datetime import date, datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from ..database import get_db
from ..models.daily import DailyChallenge, DailySubmission
from ..models.question import Question
from ..models.user import User
from ..schemas.match import SubmitDailyRequest
from ..utils.deps import get_current_user

router = APIRouter(prefix="/api/daily", tags=["daily"])

DAILY_QUESTION_COUNT = 10


async def _get_or_create_daily(db: AsyncSession, today: date) -> DailyChallenge:
    result = await db.execute(select(DailyChallenge).where(DailyChallenge.date == today))
    daily = result.scalar_one_or_none()
    if daily is not None:
        return daily

    # Pick 10 random questions spread across categories
    result2 = await db.execute(
        select(Question.id).order_by(func.random()).limit(DAILY_QUESTION_COUNT)
    )
    question_ids = [row[0] for row in result2.all()]
    daily = DailyChallenge(date=today, question_ids=json.dumps(question_ids))
    db.add(daily)
    await db.flush()
    return daily


@router.get("")
async def get_daily_challenge(
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    today = datetime.now(timezone.utc).date()
    daily = await _get_or_create_daily(db, today)

    already_played = False
    sub_result = await db.execute(
        select(DailySubmission).where(
            DailySubmission.user_id == user.id,
            DailySubmission.challenge_date == today,
        )
    )
    if sub_result.scalar_one_or_none():
        already_played = True

    question_ids = json.loads(daily.question_ids)
    q_result = await db.execute(select(Question).where(Question.id.in_(question_ids)))
    questions = q_result.scalars().all()

    return {
        "date": str(today),
        "questions": [q.to_dict() for q in questions],
        "already_played": already_played,
    }


@router.post("/submit")
async def submit_daily(
    body: SubmitDailyRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    challenge_date = date.fromisoformat(body.challenge_date)

    existing = await db.execute(
        select(DailySubmission).where(
            DailySubmission.user_id == user.id,
            DailySubmission.challenge_date == challenge_date,
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Already submitted today")

    daily_result = await db.execute(select(DailyChallenge).where(DailyChallenge.date == challenge_date))
    daily = daily_result.scalar_one_or_none()
    if daily is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Daily challenge not found")

    question_ids = json.loads(daily.question_ids)
    q_result = await db.execute(select(Question).where(Question.id.in_(question_ids)))
    questions = {q.id: q for q in q_result.scalars().all()}

    score = 0
    for qid, selected in body.answers.items():
        q = questions.get(qid)
        if q and q.correct_option == selected:
            score += 10

    # Count rank: how many users scored higher today
    rank_result = await db.execute(
        select(func.count(DailySubmission.id)).where(
            DailySubmission.challenge_date == challenge_date,
            DailySubmission.score > score,
        )
    )
    rank = (rank_result.scalar() or 0) + 1

    submission = DailySubmission(
        user_id=user.id,
        challenge_date=challenge_date,
        answers=json.dumps(body.answers),
        score=score,
        rank=rank,
    )
    db.add(submission)

    # Award coins
    user.coins += max(5, score // 2)
    user.weekly_score += score

    return {"score": score, "rank": rank}
