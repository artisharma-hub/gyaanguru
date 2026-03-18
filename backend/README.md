# Gyaan Guru — Backend

FastAPI + PostgreSQL + Redis backend for the Gyaan Guru quiz app.

---

## Prerequisites

### Option A — Docker Compose
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (includes Compose)

### Option B — Local
- Python 3.12+
- PostgreSQL 16
- Redis 7

---

## Option A — Docker Compose

> Spins up the API, PostgreSQL, and Redis together in containers. No manual DB setup needed.

**1. Build and start all services**

```bash
cd backend
docker compose up --build
```

**2. (First run only) Seed sample questions**

```bash
docker compose exec api python seed_questions.py
```

**3. Access the API**

- API: http://localhost:8000
- Swagger docs: http://localhost:8000/docs
- Health check: http://localhost:8000/health

**Stop services**

```bash
docker compose down          # keeps database data
docker compose down -v       # deletes database data too
```

---

## Option B — Local Setup

### 1. Install dependencies

**macOS (Homebrew)**

```bash
brew install postgresql@16 redis
brew services start postgresql@16
brew services start redis
```

**Ubuntu/Debian**

```bash
sudo apt install postgresql redis-server
sudo systemctl start postgresql redis
```

### 2. Create the database

```bash
psql postgres
```

```sql
CREATE USER gyaan WITH PASSWORD 'gyaan123';
CREATE DATABASE gyaan_guru OWNER gyaan;
\q
```

### 3. Set up Python environment

```bash
cd backend
python3 -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 4. Configure environment variables

```bash
cp .env.example .env
```

Edit `.env` for local development:

```env
DATABASE_URL=postgresql+asyncpg://gyaan:gyaan123@localhost:5432/gyaan_guru
REDIS_URL=redis://localhost:6379/0
JWT_SECRET=dev-secret
JWT_ALGORITHM=HS256
JWT_EXPIRE_HOURS=720
ENVIRONMENT=development
PORT=8000
```

### 5. Run database migrations

```bash
alembic upgrade head
```

### 6. (Optional) Seed sample questions

```bash
python seed_questions.py
```

### 7. Start the server

```bash
python run.py
```

- API: http://localhost:8000
- Swagger docs: http://localhost:8000/docs
- Health check: http://localhost:8000/health

---

## Environment Variables

| Variable           | Default                                                          | Description                          |
|--------------------|------------------------------------------------------------------|--------------------------------------|
| `DATABASE_URL`     | `postgresql+asyncpg://gyaan:gyaan123@localhost:5432/gyaan_guru` | PostgreSQL async connection string   |
| `REDIS_URL`        | `redis://localhost:6379/0`                                       | Redis connection string              |
| `JWT_SECRET`       | `dev-secret`                                                     | Secret key for JWT tokens            |
| `JWT_ALGORITHM`    | `HS256`                                                          | JWT signing algorithm                |
| `JWT_EXPIRE_HOURS` | `720`                                                            | Token expiry in hours (30 days)      |
| `PORT`             | `8000`                                                           | Port the server listens on           |
| `ENVIRONMENT`      | `development`                                                    | `development` or `production`        |
| `PUBLIC_URL`       | `http://192.168.100.53:8000`                                     | Base URL for challenge share links   |

> **Production note:** Use a strong random `JWT_SECRET` — generate one with:
> ```bash
> python -c "import secrets; print(secrets.token_hex(32))"
> ```

---

## Project Structure

```
backend/
├── app/
│   ├── main.py              # FastAPI app, middleware, router registration
│   ├── config.py            # Settings loaded from environment / .env
│   ├── database.py          # Async SQLAlchemy session setup
│   ├── models/              # SQLAlchemy ORM models
│   ├── routers/             # REST API route handlers
│   │   ├── auth.py
│   │   ├── categories.py
│   │   ├── challenge.py
│   │   ├── daily.py
│   │   ├── leaderboard.py
│   │   └── match.py
│   ├── schemas/             # Pydantic request/response schemas
│   ├── services/            # Business logic
│   ├── utils/               # JWT helpers, auth deps, Redis client
│   └── websockets/          # WebSocket handlers
│       ├── battle.py
│       ├── battle_engine.py
│       └── matchmaking.py
├── alembic/                 # Database migration scripts
├── alembic.ini              # Alembic configuration
├── seed_questions.py        # Populates DB with sample quiz questions
├── run.py                   # Dev server entry point (uvicorn with reload)
├── requirements.txt
├── Dockerfile
└── docker-compose.yml
```
