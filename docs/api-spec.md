# API Spec

Base URL: `http://localhost:3000`

## Auth

- `POST /auth/register` with `email`, `password`, optional `fullName`
- `POST /auth/login` with `email`, `password`
- `GET /auth/me`

Auth responses return `{ accessToken, user }`. Use `Authorization: Bearer <token>`. In local demo mode, endpoints can fall back to the demo user unless `REQUIRE_AUTH=true`.

## Health And Settings

- `GET /health`
- `GET /settings`
- `PUT /settings/providers`

`/settings` returns environment, mock mode, real AI enabled state, API base URL, provider status, auth mode, runtime storage label and `publicationReadiness`.

`publicationReadiness` includes:

- `ready`
- `blockers`
- `warnings`
- `nextActions`

## Profile

- `GET /profile`
- `PUT /profile`
- `GET /profile/demo`
- `PUT /profile/demo`

Profiles are scoped by authenticated user when a JWT is supplied.

## Credentials

- `GET /credentials`
- `POST /credentials`
- `PUT /credentials/:id`
- `DELETE /credentials/:id`

Trust levels are guidance only. Legal verification is not claimed unless `verificationUrl` is present.

## Portfolio

- `GET /portfolio-projects`
- `POST /portfolio-projects`
- `PUT /portfolio-projects/:id`
- `DELETE /portfolio-projects/:id`

## Job Sources

- `GET /job-sources`

Provider status values: `active`, `configured`, `needs-configuration`, `disabled`.

## Jobs

- `GET /jobs`
- `GET /jobs/:id`
- `POST /jobs/search`
- `POST /jobs/:id/analyze`
- `PATCH /jobs/:id/status` with `status`, optional `note`
- `PATCH /jobs/:id/notes`
- `GET /jobs/:id/status-history`

Search filters: `query`, `countries`, `roles`, `workModes`, `providers`, `visaRequired`, `relocationPreferred`, `housingPreferred`, `experienceLevel`.

Statuses: `saved`, `analyzed`, `eligible`, `almostEligible`, `notEligible`, `applied`, `interview`, `offer`, `rejected`, `archived`.

## Applications

- `GET /applications`
- `POST /applications/generate` with `{ "jobId": "..." }`
- `GET /applications/:jobId`

Application packages are generated for manual review and manual sending only. WorkBridge AI does not auto-apply.
