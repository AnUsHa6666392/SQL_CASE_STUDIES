USE parking_db;

CREATE TABLE interest_map (
    id INT PRIMARY KEY,
    interest_name VARCHAR(255),
    interest_summary TEXT
);
CREATE TABLE interest_metrics (
    month INT,
    year INT,
    month_year VARCHAR(10),
    interest_id INT,
    composition DECIMAL(5,2),
    index_value DECIMAL(5,2),
    ranki INT,
    FOREIGN KEY (interest_id) REFERENCES interest_map(id)
);
#1.Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month
CREATE DATABASE fresh_segments_db;
USE fresh_segments_db;
CREATE TABLE interest_metrics (
    month VARCHAR(20),
    year INT,
    month_year VARCHAR(50),
    interest_id INT,
    composition FLOAT,
    index_value FLOAT,
    ranki INT
);
ALTER TABLE interest_metrics
ADD COLUMN month_year_date DATE;

UPDATE interest_metrics
SET month_year_date = STR_TO_DATE(month_year, '%M %Y');
#2.What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?
USE parking_db;

SELECT 
    month_year,
    COUNT(*) AS record_count
FROM 
    interest_metrics
GROUP BY 
    month_year
ORDER BY 
    month_year IS NOT NULL,
    STR_TO_DATE(month_year, '%M %Y');
    SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_name = 'interest_metrics';
#3.What do you think we should do with these null values in the fresh_segments.interest_metrics
USE parking_db;
SHOW TABLES;
CREATE DATABASE fresh_segments;
USE fresh_segments;
CREATE TABLE interest_metrics (
    month INT,
    year INT,
    month_year VARCHAR(20),
    interest_id INT,
    composition FLOAT,
    index_value FLOAT,
    ranki INT
);
#4.How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?

CREATE TABLE fresh_segments.interest_map (
    id INT PRIMARY KEY,
    interest_name VARCHAR(255),
    interest_summary TEXT
);
CREATE TABLE fresh_segments.interest_metrics (
    month VARCHAR(20),
    year INT,
    month_year VARCHAR(20),
    interest_id INT,
    composition VARCHAR(255),
    index_value DECIMAL(10, 2),
    ranki INT
);
DROP TABLE fresh_segments.interest_metrics;

CREATE TABLE fresh_segments.interest_metrics (
    month VARCHAR(20),           -- Should be text, not integer
    year INT,
    month_year VARCHAR(20),
    interest_id INT,
    composition VARCHAR(255),
    index_value DECIMAL(10, 2),
    ranki INT
);
INSERT INTO fresh_segments.interest_metrics 
(month, year, month_year, interest_id, composition, index_value, ranki) VALUES
('January', 2025, 'January-2025', 1, 'High Growth', 85.5, 1),
('January', 2025, 'January-2025', 2, 'Stable', 92.1, 2),
('January', 2025, 'January-2025', 5, 'Moderate', 78.4, 3);
ALTER TABLE fresh_segments.interest_metrics 
MODIFY month VARCHAR(20);
#5.Summarise the id values in the fresh_segments.interest_map by its total record count in this table
SELECT COUNT(id) AS total_records
FROM fresh_segments.interest_map;
#6.What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.
SELECT 
    im.*,  -- All columns from interest_metrics
    mp.interest_name,
    mp.interest_summary
FROM 
    fresh_segments.interest_metrics im
LEFT JOIN 
    fresh_segments.interest_map mp
ON 
    im.interest_id = mp.id
WHERE 
    im.interest_id = 21246;
    #7.Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?
    SELECT 
    im.*, 
    mp.interest_name, 
    mp.interest_summary, 
    mp.created_at,
    STR_TO_DATE(CONCAT('01-', im.month_year), '%d-%M-%Y') AS metric_date
FROM 
    fresh_segments.interest_metrics im
LEFT JOIN 
    fresh_segments.interest_map mp
    ON im.interest_id = mp.id
WHERE 
    STR_TO_DATE(CONCAT('01-', im.month_year), '%d-%M-%Y') < mp.created_at;
    #7.Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?

    DESCRIBE fresh_segments.interest_map;
    ALTER TABLE fresh_segments.interest_map
ADD COLUMN created_at DATE;

UPDATE fresh_segments.interest_map
SET created_at = '2024-12-01'
WHERE id = 21246;
#8.Which interests have been present in all month_year dates in our dataset?
-- Step 1: Create CTE for total month_years
WITH total_months AS (
    SELECT COUNT(DISTINCT month_year) AS total_count
    FROM fresh_segments.interest_metrics
),
-- Step 2: Count how many month_years each interest_id appears in
interest_months AS (
    SELECT interest_id, COUNT(DISTINCT month_year) AS interest_months_count
    FROM fresh_segments.interest_metrics
    GROUP BY interest_id
)

-- Step 3: Get interests that appear in all month_years
SELECT im.interest_id, mp.interest_name
FROM interest_months im
JOIN total_months tm 
  ON im.interest_months_count = tm.total_count
JOIN fresh_segments.interest_map mp 
  ON im.interest_id = mp.id;
  #9.Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?
  SELECT 
    total_months,
    record_count,
    @cumulative_sum := @cumulative_sum + record_count AS cumulative_sum,
    ROUND(@cumulative_sum * 100 / @total_records, 2) AS cumulative_percent
FROM (
    SELECT 
        imos.interest_id,
        COUNT(DISTINCT im.month_year) AS total_months,
        COUNT(*) AS record_count
    FROM fresh_segments.interest_metrics im
    JOIN (
        SELECT interest_id 
        FROM fresh_segments.interest_metrics
        GROUP BY interest_id
        HAVING COUNT(DISTINCT month_year) >= 14
    ) imos ON im.interest_id = imos.interest_id
    GROUP BY imos.interest_id
) AS interest_data
JOIN (
    SELECT @cumulative_sum := 0, 
           @total_records := (
               SELECT COUNT(*) 
               FROM fresh_segments.interest_metrics im
               JOIN (
                   SELECT interest_id 
                   FROM fresh_segments.interest_metrics
                   GROUP BY interest_id
                   HAVING COUNT(DISTINCT month_year) >= 14
               ) imos ON im.interest_id = imos.interest_id
           )
) vars
ORDER BY total_months;
#10.If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?
-- First: Find how many month_years each interest_id appears in
SELECT COUNT(*) AS records_to_remove
FROM fresh_segments.interest_metrics im
JOIN (
    SELECT interest_id, COUNT(DISTINCT month_year) AS total_months
    FROM fresh_segments.interest_metrics
    GROUP BY interest_id
    HAVING total_months < 17  -- Replace 17 with your actual cutoff value
) low_months
ON im.interest_id = low_months.interest_id;
#11.After removing these interests - how many unique interests are there for each month?
WITH valid_interests AS (
    SELECT interest_id
    FROM fresh_segments.interest_metrics
    GROUP BY interest_id
    HAVING COUNT(DISTINCT month_year) >= 17  -- replace 17 with your actual cutoff
)

-- Step 2: Count unique valid interests per month
SELECT 
    month_year,
    COUNT(DISTINCT im.interest_id) AS unique_valid_interests
FROM fresh_segments.interest_metrics im
JOIN valid_interests vi 
    ON im.interest_id = vi.interest_id
GROUP BY month_year
ORDER BY month_year;

