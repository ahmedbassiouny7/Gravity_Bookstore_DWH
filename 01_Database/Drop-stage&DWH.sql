USE master;
GO

-- Drop DWH Database
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'GravityBookstore_DWH')
BEGIN
    ALTER DATABASE GravityBookstore_DWH SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE GravityBookstore_DWH;
END

-- Drop Staging Database
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'GravityBookstore_Staging')
BEGIN
    ALTER DATABASE GravityBookstore_Staging SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE GravityBookstore_Staging;
END

PRINT 'Databases dropped successfully at: ' + CONVERT(varchar, GETDATE(), 113);