import uuid

from sqlalchemy import String, Text
from sqlalchemy.orm import Mapped, mapped_column

from ..database import Base

CATEGORIES = ["cricket", "bollywood", "gk", "math", "science", "hindi"]
DIFFICULTIES = ["easy", "medium", "hard"]
LANGUAGES = ["en", "hi"]


class Question(Base):
    __tablename__ = "questions"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    question_text: Mapped[str] = mapped_column(Text, nullable=False)
    option_a: Mapped[str] = mapped_column(String(300), nullable=False)
    option_b: Mapped[str] = mapped_column(String(300), nullable=False)
    option_c: Mapped[str] = mapped_column(String(300), nullable=False)
    option_d: Mapped[str] = mapped_column(String(300), nullable=False)
    correct_option: Mapped[str] = mapped_column(String(1), nullable=False)  # A/B/C/D
    category: Mapped[str] = mapped_column(String(30), nullable=False, index=True)
    difficulty: Mapped[str] = mapped_column(String(10), default="medium")
    language: Mapped[str] = mapped_column(String(5), default="en")

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "question_text": self.question_text,
            "options": {
                "A": self.option_a,
                "B": self.option_b,
                "C": self.option_c,
                "D": self.option_d,
            },
            "correct_option": self.correct_option,
            "category": self.category,
            "difficulty": self.difficulty,
            "language": self.language,
        }
