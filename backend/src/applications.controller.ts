import { Body, Controller, Get, NotFoundException, Param, Post } from '@nestjs/common';

import { ApplicationBuilderService, EligibilityService } from './analysis.service';
import { CurrentUserId } from './current-user';
import type { ApplicationPackage } from './domain';
import { StoreService } from './store.service';

@Controller('applications')
export class ApplicationsController {
  constructor(
    private readonly store: StoreService,
    private readonly eligibility: EligibilityService,
    private readonly builder: ApplicationBuilderService
  ) {}

  @Get()
  list(@CurrentUserId() userId: string): ApplicationPackage[] {
    return this.store.listApplications(userId);
  }

  @Post('generate')
  async generate(@Body() input: { jobId: string }, @CurrentUserId() userId: string): Promise<ApplicationPackage> {
    const job = this.store.getJob(input.jobId, userId);
    if (!job) throw new NotFoundException(`Job ${input.jobId} was not found.`);
    const analysis =
      this.store.getAnalysis(job.id, userId) ??
      this.store.saveAnalysis(
        await this.eligibility.analyze(
          this.store.getProfile(userId),
          this.store.listCredentials(userId),
          this.store.listPortfolioProjects(userId),
          job
        ),
        userId
      );
    const application = this.builder.generate(
      this.store.getProfile(userId),
      this.store.listPortfolioProjects(userId),
      job,
      analysis
    );
    return this.store.saveApplication(application, userId);
  }

  @Get(':jobId')
  getByJobId(@Param('jobId') jobId: string, @CurrentUserId() userId: string): ApplicationPackage {
    const application = this.store.getApplication(jobId, userId);
    if (!application) throw new NotFoundException(`Application for job ${jobId} was not found.`);
    return application;
  }
}
