/* Notes: 
    - This script contains a collection of SQL commands that I've found useful in my work.
    - Make sure to include the appropriate database, schema and table names when reusing the scripts.
    - Ensure the correct data types are used.
    - When possible, create CTEs to avoid calculating the same values multiple times.
    - The script is organized by the following sections:
        - Create a Table
        - Alter column data types
        - Create a Stored Procedure
        - Drop Table or View
        - Date dimension
        - Alter a view (in this case, the date dimension view defined above)
*/

-- Alter column data types
ALTER TABLE [table]
ADD [Column1] nvarchar(255),
    [Column2] nvarchar(50),
    [Column3] nvarchar(100);

-- Create a Stored Procedure
CREATE PROCEDURE dbo.TruncateTable
AS
BEGIN
    DELETE FROM [tablename];
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

-- Alter a view (in this case, the date view above)
ALTER VIEW [dbo].[dim_date_vw]
AS
/* view to create a date table based on the first and last date keys of the fact table */
WITH E1(N) AS (
    SELECT N FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) t(N)
), E2(N) AS (
    SELECT a.N FROM E1 a, E1 b -- 100 values
), E4(N) AS (
    SELECT a.N FROM E2 a, E2 b -- 10,000 values
), cteDateRangeKeys AS (
	SELECT 'start' = CAST( MIN( [DateKEY] ) AS CHAR(8) )
	,'end' = CAST( MAX( [DateKEY] ) AS CHAR(8) )
	FROM [dbo].[fact tablename] /* replace with actual fact table */
), cteDateRange AS (
	SELECT 'start' = DATEFROMPARTS( LEFT( [start], 4 ), SUBSTRING( [start], 5, 2 ), RIGHT( [start], 2 ) )
	, 'end' = DATEFROMPARTS( LEFT( [end], 4 ), SUBSTRING( [end], 5, 2 ), RIGHT( [end],2 ) )
	FROM cteDateRangeKeys
), cteDates AS (
	SELECT
        'Date' = CAST([Calendar_Date] AS DATE)
        ,'Year' = CAST(DATEPART(YEAR, [Calendar_Date]) AS INT)
        ,'Quarter Number' = CAST(DATEPART(QUARTER, [Calendar_Date]) AS INT)
        ,'Quarter Name' = CONCAT('Q', CAST(DATEPART(QUARTER, [Calendar_Date]) AS INT))
        ,'Month Number' = CAST(DATEPART(MONTH, [Calendar_Date]) AS INT)
        ,'Month Name' = CAST(DATENAME(MONTH, [Calendar_Date]) AS CHAR(10)) 
        ,'Month Name Abbr' = CAST(DATENAME(MONTH, [Calendar_Date]) AS CHAR(3))
        ,'Day of Month' = CAST(DATEPART(DAY, [Calendar_Date]) AS INT) 
        ,'Day of Week' = CAST(DATEPART(DW, [Calendar_Date]) AS INT) 
        ,'Day Name' = CAST(DATENAME(WEEKDAY, [Calendar_Date]) AS CHAR(10))
        ,'Day Name Abbr' = CAST(DATENAME(WEEKDAY, [Calendar_Date]) AS CHAR(3))
        ,'Fiscal Year' = CAST(DATEPART(YEAR, DATEADD(MONTH, 3, [Calendar_Date])) AS INT)
        ,'Fiscal Quarter' = CAST((DATEPART(QUARTER, DATEADD(MONTH, 3, [Calendar_Date])) - 1) % 4 + 1 AS INT)
        ,'Fiscal Month' = CAST((DATEPART(MONTH, DATEADD(MONTH, 3, [Calendar_Date])) - 1) % 12 + 1 AS INT)
        ,'YearMonth' = CONCAT(CAST(DATENAME(MONTH, [Calendar_Date]) AS CHAR(3)), ' ', CAST(DATEPART(YEAR, [Calendar_Date]) AS CHAR(4)))
	FROM (
		SELECT 'Calendar_Date' = CAST( DATEADD(DAY, -1 + ROW_NUMBER() OVER ( ORDER BY (SELECT 1) ), dr.[start] ) AS DATE )
		FROM E4, E1 /* creates a sequence of 1 - 100k */
		CROSS JOIN cteDateRange dr 
	) dteList
	CROSS JOIN cteDateRange dr
	WHERE dteList.[Calendar_Date] BETWEEN dr.[start] AND dr.[end] /* narrow it down to the fact table date range */

) 

SELECT [DateKEY] = CAST( YEAR( [Date] ) * 10000 + MONTH( [Date] ) * 100 + DAY( [Date] ) AS INT )
, [Date]
, [Year]
, [Quarter Number]
, [Quarter Name]
, [Month Number]
, [Month Name]
, [Month Name Abbr]
, [Day of Month]
, [Day of Week]
, [Day Name]
, [Day Name Abbr]
, [Fiscal Year]
, [Fiscal Quarter]
, [Fiscal Month]
, [YearMonth]
, 'Fiscal Year Name' = CONCAT('FY ', CAST([Fiscal Year] AS CHAR(4)))
, 'Fiscal Quarter Name' = CONCAT('Q', CAST([Fiscal Quarter] AS CHAR(1)))
FROM cteDates
;
GO

-- Query lakehouse in the same Fabric workspace
SELECT 
    Column1
    , Column2
    , Column3
FROM <lakehousename>.<schemaname>.<tablename>;

-- Append two tables in the same Fabric workspace
SELECT
    Column1
    ,Column2
    ,Column3 AS [Column Name]
    ,DateKEY
FROM <lakehousename>.<schemaname>.<tablename> /*this could be a table with current data*/
WHERE Column3 <> 'DO NOT USE' /* filter out unwanted values, don't use alias*/

UNION ALL

SELECT
    Column1
    ,Column2
    ,Column3 AS [Column Name]
    ,DateKEY
FROM <lakehousename>.<schemaname>.<tablename> /*this could be a table with historical data*/
WHERE Column3 <> 'DO NOT USE' 
AND DateKEY NOT IN (20240501, 20240401, 20240301, 20240201) /* filter out multiple dates by using a NOT IN clause)*/

-- Create start of month key column
UPDATE YourTableName
SET StartOfMonthKey = CONCAT(SUBSTRING(DateKey, 1, 6), '01'); -- Not preferred since this creates a string
SET StartOfMonthKey = DATEFROMPARTS([Year], [Month Number], 1 -- Use this when month number and year are available


-- Calculate average number of streams since release date
SELECT 
    TrackName
    ,ArtistName
    ,ReleaseDate /* Date based on release year, month and day fields */
    ,Streams
    ,DATEDIFF(day, ReleaseDate, CURRENT_DATE()) AS days_since_release,
    CASE 
        WHEN DATEDIFF(day, ReleaseDate, CURRENT_DATE()) = 0 THEN Streams
        ELSE Streams / NULLIF(DATEDIFF(day, ReleaseDate, CURRENT_DATE()), 0)
    END AS average_streams_per_day
FROM 
    cleansed_data;

-- Create cases to group into seasons
SELECT 
    CASE 
        WHEN ReleaseMonth IN (12, 1, 2) THEN 'Winter'
        WHEN ReleaseMonth IN (3, 4, 5) THEN 'Spring'
        WHEN ReleaseMonth IN (6, 7, 8) THEN 'Summer'
        ELSE 'Fall'
    END AS season,
    AVG(Streams) AS avg_streams_per_season
FROM 
    cleansed_data
GROUP BY 
    CASE 
        WHEN ReleaseMonth IN (12, 1, 2) THEN 'Winter'
        WHEN ReleaseMonth IN (3, 4, 5) THEN 'Spring'
        WHEN ReleaseMonth IN (6, 7, 8) THEN 'Summer'
        ELSE 'Fall'
    END;

-- Another example based on count of streams
%%sql
SELECT 
    CASE 
        WHEN ReleaseMonth IN (12, 1, 2) THEN 'Winter'
        WHEN ReleaseMonth IN (3, 4, 5) THEN 'Spring'
        WHEN ReleaseMonth IN (6, 7, 8) THEN 'Summer'
        ELSE 'Fall'
    END AS season,
    COUNT(TrackName) AS track_count_per_season
FROM 
    cleansed_data
GROUP BY 
    CASE 
        WHEN ReleaseMonth IN (12, 1, 2) THEN 'Winter'
        WHEN ReleaseMonth IN (3, 4, 5) THEN 'Spring'
        WHEN ReleaseMonth IN (6, 7, 8) THEN 'Summer'
        ELSE 'Fall'
    END;

-- Create a subquery to limit the rows returned to the top 50 by a given criteria
SELECT 
    Key
    ,COUNT(*)
FROM (
    SELECT 
        Key
        ,Streams
    FROM cleansed_data
    WHERE Key IS NOT NULL
    ORDER BY Streams DESC
    LIMIT 100
) AS top_100
GROUP BY Key
ORDER BY COUNT(*) DESC; 

-- Create a Common Table Expression (CTE) to bin the data into BPM groups
WITH bpm_bins AS ( 
    SELECT 
        CAST(FLOOR(BPM / 20.0) * 20 AS INT) AS BPM_bin_start
        ,CAST(FLOOR(BPM / 20.0) * 20 + 19 AS INT) AS BPM_bin_end
        ,CONCAT(CAST(FLOOR(BPM / 20.0) * 20 AS STRING), '-', CAST(FLOOR(BPM / 20.0) * 20 + 19 AS STRING)) AS BPM_bin
        ,COUNT(TrackName) AS num_songs_in_bin
        ,SUM(Streams) AS total_streams_in_bin
    FROM 
        cleansed_data
    GROUP BY 
        CAST(FLOOR(BPM / 20.0) * 20 AS INT),
        CAST(FLOOR(BPM / 20.0) * 20 + 19 AS INT),
        CONCAT(CAST(FLOOR(BPM / 20.0) * 20 AS STRING), '-', CAST(FLOOR(BPM / 20.0) * 20 + 19 AS STRING))
) 

SELECT 
    BPM_bin_start
    ,BPM_bin_end
    ,BPM_bin
    ,total_streams_in_bin / num_songs_in_bin AS normalized_streams_per_song
FROM 
    bpm_bins
ORDER BY 
    BPM_bin_start ASC;