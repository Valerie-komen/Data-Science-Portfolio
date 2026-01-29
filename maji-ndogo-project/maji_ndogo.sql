-- ============================================
-- Project: Maji Ndogo Water Access Analysis
-- Author: Valerie Komen
-- Description:
-- This SQL script analyzes access to basic water servicess across provinces and towns in Maji Ndogo to identify gaps and priorities.
-- =============================================

/* 1. DATA DESCRIPTION
Tables used:
- data_dictionary
- employee
- auditor_report
- global_water_access
- location
- project_progress
- visits
- water_quality
- water_source
- well_pollution

/* DATA EXPLORATION
-- Purpose: Understand the structure and contents of the database

SELECT * FROM emloyee LIMIT 10;
SELECT * FROM auditor_report LIMIT 10;
SELECT * FROM location LIMIT 10;
SELECT * FROM project_progress LIMIT 10;
SELECT * FROM water_source LIMIT 10;
SELECT * FROM visits LIMIT 10;
SELECT * FROM water_quality LIMIT 10;
SELECT * FROM well_pollution LIMIT 10;

/* DATA CLEANING
-- Create an Email address column in the employee table

SELECT employee_name,
	   LOWER(concat( REPLACE(employee_name,' ', '.'),'@ndogowater.gov')) AS email
FROM employee;

-- update the email column in the dataset

SET SQL_SAFE_UPDATES = 0;
UPDATE employee
SET email = CONCAT(LOWER(REPLACE(employee_name, ' ', '.')),'@ndogowater.gov');

-- Remove phone number length from 13 to 12.
UPDATE md_water_services.employee
SET 
phone_number = TRIM(phone_number)
WHERE LENGTH(phone_number) = 13;

/* DATA ANALYSIS

1. EMPLOYEE TABLE
-- No. of employees in each town
SELECT province_name, town_name, 
COUNT(town_name) AS number_of_employees
FROM md_water_services.employee
GROUP BY province_name, town_name
ORDER BY province_name, COUNT(town_name) DESC;

2. TYPES OF WATER SOURCES 
-- Purpose: Identify all unique water source types in Maji Ndogo
SELECT DISTINCT type_of_water_source
FROM water_source;

-- Total number of people served
SELECT 
SUM(number_of_people_served) 
FROM water_source;

-- Number of people served by each type of water source
SELECT type_of_water_source, SUM(number_of_people_served) AS total
FROM water_source
GROUP BY type_of_water_source;

-- Total number of well, taps and rivers
SELECT type_of_water_source, count(source_id) as total_source
FROM water_source
GROUP BY type_of_water_source;

-- partition each water source and rank it.
SELECT source_id, type_of_water_source, number_of_people_served,
		RANK()OVER(PARTITION BY type_of_water_source ORDER BY number_of_people_served DESC) AS rank_of_population,
    	DENSE_RANK()OVER(PARTITION BY type_of_water_source ORDER BY number_of_people_served) AS dense_rank_of_population,
    	ROW_NUMBER()OVER(PARTITION BY type_of_water_source ORDER BY number_of_people_served) AS row_number_of_population
FROM water_source;

3. VISIT FREQUENCY ANALYSIS
-- Question 1: Identify the most visited water sources in Maji Ndogo
SELECT visits.time_in_queue, water_source.type_of_water_source 
FROM md_water_services.visits
JOIN water_source
	ON water_source.source_id = visits.source_id
WHERE time_in_queue > 500
ORDER BY time_in_queue DESC
LIMIT 10;

-- Question 2: How long was the survey?
SELECT MIN(time_of_record) AS MIN,
		   MAX(time_of_record) AS MAX,
       DATEDIFF(MAX(time_of_record),MIN(time_of_record)) AS NO_OF_DAYS
 FROM visits;

-- Question 3; how long do people queue on average?
SELECT AVG(IF(time_in_queue = 0, NULL, time_in_queue)) AS modified_time_in_queue
FROM visits;

-- Question 4; Average queue time on different days
SELECT dayname(time_of_record) AS Day_of_the_week,
       ROUND(AVG(IF(time_in_queue = 0, NULL, time_in_queue)), 0) AS avg_queue_time
FROM visits
GROUP BY dayname(time_of_record);

-- Question 5; time during the day people collect water
SELECT time_format(TIME(time_of_record),'%H:00') AS HOUR_of_the_DAY,
       ROUND(AVG(IF(time_in_queue = 0, NULL, time_in_queue)), 0) AS queue_time
FROM visits
GROUP BY time_format(TIME(time_of_record),'%H:00')
ORDER BY time_format(TIME(time_of_record),'%H:00');

SELECT TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,
-- Sunday
	ROUND(AVG(
		CASE
		WHEN DAYNAME(time_of_record) = 'Sunday' THEN time_in_queue
		ELSE NULL
	END
		),0) AS Sunday,
-- Monday
	ROUND(AVG(
		CASE
		WHEN DAYNAME(time_of_record) = 'Monday' THEN time_in_queue
		ELSE NULL
	END
		),0) AS Monday,
-- Tuesday
ROUND(AVG(
		CASE
		WHEN DAYNAME(time_of_record) = 'Tuesday' THEN time_in_queue
		ELSE NULL
	END
		),0) AS Tuesday,
-- Wednesday
ROUND(AVG(
		CASE
		WHEN DAYNAME(time_of_record) = 'Wednesday' THEN time_in_queue
		ELSE NULL
	END
		),0) AS Wednesday,
-- Thursday
ROUND(AVG(
		CASE
		WHEN DAYNAME(time_of_record) = 'Thursday' THEN time_in_queue
		ELSE NULL
	END
		),0) AS Thursday,
-- Friday
ROUND(AVG(
		CASE
		WHEN DAYNAME(time_of_record) = 'Friday' THEN time_in_queue
		ELSE NULL
	END
		),0) AS Friday,
-- Saturday
ROUND(AVG(
		CASE
		WHEN DAYNAME(time_of_record) = 'Saturday' THEN time_in_queue
		ELSE NULL
	END
		),0) AS Saturday
FROM visits
WHERE time_in_queue != 0 -- this excludes other sources with 0 queue times
GROUP BY time_format(TIME(time_of_record),'%H:00')
ORDER BY time_format(TIME(time_of_record),'%H:00');

