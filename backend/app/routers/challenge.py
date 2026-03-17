import uuid
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import HTMLResponse
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


@router.get("/open/{token}", response_class=HTMLResponse)
async def open_challenge_link(token: str):
    """
    HTTP redirect page — makes the share link clickable in WhatsApp/SMS.
    Browser opens this URL → JS redirects to gyaanguru://challenge/{token} → app opens.
    """
    deep_link = f"gyaanguru:///challenge/accept/{token}"
    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Gyaan Guru Challenge</title>
  <style>
    body {{ background:#07080F; color:#fff; font-family:sans-serif;
           display:flex; flex-direction:column; align-items:center;
           justify-content:center; height:100vh; margin:0; text-align:center; }}
    h2  {{ color:#FF4500; font-size:1.6rem; margin-bottom:.5rem; }}
    p   {{ color:#7080A0; font-size:.95rem; }}
    a   {{ display:inline-block; margin-top:1.5rem; padding:.9rem 2.2rem;
           background:#FF4500; color:#fff; text-decoration:none;
           border-radius:14px; font-weight:700; font-size:1rem; }}
  </style>
</head>
<body>
  <h2>⚔️ Gyaan Guru Challenge</h2>
  <p>Opening the app…</p>
  <a href="{deep_link}">Open in Gyaan Guru</a>
  <script>
    setTimeout(function() {{ window.location.href = "{deep_link}"; }}, 300);
  </script>
</body>
</html>"""
    return HTMLResponse(content=html)


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

    return {
        "token": token,
        "link": f"{settings.public_url}/api/challenge/open/{token}",
        "expires_at": expires_at.isoformat(),
    }


@router.get("/{token}")
async def get_challenge(
    token: str,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
):
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
