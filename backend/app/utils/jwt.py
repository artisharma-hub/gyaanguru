from datetime import datetime, timedelta, timezone
from typing import Optional

from jose import JWTError, jwt

from ..config import settings


def create_access_token(user_id: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(hours=settings.jwt_expire_hours)
    payload = {"sub": user_id, "exp": expire}
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def decode_access_token(token: str) -> str:
    """Returns user_id or raises JWTError."""
    payload = jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
    user_id: Optional[str] = payload.get("sub")
    if user_id is None:
        raise JWTError("Missing sub claim")
    return user_id
