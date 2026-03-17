from fastapi import APIRouter

router = APIRouter(prefix="/api", tags=["categories"])

CATEGORIES = [
    {"key": "cricket",   "name": "Cricket & Sports",    "count": 500},
    {"key": "bollywood", "name": "Bollywood & OTT",      "count": 450},
    {"key": "gk",        "name": "Indian GK & History",  "count": 600},
    {"key": "math",      "name": "Rapid Math",           "count": 300},
    {"key": "science",   "name": "Science & Tech",       "count": 400},
    {"key": "hindi",     "name": "Hindi Wordplay",       "count": 250},
]


@router.get("/categories")
async def get_categories():
    return {"categories": CATEGORIES}
