-- Question 1
-- 1. Build a Data Model using the Sheets in the Excel File
create database zomato_db;
use zomato_db;
Create table main
	(
      RestaurantID int primary key ,
      RestaurantName varchar(255),
      CountryCode int,
      City varchar(255),
      Address varchar(255),
      Locality varchar(255),
      LocalityVerbose varchar(255),
      Longitude  double,
      Latitude  double,
      Cuisines varchar(255),
      Currency varchar(255),
      Has_Table_booking varchar(255),
      Has_Online_delivery varchar(255),
      Is_delivering_now varchar(255),
      Switch_to_order_menu varchar(255),
      Price_range int,
      Votes int,
      Average_Cost_for_two double,
      Rating double,
      YearOpening int,
      MonthOpening int,
      DayOpening int
      );


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Zomata - Main.csv'
INTO TABLE main
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SHOW CREATE TABLE main;
ALTER TABLE main CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

select count(*) from main;

ALTER TABLE main ADD COLUMN Date DATE;

UPDATE main
SET Date = STR_TO_DATE(CONCAT(DayOpening, '-', MonthOpening, '-', YearOpening), '%d-%m-%Y');

INSERT INTO date (Date)
SELECT DISTINCT Date
FROM main;

ALTER TABLE country
ADD PRIMARY KEY (CountryID);

ALTER TABLE currency MODIFY COLUMN Currency VARCHAR(255);
ALTER TABLE currency ADD PRIMARY KEY (Currency(255));

ALTER TABLE date
ADD PRIMARY KEY (Date);

ALTER TABLE main
ADD CONSTRAINT country_constraint
FOREIGN KEY (CountryCode) REFERENCES country(CountryID);

ALTER TABLE main
ADD CONSTRAINT Currency_constraint
FOREIGN KEY (Currency) REFERENCES currency(Currency);

ALTER TABLE main
ADD CONSTRAINT date_constraint
FOREIGN KEY (Date) REFERENCES date(Date);

-- ----------------------------------------------------------------------------------------------------------------    
 -- Question 2
--  2. Build a Calendar Table using the Columns Datekey_Opening ( Which has Dates from Minimum Dates and Maximum Dates)
--   Add all the below Columns in the Calendar Table using the Formulas.
--    A.Year
--    B.Monthno
--    C.Monthfullname
--    D.Quarter(Q1,Q2,Q3,Q4)
--    E. YearMonth ( YYYY-MMM)
--    F. Weekdayno
--    G.Weekdayname
--    H.FinancialMOnth ( April = FM1, May= FM2  …. March = FM12)
--    I. Financial Quarter ( Quarters based on Financial Month FQ-1 . FQ-2..)


select * from date;

-- A. Year
UPDATE date
SET year = YEAR(date)
WHERE year IS NULL;

-- B. Monthno
UPDATE date
SET month = month(date)
WHERE month IS NULL;

-- C.Monthfullname
UPDATE date
SET Monthname = monthname(date)
WHERE Monthname IS NULL;

-- D.Quarter(Q1,Q2,Q3,Q4)
UPDATE date
SET quarter = CONCAT('Q', QUARTER(date))
WHERE quarter IS NULL;

-- E. YearMonth ( YYYY-MMM)
ALTER TABLE date ADD COLUMN YearMonth VARCHAR(10);
UPDATE date
SET YearMonth = DATE_FORMAT(date, '%Y-%b')
WHERE YearMonth IS NULL;

-- F. Weekdayno
ALTER TABLE date ADD COLUMN Weekdayno INT;
UPDATE date
SET Weekdayno = WEEKDAY(date)
WHERE Weekdayno IS NULL;

-- G.Weekdayname
ALTER TABLE date ADD COLUMN Weekdayname varchar(10);
UPDATE date
SET weekdayname = dayname(date)
WHERE Weekdayname IS NULL;

 -- H.FinancialMOnth ( April = FM1, May= FM2  …. March = FM12)
 ALTER TABLE Date ADD COLUMN FinancialMonth VARCHAR(10);
 UPDATE Date
SET FinancialMonth = CASE 
    WHEN MONTH(date) = 4 THEN 'FM1'   
    WHEN MONTH(date) = 5 THEN 'FM2'   
    WHEN MONTH(date) = 6 THEN 'FM3'   
    WHEN MONTH(date) = 7 THEN 'FM4'   
    WHEN MONTH(date) = 8 THEN 'FM5'   
    WHEN MONTH(date) = 9 THEN 'FM6'   
    WHEN MONTH(date) = 10 THEN 'FM7' 
    WHEN MONTH(date) = 11 THEN 'FM8' 
    WHEN MONTH(date) = 12 THEN 'FM9'  
    WHEN MONTH(date) = 1 THEN 'FM10'  
    WHEN MONTH(date) = 2 THEN 'FM11'  
    WHEN MONTH(date) = 3 THEN 'FM12'  
    ELSE NULL
END
WHERE FinancialMonth IS NULL;

-- I. Financial Quarter ( Quarters based on Financial Month FQ-1 . FQ-2..)

ALTER TABLE date ADD COLUMN FinancialQuarter VARCHAR(5);
UPDATE Date
SET FinancialQuarter = CASE 
    WHEN MONTH(date) IN (4, 5, 6) THEN 'FQ-1'  
    WHEN MONTH(date) IN (7, 8, 9) THEN 'FQ-2'  
    WHEN MONTH(date) IN (10, 11, 12) THEN 'FQ-3'  
    WHEN MONTH(date) IN (1, 2, 3) THEN 'FQ-4'  
    ELSE NULL
END
WHERE FinancialQuarter IS NULL;

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 3. Convert the Average cost for 2 column into USD dollars (currently the Average cost for 2 in local currencies

UPDATE main m
JOIN currency c ON m.Currency = c.Currency
SET m.Average_Cost_for_two = m.Average_Cost_for_two* c.`USD Rate`;

select * from main;
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 4.Find the Numbers of Resturants based on City and Country

select m.city,c.Countryname,count(RestaurantID) NumberOfRestaurants from main m join country c on m.CountryCode=c.CountryID group by m.city,c.countryname;

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 5.Numbers of Resturants opening based on Year , Quarter , Month
select Year,Monthname,Quarter,count(*) NumberOfRestaurant from main m join date d on m.date=d.date group by year , monthname,quarter;

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 6. Count of Resturants based on Average Ratings

select rating,count(*)countOfRestaurant from main group by rating order by rating desc ;

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 7. Create buckets based on Average Price of reasonable size and find out how many resturants falls in each buckets

SELECT 
    CASE 
        WHEN Average_Cost_for_two < 10 THEN 'Below $10'
        WHEN Average_Cost_for_two BETWEEN 10 AND 19.99 THEN '$10 - $19.99'
        WHEN Average_Cost_for_two BETWEEN 20 AND 29.99 THEN '$20 - $29.99'
        WHEN Average_Cost_for_two BETWEEN 30 AND 49.99 THEN '$30 - $49.99'
        ELSE 'Above $50'
    END AS PriceBucket,
    COUNT(*) AS RestaurantCount
FROM main
GROUP BY PriceBucket
ORDER BY PriceBucket;
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 8.Percentage of Resturants based on "Has_Table_booking"

SELECT 
    SUM(CASE WHEN Has_Table_Booking = 'Yes' THEN 1 ELSE 0 END) AS BookingYes,
    SUM(CASE WHEN Has_Table_Booking = 'No' THEN 1 ELSE 0 END) AS BookingNo,
    COUNT(*) AS TotalRestaurants,
    ROUND((SUM(CASE WHEN Has_Table_Booking = 'Yes' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS PercentageWithBooking,
    ROUND((SUM(CASE WHEN Has_Table_Booking = 'No' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS PercentageWithoutBooking
FROM main;
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 9.Percentage of Resturants based on "Has_Online_delivery"

SELECT 
    SUM(CASE WHEN Has_Online_Delivery = 'Yes' THEN 1 ELSE 0 END) AS DeliveryYes,
    SUM(CASE WHEN Has_Online_Delivery = 'No' THEN 1 ELSE 0 END) AS DeliveryNo,
    COUNT(*) AS TotalRestaurants,
    ROUND((SUM(CASE WHEN Has_Online_Delivery = 'Yes' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS PercentageWithDelivery,
    ROUND((SUM(CASE WHEN Has_Online_Delivery = 'No' THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS PercentageWithoutDelivery
FROM main;

