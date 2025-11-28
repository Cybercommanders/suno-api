import { describe, it, expect } from 'vitest';
import {
  generateSchema,
  customGenerateSchema,
  extendAudioSchema,
  generateLyricsSchema,
  validateRequest,
  safeValidateRequest,
} from '../src/lib/validation';

describe('Validation Schemas', () => {
  describe('generateSchema', () => {
    it('should validate valid generate request', () => {
      const validData = {
        prompt: 'A beautiful song about nature',
        make_instrumental: false,
        wait_audio: true,
      };

      const result = generateSchema.safeParse(validData);
      expect(result.success).toBe(true);
    });

    it('should reject empty prompt', () => {
      const invalidData = {
        prompt: '',
        make_instrumental: false,
      };

      const result = generateSchema.safeParse(invalidData);
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.errors[0].message).toContain('Prompt is required');
      }
    });

    it('should reject prompt that is too long', () => {
      const invalidData = {
        prompt: 'a'.repeat(3001),
        make_instrumental: false,
      };

      const result = generateSchema.safeParse(invalidData);
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.errors[0].message).toContain('less than 3000 characters');
      }
    });

    it('should apply defaults for optional fields', () => {
      const minimalData = {
        prompt: 'Test song',
      };

      const result = generateSchema.safeParse(minimalData);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.make_instrumental).toBe(false);
        expect(result.data.wait_audio).toBe(false);
        expect(result.data.model).toBe('chirp-v3-5');
      }
    });
  });

  describe('customGenerateSchema', () => {
    it('should validate valid custom generate request', () => {
      const validData = {
        prompt: '[Verse 1]\nTest lyrics here',
        tags: 'rock, energetic',
        title: 'My Test Song',
        make_instrumental: false,
      };

      const result = customGenerateSchema.safeParse(validData);
      expect(result.success).toBe(true);
    });

    it('should reject missing required fields', () => {
      const invalidData = {
        prompt: 'Test lyrics',
        // missing tags and title
      };

      const result = customGenerateSchema.safeParse(invalidData);
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.errors.length).toBeGreaterThan(0);
      }
    });

    it('should validate negative_tags as optional', () => {
      const validData = {
        prompt: 'Test lyrics',
        tags: 'rock',
        title: 'Test Song',
        negative_tags: 'slow, sad',
      };

      const result = customGenerateSchema.safeParse(validData);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.negative_tags).toBe('slow, sad');
      }
    });
  });

  describe('extendAudioSchema', () => {
    it('should validate valid extend audio request', () => {
      const validData = {
        audio_id: '550e8400-e29b-41d4-a716-446655440000',
        prompt: 'Continue the song',
        continue_at: 30,
        tags: 'rock',
      };

      const result = extendAudioSchema.safeParse(validData);
      expect(result.success).toBe(true);
    });

    it('should reject invalid UUID', () => {
      const invalidData = {
        audio_id: 'not-a-valid-uuid',
        prompt: 'Test',
      };

      const result = extendAudioSchema.safeParse(invalidData);
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.errors[0].message).toContain('valid UUID');
      }
    });

    it('should reject negative continue_at', () => {
      const invalidData = {
        audio_id: '550e8400-e29b-41d4-a716-446655440000',
        continue_at: -5,
      };

      const result = extendAudioSchema.safeParse(invalidData);
      expect(result.success).toBe(false);
    });
  });

  describe('generateLyricsSchema', () => {
    it('should validate valid lyrics request', () => {
      const validData = {
        prompt: 'A song about summer',
      };

      const result = generateLyricsSchema.safeParse(validData);
      expect(result.success).toBe(true);
    });
  });

  describe('Helper functions', () => {
    it('validateRequest should return parsed data', () => {
      const validData = {
        prompt: 'Test song',
      };

      const result = validateRequest(generateSchema, validData);
      expect(result.prompt).toBe('Test song');
    });

    it('validateRequest should throw on invalid data', () => {
      const invalidData = {
        prompt: '',
      };

      expect(() => validateRequest(generateSchema, invalidData)).toThrow();
    });

    it('safeValidateRequest should return success object', () => {
      const validData = {
        prompt: 'Test song',
      };

      const result = safeValidateRequest(generateSchema, validData);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.prompt).toBe('Test song');
      }
    });

    it('safeValidateRequest should return error object', () => {
      const invalidData = {
        prompt: '',
      };

      const result = safeValidateRequest(generateSchema, invalidData);
      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error).toBeDefined();
      }
    });
  });
});
