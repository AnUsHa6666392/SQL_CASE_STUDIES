CREATE DATABASE foodie_fi;
USE foodie_fi;
CREATE TABLE plans (
    plan_id INT PRIMARY KEY,
    plan_name VARCHAR(50),
    price DECIMAL(10, 2)
);
CREATE TABLE subscriptions (
    customer_id INT,
    plan_id INT,
    start_date DATE,
    FOREIGN KEY (plan_id) REFERENCES plans(plan_id)
);
#1.how many customer has foodie-fi ever had?
SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM subscriptions;
#2.What is the monthly distribution of trial plan start_data values for our dataset use the start of the month as the group  by value 
SELECT
    DATE_FORMAT(start_date, '%Y-%m-01') AS month_start,
    COUNT(*) AS trial_starts
FROM subscriptions s
JOIN plans p ON s.plan_id = p.plan_id
WHERE p.plan_name = 'Trial'
GROUP BY DATE_FORMAT(start_date, '%Y-%m-01')
ORDER BY month_start;
#3.What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name 
SELECT 
    p.plan_name,
    COUNT(*) AS plan_start_count
FROM subscriptions s
JOIN plans p ON s.plan_id = p.plan_id
WHERE s.start_date > '2020-12-31'
GROUP BY p.plan_name
ORDER BY plan_start_count DESC;
#4.What is the customer count and percentage of customers who have churned rounded to 1 decimal place 
WITH latest_plan AS (
    SELECT 
        customer_id,
        plan_id,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date DESC) AS rn
    FROM subscriptions
)
SELECT
    COUNT(CASE WHEN p.plan_name = 'Churn' THEN 1 END) AS churned_customers,
    COUNT(*) AS total_customers,
    ROUND(
        100.0 * COUNT(CASE WHEN p.plan_name = 'Churn' THEN 1 END) / COUNT(*),
        1
    ) AS churn_percentage
FROM latest_plan lp
JOIN plans p ON lp.plan_id = p.plan_id
WHERE lp.rn = 1;
#5.How  many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number? 

WITH ranked_plans AS (
    SELECT 
        customer_id,
        plan_id,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date) AS plan_order
    FROM subscriptions
),
trial_churn_customers AS (
    SELECT rp1.customer_id
    FROM ranked_plans rp1
    JOIN plans p1 ON rp1.plan_id = p1.plan_id
    JOIN ranked_plans rp2 ON rp1.customer_id = rp2.customer_id AND rp2.plan_order = 2
    JOIN plans p2 ON rp2.plan_id = p2.plan_id
    WHERE rp1.plan_order = 1
      AND p1.plan_name = 'Trial'
      AND p2.plan_name = 'Churn'
)

SELECT
    COUNT(*) AS churn_after_trial,
    (SELECT COUNT(DISTINCT customer_id) FROM subscriptions) AS total_customers,
    ROUND(
        100.0 * COUNT(*) / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions)
    ) AS churn_percentage
FROM trial_churn_customers;

#6.
WITH ranked_plans AS (
    SELECT 
        customer_id,
        plan_id,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date) AS plan_order
    FROM subscriptions
),
post_trial_customers AS (
    SELECT rp1.customer_id
    FROM ranked_plans rp1
    JOIN plans p1 ON rp1.plan_id = p1.plan_id
    JOIN ranked_plans rp2 ON rp1.customer_id = rp2.customer_id AND rp2.plan_order = 2
    JOIN plans p2 ON rp2.plan_id = p2.plan_id
    WHERE rp1.plan_order = 1
      AND p1.plan_name = 'Trial'
      AND p2.plan_name <> 'Churn'  -- continued to any plan other than churn
)

SELECT
    COUNT(*) AS continued_after_trial,
    (SELECT COUNT(DISTINCT customer_id) FROM subscriptions) AS total_customers,
    ROUND(
        100.0 * COUNT(*) / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions),
        1
    ) AS continuation_percentage
FROM post_trial_customers;
#7.What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31? Slove this
WITH ranked_plans AS (
    SELECT 
        customer_id,
        plan_id,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date) AS plan_order
    FROM subscriptions
),
post_trial_customers AS (
    SELECT rp1.customer_id
    FROM ranked_plans rp1
    JOIN plans p1 ON rp1.plan_id = p1.plan_id
    JOIN ranked_plans rp2 ON rp1.customer_id = rp2.customer_id AND rp2.plan_order = 2
    JOIN plans p2 ON rp2.plan_id = p2.plan_id
    WHERE rp1.plan_order = 1
      AND p1.plan_name = 'Trial'
      AND p2.plan_name <> 'Churn'  -- continued to any plan other than churn
)

SELECT
    COUNT(*) AS continued_after_trial,
    (SELECT COUNT(DISTINCT customer_id) FROM subscriptions) AS total_customers,
    ROUND(
        100.0 * COUNT(*) / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions),
        1
    ) AS continuation_percentage
FROM post_trial_customers;
WITH latest_plan_before_2021 AS (
    SELECT 
        customer_id,
        plan_id,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id 
            ORDER BY start_date DESC
        ) AS rn
    FROM subscriptions
    WHERE start_date <= '2020-12-31'
)

SELECT 
    p.plan_name,
    COUNT(lp.customer_id) AS customer_count,
    ROUND(
        100.0 * COUNT(lp.customer_id) / 
        (SELECT COUNT(DISTINCT customer_id) FROM latest_plan_before_2021 WHERE rn = 1), 
        1
    ) AS percentage
FROM latest_plan_before_2021 lp
JOIN plans p ON lp.plan_id = p.plan_id
WHERE lp.rn = 1
GROUP BY p.plan_name
ORDER BY customer_count DESC;
#8.HOW MANY CUSTOMERS HAVE UPGRADED TO AN ANNUAL PLAN IN 2020?
SELECT 
    COUNT(DISTINCT customer_id) AS annual_upgrade_2020
FROM subscriptions s
JOIN plans p ON s.plan_id = p.plan_id
WHERE p.plan_name = 'Annual'
  AND YEAR(s.start_date) = 2020;
  #9.How many days on average does it take for a customer to an annual plan from the day they join foodie-fi?
  WITH customer_join_date AS (
    SELECT 
        customer_id,
        MIN(start_date) AS join_date
    FROM subscriptions
    GROUP BY customer_id
),
customer_annual_date AS (
    SELECT 
        s.customer_id,
        s.start_date AS annual_date
    FROM subscriptions s
    JOIN plans p ON s.plan_id = p.plan_id
    WHERE p.plan_name = 'Annual'
)
SELECT 
    ROUND(AVG(DATEDIFF(ca.annual_date, cj.join_date)), 1) AS avg_days_to_annual
FROM customer_annual_date ca
JOIN customer_join_date cj 
  ON ca.customer_id = cj.customer_id;
#10.Can you further breakdown  this average value into 30 day periods (I.e. 0-30 days, 31-60 days etc) 
WITH customer_join_date AS (
    SELECT 
        customer_id,
        MIN(start_date) AS join_date
    FROM subscriptions
    GROUP BY customer_id
),
customer_annual_date AS (
    SELECT 
        s.customer_id,
        s.start_date AS annual_date
    FROM subscriptions s
    JOIN plans p ON s.plan_id = p.plan_id
    WHERE p.plan_name = 'Annual'
),
days_to_annual AS (
    SELECT 
        ca.customer_id,
        DATEDIFF(ca.annual_date, cj.join_date) AS days_diff
    FROM customer_annual_date ca
    JOIN customer_join_date cj 
      ON ca.customer_id = cj.customer_id
),
bucketed_diff AS (
    SELECT 
        customer_id,
        days_diff,
        CONCAT(FLOOR(days_diff / 30) * 30 + 1, '-', (FLOOR(days_diff / 30) + 1) * 30) AS day_bucket
    FROM days_to_annual
)
SELECT 
    day_bucket,
    COUNT(*) AS customer_count
FROM bucketed_diff
GROUP BY day_bucket
ORDER BY MIN(days_diff);
#11.How many customers downgraded from a pro monthly to a basic monthly plan in 2020? 
WITH customer_plan_sequence AS (
    SELECT 
        s.customer_id,
        p.plan_name,
        s.start_date,
        ROW_NUMBER() OVER (
            PARTITION BY s.customer_id ORDER BY s.start_date
        ) AS plan_order
    FROM subscriptions s
    JOIN plans p ON s.plan_id = p.plan_id
),
downgrades AS (
    SELECT 
        curr.customer_id,
        prev.plan_name AS previous_plan,
        curr.plan_name AS current_plan,
        curr.start_date
    FROM customer_plan_sequence curr
    JOIN customer_plan_sequence prev 
      ON curr.customer_id = prev.customer_id
     AND curr.plan_order = prev.plan_order + 1
    WHERE prev.plan_name = 'Pro Monthly'
      AND curr.plan_name = 'Basic Monthly'
      AND YEAR(curr.start_date) = 2020
)

SELECT 
    COUNT(DISTINCT customer_id) AS downgraded_customers
FROM downgrades;



