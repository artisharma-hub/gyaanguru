from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from ..database import get_db
from ..models.match import Match
from ..models.user import User
from ..utils.deps import get_current_user

router = APIRouter(prefix="/api/match", tags=["match"])


@router.post("/bot")
async def create_bot_match(
    category: str = "cricket",
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    """Create a match against the bot (player2_id = None)."""
    match = Match(
        player1_id=user.id,
        player2_id=None,
        category=category,
        status="waiting",
    )
    db.add(match)
    await db.flush()
    return {
        "match_id": match.id,
        "opponent": {
            "id": "gyaan-bot",
            "name": "Gyaan Bot",
            "avatar_color": "#E65100",
        },
    }
