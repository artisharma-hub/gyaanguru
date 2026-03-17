import uuid
from datetime import date as date_type
from datetime import datetime
from typing import Optional

from sqlalchemy import Date, DateTime, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from ..database import Base


class DailyChallenge(Base):
    __tablename__ = "daily_challenges"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    date: Mapped[date_type] = mapped_column(Date, unique=True, nullable=False, index=True)
    question_ids: Mapped[str] = mapped_column(Text, nullable=False)  # JSON list


class DailySubmission(Base):
    __tablename__ = "daily_submissions"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    challenge_date: Mapped[date_type] = mapped_column(Date, nullable=False, index=True)
    answers: Mapped[str] = mapped_column(Text, nullable=False)  # JSON dict
    score: Mapped[int] = mapped_column(Integer, default=0)
    rank: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    submitted_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
