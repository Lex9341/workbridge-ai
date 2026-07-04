import { Body, Controller, Get, Put } from '@nestjs/common';

import type { AppSettings, ProviderSetting } from './domain';
import { appEnvironment, requireAuth, storageType, useMockJobs } from './runtime-config';
import { StoreService } from './store.service';

@Controller()
export class ConfigController {
  constructor(private readonly store: StoreService) {}

  @Get('settings')
  settings(): AppSettings {
    const providers = providerSettings(this.store.getProviderSettings());
    const readiness = publicationReadiness(providers);
    return {
      environment: appEnvironment(),
      useMockJobs: useMockJobs(),
      useRealAi: process.env.USE_REAL_AI === 'true' && Boolean(process.env.OPENAI_API_KEY || process.env.AI_API_KEY),
      apiBaseUrl: process.env.API_BASE_URL ?? `http://localhost:${process.env.PORT ?? 3000}`,
      configuredProviders: providers
        .filter((item) => item.enabled && (item.status === 'active' || item.status === 'configured'))
        .map((item) => item.name),
      storage: storageType(),
      requireAuth: requireAuth(),
      providers,
      publicationReadiness: readiness
    };
  }

  @Put('settings/providers')
  updateProviders(@Body() input: ProviderSetting[]): ProviderSetting[] {
    return providerSettings(this.store.updateProviderSettings(input));
  }
}

function providerSettings(saved: ProviderSetting[]): ProviderSetting[] {
  return saved.map((item) => {
    const ready = providerReady(item);
    const enabled = item.name === 'MockJobProvider' ? useMockJobs() : item.enabled;
    return {
      ...item,
      enabled,
      status: !enabled ? 'disabled' : item.name === 'MockJobProvider' && useMockJobs() ? 'active' : ready ? 'configured' : 'needs-configuration',
      warning: enabled && !ready ? missingWarning(item) : undefined
    };
  });
}

function providerReady(provider: ProviderSetting): boolean {
  if (provider.name === 'MockJobProvider') return useMockJobs();
  if (provider.name === 'RemotiveProvider' || provider.name === 'TheMuseProvider') return true;
  if (provider.name === 'AdzunaProvider') return Boolean(process.env.ADZUNA_APP_ID && process.env.ADZUNA_APP_KEY);
  if (provider.name === 'GreenhouseProvider') return provider.companySlugs.length > 0 || Boolean(process.env.GREENHOUSE_BOARD_TOKEN);
  if (provider.name === 'LeverProvider') return provider.companySlugs.length > 0 || Boolean(process.env.LEVER_COMPANY_SLUG);
  if (provider.name === 'AshbyProvider') return provider.companySlugs.length > 0 || Boolean(process.env.ASHBY_ORGANIZATION_SLUG);
  return false;
}

function missingWarning(provider: ProviderSetting): string {
  if (provider.name === 'AdzunaProvider') return 'ADZUNA_APP_ID and ADZUNA_APP_KEY are required.';
  if (provider.requiresCompanySlug) return 'Add at least one public company slug/token.';
  return 'Provider is not configured.';
}

function publicationReadiness(providers: ProviderSetting[]) {
  const blockers = [
    ...(appEnvironment() === 'production' && storageType() !== 'postgresql'
      ? ['PostgreSQL is not enabled']
      : []),
    ...(appEnvironment() === 'production' && !requireAuth() ? ['Auth is disabled'] : []),
    ...(appEnvironment() === 'production' && useMockJobs() ? ['Mock jobs are enabled'] : []),
    ...(appEnvironment() === 'production' && providers.every((item) => item.name === 'MockJobProvider' || item.status === 'disabled' || item.status === 'needs-configuration')
      ? ['No production job provider is configured']
      : [])
  ];
  const warnings = [
    ...providers.filter((item) => item.status === 'needs-configuration').map((item) => `${item.name}: ${item.warning ?? 'Needs configuration'}`),
    ...(process.env.USE_REAL_AI === 'true' && !(process.env.OPENAI_API_KEY || process.env.AI_API_KEY)
      ? ['USE_REAL_AI is true but no AI API key is configured']
      : [])
  ];
  const nextActions = [
    ...(storageType() !== 'postgresql' ? ['Set STORAGE_DRIVER=postgres and DATABASE_URL, then run Prisma migrations.'] : []),
    ...(!requireAuth() ? ['Set REQUIRE_AUTH=true for production.'] : []),
    ...(useMockJobs() ? ['Set USE_MOCK_JOBS=false for production search.'] : []),
    ...(providers.some((item) => item.status === 'needs-configuration') ? ['Configure API keys or company slugs for needed providers.'] : [])
  ];
  return {
    ready: blockers.length === 0,
    blockers,
    warnings,
    nextActions
  };
}
