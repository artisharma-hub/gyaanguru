from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..database import get_db
from ..models.user import User
from ..schemas.auth import LoginRequest, RegisterRequest, TokenResponse
from ..utils.deps import get_current_user
from ..utils.jwt import create_access_token

router = APIRouter(prefix="/api/auth", tags=["auth"])

AVATAR_COLORS = [
    "#6C63FF", "#E65100", "#1565C0", "#C2185B",
    "#2E7D32", "#6A1B9A", "#00695C", "#F5A623",
]


@router.post("/register", response_model=TokenResponse)
async def register(body: RegisterRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.phone == body.phone))
    user = result.scalar_one_or_none()

    existing_name: str | None = None
    if user is None:
        # Deterministic avatar color from phone digits
        color = AVATAR_COLORS[int(body.phone[-1]) % len(AVATAR_COLORS)]
        user = User(name=body.name, phone=body.phone, avatar_color=color)
        db.add(user)
        await db.flush()
    else:
        # Phone already registered — keep the saved name, but surface it if different
        if user.name.strip().lower() != body.name.strip().lower():
            existing_name = user.name

    token = create_access_token(user.id)
    return TokenResponse(token=token, user=user.to_dict(), existing_name=existing_name)


@router.post("/login", response_model=TokenResponse)
async def login(body: LoginRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.phone == body.phone))
    user = result.scalar_one_or_none()
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    token = create_access_token(user.id)
    return TokenResponse(token=token, user=user.to_dict())


@router.get("/me")
async def get_me(user: User = Depends(get_current_user)):
    return user.to_dict()


class UpdateProfileRequest(BaseModel):
    name: Optional[str] = None
    avatar_color: Optional[str] = None


@router.patch("/profile")
async def update_profile(
    body: UpdateProfileRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
):
    if body.name is not None:
        name = body.name.strip()
        if not name:
            raise HTTPException(status_code=400, detail="Name cannot be empty")
        user.name = name
    if body.avatar_color is not None:
        user.avatar_color = body.avatar_color
    await db.flush()
    return user.to_dict()
