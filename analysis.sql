/*
This query calculates the total number of unique users for each step 
of the purchase funnel (view, cart, purchase).
*/

-- Step 1: Get all unique users who performed each of the key actions
WITH user_actions AS (
    SELECT 
        user_id,
        MAX(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END) AS did_view,
        MAX(CASE WHEN event_type = 'cart' THEN 1 ELSE 0 END) AS did_cart,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS did_purchase
    FROM events
    GROUP BY user_id
),

-- Step 2: Define the funnel steps and count users who *entered* each step
-- Note: This is a "waterfall" or "dependent" funnel.
funnel_steps AS (
	SELECT 
        1 AS step_order, 
        '1. View Product' AS step_name,
        COUNT(user_id) AS user_count
    FROM user_actions
    WHERE did_view = 1

    UNION ALL

    SELECT 
        2 AS step_order, 
        '2. Add to Cart' AS step_name,
        COUNT(user_id) AS user_count
    FROM user_actions
    WHERE did_view = 1 AND did_cart = 1 -- Must have viewed AND carted

    UNION ALL

    SELECT 
        3 AS step_order, 
        '3. Purchase' AS step_name,
        COUNT(user_id) AS user_count
    FROM user_actions
    WHERE did_view = 1 AND did_cart = 1 AND did_purchase = 1 -- Must have done all three	
)

-- Step 3: Final report with step-to-step conversion
SELECT
	step_name,
    user_count,
    -- Calculate percentage of previous step
	(user_count * 1.0 / LAG(user_count, 1, user_count) OVER (ORDER BY step_order)) * 100 AS step_to_step_conversion_pct,
	-- Calculate percentage of the top of the funnel (overall)
    (user_count * 1.0 / FIRST_VALUE(user_count) OVER (ORDER BY step_order)) * 100 AS overall_conversion_pct
FROM funnel_steps
ORDER BY step_order;



--- By Category
-- Step 1: Prepare user actions per category
WITH user_actions AS (
    SELECT 
        category_id,  
        user_id,
        MAX(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END) AS did_view,
        MAX(CASE WHEN event_type = 'cart' THEN 1 ELSE 0 END) AS did_cart,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS did_purchase
    FROM events
    GROUP BY category_id, user_id
),

-- Step 2: Funnel steps per category
funnel_steps AS (
    -- Step 1: Viewed product
    SELECT category_id, 1 AS step_order, '1. View Product' AS step_name, COUNT(user_id) AS user_count
    FROM user_actions
    WHERE did_view = 1
    GROUP BY category_id

    UNION ALL

    -- Step 2: Added to cart
    SELECT category_id, 2, '2. Add to Cart', COUNT(user_id)
    FROM user_actions
    WHERE did_view = 1 AND did_cart = 1
    GROUP BY category_id

    UNION ALL

    -- Step 3: Purchased
    SELECT category_id, 3, '3. Purchase', COUNT(user_id)
    FROM user_actions
    WHERE did_view = 1 AND did_cart = 1 AND did_purchase = 1
    GROUP BY category_id
)

-- Step 3: Final report per category
SELECT 
    category_id,
    step_name,
    user_count,
    -- Step-to-step conversion per category
    (user_count * 1.0 / LAG(user_count, 1, user_count) OVER (PARTITION BY category_id ORDER BY step_order)) * 100 AS step_to_step_conversion_pct,
    -- Overall conversion from top of funnel per category
    (user_count * 1.0 / FIRST_VALUE(user_count) OVER (PARTITION BY category_id ORDER BY step_order)) * 100 AS overall_conversion_pct
FROM funnel_steps
ORDER BY category_id, step_order;


--- Checking anomalies
SELECT DISTINCT
    product_id,
    user_id
FROM events e
WHERE event_type = 'remove_from_cart'
AND NOT EXISTS (
    SELECT 1
    FROM events e2
    WHERE e2.user_id = e.user_id
      AND e2.product_id = e.product_id
      AND e2.event_type = 'cart'
);




/*
This query calculates a "Rejection Rate" by product.
It only looks at users who *did* add a product to their cart
and then checks what percentage of them *also* removed it.
*/

-- Step 1: Get all user/product pairs for 'cart' or 'remove'
WITH user_product_events AS (
    SELECT
        user_id,
        product_id,
        MAX(CASE WHEN event_type = 'cart' THEN 1 ELSE 0 END) AS did_cart,
        MAX(CASE WHEN event_type = 'remove_from_cart' THEN 1 ELSE 0 END) AS did_remove
    FROM events
    WHERE event_type IN ('cart', 'remove_from_cart')
    GROUP BY user_id, product_id
),

-- Step 2: Aggregate by product
product_rejection_stats AS (
    SELECT
        product_id,
        -- Count distinct users who added this product
        SUM(did_cart) AS total_users_who_added,
        
        -- Count distinct users who BOTH added AND removed this product
        SUM(CASE WHEN did_cart = 1 AND did_remove = 1 THEN 1 ELSE 0 END) AS users_who_added_and_removed
        
    FROM user_product_events
    GROUP BY product_id
)

-- Step 3: Calculate the final rejection rate
SELECT
    p.product_id,
    p.total_users_who_added,
    p.users_who_added_and_removed,
    (p.users_who_added_and_removed * 1.0 / p.total_users_who_added) * 100 AS rejection_rate_pct,
    -- (Optional) Join with a 'products' table or brand from events
    MAX(e.brand) AS brand,
    MAX(e.category_code) AS category
FROM product_rejection_stats p
LEFT JOIN events e ON p.product_id = e.product_id
WHERE p.total_users_who_added > 50 -- Only show products with significant data
GROUP BY p.product_id, p.total_users_who_added, p.users_who_added_and_removed
ORDER BY rejection_rate_pct DESC
LIMIT 20;


-- conversion rate by category code
SELECT
    e.category_code,
    COUNT(DISTINCT CASE WHEN e.event_type = 'view' THEN e.user_id END) AS total_viewers,
    COUNT(DISTINCT CASE WHEN e.event_type = 'cart' THEN e.user_id END) AS total_carters,
    COUNT(DISTINCT CASE WHEN e.event_type = 'purchase' THEN e.user_id END) AS total_purchasers,
    
    -- Calculate overall conversion rate per category
    (COUNT(DISTINCT CASE WHEN e.event_type = 'purchase' THEN e.user_id END) * 1.0 / 
     COUNT(DISTINCT CASE WHEN e.event_type = 'view' THEN e.user_id END)) * 100 AS overall_conversion_rate
FROM events e
GROUP BY e.category_code
ORDER BY overall_conversion_rate DESC;



--- Revenue by month
SELECT
    DATE_TRUNC('month', event_time) AS sales_day,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_session END) AS total_purchases,
    SUM(CASE WHEN event_type = 'purchase' THEN price ELSE 0 END) AS total_revenue
FROM events
WHERE event_type = 'purchase'
GROUP BY sales_day
ORDER BY sales_day;


--- Revenue by day
SELECT
    DATE_TRUNC('day', event_time) AS sales_day,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_session END) AS total_purchases,
    SUM(CASE WHEN event_type = 'purchase' THEN price ELSE 0 END) AS total_revenue
FROM events
WHERE event_type = 'purchase'
GROUP BY sales_day
ORDER BY sales_day;


---
WITH session_stats AS (
    SELECT
        user_session,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS did_purchase,
        COUNT(event_time) AS total_events_in_session,
        COUNT(DISTINCT product_id) AS products_viewed,
        (MAX(event_time) - MIN(event_time)) AS session_duration
    FROM events
    GROUP BY user_session
)
SELECT
    did_purchase,
    AVG(total_events_in_session) AS avg_events,
    AVG(products_viewed) AS avg_products_viewed,
    AVG(EXTRACT(EPOCH FROM session_duration)) AS avg_session_duration_seconds
FROM session_stats
GROUP BY did_purchase;

