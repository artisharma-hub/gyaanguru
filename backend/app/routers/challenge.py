import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..config import settings
from ..database import get_db
from ..models.challenge import Challenge
from ..models.match import Match
from ..models.user import User
from ..schemas.match import CreateChallengeRequest
from ..utils.deps import get_current_user

router = APIRouter(prefix="/api/challenge", tags=["challenge"])


def _challenge_response(challenge: Challenge, challenger: Optional[User]) -> dict:
    return {
        "status": "success",
        "data": {
            "token": challenge.token,
            "challenger": {
                "id": challenger.id if challenger else "",
                "name": challenger.name if challenger else "Unknown",
                "avatar_color": challenger.avatar_color if challenger else "#6C63FF",
            },
            "category": challenge.category,
            "challenge_status": challenge.status,
            "expires_at": challenge.expires_at.isoformat(),
        },
    }


@router.get("/open/{token}")
async def get_challenge_by_link(
    token: str,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
):
    """
    API endpoint — returns JSON challenge data for the given share token.
    Used by the mobile app when a user taps a challenge deeplink.
    """
    result = await db.execute(select(Challenge).where(Challenge.token == token))
    challenge = result.scalar_one_or_none()
    if challenge is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"status": "error", "message": "Challenge not found"},
        )

    if datetime.now(timezone.utc) > challenge.expires_at.replace(tzinfo=timezone.utc):
        challenge.status = "expired"
        raise HTTPException(
            status_code=status.HTTP_410_GONE,
            detail={"status": "error", "message": "Challenge has expired"},
        )

    result2 = await db.execute(select(User).where(User.id == challenge.challenger_id))
    challenger = result2.scalar_one_or_none()
    return _challenge_response(challenge, challenger)


@router.post("/create")
async def create_challenge(
    body: CreateChallengeRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    token = str(uuid.uuid4())
    expires_at = datetime.now(timezone.utc) + timedelta(hours=24)
    challenge = Challenge(
        token=token,
        challenger_id=user.id,
        category=body.category,
        expires_at=expires_at,
    )
    db.add(challenge)
    await db.flush()

    # Share link points to the HTML deeplink page (no /api/ prefix)
    return {
        "token": token,
        "link": f"{settings.public_url}/challenge/open/{token}",
        "expires_at": expires_at.isoformat(),
    }


@router.get("/{token}")
async def get_challenge(
    token: str,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
):
    """JSON API — fetch challenge data by token (used internally by the app)."""
    result = await db.execute(select(Challenge).where(Challenge.token == token))
    challenge = result.scalar_one_or_none()
    if challenge is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Challenge not found")

    if datetime.now(timezone.utc) > challenge.expires_at.replace(tzinfo=timezone.utc):
        challenge.status = "expired"
        raise HTTPException(status_code=status.HTTP_410_GONE, detail="Challenge expired")

    result2 = await db.execute(select(User).where(User.id == challenge.challenger_id))
    challenger = result2.scalar_one_or_none()

    return {
        "token": token,
        "challenger": {
            "id": challenger.id if challenger else "",
            "name": challenger.name if challenger else "Unknown",
            "avatar_color": challenger.avatar_color if challenger else "#6C63FF",
        },
        "category": challenge.category,
        "status": challenge.status,
    }


@router.post("/{token}/join")
async def join_challenge(
    token: str,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    result = await db.execute(select(Challenge).where(Challenge.token == token))
    challenge = result.scalar_one_or_none()
    if challenge is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Challenge not found")
    if challenge.status != "pending":
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Challenge already used or expired")
    if challenge.challenger_id == user.id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Cannot join your own challenge")

    match = Match(
        player1_id=challenge.challenger_id,
        player2_id=user.id,
        category=challenge.category,
        status="waiting",
    )
    db.add(match)
    await db.flush()

    challenge.status = "accepted"
    challenge.match_id = match.id

    return {"match_id": match.id}
