from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse

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


# ── Deeplink / web landing page ────────────────────────────────────────────────
# This route lives OUTSIDE /api/ — browsers open it via share links.
# It auto-redirects to the Flutter app via the custom URI scheme.
@app.get("/challenge/open/{token}", response_class=HTMLResponse, include_in_schema=False)
async def challenge_deeplink(token: str):
    deep_link = f"gyaanguru:///challenge/accept/{token}"
    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Gyaan Guru Challenge</title>
  <style>
    body {{ background:#0A0D1A; color:#fff; font-family:sans-serif;
           display:flex; flex-direction:column; align-items:center;
           justify-content:center; height:100vh; margin:0; text-align:center; }}
    h2  {{ color:#00C8AA; font-size:1.6rem; margin-bottom:.5rem; }}
    p   {{ color:#8B9CB6; font-size:.95rem; }}
    a   {{ display:inline-block; margin-top:1.5rem; padding:.9rem 2.2rem;
           background:linear-gradient(135deg,#00C8AA,#4169E1);
           color:#fff; text-decoration:none;
           border-radius:14px; font-weight:700; font-size:1rem; }}
  </style>
</head>
<body>
  <h2>⚔️ Gyaan Guru Challenge</h2>
  <p>Opening the app…</p>
  <a href="{deep_link}">Open in Gyaan Guru</a>
  <script>
    setTimeout(function() {{ window.location.href = "{deep_link}"; }}, 300);
  </script>
</body>
</html>"""
    return HTMLResponse(content=html)
