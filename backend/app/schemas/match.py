from typing import Dict

from pydantic import BaseModel


class CreateChallengeRequest(BaseModel):
    category: str


class SubmitDailyRequest(BaseModel):
    challenge_date: str  # YYYY-MM-DD
    answers: Dict[str, str]  # question_id -> option letter
