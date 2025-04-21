CREATE TABLE data_bank (
    week_data DATE,
    region VARCHAR(50),
    platform VARCHAR(50),
    segment VARCHAR(50),
    customer_type VARCHAR(50),
    transacti INT,
    age_band VARCHAR(50),
    demographic VARCHAR(50)
);
#1.What day of the week is used for each week_date value?
SELECT week_data, DAYNAME(week_data) AS day_of_week
FROM data_bank;
#2.What range of week numbers are missing from the dataset?
CREATE TABLE numbers (
  number INT
);


INSERT INTO numbers (number)
SELECT a.N + b.N * 10 + 1 AS number
FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 
      UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
      UNION ALL SELECT 8 UNION ALL SELECT 9) a,
     (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 
      UNION ALL SELECT 4) b
WHERE a.N + b.N * 10 < 53;
SELECT n.number AS week_number
FROM numbers n
LEFT JOIN (
    SELECT DISTINCT WEEK(week_data) AS week_number
    FROM data_bank
) w ON n.number = w.week_number
WHERE w.week_number IS NULL
AND n.number BETWEEN 1 AND 53
ORDER BY n.number;
#3.How many total transactions were there for each year in the dataset?
SELECT 
    YEAR(week_data) AS year,
    SUM(transacti) AS total_transactions
FROM 
    data_bank
GROUP BY 
    YEAR(week_data)
ORDER BY 
    year;
    #4.What is the total sales for each region for each month?
    SELECT 
    region,
    YEAR(week_data) AS year,
    MONTH(week_data) AS month,
    SUM(transacti) AS total_sales
FROM 
    data_bank
GROUP BY 
    region, YEAR(week_data), MONTH(week_data)
ORDER BY 
    region, year, month;
    #5.What is the total count of transactions for each platform
    SELECT 
    platform,
    SUM(transacti) AS total_transactions
FROM 
    data_bank
GROUP BY 
    platform
ORDER BY 
    total_transactions DESC;
    #6.What is the percentage of sales for Retail vs Shopify for each month?
    WITH monthly_sales AS (
    SELECT 
        YEAR(week_data) AS year,
        MONTH(week_data) AS month,
        platform,
        SUM(transacti) AS total_sales
    FROM 
        data_bank
    WHERE platform IN ('Retail', 'Shopify')
    GROUP BY 
        YEAR(week_data), MONTH(week_data), platform
),
monthly_totals AS (
    SELECT 
        year,
        month,
        SUM(total_sales) AS month_total
    FROM 
        monthly_sales
    GROUP BY 
        year, month
)

SELECT 
    ms.year,
    ms.month,
    ms.platform,
    ms.total_sales,
    ROUND((ms.total_sales / mt.month_total) * 100, 2) AS sales_percentage
FROM 
    monthly_sales ms
JOIN 
    monthly_totals mt 
ON 
    ms.year = mt.year AND ms.month = mt.month
ORDER BY 
    ms.year, ms.month, ms.platform;
#7.What is the percentage of sales by demographic for each year in the dataset?
WITH yearly_sales AS (
    SELECT 
        YEAR(week_data) AS year,
        demographic,
        SUM(transacti) AS total_sales
    FROM 
        data_bank
    GROUP BY 
        YEAR(week_data), demographic
),
year_totals AS (
    SELECT 
        year,
        SUM(total_sales) AS year_total
    FROM 
        yearly_sales
    GROUP BY 
        year
)

SELECT 
    ys.year,
    ys.demographic,
    ys.total_sales,
    ROUND((ys.total_sales / yt.year_total) * 100, 2) AS sales_percentage
FROM 
    yearly_sales ys
JOIN 
    year_totals yt 
ON 
    ys.year = yt.year
ORDER BY 
    ys.year, ys.demographic;
#8.Which age_band and demographic values contribute the most to Retail sales?
DESCRIBE Data_Bank;
SELECT age_band, demographic, 
SUM(transacti) AS total_retail_sales
FROM Data_Bank
WHERE segment = 'Retail'
GROUP BY age_band, demographic
ORDER BY total_retail_sales DESC;
#10.Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
SELECT 
    YEAR(week_data) AS year,
    segment,
    AVG(transacti) AS avg_transaction
FROM Data_Bank
WHERE segment IN ('Retail', 'Shopify')
GROUP BY YEAR(week_data), segment
ORDER BY year, segment;
#11.What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
SELECT
    CASE
        WHEN week_data BETWEEN '2020-05-18' AND '2020-06-14' THEN 'Before'
        WHEN week_data BETWEEN '2020-06-15' AND '2020-07-12' THEN 'After'
    END AS period,
    SUM(transacti) AS total_sales
FROM Data_Bank
WHERE week_data BETWEEN '2020-05-18' AND '2020-07-12'
GROUP BY period;
WITH sales_summary AS (
    SELECT
        CASE
            WHEN week_data BETWEEN '2020-05-18' AND '2020-06-14' THEN 'Before'
            WHEN week_data BETWEEN '2020-06-15' AND '2020-07-12' THEN 'After'
        END AS period,
        SUM(transacti) AS total_sales
    FROM Data_Bank
    WHERE week_data BETWEEN '2020-05-18' AND '2020-07-12'
    GROUP BY period
),
calc AS (
    SELECT
        MAX(CASE WHEN period = 'Before' THEN total_sales END) AS sales_before,
        MAX(CASE WHEN period = 'After' THEN total_sales END) AS sales_after
    FROM sales_summary
)
SELECT
    sales_before,
    sales_after,
    (sales_after - sales_before) AS absolute_change,
    ROUND(((sales_after - sales_before) / sales_before) * 100, 2) AS percent_change
FROM calc;
#12.What about the entire 12 weeks before and after?
SELECT
    CASE
        WHEN week_data BETWEEN '2020-03-23' AND '2020-06-14' THEN 'Before'
        WHEN week_data BETWEEN '2020-06-15' AND '2020-09-06' THEN 'After'
    END AS period,
    SUM(transacti) AS total_sales
FROM Data_Bank
WHERE week_data BETWEEN '2020-03-23' AND '2020-09-06'
GROUP BY period;
WITH sales_summary AS (
    SELECT
        CASE
            WHEN week_data BETWEEN '2020-03-23' AND '2020-06-14' THEN 'Before'
            WHEN week_data BETWEEN '2020-06-15' AND '2020-09-06' THEN 'After'
        END AS period,
        SUM(transacti) AS total_sales
    FROM Data_Bank
    WHERE week_data BETWEEN '2020-03-23' AND '2020-09-06'
    GROUP BY period
),
calc AS (
    SELECT
        MAX(CASE WHEN period = 'Before' THEN total_sales END) AS sales_before,
        MAX(CASE WHEN period = 'After' THEN total_sales END) AS sales_after
    FROM sales_summary
)
SELECT
    sales_before,
    sales_after,
    (sales_after - sales_before) AS absolute_change,
    ROUND(((sales_after - sales_before) / sales_before) * 100, 2) AS percent_change
FROM calc;
#13.How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
SELECT
    CASE 
        WHEN week_data BETWEEN '2018-03-26' AND '2018-06-17' THEN 'Before'
        WHEN week_data BETWEEN '2018-06-18' AND '2018-09-09' THEN 'After'
        WHEN week_data BETWEEN '2019-03-25' AND '2019-06-16' THEN 'Before'
        WHEN week_data BETWEEN '2019-06-17' AND '2019-09-08' THEN 'After'
        WHEN week_data BETWEEN '2020-03-23' AND '2020-06-14' THEN 'Before'
        WHEN week_data BETWEEN '2020-06-15' AND '2020-09-06' THEN 'After'
    END AS period,
    YEAR(week_data) AS year,
    SUM(transacti) AS total_sales
FROM Data_Bank
WHERE week_data BETWEEN '2018-03-26' AND '2020-09-06'
GROUP BY year, period
ORDER BY year, period;

