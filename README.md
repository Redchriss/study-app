# Yaza — AI Study Platform (Flutter App)

Flutter mobile app for Yaza, a Malawi-focused AI study platform. Communicates with the Django backend via GraphQL API.

## Architecture

- **Flutter** with Riverpod state management
- **go_router** for navigation
- **graphql_flutter** for API communication
- **Hive** for local storage (quiz persistence, offline cache)
- **flutter_secure_storage** for JWT tokens
- **GenUI** for server-driven UI components (primary/secondary/tertiary catalogs)

## Key Features

### AI Features (all level-aware)
Every AI feature adapts to the student's education level:

- **AI Tutor (Agent)** — conversational tutoring with 6 modes (Coach, Quiz Me, Revise, Memorize, Plan, Coursework)
- **Material AI Tools** — generate Summary, Flashcards, Quiz, Study Pack from any material
- **Paper Solver** — camera/PDF upload → extract questions → solve step-by-step
- **Diagnostic Assessment** — adaptive testing with knowledge tracing
- **Knowledge Map** — visual prerequisite graph with mastery colors
- **Coursework Mode** — outline → draft sections for essays/reports

### Tools Hub
Centralized hub at `/tools`:
- **AI Tools**: Paper Solver, AI Tutor, Diagnostic, Knowledge Map
- **Study Tools**: Review Queue, Past Papers, Bookmarks, History

### Core Features
- **Study Materials** — browse, read, bookmark, track progress
- **Quizzes** — AI-generated from materials, adaptive difficulty
- **Communities** — Reddit-style study spaces with posts, comments, voting
- **Dashboard** — streak, points, daily goal, quick actions, weekly insights
- **Kids Mode** — COPPA-compliant learning with companions, badges, XP/levels
- **Gamification** — streaks, points, leaderboard, achievements

## Repository Layout

```
lib/
├── core/
│   ├── config/              app_config.dart
│   ├── graphql/             client, queries by domain
│   ├── services/            biometric, connectivity, hive, upload
│   ├── storage/             secure_storage.dart
│   ├── theme/               design_tokens.dart
│   └── widgets/             shared widgets
├── features/
│   ├── account/             upgrade, history, bookmarks, past papers, upload
│   ├── agent/               AI tutor screen, GenUI catalogs, streaming
│   ├── auth/                login, register, onboarding, profile setup
│   ├── circles/             communities, posts, comments, voting
│   ├── dashboard/           dashboard, quick actions, insights
│   ├── diagnostics/         diagnostic, knowledge map, prerequisite graph
│   ├── kids_mode/           kids lessons, companions, badges
│   ├── leaderboard/         leaderboard
│   ├── materials/           materials list, detail, reader, study pack
│   ├── notifications/       notifications, modmail
│   ├── profile/             profile, settings, about
│   ├── quizzes/             quiz list, take, results
│   ├── scanner/             paper solver
│   ├── study_hub/           study hub (materials + quizzes + tools)
│   └── tools/               tools hub screen
├── router.dart              all routes
├── shell.dart               bottom nav shell (4 tabs + center AI button)
└── main.dart
```

## Quick Start

### 1. Prerequisites

- Flutter SDK (>= 3.3.0)
- Android Studio / Xcode
- Backend running at `http://localhost:8000`

### 2. Environment

Create `.env` in the project root:

```env
API_URL=http://localhost:8000
GRAPHQL_URL=http://localhost:8000/graphql/
SENTRY_DSN=
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Run

```bash
flutter run
```

### 5. Build

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## Testing

```bash
flutter test test/widget_test.dart
flutter test test/features/
flutter test test/core/
```

## Key Screens

### Auth Flow
1. **Splash** → animated brand reveal
2. **Onboarding** → 4 pages (AI Tutor, Built for Malawi, Paper Solver, Get Started)
3. **Register** → 3 steps (username, contact, password)
4. **Profile Setup** → education level → Standard/Form/University → School/Program → Term
5. **Login** → username + password + biometric option

### Main App (4 tabs + center AI button)
- **Tab 0: Feed** — community posts (Best/Hot/New/Rising/Popular)
- **Tab 1: Study Hub** — materials + quizzes + tools
- **Center: AI Tutor** — conversational AI
- **Tab 2: Dashboard** — streak, points, quick actions, insights
- **Tab 3: Profile** — profile, settings, about

### Tools Hub (`/tools`)
- AI Tools: Paper Solver, AI Tutor, Diagnostic, Knowledge Map
- Study Tools: Review Queue, Past Papers, Bookmarks, History

### Material Detail
- Study button (opens reader)
- YouTube player (if video)
- Download button (if file)
- AI Tools (2×2 grid): Study Pack, Summary, Flashcards, Quiz
- AI Summary display (if generated)

## Navigation

All routes defined in `lib/router.dart`. Key routes:

| Route | Screen |
|---|---|
| `/splash` | Splash screen |
| `/onboarding` | Onboarding |
| `/login` | Login |
| `/register` | Register |
| `/setup` | Profile setup |
| `/home` | Feed (Tab 0) |
| `/study` | Study Hub (Tab 1) |
| `/ai-tutor` | AI Tutor |
| `/dashboard` | Dashboard (Tab 2) |
| `/profile` | Profile (Tab 3) |
| `/tools` | Tools hub |
| `/tools/:tool` | Specific tool |
| `/materials` | Materials list |
| `/materials/:slug` | Material detail |
| `/materials/:slug/read` | Material reader |
| `/quizzes` | Quiz list |
| `/quizzes/:slug` | Take quiz |
| `/quizzes/results/:id` | Quiz results |
| `/scanner` | Paper solver |
| `/diagnostic/:subject` | Diagnostic |
| `/knowledge-map/:subject` | Knowledge map |
| `/kids` | Kids mode |
| `/settings` | Settings |

## State Management

- **Riverpod** for state management
- **AuthNotifier** — auth state, JWT tokens, biometric
- **AgentNotifier** — AI tutor state, streaming, GenUI surfaces
- **StudyProgressStore** — local quiz persistence (Hive)
- **MaterialCacheService** — offline material cache

## GenUI System

Server-driven UI with catalogs per education level:

- **Primary catalog** — SimpleQuiz, FillBlank, WordMatch, PictureQuiz, MathVisual, StoryComprehension
- **Secondary catalog** — FlashCard, StepSolver, PastPaperQuestion, DefinitionCard, EssayOutline, FormulaCard
- **Tertiary catalog** — ConceptMap, ArgumentBuilder, CodeSnippet, ResearchSummary, DebateCard

Each catalog maps server-returned component specs to Flutter widgets.

## Dependencies

Key dependencies (see `pubspec.yaml`):

- `flutter_riverpod` — state management
- `go_router` — navigation
- `graphql_flutter` — GraphQL API
- `hive_flutter` — local storage
- `flutter_secure_storage` — JWT tokens
- `genui` — server-driven UI
- `youtube_player_iframe` — YouTube embeds
- `flutter_pdfview` — PDF viewer
- `camera` — camera for paper solver
- `flutter_tts` — text-to-speech for kids mode
- `firebase_messaging` — push notifications
- `sentry_flutter` — error tracking

## License

No explicit license. Add one before distributing.
