CREATE TABLE pizza_names (
    pizza_id INTEGER PRIMARY KEY,
    pizza_name TEXT
);
CREATE TABLE pizza_toppings (
    topping_id INTEGER PRIMARY KEY,
    topping_name TEXT
);
CREATE TABLE pizza_recipes (
    pizza_id INTEGER,
    toppings TEXT,
    FOREIGN KEY (pizza_id) REFERENCES pizza_names(pizza_id)
);
CREATE TABLE customer_orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER,
    pizza_id INTEGER,
    exclusions TEXT,
    extras TEXT,
    order_time DATETIME,
    FOREIGN KEY (pizza_id) REFERENCES pizza_names(pizza_id)
);
CREATE TABLE runner_orders (
    order_id INTEGER,
    runner_id INTEGER,
    pickup_time DATETIME,
    distance TEXT,
    duration TEXT,
    cancellation TEXT,
    FOREIGN KEY (order_id) REFERENCES customer_orders(order_id),
    FOREIGN KEY (runner_id) REFERENCES runners(runner_id)
);
#1.How many pizzas were ordered?
SELECT COUNT(*) AS total_pizzas_ordered
FROM customer_orders;
#2.How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS unique_customer_orders
FROM customer_orders;
#3.How many successful orders were delivered by each runner?
SELECT 
    runner_id,
    COUNT(*) AS successful_deliveries
FROM 
    runner_orders
WHERE 
    cancellation IS NULL 
    OR TRIM(cancellation) = ''
GROUP BY 
    runner_id;
#4.How many of each type of pizza was delivered?
SELECT 
    pn.pizza_name,
    COUNT(*) AS pizzas_delivered
FROM 
    customer_orders co
JOIN 
    runner_orders ro ON co.order_id = ro.order_id
JOIN 
    pizza_names pn ON co.pizza_id = pn.pizza_id
WHERE 
    ro.cancellation IS NULL 
    OR TRIM(ro.cancellation) = ''
GROUP BY 
    pn.pizza_name;
    #5. How many Vegetarian and Meatlovers were ordered by each customer?
    SELECT 
    customer_id,
    pizza_name,
    COUNT(*) AS total_orders
FROM 
    customer_orders co
JOIN 
    pizza_names pn ON co.pizza_id = pn.pizza_id
WHERE 
    pizza_name IN ('Meatlovers', 'Vegetarian')
GROUP BY 
    customer_id, pizza_name
ORDER BY 
    customer_id, pizza_name;
    #6.What was the maximum number of pizzas delivered in a single order?
    SELECT 
    MAX(pizza_count) AS max_pizzas_in_single_order
FROM (
    SELECT 
        co.order_id,
        COUNT(*) AS pizza_count
    FROM 
        customer_orders co
    JOIN 
        runner_orders ro ON co.order_id = ro.order_id
    WHERE 
        ro.cancellation IS NULL 
        OR TRIM(ro.cancellation) = ''
    GROUP BY 
        co.order_id
) AS order_counts;
#7.For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT 
    co.customer_id,
    SUM(CASE 
            WHEN (TRIM(co.exclusions) IS NOT NULL AND TRIM(co.exclusions) <> '') 
              OR (TRIM(co.extras) IS NOT NULL AND TRIM(co.extras) <> '') 
            THEN 1 ELSE 0 
        END) AS pizzas_with_changes,
    SUM(CASE 
            WHEN (TRIM(co.exclusions) IS NULL OR TRIM(co.exclusions) = '') 
             AND (TRIM(co.extras) IS NULL OR TRIM(co.extras) = '') 
            THEN 1 ELSE 0 
        END) AS pizzas_without_changes
FROM 
    customer_orders co
JOIN 
    runner_orders ro ON co.order_id = ro.order_id
WHERE 
    ro.cancellation IS NULL 
    OR TRIM(ro.cancellation) = ''
GROUP BY 
    co.customer_id
ORDER BY 
    co.customer_id;
    #8.How many pizzas were delivered that had both exclusions and extras?
    SELECT 
    COUNT(*) AS pizzas_with_exclusions_and_extras
FROM 
    customer_orders co
JOIN 
    runner_orders ro ON co.order_id = ro.order_id
WHERE 
    (ro.cancellation IS NULL OR TRIM(ro.cancellation) = '')
    AND (TRIM(co.exclusions) IS NOT NULL AND TRIM(co.exclusions) <> '')
    AND (TRIM(co.extras) IS NOT NULL AND TRIM(co.extras) <> '');
    #9.What was the total volume of pizzas ordered for each hour of the day?
    SELECT 
    HOUR(order_time) AS order_hour,
    COUNT(*) AS total_pizzas_ordered
FROM 
    customer_orders
GROUP BY 
    order_hour
ORDER BY 
    order_hour;
    #10.What was the volume of orders for each day of the week?
    SELECT 
    DAYNAME(order_time) AS day_of_week,
    COUNT(*) AS total_orders
FROM 
    customer_orders
GROUP BY 
    day_of_week
ORDER BY 
    FIELD(day_of_week, 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday');
    #11.How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
    SELECT 
    DATE_ADD('2021-01-01', INTERVAL FLOOR(DATEDIFF(registration_date, '2021-01-01') / 7) * 7 DAY) AS week_start,
    COUNT(*) AS runners_signed_up
FROM 
    runners
GROUP BY 
    week_start
ORDER BY 
    week_start;
    #12.What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
    SELECT 
    runner_id,
    AVG(CAST(REPLACE(duration, 'minutes', '') AS UNSIGNED)) AS avg_pickup_time_minutes
FROM 
    runner_orders
WHERE 
    cancellation IS NULL OR TRIM(cancellation) = ''
GROUP BY 
    runner_id
ORDER BY 
    runner_id;
    #13.Is there any relationship between the number of pizzas and how long the order takes to prepare?
    WITH pizza_counts AS (
    SELECT 
        order_id,
        COUNT(*) AS num_pizzas
    FROM 
        customer_orders
    GROUP BY 
        order_id
),
cleaned_orders AS (
    SELECT 
        ro.order_id,
        pc.num_pizzas,
        CAST(REPLACE(ro.duration, 'minutes', '') AS FLOAT) AS duration_minutes
    FROM 
        runner_orders ro
    JOIN 
        pizza_counts pc ON ro.order_id = pc.order_id
    WHERE 
        ro.cancellation IS NULL OR TRIM(ro.cancellation) = ''
)
SELECT 
    num_pizzas,
    COUNT(*) AS num_orders,
    ROUND(AVG(duration_minutes), 2) AS avg_duration_minutes
FROM 
    cleaned_orders
GROUP BY 
    num_pizzas
ORDER BY 
    num_pizzas;
    #14.What was the average distance travelled for each customer?
    SELECT 
    co.customer_id,
    ROUND(AVG(CAST(REPLACE(ro.distance, 'km', '') AS FLOAT)), 2) AS avg_distance_km
FROM 
    customer_orders co
JOIN 
    runner_orders ro ON co.order_id = ro.order_id
WHERE 
    ro.cancellation IS NULL OR TRIM(ro.cancellation) = ''
GROUP BY 
    co.customer_id
ORDER BY 
    co.customer_id;
    #15.What was the difference between the longest and shortest delivery times for all orders?
    SELECT 
    MAX(clean_duration) - MIN(clean_duration) AS delivery_time_difference_minutes
FROM (
    SELECT 
        CAST(REPLACE(duration, 'minutes', '') AS FLOAT) AS clean_duration
    FROM 
        runner_orders
    WHERE 
        cancellation IS NULL OR TRIM(cancellation) = ''
) AS cleaned_data;
#16.What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT 
    runner_id,
    order_id,
    ROUND(
        CAST(REPLACE(distance, 'km', '') AS FLOAT) / 
        (CAST(REPLACE(duration, 'minutes', '') AS FLOAT) / 60.0),
        2
    ) AS avg_speed_kmh
FROM 
    runner_orders
WHERE 
    cancellation IS NULL OR TRIM(cancellation) = ''
ORDER BY 
    runner_id, order_id;
    #17.What is the successful delivery percentage for each runner?
    SELECT 
    runner_id,
    COUNT(*) AS total_orders,
    SUM(CASE 
            WHEN cancellation IS NULL OR TRIM(cancellation) = '' THEN 1 
            ELSE 0 
        END) AS successful_deliveries,
    ROUND(
        100.0 * SUM(CASE 
                        WHEN cancellation IS NULL OR TRIM(cancellation) = '' THEN 1 
                        ELSE 0 
                   END) / COUNT(*),
        2
    ) AS success_percentage
FROM 
    runner_orders
GROUP BY 
    runner_id
ORDER BY 
    runner_id;
  