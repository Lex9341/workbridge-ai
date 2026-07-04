import { Injectable } from '@nestjs/common';

import type { JobPosting, JobSearchFilters, JobSourceProvider, RawJob, WorkMode } from './domain';

const nowIso = () => new Date().toISOString();

const mockJobs: JobPosting[] = [
  {
    id: 'mock-jp-flutter-1',
    source: 'MockJobProvider',
    externalId: 'jp-flutter-1',
    companyName: 'Tokyo Mobility Labs',
    jobTitle: 'Flutter Developer',
    country: 'Japan',
    city: 'Tokyo',
    workMode: 'hybrid',
    jobUrl: 'https://example.com/jobs/tokyo-flutter',
    rawDescription:
      'Flutter, Dart, Firebase, REST API and Testing. English required, Japanese N4 helpful. Visa sponsorship, certificate of eligibility, relocation support, temporary accommodation, equipment and health insurance provided.',
    salaryRange: 'JPY 5M-7M',
    publishedAt: nowIso(),
    status: 'saved',
    createdAt: nowIso(),
    updatedAt: nowIso()
  },
  {
    id: 'mock-de-fullstack-1',
    source: 'MockJobProvider',
    externalId: 'de-fullstack-1',
    companyName: 'Berlin Cloud Works',
    jobTitle: 'Junior Full-stack Developer',
    country: 'Germany',
    city: 'Berlin',
    workMode: 'remote',
    jobUrl: 'https://example.com/jobs/berlin-fullstack',
    rawDescription:
      'React, TypeScript, Node.js, PostgreSQL, Docker, CI/CD and AWS. English B2 required. Visa sponsorship unclear. Remote work support and equipment provided.',
    salaryRange: 'EUR 48K-62K',
    publishedAt: nowIso(),
    status: 'saved',
    createdAt: nowIso(),
    updatedAt: nowIso()
  },
  {
    id: 'mock-nl-qa-1',
    source: 'MockJobProvider',
    externalId: 'nl-qa-1',
    companyName: 'Amsterdam Quality Systems',
    jobTitle: 'QA Automation Engineer',
    country: 'Netherlands',
    city: 'Amsterdam',
    workMode: 'hybrid',
    jobUrl: 'https://example.com/jobs/amsterdam-qa',
    rawDescription:
      'QA Automation, Playwright, Selenium, JavaScript, REST API and GitHub Actions. Must already have work authorization. Relocation support not provided.',
    salaryRange: 'EUR 42K-55K',
    publishedAt: nowIso(),
    status: 'saved',
    createdAt: nowIso(),
    updatedAt: nowIso()
  }
];

@Injectable()
export class MockJobProvider implements JobSourceProvider {
  name = 'MockJobProvider';

  async searchJobs(filters: JobSearchFilters): Promise<RawJob[]> {
    return mockJobs
      .filter((job) => matchesFilters(job, filters))
      .map((job) => ({ id: job.externalId, source: this.name, payload: job as unknown as Record<string, unknown> }));
  }

  normalize(rawJob: RawJob): JobPosting {
    return rawJob.payload as unknown as JobPosting;
  }
}

@Injectable()
export class RemotiveProvider implements JobSourceProvider {
  name = 'RemotiveProvider';

  async searchJobs(filters: JobSearchFilters): Promise<RawJob[]> {
    const query = encodeURIComponent(filters.query ?? 'software developer');
    const response = await fetch(`https://remotive.com/api/remote-jobs?search=${query}`);
    if (!response.ok) {
      return [];
    }
    const data = (await response.json()) as { jobs?: Array<Record<string, unknown>> };
    return (data.jobs ?? []).map((job) => ({
      id: String(job.id),
      source: this.name,
      payload: job
    }));
  }

  normalize(rawJob: RawJob): JobPosting {
    const job = rawJob.payload;
    const description = String(job.description ?? '');
    return {
      id: `remotive-${rawJob.id}`,
      source: this.name,
      externalId: rawJob.id,
      companyName: String(job.company_name ?? 'Unknown company'),
      jobTitle: String(job.title ?? 'Untitled IT role'),
      country: inferCountry(String(job.candidate_required_location ?? 'Worldwide')),
      city: String(job.candidate_required_location ?? 'Remote'),
      workMode: 'remote',
      jobUrl: String(job.url ?? ''),
      rawDescription: stripHtml(description),
      salaryRange: String(job.salary ?? ''),
      publishedAt: String(job.publication_date ?? nowIso()),
      status: 'saved',
      createdAt: nowIso(),
      updatedAt: nowIso()
    };
  }
}

@Injectable()
export class AdzunaProvider implements JobSourceProvider {
  name = 'AdzunaProvider';
  async searchJobs(filters: JobSearchFilters): Promise<RawJob[]> {
    if (!process.env.ADZUNA_APP_ID || !process.env.ADZUNA_APP_KEY) return [];
    const country = adzunaCountryCode(filters.countries?.[0] ?? 'United Kingdom');
    const params = new URLSearchParams({
      app_id: process.env.ADZUNA_APP_ID,
      app_key: process.env.ADZUNA_APP_KEY,
      what: filters.query ?? filters.roles?.[0] ?? 'software developer',
      results_per_page: '20',
      'content-type': 'application/json'
    });
    const response = await fetch(`https://api.adzuna.com/v1/api/jobs/${country}/search/1?${params.toString()}`);
    if (!response.ok) return [];
    const data = (await response.json()) as { results?: Array<Record<string, unknown>> };
    return (data.results ?? []).map((job) => ({ id: String(job.id), source: this.name, payload: job }));
  }
  normalize(rawJob: RawJob): JobPosting {
    const job = rawJob.payload;
    const location = job.location as { display_name?: string; area?: string[] } | undefined;
    const area = location?.area ?? [];
    return {
      id: `adzuna-${rawJob.id}`,
      source: this.name,
      externalId: rawJob.id,
      companyName: String((job.company as { display_name?: string } | undefined)?.display_name ?? 'Unknown company'),
      jobTitle: String(job.title ?? 'Untitled IT role'),
      country: inferCountry(area.join(' ') || location?.display_name || ''),
      city: String(location?.display_name ?? area[area.length - 1] ?? ''),
      workMode: normalizeWorkMode(`${job.title ?? ''} ${job.description ?? ''}`),
      jobUrl: String(job.redirect_url ?? ''),
      rawDescription: stripHtml(String(job.description ?? '')),
      salaryRange: salaryRange(job),
      publishedAt: String(job.created ?? nowIso()),
      status: 'saved',
      createdAt: nowIso(),
      updatedAt: nowIso()
    };
  }
}

@Injectable()
export class TheMuseProvider implements JobSourceProvider {
  name = 'TheMuseProvider';
  async searchJobs(filters: JobSearchFilters): Promise<RawJob[]> {
    const params = new URLSearchParams({ page: '1', category: 'Software Engineering' });
    if (filters.query) params.set('keyword', filters.query);
    for (const country of filters.countries ?? []) params.append('location', country);
    const response = await fetch(`https://www.themuse.com/api/public/jobs?${params.toString()}`);
    if (!response.ok) return [];
    const data = (await response.json()) as { results?: Array<Record<string, unknown>> };
    return (data.results ?? []).map((job) => ({ id: String(job.id), source: this.name, payload: job }));
  }
  normalize(rawJob: RawJob): JobPosting {
    const job = rawJob.payload;
    const locations = (job.locations as Array<{ name?: string }> | undefined)?.map((item) => item.name ?? '') ?? [];
    const locationText = locations.join(', ');
    return {
      id: `themuse-${rawJob.id}`,
      source: this.name,
      externalId: rawJob.id,
      companyName: String((job.company as { name?: string } | undefined)?.name ?? 'Unknown company'),
      jobTitle: String(job.name ?? 'Untitled IT role'),
      country: inferCountry(locationText),
      city: locationText || 'Unclear',
      workMode: normalizeWorkMode(`${job.name ?? ''} ${job.contents ?? ''} ${locationText}`),
      jobUrl: String((job.refs as { landing_page?: string } | undefined)?.landing_page ?? ''),
      rawDescription: stripHtml(String(job.contents ?? '')),
      salaryRange: '',
      publishedAt: String(job.publication_date ?? nowIso()),
      status: 'saved',
      createdAt: nowIso(),
      updatedAt: nowIso()
    };
  }
}

@Injectable()
export class GreenhouseProvider implements JobSourceProvider {
  name = 'GreenhouseProvider';
  async searchJobs(_filters: JobSearchFilters): Promise<RawJob[]> {
    const tokens = csv(process.env.GREENHOUSE_BOARD_TOKEN);
    const results: RawJob[] = [];
    for (const token of tokens) {
      try {
        const response = await fetch(`https://boards-api.greenhouse.io/v1/boards/${token}/jobs?content=true`);
        if (!response.ok) continue;
        const data = (await response.json()) as { jobs?: Array<Record<string, unknown>> };
        results.push(
          ...(data.jobs ?? []).map((job) => ({
            id: `${token}-${String(job.id)}`,
            source: this.name,
            payload: { ...job, boardToken: token }
          }))
        );
      } catch {
        continue;
      }
    }
    return results;
  }
  normalize(rawJob: RawJob): JobPosting {
    const job = rawJob.payload;
    const location = String((job.location as { name?: string } | undefined)?.name ?? '');
    return {
      id: `greenhouse-${rawJob.id}`,
      source: this.name,
      externalId: rawJob.id,
      companyName: String(job.boardToken ?? 'Greenhouse company'),
      jobTitle: String(job.title ?? 'Untitled IT role'),
      country: inferCountry(location),
      city: location || 'Unclear',
      workMode: normalizeWorkMode(`${job.title ?? ''} ${job.content ?? ''} ${location}`),
      jobUrl: String(job.absolute_url ?? ''),
      rawDescription: stripHtml(String(job.content ?? '')),
      salaryRange: '',
      publishedAt: String(job.updated_at ?? nowIso()),
      status: 'saved',
      createdAt: nowIso(),
      updatedAt: nowIso()
    };
  }
}

@Injectable()
export class LeverProvider implements JobSourceProvider {
  name = 'LeverProvider';
  async searchJobs(_filters: JobSearchFilters): Promise<RawJob[]> {
    const slugs = csv(process.env.LEVER_COMPANY_SLUG);
    const results: RawJob[] = [];
    for (const slug of slugs) {
      try {
        const response = await fetch(`https://api.lever.co/v0/postings/${slug}?mode=json`);
        if (!response.ok) continue;
        const data = (await response.json()) as Array<Record<string, unknown>>;
        results.push(
          ...data.map((job) => ({
            id: `${slug}-${String(job.id)}`,
            source: this.name,
            payload: { ...job, companySlug: slug }
          }))
        );
      } catch {
        continue;
      }
    }
    return results;
  }
  normalize(rawJob: RawJob): JobPosting {
    const job = rawJob.payload;
    const categories = job.categories as { location?: string; commitment?: string; team?: string } | undefined;
    const text = `${job.text ?? ''} ${job.descriptionPlain ?? ''} ${job.additionalPlain ?? ''}`;
    const location = String(categories?.location ?? '');
    return {
      id: `lever-${rawJob.id}`,
      source: this.name,
      externalId: rawJob.id,
      companyName: String(job.companySlug ?? 'Lever company'),
      jobTitle: String(job.text ?? 'Untitled IT role'),
      country: inferCountry(location),
      city: location || 'Unclear',
      workMode: normalizeWorkMode(`${text} ${location}`),
      jobUrl: String(job.hostedUrl ?? job.applyUrl ?? ''),
      rawDescription: stripHtml(text),
      salaryRange: '',
      publishedAt: job.createdAt ? new Date(Number(job.createdAt)).toISOString() : nowIso(),
      status: 'saved',
      createdAt: nowIso(),
      updatedAt: nowIso()
    };
  }
}

@Injectable()
export class AshbyProvider implements JobSourceProvider {
  name = 'AshbyProvider';
  async searchJobs(_filters: JobSearchFilters): Promise<RawJob[]> {
    const slugs = csv(process.env.ASHBY_ORGANIZATION_SLUG);
    const results: RawJob[] = [];
    for (const slug of slugs) {
      try {
        const response = await fetch(`https://api.ashbyhq.com/posting-api/job-board/${slug}`);
        if (!response.ok) continue;
        const data = (await response.json()) as { jobs?: Array<Record<string, unknown>> };
        results.push(
          ...(data.jobs ?? []).map((job) => ({
            id: `${slug}-${String(job.id)}`,
            source: this.name,
            payload: { ...job, organizationSlug: slug }
          }))
        );
      } catch {
        continue;
      }
    }
    return results;
  }
  normalize(rawJob: RawJob): JobPosting {
    const job = rawJob.payload;
    const location = String((job.location as string | undefined) ?? '');
    const description = String(job.descriptionHtml ?? job.descriptionPlain ?? job.description ?? '');
    return {
      id: `ashby-${rawJob.id}`,
      source: this.name,
      externalId: rawJob.id,
      companyName: String(job.organizationSlug ?? 'Ashby company'),
      jobTitle: String(job.title ?? 'Untitled IT role'),
      country: inferCountry(location),
      city: location || 'Unclear',
      workMode: normalizeWorkMode(`${job.title ?? ''} ${description} ${location}`),
      jobUrl: String(job.jobUrl ?? `https://jobs.ashbyhq.com/${job.organizationSlug}/${job.id}`),
      rawDescription: stripHtml(description),
      salaryRange: '',
      publishedAt: String(job.publishedAt ?? nowIso()),
      status: 'saved',
      createdAt: nowIso(),
      updatedAt: nowIso()
    };
  }
}

function csv(value: string | undefined): string[] {
  return (value ?? '')
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
}

function matchesFilters(job: JobPosting, filters: JobSearchFilters): boolean {
  const countryMatch =
    !filters.countries?.length ||
    filters.countries.includes(job.country) ||
    job.country === 'Unclear' ||
    job.workMode === 'remote';
  const workModeMatch = !filters.workModes?.length || filters.workModes.includes(job.workMode);
  const query = filters.query?.trim().toLowerCase();
  const queryMatch =
    !query ||
    `${job.jobTitle} ${job.companyName} ${job.rawDescription}`.toLowerCase().includes(query);
  const roleMatch =
    !filters.roles?.length ||
    filters.roles.some((role) => job.jobTitle.toLowerCase().includes(role.toLowerCase()));
  return countryMatch && workModeMatch && queryMatch && roleMatch;
}

function inferCountry(location: string): string {
  const known = ['Japan', 'Germany', 'Netherlands', 'United States', 'Canada', 'United Kingdom'];
  return known.find((country) => location.toLowerCase().includes(country.toLowerCase())) ?? 'Unclear';
}

function stripHtml(input: string): string {
  return input.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
}

export function strictCountryFilter(jobs: JobPosting[], filters: JobSearchFilters): JobPosting[] {
  const providerFiltered = filters.providers?.length
    ? jobs.filter((job) => filters.providers?.includes(job.source))
    : jobs;
  const itJobs = providerFiltered.filter(isItJob);
  if (!filters.countries?.length) return itJobs;
  return itJobs.filter((job) => {
    if (job.country === 'Unclear') {
      return job.workMode === 'remote';
    }
    return filters.countries?.includes(job.country) || job.workMode === 'remote';
  });
}

export function normalizeWorkMode(value: string): WorkMode {
  const lower = value.toLowerCase();
  if (lower.includes('remote')) return 'remote';
  if (lower.includes('hybrid')) return 'hybrid';
  if (lower.includes('onsite') || lower.includes('on-site')) return 'onsite';
  return 'unknown';
}

function salaryRange(job: Record<string, unknown>): string {
  const min = job.salary_min ? String(job.salary_min) : '';
  const max = job.salary_max ? String(job.salary_max) : '';
  if (min && max) return `${min}-${max}`;
  return min || max || '';
}

function adzunaCountryCode(country: string): string {
  const map: Record<string, string> = {
    'United Kingdom': 'gb',
    'United States': 'us',
    Germany: 'de',
    Netherlands: 'nl',
    Canada: 'ca',
    France: 'fr',
    Austria: 'at',
    Australia: 'au'
  };
  return map[country] ?? 'gb';
}

function isItJob(job: JobPosting): boolean {
  const text = `${job.jobTitle} ${job.rawDescription}`.toLowerCase();
  return [
    'software',
    'developer',
    'engineer',
    'flutter',
    'frontend',
    'backend',
    'full-stack',
    'fullstack',
    'mobile',
    'cloud',
    'devops',
    'data',
    'qa',
    'automation',
    'typescript',
    'python',
    'java',
    'react'
  ].some((term) => text.includes(term));
}
