from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .database import init_db
from .routers import auth, categories, challenge, daily, leaderboard, match
from .websockets.battle import router as battle_ws_router
from .websockets.matchmaking import router as matchmaking_ws_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    yield


app = FastAPI(title="Gyaan Guru API", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(categories.router)
app.include_router(leaderboard.router)
app.include_router(challenge.router)
app.include_router(daily.router)
app.include_router(match.router)
app.include_router(matchmaking_ws_router)
app.include_router(battle_ws_router)


@app.get("/health")
async def health():
    return {"status": "ok"}
