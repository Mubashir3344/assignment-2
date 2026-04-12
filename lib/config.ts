const browserFallbackApiBaseUrl =
  typeof window !== 'undefined'
    ? `${window.location.protocol}//${window.location.hostname}:3001`
    : 'http://localhost:3001';

const serverApiBaseUrl =
  process.env.INTERNAL_API_BASE_URL ||
  process.env.NEXT_PUBLIC_API_BASE_URL ||
  'http://api:3001';

const clientApiBaseUrl =
  process.env.NEXT_PUBLIC_API_BASE_URL || browserFallbackApiBaseUrl;

const config = {
  apiBaseUrl: typeof window === 'undefined' ? serverApiBaseUrl : clientApiBaseUrl,
  nextAuthUrl: process.env.NEXTAUTH_URL || 'http://localhost:3000',
};

export default config;

