-- Step 1: View raw column and row details
SELECT *
FROM THEFT.RAW.STOLEN_CARS
LIMIT 10

-- Step 2: Set the default schema
USE THEFT.CLEAN;

-- Step 3: Initial table creation with casting of DATE_STOLEN
CREATE OR REPLACE TABLE CLEAN AS (
    SELECT 
        TO_DATE(DATE_STOLEN, 'MM/DD/YY') AS DATE_STOLEN_CASTED,
        COALESCE(VEHICLE_ID, 0) AS VEHICLE_ID,
        COALESCE(VEHICLE_TYPE, '') AS VEHICLE_TYPE,
        COALESCE(VEHICLE_DESC, '') AS VEHICLE_DESC,
        COALESCE(COLOR, '') AS COLOR,
        TO_DATE(CAST(CAST(MODEL_YEAR AS INT) AS VARCHAR), 'YYYY') AS MODEL_YEAR_CASTED,
        COALESCE(CAST(MAKE_ID AS NUMBER), 0) AS MAKE_ID,
        COALESCE(MAKE_NAME, '') AS MAKE_NAME,
        COALESCE(MAKE_TYPE, '') AS MAKE_TYPE,
        COALESCE(LOCATION_ID, 0) AS LOCATION_ID,
        COALESCE(REGION, '') AS REGION,
        COALESCE(COUNTRY, '') AS COUNTRY,
        COALESCE(CAST(REPLACE(POPULATION, ',', '') AS NUMBER), 0) AS POPULATION,
        COALESCE(CAST(REPLACE(DENSITY, ',', '') AS NUMBER), 0) AS DENSITY
    FROM THEFT.RAW.STOLEN_CARS
    WHERE 
        DATE_STOLEN IS NOT NULL
        AND MODEL_YEAR IS NOT NULL
);

-- Step 4: View TABLE CLEAN after data cleaning
SELECT *
FROM CLEAN
LIMIT 5


-- Step 5: Create star schema FACT table
CREATE OR REPLACE TABLE FCT_STOLEN_VEHICLE AS (
SELECT 
    VEHICLE_ID,
    MAKE_ID,
    LOCATION_ID,
    DATE_STOLEN_CASTED

FROM CLEAN    
);

-- Step 6: Create VIEW DIM VEHICLE 
CREATE OR REPLACE VIEW DIM_VEHICLE AS (
SELECT 
    VEHICLE_ID,
    VEHICLE_TYPE,
    VEHICLE_DESC,
    MODEL_YEAR_CASTED,
    COLOR

FROM CLEAN    
);

-- Step 7: Create VIEW DIM MAKE
CREATE OR REPLACE VIEW DIM_MAKE AS (
SELECT 
    MAKE_ID,
    MAKE_NAME,
    MAKE_TYPE,

FROM CLEAN    
);

-- Step 8: Create VIEW DIM LOCATION
CREATE OR REPLACE VIEW DIM_LOCATION AS (
SELECT 
    LOCATION_ID,
    REGION,
    COUNTRY,
    POPULATION,
    DENSITY

FROM CLEAN    
);

-- Step 9: Question 5b.i.Aggregate total stolen vehicles over time grouped by region
CREATE OR REPLACE VIEW STOLEN_VEHICLES_TIME_REGION AS (
SELECT
    FCT_STOLEN_VEHICLE.DATE_STOLEN_CASTED,
    DIM_LOCATION.REGION,
    COUNT(FCT_STOLEN_VEHICLE.VEHICLE_ID) AS TOTAL_STOLEN_VEHICLES
FROM
    FCT_STOLEN_VEHICLE
INNER JOIN
    DIM_LOCATION 
        ON FCT_STOLEN_VEHICLE.LOCATION_ID = DIM_LOCATION.LOCATION_ID
GROUP BY
    FCT_STOLEN_VEHICLE.DATE_STOLEN_CASTED,
    DIM_LOCATION.REGION
ORDER BY
    FCT_STOLEN_VEHICLE.DATE_STOLEN_CASTED,
    DIM_LOCATION.REGION);

SELECT *
FROM STOLEN_VEHICLES_TIME_REGION;

-- Step 10: Question 5b.ii.number of days difference between model year and date stolen
CREATE OR REPLACE VIEW STOLEN_VEHICLES_DAYDIFF_MODEL AS (
    SELECT
        DATEDIFF('DAY', DIM_VEHICLE.MODEL_YEAR_CASTED,              
        FCT_STOLEN_VEHICLE.DATE_STOLEN_CASTED) AS DAYS_DIFFERENCE,
    COUNT(*) AS STOLEN_QTY
    FROM 
        FCT_STOLEN_VEHICLE
    INNER JOIN 
        DIM_VEHICLE
        ON FCT_STOLEN_VEHICLE.VEHICLE_ID = DIM_VEHICLE.VEHICLE_ID
    GROUP BY 
        DATEDIFF('DAY', DIM_VEHICLE.MODEL_YEAR_CASTED,  
        FCT_STOLEN_VEHICLE.DATE_STOLEN_CASTED)
);

SELECT *
FROM STOLEN_VEHICLES_DAYDIFF_MODEL;


-- Step 11: Question 5b.ii.get average of total stolen vehicles
CREATE OR REPLACE VIEW AVERAGE_STOLEN_VEHICLES_DAYDIFF_MODEL AS (
    SELECT
        AVG(DAYS_DIFFERENCE,DIM_VEHICLE.VEHICLE_ID) AS AVERAGE_STOLEN_QTY
    FROM 
        STOLEN_VEHICLES_DAYDIFF_MODEL
);

-- Step 12: Question 5b.ii.table output get average of total stolen vehicles
SELECT DAYS_DIFFERENCE, AVERAGE_STOLEN_QTY
FROM STOLEN_VEHICLES_DAYDIFF_MODEL
INNER JOIN
AVERAGE_STOLEN_VEHICLES_DAYDIFF_MODEL;

-- Step 13: Question 5b.iii.number of stolen vehicle by make name over time
CREATE OR REPLACE TABLE NUM_STOLEN_VEHICLES_MAKE_NAME_TIME AS (
    SELECT 
        FCT_STOLEN_VEHICLE.DATE_STOLEN_CASTED,
        DIM_MAKE.MAKE_NAME,
        COUNT(FCT_STOLEN_VEHICLE.VEHICLE_ID) AS TOTAL_STOLEN_VEHICLES

    FROM
        FCT_STOLEN_VEHICLE
    INNER JOIN
        DIM_MAKE
        ON FCT_STOLEN_VEHICLE.MAKE_ID = DIM_MAKE.MAKE_ID
        
    GROUP BY
        FCT_STOLEN_VEHICLE.DATE_STOLEN_CASTED,
        DIM_MAKE.MAKE_NAME
    
);

SELECT *
FROM NUM_STOLEN_VEHICLES_MAKE_NAME_TIME;