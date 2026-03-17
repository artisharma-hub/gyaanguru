from typing import List

from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from ..database import get_db
from ..models.user import User
from ..utils.deps import get_current_user

router = APIRouter(prefix="/api/leaderboard", tags=["leaderboard"])


async def _build_leaderboard(users: List[User], current_user: User) -> dict:
    players = []
    for rank, u in enumerate(users, start=1):
        players.append({
            "id": u.id,
            "name": u.name,
            "avatar_color": u.avatar_color,
            "wins": u.wins,
            "coins": u.coins,
            "rank": rank,
        })

    my_rank = next((p["rank"] for p in players if p["id"] == current_user.id), None)
    return {"players": players, "my_rank": my_rank}


@router.get("/global")
async def global_leaderboard(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(User).order_by(User.wins.desc(), User.coins.desc()).limit(50)
    )
    users = result.scalars().all()
    return await _build_leaderboard(list(users), current_user)


@router.get("/weekly")
async def weekly_leaderboard(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(User).order_by(User.weekly_score.desc(), User.wins.desc()).limit(50)
    )
    users = result.scalars().all()
    return await _build_leaderboard(list(users), current_user)


@router.get("/category/{category}")
async def category_leaderboard(
    category: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    from ..models.match import Match
    # Aggregate wins per player in this category
    subq = (
        select(Match.winner_id, func.count(Match.id).label("cat_wins"))
        .where(Match.category == category, Match.winner_id.isnot(None))
        .group_by(Match.winner_id)
        .order_by(func.count(Match.id).desc())
        .limit(50)
        .subquery()
    )
    result = await db.execute(
        select(User, subq.c.cat_wins)
        .join(subq, User.id == subq.c.winner_id)
        .order_by(subq.c.cat_wins.desc())
    )
    rows = result.all()

    players = [
        {
            "id": u.id,
            "name": u.name,
            "avatar_color": u.avatar_color,
            "wins": cat_wins,
            "coins": u.coins,
            "rank": rank,
        }
        for rank, (u, cat_wins) in enumerate(rows, start=1)
    ]
    my_rank = next((p["rank"] for p in players if p["id"] == current_user.id), None)
    return {"players": players, "my_rank": my_rank}
