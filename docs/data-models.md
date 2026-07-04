# Data Models

## User

`id`, `email`, `passwordHash`, `fullName`, timestamps. API responses expose `SafeUser` without password hash.

## UserProfile

`id`, `fullName`, `currentCountry`, `citizenship`, `targetRole`, `experienceLevel`, `yearsOfExperience`, `educationLevel`, language levels, `otherLanguages`, `skills`, `preferredCountries`, `preferredWorkModes`, visa/relocation/housing preferences, profile links, timestamps.

## Credential

`id`, `title`, `provider`, `type`, `trustLevel`, `issueDate`, `expiryDate`, `verificationUrl`, `fileName`, `notes`.

Trust levels are career guidance only.

## PortfolioProject

`id`, `title`, `description`, `techStack`, `proofSkills`, `githubUrl`, `demoUrl`, `appStoreUrl`, `screenshots`, `hasTests`, `hasCiCd`, `notes`.

## JobPosting

`id`, `source`, `externalId`, `companyName`, `jobTitle`, `country`, `city`, `workMode`, `jobUrl`, `rawDescription`, `salaryRange`, `publishedAt`, `status`, optional `notes`, timestamps.

## JobStatusHistory

`id`, `jobId`, `previousStatus`, `newStatus`, `note`, `changedAt`.

## JobNotes

`generalNotes`, `interviewNotes`, `recruiterNotes`, `nextAction`, optional `followUpDate`, `updatedAt`.

## ParsedJobRequirements

Required/preferred skills, experience level, languages, education, certificates, visa/work permit/relocation/housing support, flight, insurance, salary, work mode, location restrictions and company support.

## EligibilityAnalysis

Scores, decision, matched skills, missing skills, missing proof, requirements, support status, risks, action plan, explanation, summary, parsed requirements, `source`, `fallbackUsed`, `confidence`, `missingInformationQuestions`, timestamps.

## ApplicationPackage

`cvSummary`, `coverLetter`, `recruiterMessage`, `skillMatchExplanation`, `projectEvidence`, `riskNotes`, `finalChecklist`, timestamps.

## Settings

Provider enablement, provider status, required key/slug warnings, auth mode and storage label.
