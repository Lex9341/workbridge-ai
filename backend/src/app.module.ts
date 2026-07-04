import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { JwtModule } from '@nestjs/jwt';

import { ApplicationBuilderService, EligibilityService, LocalAnalyzerService } from './analysis.service';
import { ApplicationsController } from './applications.controller';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { ConfigController } from './config.controller';
import { CredentialsController } from './credentials.controller';
import { HealthController } from './health.controller';
import {
  AdzunaProvider,
  AshbyProvider,
  GreenhouseProvider,
  LeverProvider,
  MockJobProvider,
  RemotiveProvider,
  TheMuseProvider
} from './job-source.providers';
import { JobsController } from './jobs.controller';
import { PortfolioController } from './portfolio.controller';
import { ProfilesController } from './profiles.controller';
import { StoreService } from './store.service';
import { JwtAuthGuard } from './jwt-auth.guard';

@Module({
  imports: [
    JwtModule.register({
      global: true,
      secret: process.env.JWT_SECRET ?? 'workbridge-local-dev-secret',
      signOptions: { expiresIn: (process.env.JWT_EXPIRES_IN ?? '7d') as never }
    })
  ],
  controllers: [
    AuthController,
    HealthController,
    ConfigController,
    ProfilesController,
    CredentialsController,
    PortfolioController,
    JobsController,
    ApplicationsController
  ],
  providers: [
    StoreService,
    LocalAnalyzerService,
    EligibilityService,
    ApplicationBuilderService,
    MockJobProvider,
    RemotiveProvider,
    AdzunaProvider,
    TheMuseProvider,
    GreenhouseProvider,
    LeverProvider,
    AshbyProvider,
    AuthService,
    {
      provide: APP_GUARD,
      useClass: JwtAuthGuard
    }
  ]
})
export class AppModule {}
