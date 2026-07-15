-- ============================================================
-- PART 2: STORED PROCEDURES
-- Run this in SSMS against UserManagementDB, after 02_schema_extensions.sql
-- ============================================================
USE UserManagementDB;
GO

-- ============================================================
-- sp_CreateUser
-- Accepts a username and email, creates a new user with status
-- defaulted to 'Pending', and returns the new user's ID.
-- ============================================================

-- DROP IF EXISTS lets us re-run this script safely while developing/testing,
-- without SQL Server complaining "there's already a procedure with this name".
DROP PROCEDURE IF EXISTS sp_CreateUser;
GO

CREATE PROCEDURE sp_CreateUser
    @Username    NVARCHAR(50),
    @Email       NVARCHAR(150),
    @NewUserId   BIGINT OUTPUT   -- OUTPUT means: after this procedure runs, the caller
                                  -- can read this variable to get the generated ID back.
AS
BEGIN
    -- Stops SQL Server from sending back "(1 row affected)" style messages,
    -- which are just noise when a procedure is called from application code.
    SET NOCOUNT ON;

    -- ---- VALIDATION: reject duplicate username or email BEFORE inserting ----
    -- We check both in one query. LOWER() on the email comparison protects us
    -- even if the server's collation happens to be case-sensitive.
    IF EXISTS (
        SELECT 1 FROM users
        WHERE username = @Username
           OR LOWER(email) = LOWER(@Email)
    )
    BEGIN
        -- THROW raises a custom error and immediately stops the procedure.
        -- 50001 is an arbitrary custom error number (SQL Server reserves
        -- numbers below 50000 for its own built-in errors).
        THROW 50001, 'Username or email already exists.', 1;
    END

    -- ---- INSERT the new user ----
    -- full_name is set equal to username here: your users table still requires
    -- full_name (NOT NULL) from the original CRUD screens, so this keeps both
    -- the old web form and this new procedure working against the same table.
    INSERT INTO users (full_name, username, email, status)
    VALUES (@Username, @Username, @Email, 'Pending');

    -- SCOPE_IDENTITY() returns the auto-generated "id" from the INSERT we just
    -- ran, in THIS session/scope only (safer than @@IDENTITY, which can pick up
    -- an ID from an unrelated trigger firing on another table).
    SET @NewUserId = SCOPE_IDENTITY();
END
GO


-- ============================================================
-- sp_GetAllUsers
-- Returns a paginated list of users, optionally filtered by status.
-- ============================================================

DROP PROCEDURE IF EXISTS sp_GetAllUsers;
GO

CREATE PROCEDURE sp_GetAllUsers
    @Limit         INT,
    @Offset        INT,
    @StatusFilter  NVARCHAR(20) = NULL   -- "= NULL" makes this an OPTIONAL parameter;
                                          -- callers can omit it entirely.
AS
BEGIN
    SET NOCOUNT ON;

    SELECT id, full_name, username, email, phone_number, address, status, created_at, updated_at
    FROM users
    -- If @StatusFilter wasn't supplied (NULL), this condition is always true,
    -- so ALL rows pass through. If it WAS supplied, only matching rows do.
    WHERE (@StatusFilter IS NULL OR status = @StatusFilter)
    ORDER BY id
    -- This is SQL Server's standard pagination syntax: skip @Offset rows,
    -- then take the next @Limit rows. ORDER BY is REQUIRED for OFFSET/FETCH to work.
    OFFSET @Offset ROWS
    FETCH NEXT @Limit ROWS ONLY;
END
GO


-- ============================================================
-- sp_GetUserById
-- Returns one user's full details, or raises a custom error if
-- the ID doesn't exist.
-- ============================================================

DROP PROCEDURE IF EXISTS sp_GetUserById;
GO

CREATE PROCEDURE sp_GetUserById
    @UserId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM users WHERE id = @UserId)
    BEGIN
        THROW 50002, 'User Not Found.', 1;
    END

    SELECT id, full_name, username, email, phone_number, address, status, created_at, updated_at
    FROM users
    WHERE id = @UserId;
END
GO


-- ============================================================
-- sp_UpdateUser
-- Updates username/email/status for an existing user.
-- Blocks changing the email to one already used by ANOTHER user.
-- ============================================================

DROP PROCEDURE IF EXISTS sp_UpdateUser;
GO

CREATE PROCEDURE sp_UpdateUser
    @UserId    BIGINT,
    @Username  NVARCHAR(50),
    @Email     NVARCHAR(150),
    @Status    NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM users WHERE id = @UserId)
    BEGIN
        THROW 50002, 'User Not Found.', 1;
    END

    -- ---- VALIDATION: is this email already used by a DIFFERENT user? ----
    -- "id <> @UserId" is the key part -- without it, a user updating their OWN
    -- record (keeping the same email) would incorrectly be blocked, since
    -- their own current email would match the EXISTS check.
    IF EXISTS (
        SELECT 1 FROM users
        WHERE LOWER(email) = LOWER(@Email)
          AND id <> @UserId
    )
    BEGIN
        THROW 50003, 'Email is already taken by another user.', 1;
    END

    UPDATE users
    SET username   = @Username,
        email      = LOWER(@Email),  -- lowercased here for consistency with new inserts
        status     = @Status,
        updated_at = GETDATE()       -- stamps "now" every time this procedure runs
    WHERE id = @UserId;
END
GO


-- ============================================================
-- sp_DeleteUser
-- Deletes a user, but blocks the deletion if their status is
-- 'Active' -- they must be suspended first.
-- ============================================================

DROP PROCEDURE IF EXISTS sp_DeleteUser;
GO

CREATE PROCEDURE sp_DeleteUser
    @UserId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentStatus NVARCHAR(20);

    IF NOT EXISTS (SELECT 1 FROM users WHERE id = @UserId)
    BEGIN
        THROW 50002, 'User Not Found.', 1;
    END

    -- Read the current status into a variable so we can check it below.
    SELECT @CurrentStatus = status FROM users WHERE id = @UserId;

    IF @CurrentStatus = 'Active'
    BEGIN
        THROW 50004, 'Cannot delete an Active user. Suspend the user before deleting.', 1;
    END

    -- This DELETE is what fires trg_AfterUserDelete (created in Part 3),
    -- which writes the audit log row automatically.
    DELETE FROM users WHERE id = @UserId;
END
GO
