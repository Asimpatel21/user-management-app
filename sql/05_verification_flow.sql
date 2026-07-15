-- ============================================================
-- PART 4: VERIFICATION FLOW
-- Run this in SSMS against UserManagementDB, after 04_triggers.sql
-- Run it ONE numbered block at a time (highlight the block, press F5)
-- so you can read each result before moving to the next.
-- ============================================================
USE UserManagementDB;
GO


-- ============================================================
-- STEP 1: Create two valid users
-- Expect: both succeed, each printing a generated ID.
-- ============================================================

DECLARE @Id1 BIGINT, @Id2 BIGINT;

EXEC sp_CreateUser @Username = 'ravi_k', @Email = 'Ravi.K@Example.com', @NewUserId = @Id1 OUTPUT;
PRINT 'Created user 1 with ID: ' + CAST(@Id1 AS NVARCHAR(10));

EXEC sp_CreateUser @Username = 'sneha_r', @Email = 'Sneha.R@Example.com', @NewUserId = @Id2 OUTPUT;
PRINT 'Created user 2 with ID: ' + CAST(@Id2 AS NVARCHAR(10));

-- Check the emails were forced to lowercase by trg_BeforeUserInsert,
-- and that status defaulted to 'Pending'.
SELECT id, username, email, status FROM users WHERE id IN (@Id1, @Id2);
GO


-- ============================================================
-- STEP 2: Attempt to create a DUPLICATE email
-- Expect: THIS SHOULD FAIL with our custom error 50001.
-- We wrap it in TRY/CATCH so the script doesn't stop -- we WANT
-- to see the error printed, then keep going.
-- ============================================================

BEGIN TRY
    DECLARE @DupId BIGINT;
    -- Same email as ravi_k above, just different casing --
    -- proves the duplicate check is case-insensitive.
    EXEC sp_CreateUser @Username = 'ravi_new', @Email = 'ravi.k@example.com', @NewUserId = @DupId OUTPUT;
    PRINT 'ERROR: This should NOT have succeeded!';
END TRY
BEGIN CATCH
    PRINT 'Expected failure caught: ' + ERROR_MESSAGE();
END CATCH
GO


-- ============================================================
-- STEP 3: Read all users, filtered by status = 'Pending'
-- Expect: both users from Step 1 come back (they're both
-- still 'Pending' at this point).
-- ============================================================

EXEC sp_GetAllUsers @Limit = 10, @Offset = 0, @StatusFilter = 'Pending';
GO


-- ============================================================
-- STEP 4: Update a user's email, and verify the audit trigger
-- captured OLD vs NEW correctly.
-- ============================================================

DECLARE @RaviId BIGINT = (SELECT id FROM users WHERE username = 'ravi_k');

EXEC sp_UpdateUser
    @UserId = @RaviId,
    @Username = 'ravi_k',
    @Email = 'ravi.kumar.new@example.com',
    @Status = 'Active';

-- Confirm the user's row changed, including updated_at:
SELECT id, username, email, status, updated_at FROM users WHERE id = @RaviId;

-- Confirm trg_AfterUserUpdate logged exactly this change:
SELECT * FROM user_audit_log WHERE user_id = @RaviId AND action_type = 'UPDATE';
GO


-- ============================================================
-- STEP 5: Attempt to DELETE this user while status = 'Active'
-- Expect: THIS SHOULD FAIL with our custom error 50004.
-- ============================================================

BEGIN TRY
    DECLARE @RaviId2 BIGINT = (SELECT id FROM users WHERE username = 'ravi_k');
    EXEC sp_DeleteUser @UserId = @RaviId2;
    PRINT 'ERROR: This should NOT have succeeded -- user is Active!';
END TRY
BEGIN CATCH
    PRINT 'Expected failure caught: ' + ERROR_MESSAGE();
END CATCH
GO


-- ============================================================
-- STEP 6: Suspend the user, THEN delete them, then check the
-- audit log for the deletion record.
-- ============================================================

DECLARE @RaviId3 BIGINT = (SELECT id FROM users WHERE username = 'ravi_k');

-- Suspend first (required before delete is allowed)
EXEC sp_UpdateUser
    @UserId = @RaviId3,
    @Username = 'ravi_k',
    @Email = 'ravi.kumar.new@example.com',
    @Status = 'Suspended';

-- Now the delete should succeed
EXEC sp_DeleteUser @UserId = @RaviId3;

-- Confirm the user is really gone from the users table:
SELECT * FROM users WHERE id = @RaviId3;   -- expect: 0 rows

-- Confirm trg_AfterUserDelete logged the deletion, including username:
SELECT * FROM user_audit_log WHERE user_id = @RaviId3 AND action_type = 'DELETE';
GO


-- ============================================================
-- STEP 7: Confirm sp_GetUserById's custom "not found" error
-- Expect: THIS SHOULD FAIL with our custom error 50002.
-- (99999999 is a made-up ID that should never exist.)
-- ============================================================

BEGIN TRY
    EXEC sp_GetUserById @UserId = 99999999;
    PRINT 'ERROR: This should NOT have succeeded!';
END TRY
BEGIN CATCH
    PRINT 'Expected failure caught: ' + ERROR_MESSAGE();
END CATCH
GO


-- ============================================================
-- STEP 8: Final full picture -- everything together.
-- ============================================================

SELECT id, username, email, status, created_at, updated_at FROM users ORDER BY id;
SELECT * FROM user_audit_log ORDER BY audit_id;
GO
