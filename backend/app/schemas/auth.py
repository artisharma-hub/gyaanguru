from typing import Optional

from pydantic import BaseModel, field_validator


def _normalize_phone(raw: str) -> str:
    """Strip non-digits; if result is longer than 10 digits, keep the last 10."""
    digits = "".join(c for c in raw.strip() if c.isdigit())
    if len(digits) > 10:
        digits = digits[-10:]
    if len(digits) != 10:
        raise ValueError("Phone must be a valid 10-digit mobile number")
    return digits


class RegisterRequest(BaseModel):
    name: str
    phone: str

    @field_validator("name")
    @classmethod
    def name_not_empty(cls, v: str) -> str:
        v = v.strip()
        if len(v) < 2:
            raise ValueError("Name must be at least 2 characters")
        return v

    @field_validator("phone")
    @classmethod
    def phone_valid(cls, v: str) -> str:
        return _normalize_phone(v)


class LoginRequest(BaseModel):
    phone: str

    @field_validator("phone")
    @classmethod
    def phone_valid(cls, v: str) -> str:
        return _normalize_phone(v)


class TokenResponse(BaseModel):
    token: str
    user: dict
    existing_name: Optional[str] = None
