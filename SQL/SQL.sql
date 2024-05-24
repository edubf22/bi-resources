-- Alter column data types
ALTER TABLE [table]
ADD [Column1] nvarchar(255),
    [Column2] nvarchar(50),
    [Column3] nvarchar(100);

-- Create a Stored Procedure
CREATE PROCEDURE dbo.TruncateTable
AS
BEGIN
    DELETE FROM [fact Sell-Through];
END;

-- Drop Table or View
DROP TABLE [dbo].[tablename];
DROP VIEW [dbo].[viewname];

-- Date dimension
CREATE VIEW [dbo].[dim_date_vw]
AS
-- Create the Numbers CTE
WITH 
E1(N) AS (
    SELECT N FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) t(N)
),
E2(N) AS (
    SELECT a.N FROM E1 a, E1 b -- 100 values
),
E4(N) AS (
    SELECT a.N FROM E2 a, E2 b -- 10,000 values
),
Numbers AS (
    SELECT TOP (DATEDIFF(dd, '2009-01-01', '2049-12-31') + 1)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N
    FROM E4, E2
),
DateSequence AS (
    SELECT 
        DATEADD(DAY, N - 1, '2009-01-01') AS Calendar_Date -- Change the period in first parameter
    FROM Numbers
)

-- Select date-related attributes
SELECT
    CAST(FORMAT(Calendar_Date, 'yyyyMMdd') AS INT) AS [DateKEY],
    CAST(Calendar_Date AS DATE) AS [Date],
    CAST(DATEPART(YEAR, Calendar_Date) AS INT) AS [Year],
    CAST(DATEPART(QUARTER, Calendar_Date) AS INT) AS [QuarterNumber],
    CONCAT('Q', CAST(DATEPART(QUARTER, Calendar_Date) AS INT)) AS [QuarterName],
    CAST(DATEPART(MONTH, Calendar_Date) AS INT) AS [MonthNumber],
    CAST(DATENAME(MONTH, Calendar_Date) AS CHAR(10)) AS [MonthName],
    CAST(DATENAME(MONTH, Calendar_Date) AS CHAR(3)) AS [MonthNameAbbr],
    CAST(DATEPART(DAY, Calendar_Date) AS INT) AS [DayOfMonth],
    CAST(DATEPART(DW, Calendar_Date) AS INT) AS [DayOfWeek],
    CAST(DATENAME(WEEKDAY, Calendar_Date) AS CHAR(10)) AS [DayName],
    CAST(DATENAME(WEEKDAY, Calendar_Date) AS CHAR(3)) AS [DayNameAbbr]
FROM DateSequence;