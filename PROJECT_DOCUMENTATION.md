# Gyaan Guru — Complete Project Documentation

## Table of Contents
1. [Project Overview](#1-project-overview)
2. [Technology Stack](#2-technology-stack)
3. [Frontend Architecture (lib/)](#3-frontend-architecture-lib)
   - [Entry Point & Routing](#31-entry-point--routing)
   - [Theme & Design System](#32-theme--design-system)
   - [Data Models](#33-data-models)
   - [Services](#34-services)
   - [State Management (Riverpod)](#35-state-management-riverpod)
   - [Screens](#36-screens)
   - [Widgets](#37-widgets)
4. [Backend Architecture (backend/)](#4-backend-architecture-backend)
   - [Configuration & Database](#41-configuration--database)
   - [Database Models](#42-database-models)
   - [Auth & Utilities](#43-auth--utilities)
   - [REST API Routers](#44-rest-api-routers)
   - [WebSocket Handlers](#45-websocket-handlers)
   - [Battle Engine](#46-battle-engine)
5. [API Reference](#5-api-reference)
6. [Feature Flows (End-to-End)](#6-feature-flows-end-to-end)
   - [Registration & Login](#61-registration--login)
   - [PvP Matchmaking & Battle](#62-pvp-matchmaking--battle)
   - [Friend Challenge (Deep Link)](#63-friend-challenge-deep-link)
   - [Daily Challenge](#64-daily-challenge)
   - [Leaderboard](#65-leaderboard)
7. [WebSocket Event Reference](#7-websocket-event-reference)
8. [Coin Economy & Game Mechanics](#8-coin-economy--game-mechanics)
9. [Deployment Notes](#9-deployment-notes)

---

## 1. Project Overview

**Gyaan Guru** is a live multiplayer quiz battle app targeting Indian users. Players compete in real-time across 6 knowledge categories, challenge friends via share links, and participate in a daily global quiz.

**Core Experience:**
- Select a category → get matched with a real opponent (or a bot)
- Answer 10 questions in 10 seconds each
- Earn coins and climb leaderboards
- Challenge friends via WhatsApp / SMS deep links
- One daily quiz with global ranking

---

## 2. Technology Stack

| Layer | Technology |
|-------|-----------|
| Frontend UI | Flutter (Dart), Material Design 3 |
| State Management | Riverpod (StateNotifier + AsyncValue) |
| Navigation | GoRouter + AppLinks (deep linking) |
| HTTP Client | Dio |
| WebSocket Client | web_socket_channel |
| Local Storage | SharedPreferences |
| Fonts / Animations | Google Fonts (Nunito), flutter_animate, lottie |
| Backend API | FastAPI (Python, async) |
| Database | PostgreSQL (asyncpg driver) |
| ORM | SQLAlchemy 2.0 (async) |
| Authentication | JWT (python-jose), 30-day tokens |
| Real-time | WebSockets via asyncio.Queue (single-process) |
| Config | Pydantic Settings |

---

## 3. Frontend Architecture (lib/)

### 3.1 Entry Point & Routing

**`lib/main.dart`**
- Wraps app in Riverpod `ProviderScope`
- Listens for deep links via `AppLinks` (cold-start and warm-start)
- Deep link format: `gyaanguru:///challenge/accept/{token}`
- Text scale constrained to 0.85–1.15×

**`lib/app/router.dart`** — 11 routes via GoRouter

| Route | Screen | Notes |
|-------|--------|-------|
| `/` | SplashScreen | Handles auth check + deep link redirect |
| `/register` | RegisterScreen | Phone + name registration |
| `/home` | HomeScreen | Category grid + nav bar index 0 |
| `/matchmaking?category=X` | MatchmakingScreen | WS-based opponent search |
| `/battle/:matchId?category=X` | BattleScreen | Live quiz gameplay |
| `/result` | ResultScreen | Post-match outcome |
| `/challenge/create` | ChallengeCreateScreen | Generate friend challenge link |
| `/challenge/accept/:token` | ChallengeAcceptScreen | Deep link landing page |
| `/daily` | DailyChallengeScreen | Daily quiz (nav bar index 1) |
| `/leaderboard` | LeaderboardScreen | Global/weekly/category rankings (nav bar index 2) |
| `/profile` | ProfileScreen | User profile & settings (nav bar index 3) |

---

### 3.2 Theme & Design System

**`lib/app/theme.dart`**

**Colors (`AppColors`):**
- Primary: `#FF4500` (orange-red)
- Accent: `#0088CC` (cerulean blue)
- Correct: `#16A34A` (green), Wrong: `#DC2626` (red)
- Category colors: Cricket (blue), Bollywood (magenta), GK (gold), Math (purple), Science (cyan), Hindi (green)
- 6 gradient presets (primary, accent, per-category)

**Typography:** Nunito (400–900 weight), sized via `AppSizes.sp()` (scalable) and `AppSizes.hp()` (height-based)

---

### 3.3 Data Models

#### `UserModel` (`lib/models/user_model.dart`)
```
id            String
name          String
phone         String       (masked in UI as ×××× ×××× last4)
avatarColor   String       (hex color)
coins         int
totalMatches  int
wins          int
winStreak     int
bestStreak    int
weeklyScore   int
avatarImagePath  String?   (local path only, not synced to server)

// Computed
winRate  double   (wins / totalMatches)
losses   int      (totalMatches - wins)
```

#### `QuestionModel` (`lib/models/question_model.dart`)
```
id            String
questionText  String
options       Map<String, String>   {A, B, C, D}
correctOption String
category      String
difficulty    String   (default "medium")
language      String   (default "en")
```

#### `MatchState` (`lib/models/match_state.dart`)
```
MatchPhase enum:
  idle | searching | matched | countdown | playing | showResult | finished | error

MatchState {
  phase            MatchPhase
  matchId          String?
  myId             String?
  player1Id        String?
  opponentId       String?
  opponentName     String?
  opponentAvatarColor  String?
  myScore          int
  opponentScore    int
  questions        List<QuestionModel>
  currentQuestionIndex  int
  selectedOption   String?
  correctOption    String?
  winnerId         String?
  coinsEarned      int
  errorMessage     String?
  countdown        int        (3 → 2 → 1 → 0)

  // Computed
  isPlayer1    bool
  isWinner     bool
  isTie        bool
  currentQuestion  QuestionModel?
}
```

---

### 3.4 Services

#### `ApiService` (`lib/services/api_service.dart`)
- HTTP client built on **Dio**
- Base URL: `http://192.168.100.53:8000` (dev)
- Auto-injects `Authorization: Bearer {jwt}` from SharedPreferences on every request

**Methods:**
```
// Auth
register(name, phone)           POST /api/auth/register
login(phone)                    POST /api/auth/login
getMe()                         GET  /api/auth/me
updateProfile(name?, color?)    PATCH /api/auth/profile

// Categories
getCategories()                 GET  /api/categories

// Leaderboard
getGlobalLeaderboard()          GET  /api/leaderboard/global
getWeeklyLeaderboard()          GET  /api/leaderboard/weekly
getCategoryLeaderboard(cat)     GET  /api/leaderboard/category/{cat}

// Challenges
createChallenge(category)       POST /api/challenge/create
getChallenge(token)             GET  /api/challenge/{token}
joinChallenge(token)            POST /api/challenge/{token}/join

// Match
playBot(category)               POST /api/match/bot?category={cat}

// Daily
getDailyChallenge()             GET  /api/daily
submitDailyChallenge(date, ans) POST /api/daily/submit
```

#### `SocketService` (`lib/services/socket_service.dart`)
- WebSocket client built on **web_socket_channel**
- Base URL: `ws://192.168.100.53:8000`

**Matchmaking connection:**
```
URI: ws://host/ws/match/{userId}?category={cat}&token={jwt}
```

**Battle connection:**
```
URI: ws://host/ws/battle/{matchId}?token={jwt}
```

**Send answer:**
```json
{ "event": "answer", "question_id": "...", "option": "A", "time_taken": 3500 }
```

---

### 3.5 State Management (Riverpod)

#### `authProvider` (`lib/providers/auth_provider.dart`)
```
Type: StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>

On startup: fetch stored JWT → GET /api/auth/me → hydrate UserModel

Methods:
  register(name, phone)                   → POST /register, store token
  updateProfile(name?, color?, imgPath?)  → PATCH /profile, update local state
  refreshUser()                           → GET /me, refresh state
  logout()                                → clear token + avatar path
  getToken()                              → read token from SharedPreferences
```

#### `matchProvider` (`lib/providers/match_provider.dart`)
```
Type: StateNotifierProvider<MatchNotifier, MatchState>

Methods:
  startMatchmaking(userId, category, token) → connect WS /ws/match/...
  cancelMatchmaking()                       → close WS
  connectBattle(matchId, token)             → connect WS /ws/battle/...
  submitAnswer(questionId, option, ms)      → send answer via WS
  reset()                                   → back to MatchState.initial

WebSocket event → MatchState mapping:
  "searching"   → phase: searching
  "matched"     → phase: matched, sets matchId + opponent info
  "battle_info" → sets player1Id
  "countdown"   → phase: countdown, sets countdown value
  "question"    → phase: playing, adds question
  "result"      → phase: showResult, sets correctOption + scores
  "game_over"   → phase: finished, sets winnerId + coinsEarned
  "error"       → phase: error, sets errorMessage
```

#### `challengeProvider` (`lib/providers/challenge_provider.dart`)
```
Type: StateNotifierProvider<ChallengeNotifier, AsyncValue<Map?>>

Methods:
  createChallenge(category)   → POST /api/challenge/create
  getChallenge(token)         → GET  /api/challenge/{token}
  joinChallenge(token)        → POST /api/challenge/{token}/join
```

#### `leaderboardProvider` (`lib/providers/leaderboard_provider.dart`)
```
Type: StateNotifierProvider<LeaderboardNotifier, AsyncValue<Map?>>

Methods:
  fetchGlobal()           → GET /api/leaderboard/global
  fetchWeekly()           → GET /api/leaderboard/weekly
  fetchCategory(cat)      → GET /api/leaderboard/category/{cat}
```

---

### 3.6 Screens

#### SplashScreen (`lib/screens/splash_screen.dart`)
- 2.4s animated intro with glowing logo and pulsing text
- Checks for pending deep link → routes to `/challenge/accept/{token}`
- No token → `/register`; valid token → `/home`

#### RegisterScreen (`lib/screens/register_screen.dart`)
- Fields: Name (2–30 chars, letters + spaces), Phone (10 digits, starts with 6–9)
- Calls `authProvider.register(name, phone)`
- Shows snackbar if phone exists under a different name (returns `existing_name`)
- Glass card design with gradient CTA

#### HomeScreen (`lib/screens/home_screen.dart`)
- Header: avatar, name, win streak, coins balance
- 6 category cards in 2×3 grid (tap to select)
- **"Find Opponent"** → `/matchmaking?category={selected}`
- **"Challenge a Friend"** → `/challenge/create`

#### MatchmakingScreen (`lib/screens/matchmaking_screen.dart`)
- Connects WS immediately on mount
- **Searching** state: animated ripple + search icon
- **Matched** state: VS card with opponent info
- **30-second timeout**: "Play vs Bot" button appears → `POST /api/match/bot`
- **Error** state: WiFi icon + message + retry
- On match: navigate to `/battle/{matchId}?category={cat}`

#### BattleScreen (`lib/screens/battle_screen.dart`)
- Connects WS on mount → waits for `battle_info` + `countdown`
- **VS card** at top: both player avatars, names, live scores
- **Question area**: question text + 4 answer buttons (A/B/C/D)
- **Timer bar**: 10s countdown, color changes blue → yellow → red
- Answer buttons reflect state: selected (active), correct (green), wrong (red)
- Auto-submits `null` answer on timeout
- On `game_over`: navigate to `/result`

#### ResultScreen (`lib/screens/result_screen.dart`)
- Confetti animation if winner
- Icon: Trophy (win) / Handshake (tie) / Trending (loss)
- Shows: Final scores, coins earned (animated counter), stats summary
- **"Rematch"** → back to matchmaking with same category
- **"Home"** → `/home`

#### DailyChallengeScreen (`lib/screens/daily_challenge_screen.dart`)
- `GET /api/daily` on mount
- **Already played**: shows rank badge, no replay allowed
- **Not started**: intro card with rules → "Start Challenge" button
- **Playing**: same timer + answer button UX as BattleScreen (no WS, local state)
- **Submitted**: `POST /api/daily/submit` → score, rank, coins banner
- Quit dialog warns that progress is lost

#### ChallengeCreateScreen (`lib/screens/challenge_create_screen.dart`)
- Pick category from 6 cards
- "Create Challenge Link" → `POST /api/challenge/create`
- On success: shows share link, auto-opens native share sheet
- Link format: `{public_url}/api/challenge/open/{token}`

#### ChallengeAcceptScreen (`lib/screens/challenge_accept_screen.dart`)
- Receives `token` via deep link param
- `GET /api/challenge/{token}` → shows challenger avatar, name, category
- **"⚔️ Accept Challenge"** → `POST /api/challenge/{token}/join` → `{match_id}` → `/battle/{matchId}`
- Error state if challenge expired (HTTP 410) or not found

#### LeaderboardScreen (`lib/screens/leaderboard_screen.dart`)
- 3 tabs: **All-Time**, **Weekly**, **Category**
- Category tab has dropdown to switch category
- Top 3 get medal badges (🥇🥈🥉)
- Current user row highlighted with gradient background
- "Your Rank" separator shown if user is ranked > 50

#### ProfileScreen (`lib/screens/profile_screen.dart`)
- Avatar glow ring (tap → camera / gallery / remove options via image_picker)
- **Edit mode**: inline name editor + 6-color avatar picker
- Displays masked phone, coins, win streak badge
- Stats grid: Matches, Wins, Win Rate, Best Streak
- Settings: sound toggle, navigation shortcuts, logout (with confirmation)

---

### 3.7 Widgets

| Widget | File | Purpose |
|--------|------|---------|
| `AnswerButton` | `widgets/answer_button.dart` | 4-state button: none / selected / correct / wrong |
| `AppNavBar` | `widgets/app_nav_bar.dart` | Bottom nav: Home, Daily, Leaderboard, Profile |
| `CategoryCard` | `widgets/category_card.dart` | Selectable card with gradient icon |
| `CoinDisplay` | `widgets/coin_display.dart` | Gold coin icon + amount |
| `VsCard` | `widgets/vs_card.dart` | Both players' avatars, names, live scores |
| `ShareSheet` | `widgets/share_sheet.dart` | Custom bottom sheet for challenge sharing |
| `AvatarWidget` | (inline) | Renders avatar from color hex or local image |

---

## 4. Backend Architecture (backend/)

### 4.1 Configuration & Database

**`app/config.py`** (Pydantic Settings)
```
database_url   = postgresql+asyncpg://gyaan:gyaan123@localhost:5432/gyaan_guru
jwt_secret     = "dev-secret"
jwt_algorithm  = "HS256"
jwt_expire_hours = 720   (30 days)
public_url     = "http://192.168.100.53:8000"
```

**`app/database.py`**
- Async SQLAlchemy engine + session factory
- `init_db()` creates all tables on startup
- `get_db()` dependency yields `AsyncSession`

**`app/main.py`**
- FastAPI with CORS (all origins allowed for dev)
- Registers routers: auth, categories, leaderboard, challenge, daily, match
- WebSocket routes: matchmaking, battle
- `GET /health` endpoint

---

### 4.2 Database Models

#### `User` (`models/user.py`)
```sql
id            UUID        PRIMARY KEY
name          VARCHAR(100)
phone         VARCHAR(20) UNIQUE, INDEXED
avatar_color  VARCHAR(10) DEFAULT '#6C63FF'
coins         INT         DEFAULT 100
total_matches INT         DEFAULT 0
wins          INT         DEFAULT 0
win_streak    INT         DEFAULT 0
best_streak   INT         DEFAULT 0
weekly_score  INT         DEFAULT 0
created_at    DATETIME    (server default)
```

#### `Question` (`models/question.py`)
```sql
id             UUID  PRIMARY KEY
question_text  TEXT
option_a       VARCHAR(300)
option_b       VARCHAR(300)
option_c       VARCHAR(300)
option_d       VARCHAR(300)
correct_option VARCHAR(1)   -- A|B|C|D
category       VARCHAR(30)  INDEXED
difficulty     VARCHAR(10)  -- easy|medium|hard
language       VARCHAR(5)   -- en|hi
```
Categories: `cricket`, `bollywood`, `gk`, `math`, `science`, `hindi`

#### `Match` (`models/match.py`)
```sql
id              UUID    PRIMARY KEY
player1_id      UUID    FK(User) INDEXED
player2_id      UUID    FK(User) NULLABLE  -- NULL = bot match
category        VARCHAR(30)
player1_score   INT     DEFAULT 0
player2_score   INT     DEFAULT 0
winner_id       UUID    FK(User) NULLABLE
status          VARCHAR(20)  -- waiting|playing|finished|cancelled
created_at      DATETIME
finished_at     DATETIME NULLABLE
```

#### `MatchAnswer` (`models/match.py`)
```sql
id               UUID    PRIMARY KEY
match_id         UUID    FK(Match) INDEXED
player_id        UUID    FK(User)
question_id      UUID    FK(Question)
selected_option  VARCHAR(1) NULLABLE  -- NULL = timed out
is_correct       BOOL
time_taken_ms    INT
```

#### `Challenge` (`models/challenge.py`)
```sql
id             UUID    PRIMARY KEY
token          VARCHAR(36) UNIQUE INDEXED
challenger_id  UUID    FK(User)
category       VARCHAR(30)
status         VARCHAR(20)  -- pending|accepted|expired
match_id       UUID    FK(Match) NULLABLE
created_at     DATETIME
expires_at     DATETIME    (created_at + 24h)
```

#### `DailyChallenge` (`models/daily.py`)
```sql
id            UUID  PRIMARY KEY
date          DATE  UNIQUE INDEXED
question_ids  TEXT  -- JSON list of 10 question UUIDs
```

#### `DailySubmission` (`models/daily.py`)
```sql
id              UUID  PRIMARY KEY
user_id         UUID  FK(User) INDEXED
challenge_date  DATE  INDEXED
answers         TEXT  -- JSON dict {question_id: selected_option}
score           INT
rank            INT NULLABLE
submitted_at    DATETIME
```

---

### 4.3 Auth & Utilities

**`utils/jwt.py`**
- `create_access_token(user_id)` → JWT signed with HS256, exp = now + 720h
- `decode_access_token(token)` → returns `user_id` or raises `JWTError`

**`utils/deps.py`**
- `get_current_user` FastAPI dependency → validates Bearer token → returns `User` from DB

---

### 4.4 REST API Routers

#### Auth — `/api/auth`

```
POST /register
  Body: { name: str, phone: str }
  Response: { token: str, user: {...}, existing_name: str|null }
  Logic:
    - Lookup User by phone
    - If not found: create with avatar_color from (phone[-1] % colors)
    - Return JWT + user dict + existing_name if re-registering with different name

POST /login
  Body: { phone: str }
  Response: { token: str, user: {...} }
  Logic: 404 if phone not found

GET /me  [Auth required]
  Response: user dict

PATCH /profile  [Auth required]
  Body: { name?: str, avatar_color?: str }
  Response: updated user dict
```

#### Categories — `/api/categories`

```
GET /
  Response: { categories: ["cricket", "bollywood", "gk", "math", "science", "hindi"] }
```

#### Leaderboard — `/api/leaderboard`

```
GET /global  [Auth required]
  Response: { players: [{id, name, avatar_color, wins, coins, rank}], my_rank?: int }
  Logic: ORDER BY wins DESC, coins DESC LIMIT 50

GET /weekly  [Auth required]
  Response: same structure
  Logic: ORDER BY weekly_score DESC, wins DESC LIMIT 50

GET /category/{category}  [Auth required]
  Response: same structure
  Logic: subquery counts wins per player in this category, ORDER BY wins DESC LIMIT 50
```

#### Challenge — `/api/challenge`

```
GET /open/{token}
  Response: HTML redirect page
  Logic: Returns HTML with JS → window.location.href = "gyaanguru:///challenge/accept/{token}"
  (Used as the shareable link for non-app browsers)

POST /create  [Auth required]
  Body: { category: str }
  Response: { token: str, link: str, expires_at: datetime }
  Logic: Create Challenge with expires_at = now + 24h
         link = "{public_url}/api/challenge/open/{token}"

GET /{token}  [Auth required]
  Response: { token, challenger: {id, name, avatar_color}, category, status }
  Logic: 410 Gone if expired

POST /{token}/join  [Auth required]
  Response: { match_id: str }
  Logic:
    - Validate: exists, status=pending, not own challenge
    - Create Match(player1=challenger, player2=current_user, category)
    - Update Challenge: status=accepted, match_id=match.id
```

#### Daily — `/api/daily`

```
GET /  [Auth required]
  Response: { date: str, questions: [...], already_played: bool }
  Logic:
    - Get or create DailyChallenge for today (pick 10 random questions)
    - Check if user has a DailySubmission for today

POST /submit  [Auth required]
  Body: { challenge_date: str, answers: { question_id: option } }
  Response: { score: int, rank: int }
  Logic:
    - Check no duplicate submission
    - Load today's question_ids
    - Score: +10 per correct answer (max 100)
    - Rank: count users with higher score today + 1
    - Coins awarded: base 5 + score // 2
    - Update user.weekly_score
    - Create DailySubmission
```

#### Match — `/api/match`

```
POST /bot?category={cat}  [Auth required]
  Response: { match_id: str, opponent: { id: "gyaan-bot", name: "Gyaan Bot", avatar_color: "#E65100" } }
  Logic: Create Match(player1=current_user, player2=null, category)
```

---

### 4.5 WebSocket Handlers

#### Matchmaking (`websockets/matchmaking.py`)

**Endpoint:** `ws://host/ws/match/{user_id}?category={cat}&token={jwt}`

**Server-side queues:** `_waiting: Dict[category, List[WebSocket]]`

**Flow:**
1. Validate JWT token matches `user_id` param
2. Send `{ event: "searching" }`
3. Append connection to `_waiting[category]`
4. When `len(_waiting[category]) >= 2`:
   - Pop first 2 players
   - Create `Match` DB record (player1, player2, category)
   - Send each player their `matched` event with opponent info
5. Timeout after 60s → remove from queue, send error

**Events sent:**
```json
{ "event": "searching" }
{ "event": "matched", "match_id": "...", "player1_id": "...", "opponent": { "id": "...", "name": "...", "avatar_color": "..." } }
{ "event": "error", "message": "..." }
```

#### Battle (`websockets/battle.py`)

**Endpoint:** `ws://host/ws/battle/{match_id}?token={jwt}`

**Per-match state:**
- Connection tracker (up to 2 players)
- One answer queue per player (`asyncio.Queue`)
- One broadcast queue per connected client

**Auto-start battle engine when:**
- 2 real players connected (PvP), OR
- 1 player connected + `player2_id IS NULL` (bot match)

**Events received from client:**
```json
{ "event": "answer", "question_id": "...", "option": "A", "time_taken": 3200 }
```

**Events sent to client:** see [Section 7](#7-websocket-event-reference)

---

### 4.6 Battle Engine (`websockets/battle_engine.py`)

**Constants:**
```
QUESTION_COUNT   = 10
QUESTION_TIMEOUT = 10.0s
RESULT_PAUSE     = 2.0s
COINS_WIN        = 30
COINS_LOSE       = 10
```

**Execution phases:**

1. **Countdown** — broadcasts `{ event: "countdown", seconds: 3 }` then `2`, then `1`

2. **Question loop** (×10):
   - Fetch 10 questions for category (fallback to any category if insufficient)
   - Broadcast `{ event: "question", question: {...}, index: N }`
   - Collect answers in parallel:
     - **Real player**: wait up to 10s on their `asyncio.Queue`
     - **Bot**: random delay 1–7s, correct 60% of the time
   - Award 10pts for correct answer
   - Broadcast `result` event with correct option + updated scores
   - Sleep 2s before next question

3. **Finish**:
   - Determine winner (higher score; tie → no winner)
   - Broadcast `game_over` with final scores, winner, coins earned
   - Persist to DB:
     - `Match.player1_score`, `player2_score`, `winner_id`, `status=finished`, `finished_at`
     - Create `MatchAnswer` record per question per player
     - Update `User` stats:
       - `total_matches += 1`
       - `coins += COINS_WIN` (winner) or `coins += COINS_LOSE` (loser)
       - `wins += 1` (if winner)
       - `win_streak = streak + 1` (win) or `0` (loss)
       - `best_streak = max(best_streak, win_streak)`
       - `weekly_score += 30` (if winner)

---

## 5. API Reference

### Full Endpoint Matrix

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/auth/register` | No | Register or re-login by phone |
| POST | `/api/auth/login` | No | Login by phone |
| GET | `/api/auth/me` | JWT | Get current user |
| PATCH | `/api/auth/profile` | JWT | Update name / avatar color |
| GET | `/api/categories` | No | List all categories |
| GET | `/api/leaderboard/global` | JWT | Top 50 all-time (by wins) |
| GET | `/api/leaderboard/weekly` | JWT | Top 50 this week (by weekly_score) |
| GET | `/api/leaderboard/category/{cat}` | JWT | Top 50 in specific category |
| POST | `/api/challenge/create` | JWT | Create a friend challenge link |
| GET | `/api/challenge/open/{token}` | No | HTML deep-link redirect page |
| GET | `/api/challenge/{token}` | JWT | Get challenge details |
| POST | `/api/challenge/{token}/join` | JWT | Accept and start challenge match |
| GET | `/api/daily` | JWT | Get today's daily quiz |
| POST | `/api/daily/submit` | JWT | Submit daily quiz answers |
| POST | `/api/match/bot` | JWT | Start a bot match |
| WS | `/ws/match/{userId}` | Token param | Matchmaking queue |
| WS | `/ws/battle/{matchId}` | Token param | Live battle |
| GET | `/health` | No | Health check |

---

## 6. Feature Flows (End-to-End)

### 6.1 Registration & Login

```
App cold-start
  └─ SplashScreen (2.4s)
       ├─ No stored token → /register
       │     RegisterScreen: enter name + phone
       │     POST /api/auth/register
       │     Server: create User (if new) or return existing user
       │     Response: { token, user, existing_name? }
       │     App: store JWT in SharedPreferences
       │     Navigate → /home
       │
       └─ Token found → GET /api/auth/me
             Success → hydrate UserModel → /home
             Failure → clear token → /register
```

### 6.2 PvP Matchmaking & Battle

```
HomeScreen
  1. Tap category card (e.g., cricket)
  2. Tap "Find Opponent"
  └─ /matchmaking?category=cricket

MatchmakingScreen
  3. Connect WS: ws://host/ws/match/{userId}?category=cricket&token=JWT
  4. Server: searching → send { event: "searching" }
  5. Server: second player joins same category queue
  6. Server: create Match DB record, assign player1/player2
  7. Both players receive: { event: "matched", match_id, player1_id, opponent: {...} }
  8. App: show VS card → navigate to /battle/{matchId}?category=cricket

BattleScreen
  9.  Connect WS: ws://host/ws/battle/{matchId}?token=JWT
  10. Server detects 2 players connected → start battle engine
  11. Engine broadcasts: { event: "battle_info", player1_id }
  12. Engine broadcasts: { event: "countdown", seconds: 3 }, { seconds: 2 }, { seconds: 1 }
  13. Engine broadcasts: { event: "question", question: {...}, index: 0 }
  14. User taps answer within 10s
  15. App sends: { event: "answer", question_id, option, time_taken }
  16. Engine scores answer, waits for opponent (or bot)
  17. Engine broadcasts: { event: "result", correct_option, p1_correct, p2_correct, p1_score, p2_score }
  18. Steps 13–17 repeat for questions 1–9
  19. Engine broadcasts: { event: "game_over", p1_score, p2_score, winner_id, p1_coins_earned, p2_coins_earned }
  20. Engine persists: Match record, MatchAnswer records, User stat updates
  21. App: navigate to /result

ResultScreen
  22. Shows outcome, confetti if win, coins earned
  23. "Rematch" → /matchmaking?category=cricket
      "Home"    → /home
```

**30-second timeout (no opponent found):**
```
MatchmakingScreen
  → 30s elapsed → "Play vs Bot" button appears
  → Tap → POST /api/match/bot?category=cricket
  → { match_id, opponent: { id: "gyaan-bot", name: "Gyaan Bot" } }
  → /battle/{matchId} (same flow, but server uses bot logic instead of second player)
```

### 6.3 Friend Challenge (Deep Link)

```
Challenger (User A):
  HomeScreen → "Challenge a Friend" → /challenge/create
  ChallengeCreateScreen:
    1. Select category
    2. POST /api/challenge/create { category }
    3. Server: create Challenge (token=UUID, expires_at=+24h)
    4. Response: { token, link: "http://host/api/challenge/open/{token}", expires_at }
    5. App: show link, open native share sheet
    6. Share via WhatsApp / SMS

Friend (User B) receives link:
    7. Click link in browser / WhatsApp
    8. Browser: GET /api/challenge/open/{token}
    9. Server: return HTML page with JS redirect
       window.location.href = "gyaanguru:///challenge/accept/{token}"
    10. OS opens Gyaan Guru app (cold or warm start)
    11. AppLinks fires deep link event
    12. Router navigates to /challenge/accept/{token}

ChallengeAcceptScreen:
    13. GET /api/challenge/{token}
    14. Server: validate token, check expiry (410 if expired)
    15. Response: { token, challenger: { name, avatar_color }, category, status }
    16. Show challenger card
    17. Tap "⚔️ Accept Challenge"
    18. POST /api/challenge/{token}/join
    19. Server: validate (not own challenge, status=pending)
        Create Match(player1=challenger, player2=current_user, category)
        Update Challenge: status=accepted, match_id=match.id
    20. Response: { match_id }
    21. Navigate to /battle/{matchId} (same WS flow as PvP)

Note: Challenger (User A) must also connect to /ws/battle/{matchId} for the
      battle to start (both players must be connected).
```

### 6.4 Daily Challenge

```
DailyChallengeScreen (nav bar index 1):
  1. GET /api/daily
  2. Server: get or create DailyChallenge for today
             (first request of day picks 10 random questions, stores IDs)
     Response: { date, questions: [...], already_played: bool }

  If already_played == true:
    → Show "Already Played" with rank badge

  If already_played == false:
    3. Show intro card with rules
    4. Tap "Start Challenge"
    5. Local state machine runs quiz:
       - 10 questions, 10s each (no WebSocket, fully client-side timer)
       - Same answer button UX as BattleScreen
    6. All 10 answered (or timed out) → POST /api/daily/submit
       Body: { challenge_date: "YYYY-MM-DD", answers: { qid: option, ... } }
    7. Server: score answers (+10 per correct, max 100)
               rank = count(users with higher score today) + 1
               coins += 5 + score // 2
               Update user.weekly_score
               Create DailySubmission
    8. Response: { score, rank }
    9. Show results: score out of 100, rank, coins earned (75 shown in UI)
       Top 10 rank → bonus 200 coins banner

  Quit dialog (mid-quiz):
    → "Keep Playing" continues
    → "Quit Challenge" discards progress (no submission)
```

### 6.5 Leaderboard

```
LeaderboardScreen (nav bar index 2):
  On mount: fetch all 3 tabs in parallel

  All-Time tab:
    GET /api/leaderboard/global
    → Top 50 players by wins (then coins as tiebreaker)

  Weekly tab:
    GET /api/leaderboard/weekly
    → Top 50 players by weekly_score (then wins as tiebreaker)

  Category tab:
    GET /api/leaderboard/category/{selected_category}
    → Top 50 players by wins in that category (subquery on Match table)

  UI:
    - Rank medals for top 3
    - Current user row highlighted in gradient
    - "Your Rank" separator if ranked > 50
    - Dropdown to switch category (triggers new API call)
```

---

## 7. WebSocket Event Reference

### Matchmaking (`/ws/match/{userId}`)

#### Server → Client

| Event | Payload | Triggered when |
|-------|---------|---------------|
| `searching` | `{}` | Connected to queue |
| `matched` | `{ match_id, player1_id, opponent: { id, name, avatar_color } }` | Opponent found |
| `error` | `{ message }` | Timeout or server error |

#### Client → Server
None (connection only, no messages from client)

---

### Battle (`/ws/battle/{matchId}`)

#### Client → Server

| Event | Payload | When |
|-------|---------|------|
| `answer` | `{ question_id, option, time_taken }` | User taps answer button |

#### Server → Client

| Event | Payload | When |
|-------|---------|------|
| `battle_info` | `{ player1_id }` | Both players connected |
| `countdown` | `{ seconds: 3\|2\|1 }` | Pre-battle countdown |
| `question` | `{ question: { id, question_text, options: {A,B,C,D} }, index: N }` | Each new question |
| `result` | `{ correct_option, p1_correct, p2_correct, p1_score, p2_score }` | After each question |
| `game_over` | `{ p1_score, p2_score, winner_id, p1_coins_earned, p2_coins_earned }` | Match finished |
| `error` | `{ message }` | Server error |

---

## 8. Coin Economy & Game Mechanics

### Coin Rewards
| Event | Coins |
|-------|-------|
| Account creation | +100 (starting balance) |
| Win a match | +30 |
| Lose a match | +10 |
| Daily challenge completion | +5 + (score // 2) — shown as 75 in UI |
| Daily challenge top 10 | Additional +200 |

### Match Scoring
- 10 questions, 10 seconds each
- +10 points per correct answer (max 100 per match)
- Bot accuracy: 60% correct, random delay 1–7s

### Stats Tracking
| Stat | Update rule |
|------|------------|
| `total_matches` | +1 every match |
| `wins` | +1 if winner |
| `win_streak` | +1 if won, reset to 0 if lost |
| `best_streak` | `max(best_streak, win_streak)` |
| `weekly_score` | +30 if match winner; +score from daily submit |
| `coins` | +COINS_WIN or +COINS_LOSE per match; +daily coins |

### Categories
`cricket` · `bollywood` · `gk` · `math` · `science` · `hindi`

---

## 9. Deployment Notes

### Current Development Setup
- **Frontend base URL:** `http://192.168.100.53:8000` (hardcoded in `api_service.dart` and `socket_service.dart`)
- **Backend:** Single `uvicorn` process, in-memory `asyncio.Queue` for matchmaking and battle state
- **Database:** Local PostgreSQL (`gyaan_guru` DB, user `gyaan`, password `gyaan123`)
- **JWT secret:** `"dev-secret"` (must change for production)
- **CORS:** All origins allowed (`*`)

### Production Considerations
1. **Replace hardcoded IPs** in Flutter with environment-driven config
2. **Redis** required for distributed matchmaking queues (currently in-memory = single-process only)
3. **JWT secret** must be rotated and stored in environment variable
4. **Deep links:** Android intent filters + iOS Universal Links configuration needed for `app_links`
5. **Database migrations:** Alembic migration present (`a6ca8bdebcea_initial.py`)
6. **Weekly score reset:** No automated reset job exists yet — needs a cron task

### Database Migration
```bash
cd backend
alembic upgrade head
```

### Running Locally
```bash
# Backend
cd backend
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# Frontend
flutter run
```
