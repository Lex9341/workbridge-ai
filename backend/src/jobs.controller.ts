import { Body, Controller, Get, NotFoundException, Param, Patch, Post } from '@nestjs/common';

import { EligibilityService } from './analysis.service';
import { CurrentUserId } from './current-user';
import type { JobNotes, JobPosting, JobSearchFilters, JobSourceProvider, JobStatus } from './domain';
import {
  AdzunaProvider,
  AshbyProvider,
  GreenhouseProvider,
  LeverProvider,
  MockJobProvider,
  RemotiveProvider,
  strictCountryFilter,
  TheMuseProvider
} from './job-source.providers';
import { StoreService } from './store.service';
import { useMockJobs } from './runtime-config';

@Controller()
export class JobsController {
  private readonly providers: JobSourceProvider[];

  constructor(
    private readonly store: StoreService,
    private readonly eligibility: EligibilityService,
    mockProvider: MockJobProvider,
    remotiveProvider: RemotiveProvider,
    adzunaProvider: AdzunaProvider,
    theMuseProvider: TheMuseProvider,
    greenhouseProvider: GreenhouseProvider,
    leverProvider: LeverProvider,
    ashbyProvider: AshbyProvider
  ) {
    this.providers = [
      mockProvider,
      remotiveProvider,
      adzunaProvider,
      theMuseProvider,
      greenhouseProvider,
      leverProvider,
      ashbyProvider
    ];
  }

  @Get('job-sources')
  sources() {
    return this.providers.map((provider) => ({
      name: provider.name,
      status: provider.name === 'MockJobProvider' && useMockJobs()
        ? 'active'
        : providerReady(provider.name)
          ? 'configured'
          : 'needs-configuration'
    }));
  }

  @Get('jobs')
  listJobs(@CurrentUserId() userId: string): JobPosting[] {
    return this.store.listJobs(userId);
  }

  @Get('jobs/:id')
  getJob(@Param('id') id: string, @CurrentUserId() userId: string): JobPosting {
    const job = this.store.getJob(id, userId);
    if (!job) throw new NotFoundException(`Job ${id} was not found.`);
    return job;
  }

  @Post('jobs/search')
  async search(@Body() filters: JobSearchFilters, @CurrentUserId() userId: string): Promise<JobPosting[]> {
    const mockJobsEnabled = useMockJobs();
    const selectedProviders = filters.providers?.length
      ? this.providers.filter((provider) => filters.providers?.includes(provider.name))
      : this.providers;
    const activeProviders = mockJobsEnabled
      ? selectedProviders.filter((provider) => provider.name === 'MockJobProvider')
      : selectedProviders.filter((provider) => provider.name !== 'MockJobProvider' && providerReady(provider.name));
    const nested = await Promise.all(
      activeProviders.map(async (provider) => {
        const rawJobs = await provider.searchJobs(filters);
        return rawJobs.map((rawJob) => provider.normalize(rawJob));
      })
    );
    const jobs = strictCountryFilter(nested.flat(), filters);
    return this.store.replaceJobs(jobs, userId);
  }

  @Post('jobs/:id/analyze')
  async analyze(@Param('id') id: string, @CurrentUserId() userId: string) {
    const job = this.store.getJob(id, userId);
    if (!job) throw new NotFoundException(`Job ${id} was not found.`);
    const analysis = await this.eligibility.analyze(
      this.store.getProfile(userId),
      this.store.listCredentials(userId),
      this.store.listPortfolioProjects(userId),
      job
    );
    return this.store.saveAnalysis(analysis, userId);
  }

  @Patch('jobs/:id/status')
  updateStatus(
    @Param('id') id: string,
    @Body() input: { status: JobStatus; note?: string },
    @CurrentUserId() userId: string
  ): JobPosting {
    const job = this.store.updateJobStatus(id, input.status, userId, input.note ?? '');
    if (!job) throw new NotFoundException(`Job ${id} was not found.`);
    return job;
  }

  @Patch('jobs/:id/notes')
  updateNotes(@Param('id') id: string, @Body() input: Partial<JobNotes>, @CurrentUserId() userId: string): JobPosting {
    const job = this.store.updateJobNotes(id, input, userId);
    if (!job) throw new NotFoundException(`Job ${id} was not found.`);
    return job;
  }

  @Get('jobs/:id/status-history')
  statusHistory(@Param('id') id: string, @CurrentUserId() userId: string) {
    if (!this.store.getJob(id, userId)) throw new NotFoundException(`Job ${id} was not found.`);
    return this.store.listStatusHistory(id, userId);
  }
}

function providerReady(name: string): boolean {
  if (name === 'MockJobProvider') return useMockJobs();
  if (name === 'RemotiveProvider') return true;
  if (name === 'TheMuseProvider') return true;
  if (name === 'AdzunaProvider') return Boolean(process.env.ADZUNA_APP_ID && process.env.ADZUNA_APP_KEY);
  if (name === 'GreenhouseProvider') return Boolean(process.env.GREENHOUSE_BOARD_TOKEN);
  if (name === 'LeverProvider') return Boolean(process.env.LEVER_COMPANY_SLUG);
  if (name === 'AshbyProvider') return Boolean(process.env.ASHBY_ORGANIZATION_SLUG);
  return false;
}
