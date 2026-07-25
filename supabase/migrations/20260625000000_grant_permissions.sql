-- Grant schema usage
GRANT USAGE ON SCHEMA public TO authenticated, anon, service_role;

-- Grant table privileges to authenticated and anon roles
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO authenticated, anon, service_role;

-- Grant sequence privileges
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO authenticated, anon, service_role;

-- Grant routine/function privileges
GRANT ALL PRIVILEGES ON ALL ROUTINES IN SCHEMA public TO authenticated, anon, service_role;

-- Set default privileges for future creations
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO authenticated, anon, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated, anon, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO authenticated, anon, service_role;
