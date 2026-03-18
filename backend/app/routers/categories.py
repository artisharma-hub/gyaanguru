from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from ..database import get_db
from ..models.question import Question

router = APIRouter(prefix="/api", tags=["categories"])

CATEGORIES = [
    {"key": "cricket",   "name": "Cricket & Sports"},
    {"key": "bollywood", "name": "Bollywood & OTT"},
    {"key": "gk",        "name": "Indian GK & History"},
    {"key": "math",      "name": "Rapid Math"},
    {"key": "science",   "name": "Science & Tech"},
    {"key": "hindi",     "name": "Hindi Wordplay"},
]


@router.get("/categories")
async def get_categories(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Question.category, func.count(Question.id)).group_by(Question.category)
    )
    counts = {row[0]: row[1] for row in result.all()}
    return {
        "categories": [
            {**cat, "count": counts.get(cat["key"], 0)}
            for cat in CATEGORIES
        ]
    }
