import { describe, it, expect } from 'vitest';
import { sanitize, PerformanceTimer, createRequestLogger } from '../src/lib/logger';

describe('Logger', () => {
  describe('sanitize', () => {
    it('should redact sensitive cookie data', () => {
      const data = {
        cookie: 'secret_cookie_value',
        username: 'john',
      };

      const sanitized = sanitize(data);

      expect(sanitized.cookie).toBe('[REDACTED]');
      expect(sanitized.username).toBe('john');
    });

    it('should redact authorization headers', () => {
      const data = {
        headers: {
          authorization: 'Bearer secret_token',
          'content-type': 'application/json',
        },
      };

      const sanitized = sanitize(data);

      expect(sanitized.headers.authorization).toBe('[REDACTED]');
      expect(sanitized.headers['content-type']).toBe('application/json');
    });

    it('should redact nested sensitive data', () => {
      const data = {
        user: {
          name: 'John',
          credentials: {
            api_key: 'secret_key',
            password: 'secret_password',
          },
        },
      };

      const sanitized = sanitize(data);

      expect(sanitized.user.name).toBe('John');
      expect(sanitized.user.credentials.api_key).toBe('[REDACTED]');
      expect(sanitized.user.credentials.password).toBe('[REDACTED]');
    });

    it('should handle arrays', () => {
      const data = {
        items: [
          { id: 1, token: 'secret1' },
          { id: 2, token: 'secret2' },
        ],
      };

      const sanitized = sanitize(data);

      expect(sanitized.items[0].id).toBe(1);
      expect(sanitized.items[0].token).toBe('[REDACTED]');
      expect(sanitized.items[1].token).toBe('[REDACTED]');
    });

    it('should truncate very long strings', () => {
      const longString = 'a'.repeat(2000);
      const data = {
        content: longString,
      };

      const sanitized = sanitize(data);

      expect(sanitized.content).toContain('[TRUNCATED]');
      expect(sanitized.content.length).toBeLessThan(longString.length);
    });

    it('should handle null and undefined', () => {
      const data = {
        nullValue: null,
        undefinedValue: undefined,
        normalValue: 'test',
      };

      const sanitized = sanitize(data);

      expect(sanitized.nullValue).toBeNull();
      expect(sanitized.undefinedValue).toBeUndefined();
      expect(sanitized.normalValue).toBe('test');
    });

    it('should prevent infinite recursion', () => {
      const circular: any = { name: 'test' };
      circular.self = circular;

      // Should not throw
      expect(() => sanitize(circular)).not.toThrow();
    });
  });

  describe('PerformanceTimer', () => {
    it('should track operation duration', async () => {
      const logger = createRequestLogger('test-123');
      const timer = new PerformanceTimer(logger, 'test_operation');

      await new Promise(resolve => setTimeout(resolve, 50));

      const duration = timer.end();

      expect(duration).toBeGreaterThanOrEqual(50);
      expect(duration).toBeLessThan(100);
    });

    it('should track checkpoints', async () => {
      const logger = createRequestLogger('test-123');
      const timer = new PerformanceTimer(logger, 'multi_step_operation');

      await new Promise(resolve => setTimeout(resolve, 20));
      timer.checkpoint('step1');

      await new Promise(resolve => setTimeout(resolve, 20));
      timer.checkpoint('step2');

      const duration = timer.end();

      expect(duration).toBeGreaterThanOrEqual(40);
    });

    it('should handle errors', () => {
      const logger = createRequestLogger('test-123');
      const timer = new PerformanceTimer(logger, 'failing_operation');

      const error = new Error('Test error');
      const duration = timer.endWithError(error);

      expect(duration).toBeGreaterThanOrEqual(0);
    });
  });

  describe('createRequestLogger', () => {
    it('should create logger with request ID', () => {
      const logger = createRequestLogger('req-123');

      expect(logger).toBeDefined();
      // The logger child should have the requestId in bindings
      // We can't easily test this without mocking, but we verify it doesn't throw
    });

    it('should generate ID if not provided', () => {
      const logger = createRequestLogger();

      expect(logger).toBeDefined();
    });
  });
});
