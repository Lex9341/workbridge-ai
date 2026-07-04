import { Injectable } from '@nestjs/common';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import { dirname, join } from 'path';

import type {
  ApplicationPackage,
  Credential,
  EligibilityAnalysis,
  JobNotes,
  JobPosting,
  JobStatus,
  JobStatusHistory,
  PortfolioProject,
  ProviderSetting,
  SafeUser,
  User,
  UserProfile
} from './domain';
import { storageType } from './runtime-config';

const nowIso = () => new Date().toISOString();
export const DEMO_USER_ID = 'demo-user';
const dataFile = process.env.DATA_FILE_PATH ?? join(process.cwd(), 'data', 'workbridge-store.json');

interface UserData {
  profile: UserProfile;
  credentials: Credential[];
  portfolioProjects: PortfolioProject[];
  jobs: JobPosting[];
  analyses: EligibilityAnalysis[];
  applications: ApplicationPackage[];
  statusHistory: JobStatusHistory[];
}

interface PersistedStore {
  users: User[];
  dataByUser: Record<string, UserData>;
  settings: {
    providers: ProviderSetting[];
  };
}

@Injectable()
export class StoreService {
  private state: PersistedStore;

  constructor() {
    this.state = this.load();
  }

  get storageType(): 'json-file' | 'postgresql' {
    return storageType();
  }

  createUser(input: { email: string; passwordHash: string; fullName: string }): SafeUser {
    const email = input.email.trim().toLowerCase();
    const existing = this.state.users.find((user) => user.email === email);
    if (existing) return safeUser(existing);
    const now = nowIso();
    const user: User = {
      id: `user-${Date.now()}`,
      email,
      passwordHash: input.passwordHash,
      fullName: input.fullName.trim() || email,
      createdAt: now,
      updatedAt: now
    };
    this.state.users = [...this.state.users, user];
    this.state.dataByUser[user.id] = emptyUserData(user.id, user.fullName);
    this.persist();
    return safeUser(user);
  }

  findUserByEmail(email: string): User | undefined {
    return this.state.users.find((user) => user.email === email.trim().toLowerCase());
  }

  findUserById(id: string): SafeUser | undefined {
    const user = this.state.users.find((item) => item.id === id);
    return user ? safeUser(user) : undefined;
  }

  getProfile(userId = DEMO_USER_ID): UserProfile {
    return this.userData(userId).profile;
  }

  updateProfile(input: Partial<UserProfile>, userId = DEMO_USER_ID): UserProfile {
    const data = this.userData(userId);
    const now = nowIso();
    data.profile = {
      ...data.profile,
      ...input,
      id: data.profile.id || `${userId}-profile`,
      createdAt: data.profile.createdAt || now,
      updatedAt: now
    };
    this.persist();
    return data.profile;
  }

  listCredentials(userId = DEMO_USER_ID): Credential[] {
    return this.userData(userId).credentials;
  }

  createCredential(input: Omit<Credential, 'id'>, userId = DEMO_USER_ID): Credential {
    const data = this.userData(userId);
    const item = { ...input, id: `cred-${Date.now()}` };
    data.credentials = [...data.credentials, item];
    this.persist();
    return item;
  }

  updateCredential(id: string, input: Partial<Credential>, userId = DEMO_USER_ID): Credential | undefined {
    const data = this.userData(userId);
    data.credentials = data.credentials.map((item) => (item.id === id ? { ...item, ...input, id } : item));
    this.persist();
    return data.credentials.find((item) => item.id === id);
  }

  deleteCredential(id: string, userId = DEMO_USER_ID): void {
    const data = this.userData(userId);
    data.credentials = data.credentials.filter((item) => item.id !== id);
    this.persist();
  }

  listPortfolioProjects(userId = DEMO_USER_ID): PortfolioProject[] {
    return this.userData(userId).portfolioProjects;
  }

  createPortfolioProject(input: Omit<PortfolioProject, 'id'>, userId = DEMO_USER_ID): PortfolioProject {
    const data = this.userData(userId);
    const item = { ...input, id: `project-${Date.now()}` };
    data.portfolioProjects = [...data.portfolioProjects, item];
    this.persist();
    return item;
  }

  updatePortfolioProject(id: string, input: Partial<PortfolioProject>, userId = DEMO_USER_ID): PortfolioProject | undefined {
    const data = this.userData(userId);
    data.portfolioProjects = data.portfolioProjects.map((item) =>
      item.id === id ? { ...item, ...input, id } : item
    );
    this.persist();
    return data.portfolioProjects.find((item) => item.id === id);
  }

  deletePortfolioProject(id: string, userId = DEMO_USER_ID): void {
    const data = this.userData(userId);
    data.portfolioProjects = data.portfolioProjects.filter((item) => item.id !== id);
    this.persist();
  }

  listJobs(userId = DEMO_USER_ID): JobPosting[] {
    return this.userData(userId).jobs;
  }

  replaceJobs(jobs: JobPosting[], userId = DEMO_USER_ID): JobPosting[] {
    const data = this.userData(userId);
    const knownById = new Map(data.jobs.map((job) => [job.id, job]));
    data.jobs = jobs.map((job) => ({
      ...job,
      status: knownById.get(job.id)?.status ?? job.status,
      notes: knownById.get(job.id)?.notes ?? job.notes
    }));
    this.persist();
    return data.jobs;
  }

  getJob(id: string, userId = DEMO_USER_ID): JobPosting | undefined {
    return this.userData(userId).jobs.find((job) => job.id === id);
  }

  updateJobStatus(
    id: string,
    status: JobStatus,
    userId = DEMO_USER_ID,
    note = ''
  ): JobPosting | undefined {
    const data = this.userData(userId);
    const job = data.jobs.find((item) => item.id === id);
    if (!job) return undefined;
    const previousStatus = job.status;
    data.jobs = data.jobs.map((item) => (item.id === id ? { ...item, status, updatedAt: nowIso() } : item));
    data.statusHistory = [
      ...data.statusHistory,
      {
        id: `history-${Date.now()}`,
        jobId: id,
        previousStatus,
        newStatus: status,
        note,
        changedAt: nowIso()
      }
    ];
    this.persist();
    return this.getJob(id, userId);
  }

  updateJobNotes(id: string, notes: Partial<JobNotes>, userId = DEMO_USER_ID): JobPosting | undefined {
    const data = this.userData(userId);
    const existing = data.jobs.find((job) => job.id === id);
    if (!existing) return undefined;
    const merged: JobNotes = {
      generalNotes: '',
      interviewNotes: '',
      recruiterNotes: '',
      nextAction: '',
      ...(existing.notes ?? {}),
      ...notes,
      updatedAt: nowIso()
    };
    data.jobs = data.jobs.map((job) => (job.id === id ? { ...job, notes: merged, updatedAt: nowIso() } : job));
    this.persist();
    return this.getJob(id, userId);
  }

  listStatusHistory(jobId: string, userId = DEMO_USER_ID): JobStatusHistory[] {
    return this.userData(userId).statusHistory.filter((item) => item.jobId === jobId);
  }

  saveAnalysis(analysis: EligibilityAnalysis, userId = DEMO_USER_ID): EligibilityAnalysis {
    const data = this.userData(userId);
    data.analyses = [...data.analyses.filter((item) => item.jobId !== analysis.jobId), analysis];
    const status: JobStatus = analysis.decision === 'unclear' ? 'analyzed' : analysis.decision;
    this.updateJobStatus(analysis.jobId, status, userId, 'Analysis completed.');
    this.persist();
    return analysis;
  }

  getAnalysis(jobId: string, userId = DEMO_USER_ID): EligibilityAnalysis | undefined {
    return this.userData(userId).analyses.find((item) => item.jobId === jobId);
  }

  listAnalyses(userId = DEMO_USER_ID): EligibilityAnalysis[] {
    return this.userData(userId).analyses;
  }

  saveApplication(application: ApplicationPackage, userId = DEMO_USER_ID): ApplicationPackage {
    const data = this.userData(userId);
    data.applications = [...data.applications.filter((item) => item.jobId !== application.jobId), application];
    this.persist();
    return application;
  }

  getApplication(jobId: string, userId = DEMO_USER_ID): ApplicationPackage | undefined {
    return this.userData(userId).applications.find((item) => item.jobId === jobId);
  }

  listApplications(userId = DEMO_USER_ID): ApplicationPackage[] {
    return this.userData(userId).applications;
  }

  getProviderSettings(): ProviderSetting[] {
    return this.state.settings.providers;
  }

  updateProviderSettings(input: ProviderSetting[]): ProviderSetting[] {
    const known = new Map(this.state.settings.providers.map((item) => [item.name, item]));
    this.state.settings.providers = input.map((item) => ({ ...known.get(item.name), ...item }));
    this.persist();
    return this.state.settings.providers;
  }

  private userData(userId: string): UserData {
    if (!this.state.dataByUser[userId]) {
      const user = this.state.users.find((item) => item.id === userId);
      this.state.dataByUser[userId] = emptyUserData(userId, user?.fullName ?? '');
      this.persist();
    }
    return this.state.dataByUser[userId];
  }

  private load(): PersistedStore {
    if (existsSync(dataFile)) {
      const parsed = JSON.parse(readFileSync(dataFile, 'utf8')) as Partial<PersistedStore> & Partial<UserData>;
      return normalizeStore(parsed);
    }
    const seeded = seedStore();
    this.state = seeded;
    this.persist();
    return seeded;
  }

  private persist(): void {
    if (!this.state) return;
    mkdirSync(dirname(dataFile), { recursive: true });
    writeFileSync(dataFile, `${JSON.stringify(this.state, null, 2)}\n`);
  }
}

function normalizeStore(input: Partial<PersistedStore> & Partial<UserData>): PersistedStore {
  if (input.users && input.dataByUser) {
    return {
      users: input.users,
      dataByUser: Object.fromEntries(
        Object.entries(input.dataByUser).map(([userId, data]) => [userId, normalizeUserData(userId, data)])
      ),
      settings: { providers: normalizeProviders(input.settings?.providers) }
    };
  }
  const seeded = seedStore();
  seeded.dataByUser[DEMO_USER_ID] = normalizeUserData(DEMO_USER_ID, {
    profile: input.profile,
    credentials: input.credentials,
    portfolioProjects: input.portfolioProjects,
    jobs: input.jobs,
    analyses: input.analyses,
    applications: input.applications
  });
  return seeded;
}

function seedStore(): PersistedStore {
  const now = nowIso();
  const users: User[] = [
    {
      id: DEMO_USER_ID,
      email: 'demo@workbridge.local',
      passwordHash: '',
      fullName: 'Akai Candidate',
      createdAt: now,
      updatedAt: now
    }
  ];
  return {
    users,
    dataByUser: { [DEMO_USER_ID]: process.env.USE_MOCK_JOBS === 'false' ? emptyUserData(DEMO_USER_ID, '') : demoUserData() },
    settings: { providers: normalizeProviders() }
  };
}

function normalizeUserData(userId: string, input: Partial<UserData> = {}): UserData {
  const fallback = userId === DEMO_USER_ID && process.env.USE_MOCK_JOBS !== 'false' ? demoUserData() : emptyUserData(userId, '');
  return {
    profile: { ...fallback.profile, ...input.profile },
    credentials: input.credentials ?? fallback.credentials,
    portfolioProjects: input.portfolioProjects ?? fallback.portfolioProjects,
    jobs: input.jobs ?? [],
    analyses: (input.analyses ?? []).map((analysis) => ({
      ...analysis,
      source: analysis.source ?? 'rule_based',
      fallbackUsed: analysis.fallbackUsed ?? false,
      confidence: analysis.confidence ?? 'medium',
      missingInformationQuestions: analysis.missingInformationQuestions ?? []
    })),
    applications: input.applications ?? [],
    statusHistory: input.statusHistory ?? []
  };
}

function emptyUserData(userId: string, fullName: string): UserData {
  const now = nowIso();
  return {
    profile: {
      id: `${userId}-profile`,
      fullName,
      currentCountry: '',
      citizenship: '',
      targetRole: 'Software Developer',
      experienceLevel: '',
      yearsOfExperience: 0,
      educationLevel: '',
      englishLevel: '',
      japaneseLevel: '',
      koreanLevel: '',
      germanLevel: '',
      otherLanguages: [],
      skills: [],
      preferredCountries: [],
      preferredWorkModes: ['remote'],
      needsVisaSponsorship: false,
      wantsRelocationSupport: false,
      wantsHousingSupport: false,
      githubUrl: '',
      linkedInUrl: '',
      portfolioUrl: '',
      createdAt: now,
      updatedAt: now
    },
    credentials: [],
    portfolioProjects: [],
    jobs: [],
    analyses: [],
    applications: [],
    statusHistory: []
  };
}

function demoUserData(): UserData {
  const data = emptyUserData(DEMO_USER_ID, 'Akai Candidate');
  return {
    ...data,
    profile: {
      ...data.profile,
      fullName: 'Akai Candidate',
      currentCountry: 'Uzbekistan',
      citizenship: 'Uzbekistan',
      targetRole: 'Flutter Developer',
      experienceLevel: 'Junior+',
      yearsOfExperience: 2,
      educationLevel: 'Bachelor equivalent',
      englishLevel: 'B2',
      japaneseLevel: 'N4',
      koreanLevel: 'Not provided',
      germanLevel: 'A2',
      otherLanguages: ['Uzbek', 'Russian'],
      skills: ['Flutter', 'Dart', 'Firebase', 'REST API', 'GitHub Actions', 'Testing', 'TypeScript'],
      preferredCountries: ['Japan', 'Germany', 'Netherlands'],
      preferredWorkModes: ['remote', 'hybrid', 'onsite'],
      needsVisaSponsorship: true,
      wantsRelocationSupport: true,
      wantsHousingSupport: true,
      githubUrl: 'https://github.com/example',
      linkedInUrl: 'https://linkedin.com/in/example',
      portfolioUrl: 'https://example.dev'
    },
    credentials: [
      {
        id: 'cred-ielts',
        title: 'IELTS Academic',
        provider: 'British Council',
        type: 'language',
        trustLevel: 'high',
        issueDate: '2025-05-01',
        expiryDate: '2027-05-01',
        verificationUrl: 'https://ielts.org',
        fileName: 'ielts-score.pdf',
        notes: 'B2/C1 range evidence for English communication.'
      }
    ],
    portfolioProjects: [
      {
        id: 'project-1',
        title: 'Cross-platform Task Planner',
        description: 'Flutter productivity app with Firebase auth, Firestore sync, tests and CI.',
        techStack: ['Flutter', 'Dart', 'Firebase', 'GitHub Actions'],
        proofSkills: ['Flutter', 'Dart', 'Firebase', 'Testing', 'GitHub Actions'],
        githubUrl: 'https://github.com/example/task-planner',
        demoUrl: 'https://example.dev/task-planner',
        appStoreUrl: '',
        screenshots: [],
        hasTests: true,
        hasCiCd: true,
        notes: 'Good evidence for mobile architecture and release readiness.'
      }
    ]
  };
}

function normalizeProviders(input: ProviderSetting[] = []): ProviderSetting[] {
  const defaults: ProviderSetting[] = [
    provider('MockJobProvider', true, false, false),
    provider('RemotiveProvider', true, false, false),
    provider('TheMuseProvider', true, false, false),
    provider('AdzunaProvider', true, true, false),
    provider('GreenhouseProvider', false, false, true),
    provider('LeverProvider', false, false, true),
    provider('AshbyProvider', false, false, true)
  ];
  const byName = new Map(input.map((item) => [item.name, item]));
  return defaults.map((item) => ({ ...item, ...byName.get(item.name) }));
}

function provider(
  name: string,
  enabled: boolean,
  requiresApiKey: boolean,
  requiresCompanySlug: boolean
): ProviderSetting {
  return {
    name,
    enabled,
    status: enabled ? 'configured' : 'disabled',
    requiresApiKey,
    requiresCompanySlug,
    companySlugs: []
  };
}

function safeUser(user: User): SafeUser {
  return {
    id: user.id,
    email: user.email,
    fullName: user.fullName,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt
  };
}
