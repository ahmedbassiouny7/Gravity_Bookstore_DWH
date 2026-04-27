USE GravityBookstore_DWH;
GO

-- =============================================
-- STEP 1: DROP FK CONSTRAINTS FROM FACTS
-- =============================================
BEGIN TRY ALTER TABLE Fact_BookSales    DROP CONSTRAINT FK_Sales_Time;   END TRY BEGIN CATCH END CATCH;
BEGIN TRY ALTER TABLE Fact_OrderHistory DROP CONSTRAINT FK_History_Time; END TRY BEGIN CATCH END CATCH;

-- =============================================
-- STEP 2: DROP AND RECREATE DIM_TIME
-- =============================================
BEGIN TRY DROP TABLE [Dim_Time]; END TRY BEGIN CATCH END CATCH;

CREATE TABLE [dbo].[Dim_Time] (
    [Time_SK]      INT         IDENTITY(1,1) NOT NULL,
    [Time]         TIME(0)     NOT NULL,
    [Hour]         CHAR(2)     NOT NULL,
    [MilitaryHour] CHAR(2)     NOT NULL,
    [Minute]       CHAR(2)     NOT NULL,
    [Second]       CHAR(2)     NOT NULL,
    [AmPm]         CHAR(2)     NOT NULL,
    [StandardTime] CHAR(11)    NULL,
    [Shift]        VARCHAR(10) NULL,
    CONSTRAINT [PK_Dim_Time] PRIMARY KEY CLUSTERED ([Time_SK] ASC)
);
GO

-- =============================================
-- STEP 3: POPULATE
-- =============================================
PRINT CONVERT(varchar, GETDATE(), 113);

DECLARE @Time DATETIME = '00:00:00';

WHILE @Time <= '23:59:59'
BEGIN
    INSERT INTO [dbo].[Dim_Time] (
        [Time], [Hour], [MilitaryHour], [Minute], [Second], [AmPm]
    )
    SELECT
        CONVERT(varchar, @Time, 108),
        CASE
            WHEN DATEPART(HOUR, @Time) = 0  THEN 12
            WHEN DATEPART(HOUR, @Time) > 12 THEN DATEPART(HOUR, @Time) - 12
            ELSE DATEPART(HOUR, @Time)
        END,
        RIGHT('0' + CAST(DATEPART(HOUR,   @Time) AS varchar), 2),
        RIGHT('0' + CAST(DATEPART(MINUTE, @Time) AS varchar), 2),
        RIGHT('0' + CAST(DATEPART(SECOND, @Time) AS varchar), 2),
        CASE WHEN DATEPART(HOUR, @Time) >= 12 THEN 'PM' ELSE 'AM' END;

    SET @Time = DATEADD(SECOND, 1, @Time);
END;

-- =============================================
-- STEP 4: FIX FORMATTING
-- =============================================
UPDATE [Dim_Time] SET [Hour]         = '0' + [Hour]         WHERE LEN([Hour])         = 1;
UPDATE [Dim_Time] SET [Minute]       = '0' + [Minute]       WHERE LEN([Minute])       = 1;
UPDATE [Dim_Time] SET [Second]       = '0' + [Second]       WHERE LEN([Second])       = 1;
UPDATE [Dim_Time] SET [MilitaryHour] = '0' + [MilitaryHour] WHERE LEN([MilitaryHour]) = 1;

-- =============================================
-- STEP 5: POPULATE STANDARDTIME
-- =============================================
UPDATE [Dim_Time]
SET [StandardTime] =
    CASE WHEN [Hour] = '00' THEN '12' ELSE [Hour] END
    + ':' + [Minute]
    + ':' + [Second]
    + ' ' + [AmPm]
WHERE [StandardTime] IS NULL;

-- =============================================
-- STEP 6: POPULATE SHIFT
-- =============================================
UPDATE [Dim_Time]
SET [Shift] =
    CASE
        WHEN [MilitaryHour] >= '06' AND [MilitaryHour] < '12' THEN 'Morning'
        WHEN [MilitaryHour] >= '12' AND [MilitaryHour] < '18' THEN 'Afternoon'
        WHEN [MilitaryHour] >= '18' AND [MilitaryHour] < '24' THEN 'Evening'
        ELSE 'Night'
    END;

-- =============================================
-- STEP 7: RECREATE FK CONSTRAINTS
-- =============================================
ALTER TABLE Fact_BookSales
    ADD CONSTRAINT FK_Sales_Time
    FOREIGN KEY (time_SK) REFERENCES Dim_Time(Time_SK);

ALTER TABLE Fact_OrderHistory
    ADD CONSTRAINT FK_History_Time
    FOREIGN KEY (status_time_SK) REFERENCES Dim_Time(Time_SK);

-- =============================================
-- STEP 8: INDEXES
-- =============================================
CREATE UNIQUE NONCLUSTERED INDEX [IDX_Dim_Time_Time]         ON [dbo].[Dim_Time] ([Time]);
CREATE NONCLUSTERED INDEX        [IDX_Dim_Time_Hour]         ON [dbo].[Dim_Time] ([Hour]);
CREATE NONCLUSTERED INDEX        [IDX_Dim_Time_MilitaryHour] ON [dbo].[Dim_Time] ([MilitaryHour]);
CREATE NONCLUSTERED INDEX        [IDX_Dim_Time_Minute]       ON [dbo].[Dim_Time] ([Minute]);
CREATE NONCLUSTERED INDEX        [IDX_Dim_Time_Second]       ON [dbo].[Dim_Time] ([Second]);
CREATE NONCLUSTERED INDEX        [IDX_Dim_Time_AmPm]         ON [dbo].[Dim_Time] ([AmPm]);
CREATE NONCLUSTERED INDEX        [IDX_Dim_Time_StandardTime] ON [dbo].[Dim_Time] ([StandardTime]);
CREATE NONCLUSTERED INDEX        [IDX_Dim_Time_Shift]        ON [dbo].[Dim_Time] ([Shift]);

PRINT 'Dim_Time completed at: ' + CONVERT(varchar, GETDATE(), 113);