export type WorkMode = 'remote' | 'hybrid' | 'onsite' | 'unknown';
export type JobStatus =
  | 'saved'
  | 'analyzed'
  | 'eligible'
  | 'almostEligible'
  | 'notEligible'
  | 'applied'
  | 'interview'
  | 'offer'
  | 'rejected'
  | 'archived';
export type SupportValue = 'provided' | 'notProvided' | 'mentioned' | 'notMentioned' | 'unclear';
export type EligibilityDecision = 'eligible' | 'almostEligible' | 'notEligible' | 'unclear';
export type AnalyzerSource = 'real_ai' | 'rule_based';
export type AnalyzerConfidence = 'low' | 'medium' | 'high';

export interface User {
  id: string;
  email: string;
  passwordHash: string;
  fullName: string;
  createdAt: string;
  updatedAt: string;
}

export interface SafeUser {
  id: string;
  email: string;
  fullName: string;
  createdAt: string;
  updatedAt: string;
}

export interface AuthSession {
  accessToken: string;
  user: SafeUser;
}

export interface UserProfile {
  id: string;
  fullName: string;
  currentCountry: string;
  citizenship: string;
  targetRole: string;
  experienceLevel: string;
  yearsOfExperience: number;
  educationLevel: string;
  englishLevel: string;
  japaneseLevel: string;
  koreanLevel: string;
  germanLevel: string;
  otherLanguages: string[];
  skills: string[];
  preferredCountries: string[];
  preferredWorkModes: WorkMode[];
  needsVisaSponsorship: boolean;
  wantsRelocationSupport: boolean;
  wantsHousingSupport: boolean;
  githubUrl: string;
  linkedInUrl: string;
  portfolioUrl: string;
  createdAt: string;
  updatedAt: string;
}

export interface Credential {
  id: string;
  title: string;
  provider: string;
  type: 'language' | 'programming' | 'cloud' | 'university' | 'bootcamp' | 'other';
  trustLevel: 'high' | 'medium' | 'low' | 'unverified';
  issueDate?: string;
  expiryDate?: string;
  verificationUrl: string;
  fileName: string;
  notes: string;
}

export interface PortfolioProject {
  id: string;
  title: string;
  description: string;
  techStack: string[];
  proofSkills: string[];
  githubUrl: string;
  demoUrl: string;
  appStoreUrl: string;
  screenshots: string[];
  hasTests: boolean;
  hasCiCd: boolean;
  notes: string;
}

export interface JobPosting {
  id: string;
  source: string;
  externalId: string;
  companyName: string;
  jobTitle: string;
  country: string;
  city: string;
  workMode: WorkMode;
  jobUrl: string;
  rawDescription: string;
  salaryRange: string;
  publishedAt: string;
  status: JobStatus;
  createdAt: string;
  updatedAt: string;
  notes?: JobNotes;
}

export interface JobStatusHistory {
  id: string;
  jobId: string;
  previousStatus: JobStatus;
  newStatus: JobStatus;
  note: string;
  changedAt: string;
}

export interface JobNotes {
  generalNotes: string;
  interviewNotes: string;
  recruiterNotes: string;
  nextAction: string;
  followUpDate?: string;
  updatedAt: string;
}

export interface ProviderSetting {
  name: string;
  enabled: boolean;
  status: 'active' | 'configured' | 'needs-configuration' | 'disabled';
  requiresApiKey: boolean;
  requiresCompanySlug: boolean;
  companySlugs: string[];
  warning?: string;
}

export interface PublicationReadiness {
  ready: boolean;
  blockers: string[];
  warnings: string[];
  nextActions: string[];
}

export interface AppSettings {
  environment: 'development' | 'production' | 'demo';
  useMockJobs: boolean;
  useRealAi: boolean;
  apiBaseUrl: string;
  configuredProviders: string[];
  storage: 'json-file' | 'postgresql';
  requireAuth: boolean;
  providers: ProviderSetting[];
  publicationReadiness: PublicationReadiness;
}

export interface CompanySupport {
  visaSponsorship: SupportValue;
  workPermitSupport: SupportValue;
  relocationPackage: SupportValue;
  flightTicket: SupportValue;
  temporaryHousing: SupportValue;
  housingAllowance: SupportValue;
  apartmentSearchSupport: SupportValue;
  healthInsurance: SupportValue;
  socialInsurance: SupportValue;
  equipmentProvided: SupportValue;
  remoteWorkSupport: SupportValue;
  languageClasses: SupportValue;
  familyRelocation: SupportValue;
  salaryRange: string;
  bonus: SupportValue;
  stockOptions: SupportValue;
  taxSupport: SupportValue;
}

export interface ParsedJobRequirements {
  requiredSkills: string[];
  preferredSkills: string[];
  experienceLevel: string;
  languageRequirements: string[];
  educationRequirements: string[];
  certificateRequirements: string[];
  visaSponsorship: SupportValue;
  workPermitSupport: SupportValue;
  relocationSupport: SupportValue;
  housingSupport: SupportValue;
  flightTicket: SupportValue;
  healthInsurance: SupportValue;
  salaryRange: string;
  workMode: WorkMode;
  locationRestrictions: string[];
  companySupport: CompanySupport;
}

export interface EligibilityAnalysis {
  id: string;
  jobId: string;
  overallMatchScore: number;
  skillsScore: number;
  experienceScore: number;
  languageScore: number;
  visaScore: number;
  locationScore: number;
  companySupportScore: number;
  decision: EligibilityDecision;
  matchedSkills: string[];
  missingSkills: string[];
  missingProof: string[];
  languageRequirements: string[];
  visaStatus: string;
  relocationStatus: string;
  locationRestrictions: string[];
  degreeRequirements: string[];
  companySupport: CompanySupport;
  risks: string[];
  actionPlan: string[];
  explanation: string;
  summary: string;
  parsedRequirements: ParsedJobRequirements;
  source: AnalyzerSource;
  fallbackUsed: boolean;
  confidence: AnalyzerConfidence;
  missingInformationQuestions: string[];
  createdAt: string;
  updatedAt: string;
}

export interface ApplicationPackage {
  id: string;
  jobId: string;
  cvSummary: string;
  coverLetter: string;
  recruiterMessage: string;
  skillMatchExplanation: string;
  projectEvidence: string;
  riskNotes: string;
  finalChecklist: string[];
  createdAt: string;
  updatedAt: string;
}

export interface JobSearchFilters {
  query?: string;
  countries?: string[];
  roles?: string[];
  workModes?: WorkMode[];
  providers?: string[];
  visaRequired?: boolean;
  relocationPreferred?: boolean;
  housingPreferred?: boolean;
  experienceLevel?: string;
}

export interface RawJob {
  id: string;
  source: string;
  payload: Record<string, unknown>;
}

export interface JobSourceProvider {
  name: string;
  searchJobs(filters: JobSearchFilters): Promise<RawJob[]>;
  normalize(rawJob: RawJob): JobPosting;
}
