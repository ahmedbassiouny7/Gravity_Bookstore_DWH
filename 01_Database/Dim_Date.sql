USE GravityBookstore_DWH;
GO

/*
Brief : This script creates and populates the Dim_Date table with dates,
        attributes (day, month, quarter, year, etc.), and common holidays.
        Customize @StartDate and @EndDate to set the range.
Author: Mohamed Roshdy (edited)
*/

--TRUNCATE TABLE Dim_Date;

DECLARE @tmpDOW TABLE (DOW INT, Cntr INT);
INSERT INTO @tmpDOW(DOW, Cntr) VALUES (1,0),(2,0),(3,0),(4,0),(5,0),(6,0),(7,0);

DECLARE @StartDate  DATETIME = '1980-01-01';
DECLARE @EndDate    DATETIME = '2030-01-01';
DECLARE @Date       DATETIME = @StartDate;
DECLARE @CurrentMonth INT    = MONTH(@StartDate);

WHILE @Date < @EndDate
BEGIN
    IF MONTH(@Date) <> @CurrentMonth
    BEGIN
        SET @CurrentMonth = MONTH(@Date);
        UPDATE @tmpDOW SET Cntr = 0;
    END

    UPDATE @tmpDOW SET Cntr = Cntr + 1 WHERE DOW = DATEPART(WEEKDAY, @Date);

    INSERT INTO Dim_Date (
        date_SK,
        full_date,
        day,
        day_of_week,
        day_name,
        month,
        month_name,
        quarter,
        year,
        is_weekend
    )
    VALUES (
        CONVERT(INT, FORMAT(@Date, 'yyyyMMdd')),
        CAST(@Date AS DATE),
        DAY(@Date),
        DATEPART(WEEKDAY, @Date),
        DATENAME(WEEKDAY, @Date),
        MONTH(@Date),
        DATENAME(MONTH, @Date),
        DATEPART(QUARTER, @Date),
        YEAR(@Date),
        CASE WHEN DATEPART(WEEKDAY, @Date) IN (1,7) THEN 1 ELSE 0 END
    );

    SET @Date = DATEADD(DAY, 1, @Date);
END;

PRINT 'Dim_Date populated successfully at: ' + CONVERT(varchar, GETDATE(), 113);