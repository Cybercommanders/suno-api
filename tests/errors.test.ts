import { describe, it, expect } from 'vitest';
import {
  SunoApiError,
  ValidationError,
  AuthenticationError,
  PaymentRequiredError,
  RateLimitError,
  InternalError,
  CaptchaError,
  formatErrorResponse,
} from '../src/lib/errors';
import { z } from 'zod';

describe('Error Classes', () => {
  describe('SunoApiError', () => {
    it('should create error with all properties', () => {
      const error = new SunoApiError(400, 'Test error', 'TEST_CODE', { detail: 'test' });

      expect(error.statusCode).toBe(400);
      expect(error.message).toBe('Test error');
      expect(error.code).toBe('TEST_CODE');
      expect(error.details).toEqual({ detail: 'test' });
      expect(error.name).toBe('SunoApiError');
    });
  });

  describe('ValidationError', () => {
    it('should create 400 validation error', () => {
      const error = new ValidationError('Invalid input');

      expect(error.statusCode).toBe(400);
      expect(error.code).toBe('VALIDATION_ERROR');
      expect(error.name).toBe('ValidationError');
    });
  });

  describe('AuthenticationError', () => {
    it('should create 401 authentication error', () => {
      const error = new AuthenticationError();

      expect(error.statusCode).toBe(401);
      expect(error.code).toBe('AUTHENTICATION_ERROR');
      expect(error.message).toContain('Authentication failed');
    });
  });

  describe('PaymentRequiredError', () => {
    it('should create 402 payment error', () => {
      const error = new PaymentRequiredError();

      expect(error.statusCode).toBe(402);
      expect(error.code).toBe('PAYMENT_REQUIRED');
      expect(error.message).toContain('insufficient credits');
    });
  });

  describe('RateLimitError', () => {
    it('should create 429 rate limit error', () => {
      const error = new RateLimitError('Too many requests', 60);

      expect(error.statusCode).toBe(429);
      expect(error.code).toBe('RATE_LIMIT_EXCEEDED');
      expect(error.details).toEqual({ retryAfter: 60 });
    });
  });

  describe('InternalError', () => {
    it('should create 500 internal error', () => {
      const error = new InternalError();

      expect(error.statusCode).toBe(500);
      expect(error.code).toBe('INTERNAL_ERROR');
    });
  });

  describe('CaptchaError', () => {
    it('should create CAPTCHA error', () => {
      const error = new CaptchaError('CAPTCHA failed', { reason: 'timeout' });

      expect(error.statusCode).toBe(500);
      expect(error.code).toBe('CAPTCHA_ERROR');
      expect(error.details).toEqual({ reason: 'timeout' });
    });
  });
});

describe('formatErrorResponse', () => {
  it('should format SunoApiError', () => {
    const error = new ValidationError('Invalid data');
    const response = formatErrorResponse(error);

    expect(response.error.statusCode).toBe(400);
    expect(response.error.code).toBe('VALIDATION_ERROR');
    expect(response.error.message).toBe('Invalid data');
  });

  it('should format Zod validation errors', () => {
    const schema = z.object({
      name: z.string().min(1),
      age: z.number().min(0),
    });

    try {
      schema.parse({ name: '', age: -5 });
    } catch (error) {
      const response = formatErrorResponse(error);

      expect(response.error.statusCode).toBe(400);
      expect(response.error.code).toBe('VALIDATION_ERROR');
      expect(response.error.message).toBe('Validation failed');
      expect(Array.isArray(response.error.details)).toBe(true);
    }
  });

  it('should format Axios 402 errors', () => {
    const axiosError = {
      response: {
        status: 402,
        data: {
          detail: 'Insufficient credits',
        },
      },
    };

    const response = formatErrorResponse(axiosError);

    expect(response.error.statusCode).toBe(402);
    expect(response.error.code).toBe('PAYMENT_REQUIRED');
    expect(response.error.message).toContain('Insufficient credits');
  });

  it('should format Axios 401 errors', () => {
    const axiosError = {
      response: {
        status: 401,
        data: {},
      },
    };

    const response = formatErrorResponse(axiosError);

    expect(response.error.statusCode).toBe(401);
    expect(response.error.code).toBe('AUTHENTICATION_ERROR');
    expect(response.error.message).toContain('Authentication failed');
  });

  it('should format generic Error instances', () => {
    const error = new Error('Something went wrong');
    const response = formatErrorResponse(error);

    expect(response.error.statusCode).toBe(500);
    expect(response.error.code).toBe('INTERNAL_ERROR');
    expect(response.error.message).toBe('Something went wrong');
  });

  it('should handle unknown error types', () => {
    const error = 'string error';
    const response = formatErrorResponse(error);

    expect(response.error.statusCode).toBe(500);
    expect(response.error.code).toBe('UNKNOWN_ERROR');
    expect(response.error.message).toContain('unknown error');
  });
});
