export type AppEnvironment = 'development' | 'production' | 'demo';

export function appEnvironment(): AppEnvironment {
  const value = (process.env.APP_ENV ?? process.env.NODE_ENV ?? 'development').toLowerCase();
  if (value === 'production') return 'production';
  if (value === 'demo') return 'demo';
  return 'development';
}

export function useMockJobs(): boolean {
  if (process.env.USE_MOCK_JOBS != null) return process.env.USE_MOCK_JOBS !== 'false';
  return appEnvironment() !== 'production';
}

export function requireAuth(): boolean {
  if (process.env.REQUIRE_AUTH != null) return process.env.REQUIRE_AUTH === 'true';
  return appEnvironment() === 'production';
}

export function storageType(): 'json-file' | 'postgresql' {
  return process.env.STORAGE_DRIVER === 'postgres' && Boolean(process.env.DATABASE_URL)
    ? 'postgresql'
    : 'json-file';
}
