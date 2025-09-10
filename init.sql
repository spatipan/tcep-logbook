-- init.sql - Database initialization script
-- This runs automatically when the PostgreSQL container starts

-- Create extensions if needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create indexes for better performance (these will be created by SQLAlchemy too, but this ensures they exist)
-- Note: The actual tables are created by SQLAlchemy in the application

-- Set timezone
SET timezone = 'Asia/Bangkok';

-- Create a function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Grant necessary permissions
GRANT ALL PRIVILEGES ON DATABASE tcep_logbook TO tcep_user;
GRANT ALL PRIVILEGES ON SCHEMA public TO tcep_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO tcep_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO tcep_user;