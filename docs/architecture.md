# Architecture

## Frontend

Flutter app using Riverpod and go_router. `app/lib/app_state.dart` contains the API client and state controller. The app loads backend profile, credentials, portfolio, jobs, status histories, applications and settings on startup, with seeded mock fallback data if the backend is unavailable.

Screens: Dashboard, Discover Jobs, Tracker, Job Details, Profile, Credentials, Portfolio, Resume, Applications, Settings and Auth.

Exports are written to the app documents directory under `WorkBridgeAI`, and the app shows the saved path or an error.

## Backend

NestJS API with controllers for auth, health, settings, profile, credentials, portfolio projects, job sources, jobs, analyses and applications.

Runtime persistence currently uses `StoreService` with a multi-user JSON repository stored at `backend/data/workbridge-store.json` or `DATA_FILE_PATH`. Existing single-user JSON files are normalized into the demo user.

Prisma schema and migration exist for PostgreSQL and were verified with `prisma migrate deploy`, but the live repository still needs a full Prisma implementation before JSON can be removed from production.

## Auth

Auth endpoints support register, login and current user. Passwords are hashed with bcryptjs and sessions use JWT. `REQUIRE_AUTH=true` makes bearer tokens mandatory outside public auth and health endpoints. Local demo mode allows no-token use for development.

## Modes

- Mock mode: `USE_MOCK_JOBS=true`; uses `MockJobProvider` and sample defaults if no persisted file exists.
- Real provider mode: `USE_MOCK_JOBS=false`; uses non-mock providers that are configured.
- AI mode: `USE_REAL_AI=true` plus `OPENAI_API_KEY` or `AI_API_KEY`; otherwise local rule-based parsing is used.

## Providers

Implemented:

- MockJobProvider
- RemotiveProvider
- TheMuseProvider
- AdzunaProvider with keys
- GreenhouseProvider with public board token
- LeverProvider with public company slug
- AshbyProvider with public organization slug

LinkedIn and Indeed scraping are intentionally not implemented.
