-- ============================================
-- Run this script in SSMS (SQL Server Management Studio)
-- ============================================

-- 1. Create the database (skip if it already exists)
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'UserManagementDB')
BEGIN
    CREATE DATABASE UserManagementDB;
END
GO

USE UserManagementDB;
GO

-- 2. Create the users table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'users')
BEGIN
    CREATE TABLE users (
        id            BIGINT IDENTITY(1,1) PRIMARY KEY,   -- auto-incrementing ID
        full_name     NVARCHAR(100) NOT NULL,
        email         NVARCHAR(150) NOT NULL UNIQUE,
        phone_number  NVARCHAR(20)  NULL,
        address       NVARCHAR(255) NULL,
        created_at    DATETIME2 DEFAULT GETDATE()
    );
END
GO

-- 3. (Optional) Insert a couple of sample rows so you can see data immediately
INSERT INTO users (full_name, email, phone_number, address)
VALUES
    ('John Doe', 'john.doe@example.com', '9876543210', 'Pune, India'),
    ('Jane Smith', 'jane.smith@example.com', '9123456780', 'Mumbai, India');
GO

-- 4. Verify
SELECT * FROM users;
GO

-- ============================================
-- 5. LOGIN / SIGNUP TABLE
-- This is a SEPARATE table from "users" above.
-- "users" = the people being managed by the app (the CRUD data).
-- "accounts" = the login credentials of whoever is USING the app.
-- ============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'accounts')
BEGIN
    CREATE TABLE accounts (
        id            BIGINT IDENTITY(1,1) PRIMARY KEY,
        username      NVARCHAR(50)  NOT NULL UNIQUE,
        email         NVARCHAR(150) NOT NULL UNIQUE,
        password      NVARCHAR(255) NOT NULL,   -- stores a HASHED password, never plain text
        created_at    DATETIME2 DEFAULT GETDATE()
    );
END
GO

SELECT * FROM accounts;
