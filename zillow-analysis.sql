

----------------------------- Part 1: Dataset Overview -----------------------------

SELECT * FROM zillowdata LIMIT 100;

-- total count: 21,840 entries in the entire database
SELECT COUNT(*) FROM zillowdata;

-- every state has ~400 entries
SELECT COUNT(*), State FROM zillowdata GROUP BY State;

-- # of nulls for RentEstimate per state
SELECT 
 State, 
 COUNT(*) AS num_null_rent_est
FROM zillowdata
WHERE RentEstimate IS NULL
GROUP BY State
ORDER BY num_null_rent_est DESC

-- # of nulls for MarketEstimate per state
SELECT 
 State, 
 COUNT(*) AS num_null_mkt_est
FROM zillowdata 
WHERE MarketEstimate IS NULL
GROUP BY State
ORDER BY num_null_mkt_est DESC


----------------------------- Part 2: Highest Rent, Price, and PPSq ------------------------------


-- Top 5 highest median rent estimate per state: CA, MA, NJ, VT, NH
SELECT 
 State, 
 MEDIAN(RentEstimate) AS median_rent -- MEDIAN already looks only for non-nulls
FROM zillowdata 
GROUP BY State
ORDER BY median_rent DESC
LIMIT 10;



/*
Some versions of SQL don't have a built-in MEDIAN function, though mine did.
In that case, we can use PERCENTILE_CONT instead, like here:

  SELECT 
   State, 
   PERCENTILE_CONT(0.5) OVER (
    ORDER BY RentEstimate) AS median_rent
  FROM zillowdata 
  GROUP BY State
  ORDER BY median_rent DESC
  LIMIT 10;

*/


-- Top 10 lowest median rent estimate per state
SELECT 
 State, 
 MEDIAN(RentEstimate) AS median_rent 
FROM zillowdata 
GROUP BY State
ORDER BY median_rent
LIMIT 10;


-- Top 10 highest median market estimates per state
SELECT 
 State, 
 MEDIAN(MarketEstimate) AS median_mkt_estimate
FROM zillowdata 
GROUP BY State
ORDER BY median_mkt_estimate DESC
LIMIT 10;


-- Top 10 lowest median market price estimates per state
SELECT 
 State, 
 MEDIAN(MarketEstimate) AS median_mkt_estimate
FROM zillowdata 
GROUP BY State
ORDER BY median_mkt_estimate
LIMIT 10;


-- Top 10 highest median listed prices per state

SELECT 
 State, 
 MEDIAN(ListedPrice) AS median_listed_price
FROM zillowdata 
WHERE RentEstimate > 100 -- some entries have RentEstimate with a value of 1
GROUP BY State
ORDER BY median_listed_price DESC
LIMIT 10;


-- Top 5 lowest median listed prices per state
SELECT 
 State, 
 MEDIAN(ListedPrice) AS median_listed_price
FROM zillowdata 
WHERE RentEstimate > 100
GROUP BY State
ORDER BY median_listed_price
LIMIT 10;



/*
Next we want to see highest and lowest price per square foot
*/


-- Top 10 highest Avg PPSq per state
SELECT 
 State, 
 ROUND(MEDIAN(PPSq), 2) AS median_ppsq
FROM zillowdata 
WHERE ListedPrice > 100 AND Area > 100 -- Some entries have ListedPrice = 1 or Area = 1
GROUP BY State
ORDER BY median_ppsq DESC
LIMIT 10;


-- Top 10 lowest Avg PPSq per state
SELECT 
 State, 
 ROUND(MEDIAN(PPSq), 2) AS median_ppsq
FROM zillowdata 
WHERE ListedPrice > 100 AND Area > 100
GROUP BY State
ORDER BY median_ppsq
LIMIT 10;



------------------------------ Part 3: Renting vs. Owning ----------------------------



-- First, write a CTE to add a new column, which carries the value of (RentEstimate / MarketEstimate)
WITH rent_ratio_cte AS (
    SELECT
      *,
      ROUND((RentEstimate / MarketEstimate)*100, 2) AS rent_ratio
    FROM 
      zillowdata
    WHERE 
      RentEstimate IS NOT NULL AND MarketEstimate IS NOT NULL
)


-- Top 10 states with the highest rent to home price ratio
SELECT
  State,
  ROUND(AVG(rent_ratio), 2) AS avg_rent_ratio
FROM rent_ratio_cte
GROUP BY State
ORDER BY avg_rent_ratio DESC
LIMIT 10;


-- Bottom 10 states with the lowest rent to home price ratio
SELECT
  State,
  ROUND(AVG(rent_ratio), 2) AS avg_rent_ratio
FROM rent_ratio_cte
GROUP BY State
ORDER BY avg_rent_ratio
LIMIT 10;


---------------------------   Part 4: Over- vs. Under-valued ----------------------------

/*

Next, we want to see which states have the most over-valued and the most under-valued 
homes, according to Zillow's proprietary algorithm.

We will have to create a new column called overvalue_difference. 
Any negative values in this column will indicate a positive undervalue.

ListedPrice > MarketEstimate = overvalued
MarketEstimate > ListedPrice = undervalued

*/


WITH overvalue_cte AS (
  SELECT
     *,
     ListedPrice - MarketEstimate AS overvalue_difference
  FROM
    zillowdata
  WHERE MarketEstimate IS NOT NULL AND ListedPrice > 100
)

-- Top 10 states with homes listed over their Zillow value
SELECT
  State,
  MEDIAN(overvalue_difference) AS median_overvalue
FROM overvalue_cte
GROUP BY State
ORDER BY median_overvalue DESC
LIMIT 10;

-- Top 10 states with homes listed under their Zillow value
SELECT
  State,
  MEDIAN(overvalue_difference) AS median_overvalue
FROM overvalue_cte
GROUP BY State
ORDER BY median_overvalue
LIMIT 10;

