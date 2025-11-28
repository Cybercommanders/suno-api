import pino from 'pino';
import { nanoid } from 'nanoid';

/**
 * Sensitive keys that should be redacted from logs
 */
const SENSITIVE_KEYS = [
  'cookie',
  'cookies',
  'authorization',
  'token',
  'password',
  'secret',
  'api_key',
  'apikey',
  '__client',
  '__session',
  'twocaptcha_key',
  'suno_cookie',
];

/**
 * Recursively sanitizes an object by redacting sensitive fields
 */
function sanitizeObject(obj: any, depth = 0): any {
  // Prevent infinite recursion
  if (depth > 10) return '[Max Depth Reached]';

  if (obj === null || obj === undefined) {
    return obj;
  }

  if (typeof obj !== 'object') {
    return obj;
  }

  if (Array.isArray(obj)) {
    return obj.map(item => sanitizeObject(item, depth + 1));
  }

  const sanitized: any = {};
  for (const [key, value] of Object.entries(obj)) {
    const lowerKey = key.toLowerCase();

    // Check if this key contains sensitive data
    if (SENSITIVE_KEYS.some(sensitiveKey => lowerKey.includes(sensitiveKey))) {
      sanitized[key] = '[REDACTED]';
    } else if (typeof value === 'object') {
      sanitized[key] = sanitizeObject(value, depth + 1);
    } else if (typeof value === 'string' && value.length > 1000) {
      // Truncate very long strings
      sanitized[key] = value.substring(0, 1000) + '... [TRUNCATED]';
    } else {
      sanitized[key] = value;
    }
  }

  return sanitized;
}

/**
 * Create a custom Pino logger with sanitization
 */
export const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  formatters: {
    level: (label) => {
      return { level: label };
    },
    bindings: (bindings) => {
      return {
        pid: bindings.pid,
        hostname: bindings.hostname,
      };
    },
  },
  serializers: {
    // Sanitize request objects
    req: (req) => {
      return sanitizeObject({
        method: req.method,
        url: req.url,
        headers: req.headers,
        remoteAddress: req.socket?.remoteAddress,
      });
    },
    // Sanitize response objects
    res: (res) => {
      return {
        statusCode: res.statusCode,
        headers: sanitizeObject(res.getHeaders()),
      };
    },
    // Sanitize error objects
    err: pino.stdSerializers.err,
  },
  // Pretty print in development
  transport: process.env.NODE_ENV === 'development'
    ? {
        target: 'pino-pretty',
        options: {
          colorize: true,
          translateTime: 'SYS:standard',
          ignore: 'pid,hostname',
        },
      }
    : undefined,
});

/**
 * Create a child logger with request context
 */
export function createRequestLogger(requestId?: string) {
  const id = requestId || nanoid(10);
  return logger.child({ requestId: id });
}

/**
 * Sanitize data before logging
 */
export function sanitize(data: any): any {
  return sanitizeObject(data);
}

/**
 * Type-safe logging methods with automatic sanitization
 */
export const log = {
  info: (data: any, message?: string) => {
    logger.info(sanitizeObject(data), message);
  },
  error: (data: any, message?: string) => {
    logger.error(sanitizeObject(data), message);
  },
  warn: (data: any, message?: string) => {
    logger.warn(sanitizeObject(data), message);
  },
  debug: (data: any, message?: string) => {
    logger.debug(sanitizeObject(data), message);
  },
  trace: (data: any, message?: string) => {
    logger.trace(sanitizeObject(data), message);
  },
};

/**
 * Performance timing utility
 */
export class PerformanceTimer {
  private startTime: number;
  private checkpoints: Map<string, number> = new Map();

  constructor(private logger: pino.Logger, private operation: string) {
    this.startTime = Date.now();
    this.logger.debug({ operation }, 'Operation started');
  }

  checkpoint(name: string) {
    const elapsed = Date.now() - this.startTime;
    this.checkpoints.set(name, elapsed);
    this.logger.debug({ operation: this.operation, checkpoint: name, elapsed }, 'Checkpoint');
  }

  end(additionalData?: any) {
    const elapsed = Date.now() - this.startTime;
    this.logger.info(
      sanitizeObject({
        operation: this.operation,
        duration: elapsed,
        checkpoints: Object.fromEntries(this.checkpoints),
        ...additionalData,
      }),
      'Operation completed'
    );
    return elapsed;
  }

  endWithError(error: any) {
    const elapsed = Date.now() - this.startTime;
    this.logger.error(
      sanitizeObject({
        operation: this.operation,
        duration: elapsed,
        error: error instanceof Error ? error.message : String(error),
      }),
      'Operation failed'
    );
    return elapsed;
  }
}

/**
 * Create a performance timer
 */
export function startTimer(operation: string, requestId?: string) {
  const childLogger = requestId ? logger.child({ requestId }) : logger;
  return new PerformanceTimer(childLogger, operation);
}

export default logger;
