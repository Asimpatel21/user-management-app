-- ============================================================
-- PART 3: TRIGGERS
-- Run this in SSMS against UserManagementDB, after 03_stored_procedures.sql
-- ============================================================
USE UserManagementDB;
GO

-- ============================================================
-- trg_BeforeUserInsert
-- Forces the email to lowercase on every insert into "users",
-- no matter HOW the row got inserted (this procedure, the web
-- app's Add User form, or the bulk CSV/Excel upload).
--
-- IMPORTANT SQL SERVER NOTE:
-- SQL Server does NOT have a true "BEFORE INSERT" trigger like
-- some other databases (e.g. MySQL/PostgreSQL). Its two trigger
-- types are AFTER and INSTEAD OF. To get "before insert" behavior
-- -- changing the data BEFORE it's actually written -- we use
-- INSTEAD OF INSERT: SQL Server hands us the incoming row(s) in a
-- virtual table called "inserted", we tweak the data, and then WE
-- perform the real INSERT ourselves. That's why this trigger's
-- body ends with a manual INSERT statement instead of an UPDATE.
-- ============================================================

DROP TRIGGER IF EXISTS trg_BeforeUserInsert;
GO

CREATE TRIGGER trg_BeforeUserInsert ON users
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- "inserted" contains every row that was ABOUT to be inserted
    -- (there can be more than one row if a multi-row INSERT was used).
    -- We select from it, lowercase the email, and insert that instead.
    INSERT INTO users (full_name, email, phone_number, address, created_at, username, status, updated_at)
    SELECT
        full_name,
        LOWER(email),                  -- <-- the actual requirement, right here
        phone_number,
        address,
        ISNULL(created_at, GETDATE()), -- keep the default-date behavior
        username,
        ISNULL(status, 'Pending'),     -- keep the default-status behavior
        updated_at
    FROM inserted;
END
GO


-- ============================================================
-- trg_AfterUserUpdate
-- Fires after any UPDATE on "users". Writes ONE row into
-- user_audit_log, but ONLY if email or status actually changed
-- (editing just the phone number, for example, should NOT log).
-- ============================================================

DROP TRIGGER IF EXISTS trg_AfterUserUpdate;
GO

CREATE TRIGGER trg_AfterUserUpdate ON users
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- In an UPDATE trigger, SQL Server gives us BOTH pseudo-tables:
    --   "deleted" = the row(s) as they were BEFORE the update
    --   "inserted" = the row(s) as they are AFTER the update
    -- We join them on id to compare old vs new side by side.
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
    -- ISNULL(...,'') guards against NULL comparisons: in SQL, NULL <> NULL is
    -- neither true nor false (it's UNKNOWN), so a plain "i.email <> d.email"
    -- would silently miss a change like NULL -> 'x@example.com'.
    WHERE ISNULL(i.email, '')  <> ISNULL(d.email, '')
       OR ISNULL(i.status, '') <> ISNULL(d.status, '');
END
GO


-- ============================================================
-- trg_AfterUserDelete
-- Fires after any DELETE on "users". Always writes one row to
-- user_audit_log documenting what was removed, including the
-- username of the deleted user.
-- ============================================================

DROP TRIGGER IF EXISTS trg_AfterUserDelete;
GO

CREATE TRIGGER trg_AfterUserDelete ON users
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- In a DELETE trigger, only "deleted" exists (there's no "after" state --
    -- the row is gone). It still holds the full row exactly as it was
    -- the instant before deletion, which is exactly what we need to log.
    INSERT INTO user_audit_log (user_id, username, action_type, old_email, new_email, old_status, new_status, changed_at)
    SELECT
        d.id,
        ISNULL(d.username, d.full_name),
        'DELETE',
        d.email,
        NULL,     -- no "new" email -- the user no longer exists
        d.status,
        NULL,     -- no "new" status either
        GETDATE()
    FROM deleted d;
END
GO
