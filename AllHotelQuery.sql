use hotel

------------------------  Phase 1 Data Cleaning & Preparation  ------------------------

-- Numbers of Columns 32
-- Numbers of Rows 119390

------------------------ 1# Handling Missing Values  ------------------------
SELECT
    COUNT(CASE WHEN children IS NULL THEN 1 END) AS children_nulls,
    COUNT(CASE WHEN country IS NULL THEN 1 END) AS country_nulls,
    COUNT(CASE WHEN agent IS NULL THEN 1 END) AS agent_nulls,
    COUNT(CASE WHEN company IS NULL THEN 1 END) AS company_nulls
FROM HotelBookings;

-- Country and agent and company had Nulls that 
--was written inside of single quotation marks
-- so I revert them to NULLS

----------------------------------------------------------------------------------
UPDATE HotelBookings
SET company = NULL
WHERE company = 'NULL'

UPDATE HotelBookings
SET agent = NULL
WHERE agent = 'NULL'

UPDATE HotelBookings
SET company = NULL
WHERE company = 'NULL'

-------------------------------------------------------------------------------

SELECT
    COUNT(CASE WHEN children IS NULL THEN 1 END) AS children_nulls,
    COUNT(CASE WHEN country IS NULL THEN 1 END) AS country_nulls,
    COUNT(CASE WHEN agent IS NULL THEN 1 END) AS agent_nulls,
    COUNT(CASE WHEN company IS NULL THEN 1 END) AS company_nulls
FROM HotelBookings;

-- Chidren -- > 4 NULLS (Can be deleted)
-- Country -- > 488 NULLS
-- Agent -- > 16340 NULLS
-- Company -- > 112593 NULLS (More than 90% of the data)

--------------------------------------------------------------------------------

-- Children + Country  -- > Drop the rows that has nulls from table 
--     (Only 4 + 488 rows from 119K row)

DELETE FROM HotelBookings
WHERE children IS NULL

DELETE FROM HotelBookings
WHERE Country IS NULL

-- Agents + Company --> Set them to Unkown 
-- (Almost 90+% of the data) 

UPDATE HotelBookings
SET agent = 'Unkown'
WHERE agent IS NULL

UPDATE HotelBookings
SET company = 'Unkown'
WHERE company IS NULL

---------------------------------------------------------------------------------

------------------------ 2# Data Integrity & Outliers  ------------------------

-- 1 # Can a book happen without People ?

SELECT COUNT(*)
FROM HotelBookings
WHERE adults = 0 AND 
children = 0 AND 
babies = 0

-- 170 books with no one assigned to it (Drop them)

DELETE FROM HotelBookings
WHERE adults = 0 AND 
children = 0 AND 
babies = 0

-------------------------------------------------------------------------------

-- 2 # ADR (Average Daily Revenue) Cannot have negative or high number

SELECT adr
FROM HotelBookings
WHERE adr < 0 OR adr > 1000

-- 2 Rows has high number and negatives

DELETE FROM HotelBookings
WHERE adr < 0 OR adr > 1000

-------------------------------------------------------------------------------

--3 # Total booked nights cant be 0

SELECT COUNT(total_nights) 
FROM HotelBookings
WHERE total_nights = 0

-- 640 Rows has total nights = 0

DELETE FROM HotelBookings
WHERE total_nights = 0

------------------------ 3# Feature Engineering ------------------------

-- 1- Total Nights booked is the sum of stays in weekends + stays in week

ALTER TABLE HotelBookings
ADD total_nights INT

UPDATE HotelBookings
SET total_nights = stays_in_week_nights + stays_in_weekend_nights


-- 2- Total Guests (adults + children + babies)

ALTER TABLE HotelBookings
ADD total_guests INT

UPDATE HotelBookings
SET total_guests = adults + children + babies

---------------------------------------------------------------------------------
-- Data after cleaning and prep has 118726 Rows and 34 Columns 

------------------------  Phase 2 Primary Booking KPIs  ------------------------

CREATE VIEW View_Primary_Booking_KPIs AS
SELECT 
    -- 1. Total Bookings in the table
    COUNT(*) AS Total_Bookings,

    -- 2. Total bookings where it is not canceled
    SUM(CASE WHEN is_canceled = 0 THEN 1 ELSE 0 END) AS Total_Successful_Bookings,

    -- 3. Total bookings where it is canceled
    SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END) AS Total_Canceled_Bookings,

    -- 4. Cancellation rate
    ROUND(CAST(SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END) AS FLOAT) * 100.0 / COUNT(*), 2) AS Cancellation_Rate_Pct,

    -- 5. Avg lead time (the period from the book day to the assigned day)
    ROUND(AVG(CAST(lead_time AS FLOAT)), 1) AS Avg_Lead_Time_Days,

    -- 6. Repeat Guest Rate
    ROUND(CAST(SUM(CASE WHEN is_repeated_guest = 1 THEN 1 ELSE 0 END) AS FLOAT) * 100.0 / COUNT(*), 2) AS Repeat_Guest_Rate_Pct,

    -- 7. Average of Average Daily Rate when the book is not canceled
    ROUND(AVG(CASE WHEN is_canceled = 0 THEN adr END), 2) AS Avg_ADR_Successful

FROM HotelBookings;

SELECT * FROM View_Primary_Booking_KPIs

------------------------  Phase 3 Temporal & Seasonality Analysis  ------------------------
/* ============================================================
   PHASE 3: TEMPORAL & SEASONALITY ANALYSIS
   All analyses are saved as Views for Power BI.
   ============================================================ */


/* ------------------------------------------------------------
   VIEW 1: Monthly Booking & Cancellation Analysis
   Combines Monthly Booking Trends and Monthly Cancellation.
   ------------------------------------------------------------ */

CREATE OR ALTER VIEW dbo.vw_Monthly_Booking_Cancellation AS
SELECT
    arrival_date_year,
    arrival_date_month,
    hotel,

    COUNT(*) AS Total_Bookings,

    SUM(CASE
        WHEN is_canceled = 1 THEN 1
        ELSE 0
    END) AS Canceled_Bookings,

    SUM(CASE
        WHEN is_canceled = 0 THEN 1
        ELSE 0
    END) AS Not_Canceled_Bookings,

    CAST(
        100.0 * SUM(CASE
            WHEN is_canceled = 1 THEN 1
            ELSE 0
        END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(5,2)
    ) AS Cancellation_Rate_Pct

FROM dbo.HotelBookings
GROUP BY
    arrival_date_year,
    arrival_date_month,
    hotel;
GO


/* ------------------------------------------------------------
   VIEW 2: Peak and Low Season Analysis
   Counts bookings by month and hotel across all years.
   ------------------------------------------------------------ */

CREATE OR ALTER VIEW dbo.vw_Peak_Low_Season AS
SELECT
    arrival_date_month,
    hotel,
    COUNT(*) AS Total_Bookings
FROM dbo.HotelBookings
GROUP BY
    arrival_date_month,
    hotel;
GO


/* ------------------------------------------------------------
   VIEW 3: Yearly Booking Comparison
   Compares bookings and cancellation rates by year and hotel.
   ------------------------------------------------------------ */

CREATE OR ALTER VIEW dbo.vw_Yearly_Booking_Comparison AS
SELECT
    arrival_date_year,
    hotel,

    COUNT(*) AS Total_Bookings,

    SUM(CASE
        WHEN is_canceled = 0 THEN 1
        ELSE 0
    END) AS Not_Canceled_Bookings,

    SUM(CASE
        WHEN is_canceled = 1 THEN 1
        ELSE 0
    END) AS Canceled_Bookings,

    CAST(
        100.0 * SUM(CASE
            WHEN is_canceled = 1 THEN 1
            ELSE 0
        END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(5,2)
    ) AS Cancellation_Rate_Pct

FROM dbo.HotelBookings
GROUP BY
    arrival_date_year,
    hotel;
GO


/* ------------------------------------------------------------
   VIEW 4: Monthly Seasonality Across Years
   Compares monthly bookings across 2015, 2016, and 2017.
   ------------------------------------------------------------ */

CREATE OR ALTER VIEW dbo.vw_Monthly_Seasonality_Across_Years AS
SELECT
    arrival_date_month,
    hotel,

    SUM(CASE
        WHEN arrival_date_year = 2015 THEN 1
        ELSE 0
    END) AS Bookings_2015,

    SUM(CASE
        WHEN arrival_date_year = 2016 THEN 1
        ELSE 0
    END) AS Bookings_2016,

    SUM(CASE
        WHEN arrival_date_year = 2017 THEN 1
        ELSE 0
    END) AS Bookings_2017

FROM dbo.HotelBookings
GROUP BY
    arrival_date_month,
    hotel;
GO


/* ------------------------------------------------------------
   VIEW 5: Weekday vs. Weekend Stay Analysis
   Compares average weekday and weekend nights by year and hotel.
   ------------------------------------------------------------ */

CREATE OR ALTER VIEW dbo.vw_Weekday_Weekend_Stay AS
SELECT
    arrival_date_year,
    hotel,

    AVG(CAST(stays_in_week_nights AS FLOAT))
        AS Avg_Week_Nights,

    AVG(CAST(stays_in_weekend_nights AS FLOAT))
        AS Avg_Weekend_Nights,

    AVG(CAST(total_nights AS FLOAT))
        AS Avg_Total_Nights

FROM dbo.HotelBookings
GROUP BY
    arrival_date_year,
    hotel;
GO


/* ------------------------------------------------------------
   VIEW 6: Booking Lead Time by Month
   Analyzes how far in advance bookings are made.
   ------------------------------------------------------------ */

CREATE OR ALTER VIEW dbo.vw_Monthly_Booking_Lead_Time AS
SELECT
    arrival_date_year,
    arrival_date_month,
    hotel,

    CAST(
        AVG(CAST(lead_time AS DECIMAL(12,2)))
        AS DECIMAL(12,2)
    ) AS Avg_Lead_Time_Days,

    MIN(lead_time) AS Min_Lead_Time_Days,

    MAX(lead_time) AS Max_Lead_Time_Days

FROM dbo.HotelBookings
GROUP BY
    arrival_date_year,
    arrival_date_month,
    hotel;
GO

/* ============================================================
   PHASE 4 CUSTOMER BEHAVIOR & SEGMENTATION
   All analyses are saved as Views for Power BI.
   ============================================================ */

-------Type of Market Segment--------------
--select distinct market_segment 
--from HotelBookings
-----------------------------------------------------------------------
------------NUM_OF_Market_Segment-----------

CREATE VIEW Market_Segment_Analysis AS
select market_segment,
       COUNT (*)  Total_Segment_Booking  ,
       SUM(previous_cancellations)  total_cancellation ,
       SUM(CASE WHEN previous_cancellations > 0 THEN 1 ELSE 0 END) Prev_Canceller_Bookings,
       SUM(previous_bookings_not_canceled)  total_not_cancellation 
from dbo.HotelBookings
group by market_segment

---

CREATE VIEW Total_distribution_channel AS 
select distribution_channel,count (*)  Total_distribution_channel 
from dbo.HotelBookings
group by distribution_channel

-----------------------------------------------------------------------
-------Num_Repeted_Guest Not repeated ---------------------------
--select count (*) repeated_guest 
--from HotelBookings
--where is_repeated_guest = 1 

--select count (*) repeated_guest 
--from HotelBookings
--where is_repeated_guest = 0
CREATE VIEW REPEATED_VS_NON_REPEATED AS
select sum(case when is_repeated_guest = 1 then 1 else 0 end ) repeated_guest,
	   sum(case when is_repeated_guest = 0 then 1 else 0 end ) not_repeated_guest
from HotelBookings

-----------------------------------------------------------------------
---------------------Cancellation_Rate---------------------------------

CREATE VIEW Cancellation_Rate AS
SELECT
    customer_type,
    COUNT(*) AS Total_Bookings,
    SUM(CASE WHEN is_canceled = 'TRUE' THEN 1 ELSE 0 END)
        AS Canceled_Bookings,
    CAST(
        100.0 * SUM(CASE WHEN is_canceled = 'TRUE' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS Cancellation_Rate
FROM HotelBookings
GROUP BY customer_type;

------------------------------------------------------------------
---------------------Deposit Rate---------------------------------

CREATE VIEW Deposit_Cancellation_Rate AS
SELECT
    deposit_type,
    COUNT(*) AS Total_Bookings,
    SUM(CASE WHEN is_canceled = 'TRUE' THEN 1 ELSE 0 END)
        AS Canceled_Bookings,
    CAST(
        100.0 * SUM(CASE WHEN is_canceled = 'TRUE' THEN 1 ELSE 0 END)  -- TO BE REVIEWED
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS Cancellation_Rate
FROM HotelBookings
GROUP BY deposit_type;

---------------------------------------------------------------------------
---------------------Deposit_Type_Cancellation_Summary---------------------

CREATE VIEW Deposit_Type_Cancellation_Summary AS 
 SELECT  deposit_type , is_canceled  ,CAST(AVG(lead_time)AS DECIMAL (10,2)) avg_lead_time ,CAST(AVG(adr) AS DECIMAL(10,2)) avg_adr
    FROM HotelBookings
    WHERE deposit_type in ( 'Refundable', 'Non Refund','No Deposit')
    GROUP BY deposit_type , is_canceled
    ORDER BY avg_lead_time ,avg_adr DESC
    offset 0 ROW
-----------------------------------------------------------------------
---------------------Top 10 Countries--------------------------------

create view Top_10_Countries_Booking AS
SELECT TOP 10 country, COUNT(*) AS Bookings
FROM HotelBookings
GROUP BY country
ORDER BY Bookings DESC

-----------------------------------------------------------------------

/* ============================================================
   PHASE 5 ROOM, MEAL & REVENUE OPERATIONS
   All analyses are saved as Views for Power BI.
   ============================================================ */

---------------------------------------------------------------------------
---------------------Room_Operations---------------------
CREATE VIEW View_Room_Operations AS
SELECT 
    hotel,
    reserved_room_type,
    assigned_room_type,
    COUNT(*) AS total_bookings,
    SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END) AS canceled,
    CAST(100.0 * SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS cancel_rate,
    AVG(CAST(adr AS FLOAT)) AS avg_adr,
    AVG(CAST(total_nights AS FLOAT)) AS avg_nights,
    SUM(CASE WHEN reserved_room_type <> assigned_room_type THEN 1 ELSE 0 END) AS room_changed,
    CAST(100.0 * SUM(CASE WHEN reserved_room_type <> assigned_room_type THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS room_change_rate
FROM HotelBookings
GROUP BY hotel, reserved_room_type, assigned_room_type;


---------------------------------------------------------------------------
---------------------Meal_Operations---------------------

CREATE VIEW View_Meal_Operations AS
SELECT 
    hotel,
    meal,
    COUNT(*) AS total_bookings,
    SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END) AS canceled,
    CAST(100.0 * SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS cancel_rate,
    AVG(CAST(adr AS FLOAT)) AS avg_adr,
    AVG(CAST(total_guests AS FLOAT)) AS avg_guests,
    AVG(CAST(total_nights AS FLOAT)) AS avg_nights,
    SUM(CASE WHEN is_canceled = 0 THEN adr * total_nights ELSE 0 END) AS revenue
FROM HotelBookings
GROUP BY hotel, meal;

---------------------------------------------------------------------------
---------------------Revenue_Operations---------------------

CREATE VIEW View_Revenue_Operations AS
SELECT 
    arrival_date_year,
    arrival_date_month,
    hotel,
    COUNT(*) AS total_bookings,
    SUM(CASE WHEN is_canceled = 0 THEN 1 ELSE 0 END) AS successful,
    SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END) AS canceled,
    SUM(CASE WHEN is_canceled = 0 THEN adr * total_nights ELSE 0 END) AS revenue,
    SUM(CASE WHEN is_canceled = 1 THEN adr * total_nights ELSE 0 END) AS lost_revenue,
    AVG(CASE WHEN is_canceled = 0 THEN CAST(adr AS FLOAT) END) AS avg_adr_success,
    SUM(CASE WHEN is_canceled = 0 THEN adr * total_nights ELSE 0 END) / NULLIF(SUM(CASE WHEN is_canceled = 0 THEN total_nights ELSE 0 END),0) AS revenue_per_night,
    SUM(CASE WHEN is_canceled = 0 THEN adr * total_nights ELSE 0 END) / NULLIF(SUM(CASE WHEN is_canceled = 0 THEN 1 ELSE 0 END),0) AS revenue_per_booking
FROM HotelBookings
GROUP BY arrival_date_year, arrival_date_month, hotel;

---------------------------------------------------------------------------
---------------------Revenue by Room Type & Meal---------------------

CREATE VIEW View_Revenue_By_Room_Meal AS
SELECT 
    hotel,
    reserved_room_type,
    meal,
    COUNT(*) AS total_bookings,
    SUM(CASE WHEN is_canceled = 0 THEN adr * total_nights ELSE 0 END) AS revenue,
    AVG(CASE WHEN is_canceled = 0 THEN CAST(adr AS FLOAT) END) AS avg_adr_success
FROM HotelBookings
GROUP BY hotel, reserved_room_type, meal;