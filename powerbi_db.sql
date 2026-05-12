DROP TABLE orders;

CREATE TABLE orders (
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    order_status VARCHAR(50),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);
DROP TABLE payments;
CREATE TABLE payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(50),
    payment_installments INT,
    payment_value FLOAT
);

DROP TABLE customers;
CREATE TABLE customers (
    customer_id VARCHAR(50),
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state VARCHAR(10)
);
COPY orders
FROM 'C:\csv\orders.csv'
DELIMITER ','
CSV HEADER;
SELECT COUNT(*) FROM orders;
COPY payments
FROM 'C:\csv\order_payments.csv'
DELIMITER ','
CSV HEADER;
COPY customers
FROM 'C:\csv\customers.csv'
DELIMITER ','
CSV HEADER;

SELECT 
    ROUND(SUM(payment_value)::numeric, 2) AS total_revenue
FROM payments;

SELECT 
    c.customer_unique_id,
    ROUND(SUM(p.payment_value)::numeric, 2) AS total_spent
FROM orders o
JOIN payments p 
    ON o.order_id = p.order_id
JOIN customers c 
    ON o.customer_id = c.customer_id
GROUP BY c.customer_unique_id
ORDER BY total_spent DESC
LIMIT 10;

WITH rfm AS (
    SELECT 
        c.customer_unique_id,

        MAX(o.order_purchase_timestamp) AS last_purchase,

        (
            SELECT MAX(order_purchase_timestamp)
            FROM orders
        ) - MAX(o.order_purchase_timestamp) AS recency,

        COUNT(DISTINCT o.order_id) AS frequency,

        ROUND(SUM(p.payment_value)::numeric, 2) AS monetary

    FROM orders o

    JOIN payments p
        ON o.order_id = p.order_id

    JOIN customers c
        ON o.customer_id = c.customer_id

    GROUP BY c.customer_unique_id
)

SELECT * 
FROM rfm
LIMIT 10;

WITH rfm AS (
    SELECT 
        c.customer_unique_id,

        (
            SELECT MAX(order_purchase_timestamp)
            FROM orders
        ) - MAX(o.order_purchase_timestamp) AS recency,

        COUNT(DISTINCT o.order_id) AS frequency,

        ROUND(SUM(p.payment_value)::numeric, 2) AS monetary

    FROM orders o

    JOIN payments p
        ON o.order_id = p.order_id

    JOIN customers c
        ON o.customer_id = c.customer_id

    GROUP BY c.customer_unique_id
),

rfm_scores AS (
    SELECT *,

        NTILE(5) OVER (
            ORDER BY recency DESC
        ) AS r_score,

        NTILE(5) OVER (
            ORDER BY frequency
        ) AS f_score,

        NTILE(5) OVER (
            ORDER BY monetary
        ) AS m_score

    FROM rfm
)

SELECT *
FROM rfm_scores
LIMIT 20;

WITH rfm AS (
    SELECT 
        c.customer_unique_id,

        (
            SELECT MAX(order_purchase_timestamp)
            FROM orders
        ) - MAX(o.order_purchase_timestamp) AS recency,

        COUNT(DISTINCT o.order_id) AS frequency,

        ROUND(SUM(p.payment_value)::numeric, 2) AS monetary

    FROM orders o

    JOIN payments p
        ON o.order_id = p.order_id

    JOIN customers c
        ON o.customer_id = c.customer_id

    GROUP BY c.customer_unique_id
),

rfm_scores AS (
    SELECT *,

        NTILE(5) OVER (
            ORDER BY recency DESC
        ) AS r_score,

        NTILE(5) OVER (
            ORDER BY frequency
        ) AS f_score,

        NTILE(5) OVER (
            ORDER BY monetary
        ) AS m_score

    FROM rfm
)

SELECT *,

CASE

    WHEN r_score = 5 
         AND f_score = 5 
         AND m_score = 5
    THEN 'Champions'

    WHEN f_score >= 4 
         AND m_score >= 4
    THEN 'Loyal Customers'

    WHEN r_score <= 2
         AND f_score <= 2
    THEN 'At Risk'

    WHEN r_score = 1
         AND f_score = 1
    THEN 'Lost Customers'

    ELSE 'Potential Loyalists'

END AS customer_segment

FROM rfm_scores;

CREATE TABLE customer_rfm_segments AS

WITH rfm AS (
    SELECT 
        c.customer_unique_id,

        (
            SELECT MAX(order_purchase_timestamp)
            FROM orders
        ) - MAX(o.order_purchase_timestamp) AS recency,

        COUNT(DISTINCT o.order_id) AS frequency,

        ROUND(SUM(p.payment_value)::numeric, 2) AS monetary

    FROM orders o

    JOIN payments p
        ON o.order_id = p.order_id

    JOIN customers c
        ON o.customer_id = c.customer_id

    GROUP BY c.customer_unique_id
),

rfm_scores AS (
    SELECT *,

        NTILE(5) OVER (
            ORDER BY recency DESC
        ) AS r_score,

        NTILE(5) OVER (
            ORDER BY frequency
        ) AS f_score,

        NTILE(5) OVER (
            ORDER BY monetary
        ) AS m_score

    FROM rfm
)

SELECT *,

CASE

    WHEN r_score = 5 
         AND f_score = 5 
         AND m_score = 5
    THEN 'Champions'

    WHEN f_score >= 4 
         AND m_score >= 4
    THEN 'Loyal Customers'

    WHEN r_score <= 2
         AND f_score <= 2
    THEN 'At Risk'

    WHEN r_score = 1
         AND f_score = 1
    THEN 'Lost Customers'

    ELSE 'Potential Loyalists'

END AS customer_segment

FROM rfm_scores;

