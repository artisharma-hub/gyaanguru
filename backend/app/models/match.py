import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, ForeignKey, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column

from ..database import Base

MATCH_STATUS = ["waiting", "playing", "finished", "cancelled"]


class Match(Base):
    __tablename__ = "matches"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    player1_id: Mapped[str] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    player2_id: Mapped[Optional[str]] = mapped_column(ForeignKey("users.id"), nullable=True, index=True)
    category: Mapped[str] = mapped_column(String(30), nullable=False)
    player1_score: Mapped[int] = mapped_column(Integer, default=0)
    player2_score: Mapped[int] = mapped_column(Integer, default=0)
    winner_id: Mapped[Optional[str]] = mapped_column(ForeignKey("users.id"), nullable=True)
    status: Mapped[str] = mapped_column(String(20), default="waiting", index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    finished_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)


class MatchAnswer(Base):
    __tablename__ = "match_answers"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    match_id: Mapped[str] = mapped_column(ForeignKey("matches.id"), nullable=False, index=True)
    player_id: Mapped[str] = mapped_column(ForeignKey("users.id"), nullable=False)
    question_id: Mapped[str] = mapped_column(ForeignKey("questions.id"), nullable=False)
    selected_option: Mapped[Optional[str]] = mapped_column(String(1), nullable=True)
    is_correct: Mapped[bool] = mapped_column(default=False)
    time_taken_ms: Mapped[int] = mapped_column(Integer, default=0)
