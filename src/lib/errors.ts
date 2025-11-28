import { NextResponse } from 'next/server';
import { z } from 'zod';
import { corsHeaders } from './utils';
import { logger } from './logger';

/**
 * Base error class for Suno API errors
 */
export class SunoApiError extends Error {
  constructor(
    public statusCode: number,
    message: string,
    public code?: string,
    public details?: unknown
  ) {
    super(message);
    this.name = 'SunoApiError';
  }
}

/**
 * Validation error (400)
 */
export class ValidationError extends SunoApiError {
  constructor(message: string, details?: unknown) {
    super(400, message, 'VALIDATION_ERROR', details);
    this.name = 'ValidationError';
  }
}

/**
 * Authentication error (401)
 */
export class AuthenticationError extends SunoApiError {
  constructor(message: string = 'Authentication failed') {
    super(401, message, 'AUTHENTICATION_ERROR');
    this.name = 'AuthenticationError';
  }
}

/**
 * Payment required error (402)
 */
export class PaymentRequiredError extends SunoApiError {
  constructor(message: string = 'Payment required - insufficient credits') {
    super(402, message, 'PAYMENT_REQUIRED');
    this.name = 'PaymentRequiredError';
  }
}

/**
 * Rate limit exceeded error (429)
 */
export class RateLimitError extends SunoApiError {
  constructor(message: string = 'Rate limit exceeded', retryAfter?: number) {
    super(429, message, 'RATE_LIMIT_EXCEEDED', { retryAfter });
    this.name = 'RateLimitError';
  }
}

/**
 * Internal server error (500)
 */
export class InternalError extends SunoApiError {
  constructor(message: string = 'Internal server error', details?: unknown) {
    super(500, message, 'INTERNAL_ERROR', details);
    this.name = 'InternalError';
  }
}

/**
 * CAPTCHA solving error
 */
export class CaptchaError extends SunoApiError {
  constructor(message: string = 'CAPTCHA solving failed', details?: unknown) {
    super(500, message, 'CAPTCHA_ERROR', details);
    this.name = 'CaptchaError';
  }
}

/**
 * Error response format
 */
interface ErrorResponse {
  error: {
    message: string;
    code?: string;
    details?: unknown;
    statusCode: number;
  };
}

/**
 * Formats an error into a standardized response
 */
export function formatErrorResponse(error: unknown): ErrorResponse {
  // Handle known SunoApiError instances
  if (error instanceof SunoApiError) {
    return {
      error: {
        message: error.message,
        code: error.code,
        details: error.details,
        statusCode: error.statusCode,
      },
    };
  }

  // Handle Zod validation errors
  if (error instanceof z.ZodError) {
    const formattedErrors = error.errors.map(err => ({
      path: err.path.join('.'),
      message: err.message,
    }));

    return {
      error: {
        message: 'Validation failed',
        code: 'VALIDATION_ERROR',
        details: formattedErrors,
        statusCode: 400,
      },
    };
  }

  // Handle Axios errors
  if (error && typeof error === 'object' && 'response' in error) {
    const axiosError = error as any;

    // Check for 402 Payment Required
    if (axiosError.response?.status === 402) {
      return {
        error: {
          message: axiosError.response.data?.detail || 'Payment required - insufficient credits',
          code: 'PAYMENT_REQUIRED',
          statusCode: 402,
        },
      };
    }

    // Check for 401 Unauthorized
    if (axiosError.response?.status === 401) {
      return {
        error: {
          message: 'Authentication failed - please check your SUNO_COOKIE',
          code: 'AUTHENTICATION_ERROR',
          statusCode: 401,
        },
      };
    }

    // Other Axios errors
    return {
      error: {
        message: axiosError.response?.data?.detail || axiosError.message || 'Request failed',
        code: 'REQUEST_FAILED',
        details: axiosError.response?.data,
        statusCode: axiosError.response?.status || 500,
      },
    };
  }

  // Handle generic errors
  if (error instanceof Error) {
    return {
      error: {
        message: error.message,
        code: 'INTERNAL_ERROR',
        statusCode: 500,
      },
    };
  }

  // Unknown error type
  return {
    error: {
      message: 'An unknown error occurred',
      code: 'UNKNOWN_ERROR',
      statusCode: 500,
    },
  };
}

/**
 * Creates a NextResponse with the error
 */
export function createErrorResponse(error: unknown): NextResponse {
  const errorResponse = formatErrorResponse(error);

  // Log the error (sanitized)
  logger.error({
    code: errorResponse.error.code,
    message: errorResponse.error.message,
    statusCode: errorResponse.error.statusCode,
    // Don't log details in production to avoid leaking sensitive info
    ...(process.env.NODE_ENV === 'development' && { details: errorResponse.error.details }),
  }, 'API Error');

  return new NextResponse(JSON.stringify(errorResponse), {
    status: errorResponse.error.statusCode,
    headers: {
      'Content-Type': 'application/json',
      ...corsHeaders,
    },
  });
}

/**
 * Higher-order function to wrap API route handlers with error handling
 */
export function withErrorHandling<T extends (...args: any[]) => Promise<NextResponse>>(
  handler: T
): T {
  return (async (...args: any[]) => {
    try {
      return await handler(...args);
    } catch (error) {
      return createErrorResponse(error);
    }
  }) as T;
}
