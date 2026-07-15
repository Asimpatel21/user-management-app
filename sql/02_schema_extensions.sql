-- ============================================================
-- PART 1: SCHEMA CHANGES
-- Run this in SSMS against UserManagementDB, after sql/setup.sql
-- ============================================================
USE UserManagementDB;
GO

-- ------------------------------------------------------------
-- 1a. Add the 3 new columns the stored procedures need.
-- We use "IF NOT EXISTS" checks so this script is safe to re-run.
-- ------------------------------------------------------------

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('users') AND name = 'username')
BEGIN
    -- NULL is allowed here (not NOT NULL) because your existing rows (John Doe, Jane Smith)
    -- were created before "username" existed, so they don't have one yet.
    -- A UNIQUE constraint in SQL Server allows multiple NULLs, so this is still safe --
    -- every NEW user created via sp_CreateUser will always get a real username.
    ALTER TABLE users ADD username NVARCHAR(50) NULL;
    ALTER TABLE users ADD CONSTRAINT UQ_users_username UNIQUE (username);
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('users') AND name = 'status')
BEGIN
    -- Every user needs a status. Existing rows get 'Pending' too, via the DEFAULT.
    ALTER TABLE users ADD status NVARCHAR(20) NOT NULL DEFAULT 'Pending';
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('users') AND name = 'updated_at')
BEGIN
    -- NULL until the first UPDATE happens -- a NULL here honestly means "never edited".
    ALTER TABLE users ADD updated_at DATETIME2 NULL;
END
GO

-- ------------------------------------------------------------
-- 1b. The audit log table.
-- One row is written here every time a user is UPDATED or DELETED
-- (never for INSERT -- there's nothing to "compare against" on a brand new row).
-- ------------------------------------------------------------

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'user_audit_log')
BEGIN
    CREATE TABLE user_audit_log (
        audit_id      BIGINT IDENTITY(1,1) PRIMARY KEY,
        user_id       BIGINT        NOT NULL,          -- which user this event happened to
        username      NVARCHAR(50)  NULL,               -- username at the time of the event
        action_type   NVARCHAR(10)  NOT NULL,           -- 'UPDATE' or 'DELETE'
        old_email     NVARCHAR(150) NULL,
        new_email     NVARCHAR(150) NULL,               -- NULL for DELETE (there's no "new" state)
        old_status    NVARCHAR(20)  NULL,
        new_status    NVARCHAR(20)  NULL,               -- NULL for DELETE
        changed_at    DATETIME2     NOT NULL DEFAULT GETDATE()
    );
END
GO

SELECT * FROM users;
SELECT * FROM user_audit_log;
