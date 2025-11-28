import { beforeAll, afterAll, beforeEach, afterEach } from 'vitest';

/**
 * Test setup and teardown
 */

// Set test environment variables
beforeAll(() => {
  process.env.NODE_ENV = 'test';
  process.env.SUNO_COOKIE = 'test_cookie_value';
  process.env.TWOCAPTCHA_KEY = 'test_captcha_key';
  process.env.BROWSER = 'chromium';
  process.env.BROWSER_HEADLESS = 'true';
  process.env.BROWSER_LOCALE = 'en';
});

// Clean up after all tests
afterAll(() => {
  // Cleanup resources if needed
});

// Reset state before each test
beforeEach(() => {
  // Reset any global state
});

// Clean up after each test
afterEach(() => {
  // Clear any test-specific resources
});
