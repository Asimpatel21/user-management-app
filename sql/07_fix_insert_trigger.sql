-- ============================================================
-- PART 5: FIX -- trg_BeforeUserInsert was breaking Hibernate's
-- ability to retrieve the new user's generated ID.
-- Run this in SSMS against UserManagementDB.
-- ============================================================
USE UserManagementDB;
GO

-- ------------------------------------------------------------
-- THE PROBLEM:
-- INSTEAD OF INSERT triggers REPLACE the real INSERT statement
-- with their own. SQL Server treats a trigger as a separate
-- "scope," so SCOPE_IDENTITY() -- which Hibernate/JDBC use to
-- read back the new auto-generated ID -- returns NULL from the
-- app's point of view, even though a row really was inserted.
-- That NULL is exactly what caused "null identifier" in Hibernate.
--
-- THE FIX:
-- Switch to a plain AFTER INSERT trigger. This lets the REAL
-- insert happen first (so SCOPE_IDENTITY() works normally for
-- Hibernate), then corrects the email to lowercase with a
-- follow-up UPDATE, only when actually needed.
-- ------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_BeforeUserInsert;
GO

CREATE TRIGGER trg_BeforeUserInsert ON users
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Only touch rows where the email actually has uppercase letters --
    -- this keeps the trigger a no-op (no extra write, no side effects)
    -- for the common case where the email was already lowercase.
    UPDATE u
    SET u.email = LOWER(u.email)
    FROM users u
    JOIN inserted i ON u.id = i.id
    WHERE u.email <> LOWER(u.email);
END
GO


-- ------------------------------------------------------------
-- SIDE EFFECT TO HANDLE:
-- This UPDATE (when it fires) will itself trigger trg_AfterUserUpdate,
-- since an UPDATE is an UPDATE regardless of what caused it. Without
-- a fix, that would create a FALSE "email changed" audit log entry
-- every time a user is created with a mixed-case email -- even though
-- no real business change happened, just a case correction.
--
-- THE FIX: make trg_AfterUserUpdate compare emails CASE-INSENSITIVELY.
-- A true email change (different value) still logs correctly.
-- A pure case correction (same value, different casing) is now
-- correctly ignored.
-- ------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_AfterUserUpdate;
GO

CREATE TRIGGER trg_AfterUserUpdate ON users
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO user_audit_log (user_id, username, action_type, old_email, new_email, old_status, new_status, changed_at)
    SELECT
        i.id,
        ISNULL(i.username, i.full_name),
        'UPDATE',
        d.email,
        i.email,
        d.status,
        i.status,
        GETDATE()
    FROM inserted i
    JOIN deleted d ON i.id = d.id
    WHERE LOWER(ISNULL(i.email, ''))  <> LOWER(ISNULL(d.email, ''))   -- <-- now case-insensitive
       OR ISNULL(i.status, '') <> ISNULL(d.status, '');
END
GO


-- ------------------------------------------------------------
-- VERIFY THE FIX
-- ------------------------------------------------------------

SELECT name, parent_class_desc FROM sys.triggers WHERE name LIKE 'trg_%';
