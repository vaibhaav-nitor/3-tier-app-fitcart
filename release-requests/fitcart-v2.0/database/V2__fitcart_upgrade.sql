-- FitCart v2.0 database migration.
-- This migration is intentionally additive so rollback can restore from backup
-- without requiring destructive schema changes during the demo.

ALTER TABLE gym_record
  ADD COLUMN IF NOT EXISTS photo_url VARCHAR(1024),
  ADD COLUMN IF NOT EXISTS fitness_level VARCHAR(32),
  ADD COLUMN IF NOT EXISTS target_calories INTEGER,
  ADD COLUMN IF NOT EXISTS workout_goal VARCHAR(255),
  ADD COLUMN IF NOT EXISTS audit_created_by VARCHAR(128),
  ADD COLUMN IF NOT EXISTS audit_updated_by VARCHAR(128),
  ADD COLUMN IF NOT EXISTS notification_enabled BOOLEAN DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_gym_record_fitness_level
  ON gym_record (fitness_level);

CREATE INDEX IF NOT EXISTS idx_gym_record_notification_enabled
  ON gym_record (notification_enabled);
