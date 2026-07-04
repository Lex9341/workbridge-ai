# Roadmap

## Completed For Publish-Ready V1 Foundation

- API-first backend with health, settings, auth, profile, credentials, portfolio, jobs, analysis and applications.
- Flutter app with Dashboard, Discover Jobs, Tracker, Profile, Credentials, Portfolio, Resume, Applications, Settings and Auth screens.
- JWT register/login/me backend with bcrypt password hashing.
- User-specific repository API for profile, credentials, portfolio, jobs, analyses, applications and status history.
- JSON runtime persistence with migration of old single-user data into demo user data.
- Prisma schema and migration for PostgreSQL entities: User, UserProfile, Credential, PortfolioProject, JobPosting, EligibilityAnalysis, ApplicationPackage, JobStatusHistory and Settings.
- Docker Compose for local PostgreSQL and backend.
- Mock, Remotive, The Muse, Adzuna, Greenhouse, Lever and Ashby provider implementations where public APIs are available.
- Job status history and notes backend, with Flutter timeline display.
- Rule-based analyzer with optional real AI parser, fallback metadata, confidence and missing-information questions.
- Resume/application export to the app Documents/WorkBridgeAI folder instead of unknown working directory.
- Backend and Flutter test/analyze/build passes.

## Remaining Publication Blockers

- Runtime storage still uses JSON; Prisma/PostgreSQL schema and migrations are ready, but the live repository implementation is not fully switched to Prisma.
- Provider settings UI shows status and warnings, but editing company slugs from Flutter is not yet a full form workflow.
- Auth screen stores JWT only for the current app session.
- Native user-selected export destination is not implemented; exports go to Documents/WorkBridgeAI.
- npm audit still reports dependency vulnerabilities that need review before public hosting.

## V1.1

- Implement full Prisma repository and remove JSON as production storage.
- Add persistent secure token storage in Flutter.
- Add editable provider settings forms for company slugs and API-key guidance.
- Add richer status notes editing in Job Details.
- Add native file picker/export destination.
- Expand provider-specific country and work authorization parsing.

## Later

- Employer accounts and vacancies.
- Employer-candidate chat.
- Video interview workflows.
- Non-IT role support.

LinkedIn and Indeed scraping remain intentionally out of scope unless official compliant APIs are used.
