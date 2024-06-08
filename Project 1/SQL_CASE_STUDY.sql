-- ********Data Cleaning  ***********

-- Create Temp table and do the necessary cleaning
DROP TABLE IF EXISTS #Temp_Youtube5000
CREATE TABLE #Temp_Youtube5000(
    Rank  VARCHAR(255),
    Grade VARCHAR(255),
    [Channel name] VARCHAR(255),
    [Video Uploads] VARCHAR(255),
    Subscribers VARCHAR(255),
    [Video Views] BIGINT
    )

INSERT INTO #Temp_Youtube5000
SELECT *
FROM youtube5000 

SELECT * 
FROM #Temp_Youtube5000

-- Get Information About Our Dataset Datatypes of Each Column 
SELECT 
    COLUMN_NAME, DATA_TYPE
FROM 
    tempdb.INFORMATION_SCHEMA.COLUMNS
WHERE 
    TABLE_NAME LIKE '#Temp_Youtube5000%';


-- Remove Duplicates

SELECT [Channel name] AS Duplicates, COUNT(*) AS DuplicateCount
FROM #Temp_Youtube5000
GROUP BY [Channel name]
HAVING COUNT(*) > 1;

WITH CTE_Dups AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY [Channel name] ORDER BY (SELECT 0)) AS RowNum
    FROM #Temp_Youtube5000
)
DELETE FROM CTE_Dups WHERE RowNum > 1;

-- 1. Data Cleaning  (Replace '--'  to Null)

SELECT
    COUNT(CASE WHEN Rank = '--' THEN 1 END) as NumOfDash_Rank,
    COUNT(CASE WHEN Grade = '--' THEN 1 END) as NumOfDash_Grade,
    COUNT(CASE WHEN [Channel name] = '--' THEN 1 END) as NumOfDash_Channel,
    COUNT(CASE WHEN [Video Uploads] = '--' THEN 1 END) as NumOfDash_Video,
    COUNT(CASE WHEN Subscribers = '--' THEN 1 END) as NumOfDash_Subscribe
FROM
    #Temp_Youtube5000
WHERE
    Rank = '--' OR
    Grade = '--' OR
    [Channel name] = '--' OR
    [Video Uploads] = '--' OR
    Subscribers = '--'



UPDATE 
    #Temp_Youtube5000
SET 
    [Video Uploads] = CASE WHEN [Video Uploads] = '--' THEN NULL 
    ELSE [Video Uploads] END,
    Subscribers = CASE WHEN Subscribers = '--' THEN NULL 
    ELSE Subscribers END;


-- Check Null Values In The Dataset
SELECT
    COUNT(CASE WHEN Rank IS NULL THEN 1 END) as NumOfDash_Rank,
    COUNT(CASE WHEN Grade IS NULL THEN 1 END) as NumOfDash_Grade,
    COUNT(CASE WHEN [Channel name] IS NULL THEN 1 END) as NumOfDash_Channel,
    COUNT(CASE WHEN [Video Uploads] IS NULL THEN 1 END) as NumOfDash_Video,
    COUNT(CASE WHEN Subscribers IS NULL THEN 1 END) as NumOfDash_Subscribe
FROM
    #Temp_Youtube5000
WHERE
    Rank IS NULL OR
    Grade IS NULL OR
    [Channel name] IS NULL OR
    [Video Uploads] IS NULL OR
    Subscribers IS NULL


-----Drop NULL values

DELETE FROM 
    #Temp_Youtube5000
WHERE 
    [Video Uploads] IS NULL OR
    Subscribers IS NULL

-------------------------------------------------------------------

-- 2. Data Cleaning [ Rank Column ]
SELECT
    CASE 
        WHEN Rank LIKE '%st' THEN REPLACE(Rank, 'st', '')
        WHEN Rank LIKE '%nd' THEN REPLACE(Rank, 'nd', '')
        WHEN Rank LIKE '%rd' THEN REPLACE(Rank, 'rd', '')
        WHEN Rank LIKE '%th' THEN REPLACE(Rank, 'th', '')
        ELSE Rank
    END
FROM #Temp_Youtube5000

UPDATE 
    #Temp_Youtube5000
SET 
    Rank = CASE 
        WHEN Rank LIKE '%st' THEN REPLACE(Rank, 'st', '')
        WHEN Rank LIKE '%nd' THEN REPLACE(Rank, 'nd', '')
        WHEN Rank LIKE '%rd' THEN REPLACE(Rank, 'rd', '')
        WHEN Rank LIKE '%th' THEN REPLACE(Rank, 'th', '')
        ELSE Rank
    END;



UPDATE 
    #Temp_Youtube5000
SET 
    Rank =  CASE WHEN Rank LIKE '%,%' 
            THEN PARSENAME(REPLACE(Rank, ',', '.') , 2) + PARSENAME(REPLACE(Rank, ',', '.') , 1) 
            ELSE Rank
            END;


ALTER TABLE 
    #Temp_Youtube5000
ALTER 
    COLUMN Rank int;

-----------------------------------------------------------------------

-- 3. Data Cleaning [ Video Uploads & Subscribers ]

ALTER TABLE 
    #Temp_Youtube5000
ALTER 
    COLUMN [Video Uploads] int;

ALTER TABLE 
    #Temp_Youtube5000
ALTER 
    COLUMN Subscribers int;

-----------------------------------------------------------------------

-- 4. Data Cleaning [ Grade Column ] 
-- create another column called Grade_Code

SELECT 
    DISTINCT Grade
FROM 
    #Temp_Youtube5000;

ALTER TABLE 
    #Temp_Youtube5000
Add 
    Grade_Code int;

UPDATE 
    #Temp_Youtube5000
SET 
    Grade_Code = CASE
        WHEN Grade = 'A++' THEN 5
        WHEN Grade = 'A+' THEN 4
        WHEN Grade = 'A-' THEN 3
        WHEN Grade = 'A' THEN 2
        WHEN Grade = 'B+' THEN 1
    ELSE Grade
    END

SELECT 
    Grade, Grade_Code
FROM 
    #Temp_Youtube5000

--------------------------------------------------------------

-- 5. Average Views For Each Channel

ALTER TABLE 
    #Temp_Youtube5000
ADD 
    ViewPerUploads float;


UPDATE 
    #Temp_youtube5000
SET 
    ViewPerUploads = [Video views]/[Video Uploads]


-- EXEC sp_rename '#Temp_Youtube5000.Avg_Views', 
-- 'ViewPerUploads', 'COLUMN';

-- Do this again
ALTER TABLE 
    #Temp_Youtube5000
ALTER 
    COLUMN Subscribers int;

-- Create another table and copy cleaned table into that table
DROP TABLE IF EXISTS Copy_of_TempTable_Youtube5000
CREATE TABLE Copy_of_TempTable_Youtube5000 (
   [Rank] INT,
    [Grade] VARCHAR(255),
    [Channel name] VARCHAR(255),
    [Video Uploads] INT,
    [Subscribers] INT,
    [Video Views] BIGINT,
    [Grade_Code] INT,
    [ViewPerUploads] FLOAT
);


INSERT INTO Copy_of_TempTable_Youtube5000
SELECT *
FROM #Temp_Youtube5000;




--*************** Data Analysis ****************************

-- 6. Top Five Channels With Maximum Number of Video Uploads

SELECT 
    TOP 5 [Channel name], [Video Uploads] 
FROM 
    Copy_of_TempTable_Youtube5000
ORDER BY 
    [Video Uploads] DESC

CREATE VIEW TopChannelsSQLCaseStudyView AS
SELECT TOP 5 [Channel name], [Video Uploads]
FROM Copy_of_TempTable_Youtube5000
ORDER BY [Video Uploads] DESC;

-- 7.  Which Grade Has A Maximum Number of Video Uploads?

SELECT 
    Grade, AVG([Video Uploads]) AS Avg_Uploads
FROM 
    Copy_of_TempTable_Youtube5000
GROUP BY 
    Grade
ORDER BY 
    AVG([Video Uploads]) DESC;

CREATE VIEW AverageUploadsByGrade AS
SELECT Grade, AVG([Video Uploads]) AS Avg_Uploads
FROM Copy_of_TempTable_Youtube5000
GROUP BY Grade


-- 8. Which Grade Has The Highest Average Views?

SELECT 
    Grade, AVG(ViewPerUploads)  AS Avg_Views
FROM 
    Copy_of_TempTable_Youtube5000
GROUP BY 
    Grade
ORDER BY 
    AVG(ViewPerUploads) DESC;

CREATE VIEW AverageViewsByGrade AS
SELECT Grade, AVG(ViewPerUploads)  AS Avg_Views
FROM Copy_of_TempTable_Youtube5000
GROUP BY Grade


-- 9. Which Grade Has The Highest Number of Subscribers? 
-- What is the average number of subscribers for channels in each grade? 

SELECT 
    Grade, AVG(CAST(Subscribers AS decimal)) AS Avg_Subscribers
FROM 
    Copy_of_TempTable_Youtube5000
GROUP BY 
    Grade;

CREATE VIEW AverageSubscribersByGrade AS
SELECT Grade, AVG(CAST(Subscribers AS decimal)) AS Avg_Subscribers
FROM Copy_of_TempTable_Youtube5000
GROUP BY Grade;


-- 10. What are the top 10 most subscribed YouTube channels in the dataset?

SELECT 
    TOP 10 [Channel name], Subscribers 
FROM 
    Copy_of_TempTable_Youtube5000
ORDER BY 
    Subscribers DESC;

CREATE VIEW TopChannelsBySubscribers AS
SELECT TOP 10 [Channel name], Subscribers 
FROM Copy_of_TempTable_Youtube5000
ORDER BY Subscribers DESC;

-- 11. How many channels have a subscriber count greater than 1 million?
WITH CTE_FreqNRelfreq AS (
    SELECT
        (SELECT COUNT([Channel name]) FROM Copy_of_TempTable_Youtube5000 WHERE Subscribers > 1000000) AS FreqOfSubGeMil,
        COUNT([Channel name]) AS TotalNumOfChannels
    FROM
        Copy_of_TempTable_Youtube5000
)
SELECT
    FreqOfSubGeMil AS Frequency,
        FORMAT(ROUND((CAST(FreqOfSubGeMil AS decimal) / TotalNumOfChannels) * 100, 2), '0.##')
         AS '% Frequency'
FROM
    CTE_FreqNRelfreq;


CREATE VIEW ChannelFrequency AS
WITH CTE_FreqNRelfreq AS (
    SELECT
        (SELECT COUNT([Channel name]) FROM Copy_of_TempTable_Youtube5000 WHERE Subscribers > 1000000) AS FreqOfSubGeMil,
        COUNT([Channel name]) AS TotalNumOfChannels
    FROM
        Copy_of_TempTable_Youtube5000
)
SELECT
    FreqOfSubGeMil AS Frequency,
    FORMAT(ROUND((CAST(FreqOfSubGeMil AS decimal) / TotalNumOfChannels) * 100, 2), '0.##') AS '% Frequency'
FROM
    CTE_FreqNRelfreq;


-- 12. What is the distribution of channel grades in the dataset?
SELECT
    Grade,
    COUNT(*) AS Frequency,
    (CAST(COUNT(*) AS decimal) / (SELECT COUNT(*) FROM Copy_of_TempTable_Youtube5000)) * 100 AS '% Frequency'
FROM
    Copy_of_TempTable_Youtube5000
GROUP BY
    Grade
ORDER BY
    COUNT(*) DESC;


CREATE VIEW ChannelGradeFrequency AS
SELECT
    Grade,
    COUNT(*) AS Frequency,
    (CAST(COUNT(*) AS decimal) / (SELECT COUNT(*) FROM Copy_of_TempTable_Youtube5000)) * 100 AS '% Frequency'
FROM
    Copy_of_TempTable_Youtube5000
GROUP BY
    Grade


-- 16. Which channel has the highest number of video views?

SELECT 
    [Channel name], [ViewPerUploads]
FROM 
    Copy_of_TempTable_Youtube5000
WHERE 
    [ViewPerUploads] = (SELECT MAX([ViewPerUploads]) FROM Copy_of_TempTable_Youtube5000);


CREATE VIEW ChannelWithMaxViews AS
SELECT 
    [Channel name], [Video views]
FROM 
    Copy_of_TempTable_Youtube5000
WHERE 
    [Video views] = (SELECT MAX([ViewPerUploads]) FROM Copy_of_TempTable_Youtube5000);


-- 17. How many channels have a video upload count greater than 1000?

WITH CTE_ChannelsGe1000
AS (
   SELECT 
    COUNT([Channel name]) AS ChannelsWithVidUpoadsGe1000,
    (SELECT COUNT(*) FROM Copy_of_TempTable_Youtube5000) AS NumOfChannel
FROM 
    Copy_of_TempTable_Youtube5000
WHERE
    [Video Uploads] > 1000
)
SELECT
    ChannelsWithVidUpoadsGe1000 AS 'Number of channels have a video upload count greater than 1000',
             FORMAT(ROUND((CAST(ChannelsWithVidUpoadsGe1000 AS decimal) / NumOfChannel) * 100, 2), '0.##') as '% of the total'
FROM
    CTE_ChannelsGe1000


CREATE VIEW ChannelsWithUploadsGe1000 AS
WITH CTE_ChannelsGe1000 AS (
   SELECT 
    COUNT([Channel name]) AS ChannelsWithVidUpoadsGe1000,
    (SELECT COUNT(*) FROM Copy_of_TempTable_Youtube5000) AS NumOfChannel
FROM 
    Copy_of_TempTable_Youtube5000
WHERE
    [Video Uploads] > 1000
)
SELECT
    ChannelsWithVidUpoadsGe1000 AS 'Number of channels have a video upload count greater than 1000',
    FORMAT(ROUND((CAST(ChannelsWithVidUpoadsGe1000 AS decimal) / NumOfChannel) * 100, 2), '0.##') as '% of the total'
FROM
    CTE_ChannelsGe1000;


