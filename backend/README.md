# WorkBridge AI Backend

NestJS API for WorkBridge AI V1.

## Run

```bash
npm install
cp .env.example .env
npm run build
npm test
npm run start:dev
```

## Modes

- `USE_MOCK_JOBS=true`: reliable fallback mode with sample IT jobs and sample profile defaults when no data file exists.
- `USE_MOCK_JOBS=false`: real mode using saved profile data, JSON persistence and configured real providers.
- `USE_REAL_AI=true`: attempts OpenAI-compatible JSON parsing when `OPENAI_API_KEY` or `AI_API_KEY` is present, then falls back to local rules on any failure.

Runtime user data is stored in `backend/data/workbridge-store.json`. This is a temporary V1 persistence layer with a PostgreSQL-ready service boundary.
