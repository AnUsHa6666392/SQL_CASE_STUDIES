CREATE TABLE regions (
    region_id INT PRIMARY KEY,
    region_name VARCHAR(100)
);
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    region_id INT,
    node_id INT,
    start_date DATE,
    end_date DATE,
    FOREIGN KEY (region_id) REFERENCES regions(region_id)
);
CREATE TABLE transactions (
    customer_id INT,
    txn_date DATE,
    txn_type VARCHAR(20),  -- e.g., 'credit' or 'debit'
    txn_amount DECIMAL(10, 2),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
#1.How many unique nodes are there on the Data Bank system?
SELECT COUNT(DISTINCT node_id) AS unique_nodes
FROM customers;
#2.What is the number of nodes per region?
SELECT 
    r.region_name,
    COUNT(DISTINCT c.node_id) AS num_nodes
FROM 
    customers c
JOIN 
    regions r ON c.region_id = r.region_id
GROUP BY 
    r.region_name
ORDER BY 
    num_nodes DESC;
    #3.How many customers are allocated to each region?
    SELECT 
    r.region_name,
    COUNT(c.customer_id) AS num_customers
FROM 
    customers c
JOIN 
    regions r ON c.region_id = r.region_id
GROUP BY 
    r.region_name
ORDER BY 
    num_customers DESC;
    #4.How many days on average are customers reallocated to a different node?
    WITH allocation_durations AS (
    SELECT 
        customer_id,
        node_id,
        (end_date - start_date) AS duration_days
    FROM 
        customers
),
multi_node_customers AS (
    SELECT customer_id
    FROM customers
    GROUP BY customer_id
    HAVING COUNT(DISTINCT node_id) > 1
)
SELECT 
    AVG(duration_days) AS avg_days_reallocated
FROM 
    allocation_durations
WHERE 
    customer_id IN (SELECT customer_id FROM multi_node_customers);
   #5.What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
   WITH allocation_durations AS (
    SELECT 
        c.customer_id,
        c.node_id,
        c.region_id,
        DATEDIFF(c.end_date, c.start_date) AS duration_days
    FROM customers c
),
multi_node_customers AS (
    SELECT customer_id
    FROM customers
    GROUP BY customer_id
    HAVING COUNT(DISTINCT node_id) > 1
),
reallocation_durations AS (
    SELECT 
        a.region_id,
        a.duration_days
    FROM allocation_durations a
    WHERE a.customer_id IN (SELECT customer_id FROM multi_node_customers)
),
ranked AS (
    SELECT 
        r.region_name,
        rd.duration_days,
        NTILE(100) OVER (PARTITION BY r.region_name ORDER BY rd.duration_days) AS percentile_rank
    FROM reallocation_durations rd
    JOIN regions r ON rd.region_id = r.region_id
)
SELECT 
    region_name,
    MAX(CASE WHEN percentile_rank = 50 THEN duration_days END) AS median_days,
    MAX(CASE WHEN percentile_rank = 80 THEN duration_days END) AS p80_days,
    MAX(CASE WHEN percentile_rank = 95 THEN duration_days END) AS p95_days
FROM ranked
GROUP BY region_name
ORDER BY region_name;
#6.What is the unique count and total amount for each transaction type?
SELECT 
    txn_type,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(txn_amount) AS total_amount
FROM 
    transactions
GROUP BY 
    txn_type
ORDER BY 
    total_amount DESC;
#7.
WITH customer_deposits AS (
    SELECT 
        customer_id,
        COUNT(*) AS deposit_count,
        SUM(txn_amount) AS deposit_amount
    FROM 
        transactions
    WHERE 
        txn_type = 'deposit'
    GROUP BY 
        customer_id
)

SELECT 
    AVG(deposit_count) AS avg_deposit_count,
    AVG(deposit_amount) AS avg_deposit_amount
FROM 
    customer_deposits;
  #8.For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
  WITH monthly_txns AS (
    SELECT 
        customer_id,
        DATE_FORMAT(txn_date, '%Y-%m') AS txn_month,
        SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) AS deposit_count,
        SUM(CASE WHEN txn_type = 'purchase' THEN 1 ELSE 0 END) AS purchase_count,
        SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END) AS withdrawal_count
    FROM 
        transactions
    GROUP BY 
        customer_id, DATE_FORMAT(txn_date, '%Y-%m')
)

SELECT 
    txn_month,
    COUNT(*) AS qualified_customers
FROM 
    monthly_txns
WHERE 
    deposit_count > 1
    AND (purchase_count >= 1 OR withdrawal_count >= 1)
GROUP BY 
    txn_month
ORDER BY 
    txn_month;
    #9.
    WITH monthly_txns AS (
    SELECT 
        customer_id,
        DATE_FORMAT(txn_date, '%Y-%m') AS txn_month,
        SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) AS deposit_count,
        SUM(CASE WHEN txn_type = 'purchase' THEN 1 ELSE 0 END) AS purchase_count,
        SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END) AS withdrawal_count
    FROM 
        transactions
    GROUP BY 
        customer_id, DATE_FORMAT(txn_date, '%Y-%m')
)

SELECT 
    txn_month,
    COUNT(*) AS qualified_customers
FROM 
    monthly_txns
WHERE 
    deposit_count > 1
    AND (purchase_count >= 1 OR withdrawal_count >= 1)
GROUP BY 
    txn_month
ORDER BY 
    txn_month;
#9.What is the closing balance for each customer at the end of the month?
WITH txn_with_sign AS (
    SELECT 
        customer_id,
        txn_date,
        DATE_FORMAT(txn_date, '%Y-%m') AS txn_month,
        CASE 
            WHEN txn_type = 'deposit' THEN txn_amount
            WHEN txn_type IN ('withdrawal', 'purchase') THEN -txn_amount
            ELSE 0
        END AS signed_amount
    FROM 
        transactions
),

monthly_txn_totals AS (
    SELECT 
        customer_id,
        txn_month,
        SUM(signed_amount) AS net_amount
    FROM 
        txn_with_sign
    GROUP BY 
        customer_id, txn_month
),

running_balance AS (
    SELECT 
        customer_id,
        txn_month,
        SUM(net_amount) OVER (
            PARTITION BY customer_id
            ORDER BY txn_month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS closing_balance
    FROM 
        monthly_txn_totals
)

SELECT 
    customer_id,
    txn_month,
    closing_balance
FROM 
    running_balance
ORDER BY 
    customer_id, txn_month;
    #10.What is the percentage of customers who increase their closing balance by more than 5%?
 WITH txn_with_sign AS (
    SELECT 
        customer_id,
        txn_date,
        DATE_FORMAT(txn_date, '%Y-%m') AS txn_month,
        CASE 
            WHEN txn_type = 'deposit' THEN txn_amount
            WHEN txn_type IN ('withdrawal', 'purchase') THEN -txn_amount
            ELSE 0
        END AS signed_amount
    FROM transactions
),

monthly_totals AS (
    SELECT 
        customer_id,
        txn_month,
        SUM(signed_amount) AS net_amount
    FROM txn_with_sign
    GROUP BY customer_id, txn_month
),

running_balance AS (
    SELECT 
        customer_id,
        txn_month,
        SUM(net_amount) OVER (
            PARTITION BY customer_id 
            ORDER BY txn_month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS closing_balance
    FROM monthly_totals
),

balance_change AS (
    SELECT 
        customer_id,
        txn_month,
        closing_balance,
        LAG(closing_balance) OVER (
            PARTITION BY customer_id ORDER BY txn_month
        ) AS prev_balance
    FROM running_balance
),

improved_customers AS (
    SELECT DISTINCT customer_id
    FROM balance_change
    WHERE 
        prev_balance IS NOT NULL
        AND closing_balance > prev_balance * 1.05
)

SELECT 
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(DISTINCT customer_id) FROM transactions), 2) AS percent_customers_improved
FROM improved_customers;   

  
    