-- Clear existing connection to avoid 'database is in use' errors if possible
-- (Note: some commands cannot be run inside a transaction or while connected to the target db)

-- Create user if not exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'ycsb') THEN
        CREATE USER ycsb WITH PASSWORD 'ycsb';
    END IF;
END
$$;

-- Create database if not exists (shorthand via shell usually preferred but here we use a block)
-- However, \c fails if database doesn't exist.
-- The docker_entrypoint.sh usually handles initial DB creation via env vars if it's the first run.
-- To be safe, we ensure privileges.

GRANT ALL PRIVILEGES ON DATABASE ycsb TO ycsb;

\c ycsb

-- Ensure the table is clean for every run
DROP TABLE IF EXISTS usertable CASCADE;

CREATE TABLE usertable (
    YCSB_KEY VARCHAR(255) PRIMARY KEY,
    FIELD0 TEXT, FIELD1 TEXT, FIELD2 TEXT, FIELD3 TEXT,
    FIELD4 TEXT, FIELD5 TEXT, FIELD6 TEXT, FIELD7 TEXT,
    FIELD8 TEXT, FIELD9 TEXT
);

ALTER TABLE usertable OWNER TO ycsb;
