# Product Spec

WorkBridge AI V1 is an API-first international IT job discovery and application readiness platform.

## Scope

- IT jobs only.
- Candidate-side profile, credentials, portfolio, job discovery, eligibility analysis, resume text, application packages and manual job tracking.
- Manual submission only. WorkBridge AI never auto-applies and never sends employer messages automatically.
- Multi-user-ready backend foundation with JWT auth.
- Mock mode for fallback and testing.
- Real mode requires configured providers and API keys where applicable.

## Out Of Scope

- Employer marketplace.
- Employer-created vacancies.
- Employer-candidate chat.
- Video interviews.
- Non-IT jobs.
- LinkedIn or Indeed scraping.
- Automatic application sending.

## V1 Flow

1. User registers or uses local demo fallback.
2. User creates or updates a saved profile.
3. User adds credentials and portfolio projects.
4. User searches IT jobs by query, countries, roles, work modes, support needs and source providers.
5. Backend normalizes provider jobs and applies strict country or remote-compatible filtering.
6. Analyzer parses requirements and company support signals.
7. Eligibility engine compares requirements with profile, credentials, portfolio proof and relocation needs.
8. App generates truthful resume/application text and shows AI limitations.
9. User exports/copies, reviews and manually submits outside WorkBridge AI.
10. User tracks job status, notes and status history manually.
