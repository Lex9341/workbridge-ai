# WorkBridge AI

WorkBridge AI V1 is an API-first international IT job discovery and application readiness platform. It helps candidates search international IT jobs, compare job requirements with a saved profile, credentials, portfolio evidence and relocation needs, then generate truthful resume and application material for manual submission.

## V1 Scope

Implemented: Flutter app, NestJS backend, JWT auth foundation, multi-user-ready data isolation, profile/credentials/portfolio CRUD, job search, provider normalization, eligibility analysis, application package generation, manual tracker, status history, notes, safer export, settings, PostgreSQL schema/migration and Docker Compose.

Not implemented: employer accounts, employer-created vacancies, chat, video interviews, non-IT jobs, automatic application sending, LinkedIn scraping and Indeed scraping.

## Run PostgreSQL

```bash
cd /home/akai/Projects/WorkBridge/workbridge_ai
docker compose up -d postgres
cd backend
DATABASE_URL='postgresql://workbridge:workbridge@localhost:5432/workbridge_ai?schema=public' npx prisma migrate deploy
```

## Run Backend

```bash
cd /home/akai/Projects/WorkBridge/workbridge_ai/backend
npm install
npx prisma generate
npm run build
npm test
npm run start:dev
```

Runtime storage is still JSON unless the Prisma repository is completed. The Prisma schema and migrations are ready for PostgreSQL.

## Run Flutter App

```bash
cd /home/akai/Projects/WorkBridge/workbridge_ai/app
/home/akai/flutter/bin/flutter pub get
/home/akai/flutter/bin/flutter analyze
/home/akai/flutter/bin/flutter test
/home/akai/flutter/bin/flutter run -d linux --dart-define=API_BASE_URL=http://localhost:3000
```

## Env Vars

Copy `.env.example` and set real values outside source control.

- `APP_ENV`
- `NODE_ENV`
- `DATABASE_URL`
- `PORT`
- `API_BASE_URL`
- `CORS_ORIGIN`
- `REQUIRE_AUTH`
- `JWT_SECRET`
- `USE_MOCK_JOBS`
- `USE_REAL_AI`
- `OPENAI_API_KEY`
- `AI_API_KEY`
- `OPENAI_MODEL`
- `ADZUNA_APP_ID`
- `ADZUNA_APP_KEY`
- `GREENHOUSE_BOARD_TOKEN`
- `LEVER_COMPANY_SLUG`
- `ASHBY_ORGANIZATION_SLUG`

## Runtime Modes

- `development`: mock jobs default on, auth default off, JSON fallback allowed.
- `demo`: mock jobs default on for demonstrations, auth default off.
- `production`: mock jobs default off, auth default on, PostgreSQL expected.

Production-style config:

```bash
APP_ENV=production
STORAGE_DRIVER=postgres
DATABASE_URL='postgresql://workbridge:workbridge@localhost:5432/workbridge_ai?schema=public'
REQUIRE_AUTH=true
USE_MOCK_JOBS=false
```

`GET /settings` returns `environment`, provider statuses and `publicationReadiness` with blockers, warnings and next actions.

## Real AI

Set `USE_REAL_AI=true` and provide `OPENAI_API_KEY` or `AI_API_KEY`. If AI fails, WorkBridge falls back to rule-based analysis and marks `fallbackUsed=true`.

## Providers

Remotive and The Muse use public APIs. Adzuna needs API keys. Greenhouse, Lever and Ashby need public company board slugs/tokens. Provider APIs can fail or omit visa/relocation details; the analyzer adds questions to confirm missing information.

## Safety

No secrets should be committed. WorkBridge AI does not auto-apply, submit employer forms or send recruiter messages. Generated application text must be reviewed manually because AI and rule-based parsing can make mistakes.
