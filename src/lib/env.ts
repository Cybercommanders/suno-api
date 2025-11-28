import { z } from 'zod';

/**
 * Environment variable validation schema
 * Ensures all required configuration is present at startup
 */
const envSchema = z.object({
  // Required: Suno authentication
  SUNO_COOKIE: z.string().min(1, 'SUNO_COOKIE is required'),

  // Required: 2Captcha API key
  TWOCAPTCHA_KEY: z.string().min(1, 'TWOCAPTCHA_KEY is required'),

  // Browser configuration
  BROWSER: z.enum(['chromium', 'firefox']).default('chromium'),
  BROWSER_GHOST_CURSOR: z.string().optional(),
  BROWSER_LOCALE: z.string().default('en'),
  BROWSER_HEADLESS: z.string().default('true'),
  BROWSER_DISABLE_GPU: z.string().optional(),

  // Optional: Rate limiting (Upstash Redis)
  UPSTASH_REDIS_REST_URL: z.string().url().optional(),
  UPSTASH_REDIS_REST_TOKEN: z.string().optional(),

  // Optional: CORS allowed origins (comma-separated)
  ALLOWED_ORIGINS: z.string().optional(),

  // Optional: Node environment
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
});

export type Env = z.infer<typeof envSchema>;

/**
 * Validates environment variables at startup
 * Throws an error if validation fails
 */
export function validateEnv(): Env {
  try {
    return envSchema.parse(process.env);
  } catch (error) {
    if (error instanceof z.ZodError) {
      const missingVars = error.errors.map(e => `${e.path.join('.')}: ${e.message}`);
      throw new Error(
        `Environment validation failed:\n${missingVars.join('\n')}\n\n` +
        'Please check your .env file or environment variables.'
      );
    }
    throw error;
  }
}

/**
 * Validated environment variables
 * Use this instead of process.env for type safety
 */
export const env = validateEnv();
