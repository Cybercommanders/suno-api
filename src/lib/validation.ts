import { z } from 'zod';
import { DEFAULT_MODEL } from './SunoApi';

/**
 * Validation schemas for API requests
 * Provides type-safe input validation with detailed error messages
 */

// Common validation rules
const promptSchema = z.string()
  .min(1, 'Prompt is required')
  .max(3000, 'Prompt must be less than 3000 characters');

const modelSchema = z.string()
  .optional()
  .default(DEFAULT_MODEL);

const makeInstrumentalSchema = z.boolean()
  .optional()
  .default(false);

const waitAudioSchema = z.boolean()
  .optional()
  .default(false);

// Generate endpoint validation
export const generateSchema = z.object({
  prompt: promptSchema,
  make_instrumental: makeInstrumentalSchema,
  model: modelSchema,
  wait_audio: waitAudioSchema,
});

export type GenerateInput = z.infer<typeof generateSchema>;

// Custom generate endpoint validation
export const customGenerateSchema = z.object({
  prompt: promptSchema,
  tags: z.string()
    .min(1, 'Tags are required')
    .max(200, 'Tags must be less than 200 characters'),
  title: z.string()
    .min(1, 'Title is required')
    .max(100, 'Title must be less than 100 characters'),
  make_instrumental: makeInstrumentalSchema,
  model: modelSchema,
  wait_audio: waitAudioSchema,
  negative_tags: z.string()
    .max(200, 'Negative tags must be less than 200 characters')
    .optional(),
});

export type CustomGenerateInput = z.infer<typeof customGenerateSchema>;

// Generate lyrics endpoint validation
export const generateLyricsSchema = z.object({
  prompt: promptSchema,
});

export type GenerateLyricsInput = z.infer<typeof generateLyricsSchema>;

// Extend audio endpoint validation
export const extendAudioSchema = z.object({
  audio_id: z.string()
    .min(1, 'Audio ID is required')
    .uuid('Audio ID must be a valid UUID'),
  prompt: z.string()
    .max(3000, 'Prompt must be less than 3000 characters')
    .optional()
    .default(''),
  continue_at: z.number()
    .min(0, 'Continue at must be a positive number')
    .optional(),
  tags: z.string()
    .max(200, 'Tags must be less than 200 characters')
    .optional()
    .default(''),
  negative_tags: z.string()
    .max(200, 'Negative tags must be less than 200 characters')
    .optional()
    .default(''),
  title: z.string()
    .max(100, 'Title must be less than 100 characters')
    .optional()
    .default(''),
  model: modelSchema,
  wait_audio: waitAudioSchema,
});

export type ExtendAudioInput = z.infer<typeof extendAudioSchema>;

// Generate stems endpoint validation
export const generateStemsSchema = z.object({
  song_id: z.string()
    .min(1, 'Song ID is required')
    .uuid('Song ID must be a valid UUID'),
});

export type GenerateStemsInput = z.infer<typeof generateStemsSchema>;

// Get audio endpoint validation
export const getAudioSchema = z.object({
  ids: z.string()
    .optional()
    .refine(
      (val) => !val || val.split(',').every(id => id.trim().length > 0),
      'IDs must be comma-separated valid strings'
    ),
  page: z.string()
    .optional()
    .refine(
      (val) => !val || !isNaN(Number(val)),
      'Page must be a valid number'
    ),
});

export type GetAudioInput = z.infer<typeof getAudioSchema>;

// Get clip endpoint validation
export const getClipSchema = z.object({
  id: z.string()
    .min(1, 'Clip ID is required')
    .uuid('Clip ID must be a valid UUID'),
});

export type GetClipInput = z.infer<typeof getClipSchema>;

// Concat endpoint validation
export const concatSchema = z.object({
  clip_id: z.string()
    .min(1, 'Clip ID is required')
    .uuid('Clip ID must be a valid UUID'),
});

export type ConcatInput = z.infer<typeof concatSchema>;

// Get aligned lyrics endpoint validation
export const getAlignedLyricsSchema = z.object({
  song_id: z.string()
    .min(1, 'Song ID is required')
    .uuid('Song ID must be a valid UUID'),
});

export type GetAlignedLyricsInput = z.infer<typeof getAlignedLyricsSchema>;

// Get persona endpoint validation
export const getPersonaSchema = z.object({
  persona_id: z.string()
    .min(1, 'Persona ID is required')
    .uuid('Persona ID must be a valid UUID'),
  page: z.number()
    .int('Page must be an integer')
    .min(1, 'Page must be at least 1')
    .optional()
    .default(1),
});

export type GetPersonaInput = z.infer<typeof getPersonaSchema>;

/**
 * Helper function to validate request body
 * Returns parsed data or throws a validation error
 */
export function validateRequest<T>(
  schema: z.ZodSchema<T>,
  data: unknown
): T {
  return schema.parse(data);
}

/**
 * Helper function to safely validate request body
 * Returns { success: true, data } or { success: false, error }
 */
export function safeValidateRequest<T>(
  schema: z.ZodSchema<T>,
  data: unknown
): { success: true; data: T } | { success: false; error: z.ZodError } {
  const result = schema.safeParse(data);
  if (result.success) {
    return { success: true, data: result.data };
  }
  return { success: false, error: result.error };
}
