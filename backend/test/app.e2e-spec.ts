import type { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request = require('supertest');

import { AppModule } from '../src/app.module';
import { strictCountryFilter } from '../src/job-source.providers';
import type { JobPosting } from '../src/domain';

describe('WorkBridge AI API', () => {
  let app: INestApplication;
  let token: string;

  beforeAll(async () => {
    process.env.DATA_FILE_PATH = `/tmp/workbridge-test-${Date.now()}.json`;
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule]
    }).compile();

    app = moduleRef.createNestApplication();
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('returns health status', async () => {
    await request(app.getHttpServer())
      .get('/health')
      .expect(200)
      .expect(({ body }) => {
        expect(body.status).toBe('ok');
        expect(body.service).toBe('workbridge-ai-backend');
      });
  });

  it('registers, logs in and returns current user', async () => {
    const email = `tester-${Date.now()}@workbridge.local`;
    const registered = await request(app.getHttpServer())
      .post('/auth/register')
      .send({ email, password: 'correct-horse-1', fullName: 'Test Candidate' })
      .expect(201);

    expect(registered.body.accessToken).toBeTruthy();
    expect(registered.body.user.email).toBe(email);

    const login = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email, password: 'correct-horse-1' })
      .expect(201);
    token = login.body.accessToken;

    await request(app.getHttpServer())
      .get('/auth/me')
      .set('Authorization', `Bearer ${token}`)
      .expect(200)
      .expect(({ body }) => expect(body.email).toBe(email));
  });

  it('persists profile, credentials and portfolio per user', async () => {
    const profile = await request(app.getHttpServer())
      .put('/profile')
      .set('Authorization', `Bearer ${token}`)
      .send({ fullName: 'Updated Candidate', skills: ['Flutter', 'Dart', 'REST API'], preferredCountries: ['Japan'] })
      .expect(200);
    expect(profile.body.fullName).toBe('Updated Candidate');

    const credential = await request(app.getHttpServer())
      .post('/credentials')
      .set('Authorization', `Bearer ${token}`)
      .send({
        title: 'REST API Certificate',
        provider: 'WorkBridge Test',
        type: 'programming',
        trustLevel: 'medium',
        verificationUrl: '',
        fileName: '',
        notes: 'REST API proof'
      })
      .expect(201);
    expect(credential.body.id).toContain('cred-');

    const project = await request(app.getHttpServer())
      .post('/portfolio-projects')
      .set('Authorization', `Bearer ${token}`)
      .send({
        title: 'Flutter API Client',
        description: 'Flutter app consuming REST APIs.',
        techStack: ['Flutter', 'Dart'],
        proofSkills: ['Flutter', 'Dart', 'REST API'],
        githubUrl: '',
        demoUrl: '',
        appStoreUrl: '',
        screenshots: [],
        hasTests: true,
        hasCiCd: false,
        notes: ''
      })
      .expect(201);
    expect(project.body.title).toBe('Flutter API Client');
  });

  it('searches, filters, analyzes, generates application and tracks status history', async () => {
    const search = await request(app.getHttpServer())
      .post('/jobs/search')
      .set('Authorization', `Bearer ${token}`)
      .send({ countries: ['Japan'], roles: ['Flutter Developer'] })
      .expect(201);

    expect(search.body).toHaveLength(1);
    const jobId = search.body[0].id as string;

    const analysis = await request(app.getHttpServer())
      .post(`/jobs/${jobId}/analyze`)
      .set('Authorization', `Bearer ${token}`)
      .expect(201);
    expect(analysis.body.jobId).toBe(jobId);
    expect(analysis.body.matchedSkills).toContain('Flutter');
    expect(analysis.body.source).toBe('rule_based');
    expect(Array.isArray(analysis.body.missingInformationQuestions)).toBe(true);

    const application = await request(app.getHttpServer())
      .post('/applications/generate')
      .set('Authorization', `Bearer ${token}`)
      .send({ jobId })
      .expect(201);
    expect(application.body.finalChecklist).toContain('Manually send the application outside WorkBridge AI.');

    await request(app.getHttpServer())
      .patch(`/jobs/${jobId}/status`)
      .set('Authorization', `Bearer ${token}`)
      .send({ status: 'applied', note: 'Sent manually from company website.' })
      .expect(200);

    const history = await request(app.getHttpServer())
      .get(`/jobs/${jobId}/status-history`)
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(history.body.some((item: { note: string }) => item.note.includes('Sent manually'))).toBe(true);
  });

  it('strict country filtering keeps remote-compatible jobs only', () => {
    const jobs: JobPosting[] = [
      job('local-jp', 'Japan', 'onsite'),
      job('remote-us', 'United States', 'remote'),
      job('onsite-us', 'United States', 'onsite')
    ];
    expect(strictCountryFilter(jobs, { countries: ['Japan'] }).map((item) => item.id)).toEqual([
      'local-jp',
      'remote-us'
    ]);
  });

  it('reports production readiness blockers from environment defaults', async () => {
    const previousAppEnv = process.env.APP_ENV;
    const previousUseMock = process.env.USE_MOCK_JOBS;
    const previousRequireAuth = process.env.REQUIRE_AUTH;
    const previousStorage = process.env.STORAGE_DRIVER;
    process.env.APP_ENV = 'production';
    delete process.env.USE_MOCK_JOBS;
    delete process.env.REQUIRE_AUTH;
    delete process.env.STORAGE_DRIVER;

    await request(app.getHttpServer())
      .get('/settings')
      .expect(200)
      .expect(({ body }) => {
        expect(body.environment).toBe('production');
        expect(body.useMockJobs).toBe(false);
        expect(body.requireAuth).toBe(true);
        expect(body.storage).toBe('json-file');
        expect(body.publicationReadiness.ready).toBe(false);
        expect(body.publicationReadiness.blockers).toContain('PostgreSQL is not enabled');
      });

    restore('APP_ENV', previousAppEnv);
    restore('USE_MOCK_JOBS', previousUseMock);
    restore('REQUIRE_AUTH', previousRequireAuth);
    restore('STORAGE_DRIVER', previousStorage);
  });
});

function job(id: string, country: string, workMode: JobPosting['workMode']): JobPosting {
  const now = new Date().toISOString();
  return {
    id,
    source: 'TestProvider',
    externalId: id,
    companyName: 'Test',
    jobTitle: 'Software Developer',
    country,
    city: country,
    workMode,
    jobUrl: '',
    rawDescription: 'Software developer role with Flutter and REST API.',
    salaryRange: '',
    publishedAt: now,
    status: 'saved',
    createdAt: now,
    updatedAt: now
  };
}

function restore(key: string, value: string | undefined): void {
  if (value == null) {
    delete process.env[key];
  } else {
    process.env[key] = value;
  }
}
