-- 10. SQL VALIDATION
-- 10.1. H1 2017 modelled sales value and gross profit

SELECT
    SUM(s.order_quantity * p.product_price)
        AS modelled_sales_value,
    SUM(s.order_quantity * (p.product_price - p.product_cost))
        AS modelled_gross_profit
FROM clean.v_sales AS s
JOIN clean.v_products AS p
    ON s.product_key = p.product_key
WHERE s.order_date >= DATE '2017-01-01'
  AND s.order_date <  DATE '2017-07-01';

--- Results   modelled_sales_value 9185449.4473,	modelled_gross_profit: 3889028.9748


-- 10.2. Gross margin, orders and units sold for H1 2017
SELECT
    COUNT(DISTINCT s.order_number) AS orders,
    SUM(s.order_quantity) AS units_sold,
    100.0 * SUM(
        s.order_quantity * (p.product_price - p.product_cost)
    ) / NULLIF(
        SUM(s.order_quantity * p.product_price), 0
    ) AS modelled_gross_margin_pct
FROM clean.v_sales AS s
JOIN clean.v_products AS p
    ON s.product_key = p.product_key
WHERE s.order_date >= DATE '2017-01-01'
  AND s.order_date <=  DATE '2017-06-30';


--10.3. Units returned and the returned-to-sold units ratio

WITH sales AS (
    SELECT SUM(order_quantity) AS units_sold
    FROM clean.v_sales
    WHERE order_date >= DATE '2017-01-01'
      AND order_date <= DATE '2017-06-30'
),
returns AS (
    SELECT SUM(return_quantity) AS units_returned
    FROM clean.v_returns
    WHERE return_date >= DATE '2017-01-01'
      AND return_date <=  DATE '2017-06-30'
)
SELECT
    r.units_returned,
    100.0 * r.units_returned
        / NULLIF(s.units_sold, 0) AS returned_to_sold_pct
FROM sales AS s
CROSS JOIN returns AS r;


-- 10. 4 Sales value, gross profit and margin by category

SELECT
    p.category_name,
    SUM(s.order_quantity * p.product_price)
        AS modelled_sales_value,
    SUM(s.order_quantity * (p.product_price - p.product_cost))
        AS modelled_gross_profit,
    100.0 * SUM(
        s.order_quantity * (p.product_price - p.product_cost)
    ) / NULLIF(
        SUM(s.order_quantity * p.product_price), 0
    ) AS modelled_gross_margin_pct
FROM clean.v_sales AS s
JOIN clean.v_products AS p
    ON s.product_key = p.product_key
WHERE s.order_date >= DATE '2017-01-01'
  AND s.order_date <= DATE '2017-06-30'
GROUP BY p.category_name
ORDER BY modelled_gross_profit DESC;


-- 10.5. Category returns matrix (aggregating sales and returns separately)
WITH sales AS (
    SELECT
        p.category_name,
        SUM(s.order_quantity) AS units_sold
    FROM clean.v_sales AS s
    JOIN clean.v_products AS p
        ON s.product_key = p.product_key
    WHERE s.order_date >= DATE '2017-01-01'
      AND s.order_date <=  DATE '2017-06-30'
    GROUP BY p.category_name
),
returns AS (
    SELECT
        p.category_name,
        SUM(r.return_quantity) AS units_returned
    FROM clean.v_returns AS r
    JOIN clean.v_products AS p
        ON r.product_key = p.product_key
    WHERE r.return_date >= DATE '2017-01-01'
      AND r.return_date <= DATE '2017-06-30'
    GROUP BY p.category_name
)
SELECT
    COALESCE(s.category_name, r.category_name) AS category_name,
    COALESCE(s.units_sold, 0) AS units_sold,
    COALESCE(r.units_returned, 0) AS units_returned,
    100.0 * COALESCE(r.units_returned, 0)
        / NULLIF(s.units_sold, 0) AS returned_to_sold_pct
FROM sales AS s
FULL OUTER JOIN returns AS r
    ON s.category_name = r.category_name
ORDER BY units_sold DESC;


--10.6 Top five models by modelled gross profit and their combined share

WITH model_gp AS (
    SELECT
        p.model_name,
        SUM(s.order_quantity * (p.product_price - p.product_cost))
            AS modelled_gross_profit
    FROM clean.v_sales AS s
    JOIN clean.v_products AS p
        ON s.product_key = p.product_key
    WHERE s.order_date >= DATE '2017-01-01'
      AND s.order_date <  DATE '2017-07-01'
    GROUP BY p.model_name
),
ranked AS (
    SELECT
        model_name,
        modelled_gross_profit,
        ROW_NUMBER() OVER (
            ORDER BY modelled_gross_profit DESC, model_name ASC
        ) AS model_rank,
        SUM(modelled_gross_profit) OVER () AS total_gp
    FROM model_gp
)
SELECT
    model_rank,
    model_name,
    modelled_gross_profit,
    100.0 * SUM(modelled_gross_profit) OVER ()
        / NULLIF(total_gp, 0) AS top_five_gp_share_pct
FROM ranked
WHERE model_rank <= 5
ORDER BY model_rank;


-- 10.7 H1 sales-value growth from 2016 to 2017

WITH yearly_sales AS (
    SELECT
        EXTRACT(YEAR FROM s.order_date)::INTEGER AS sales_year,
        SUM(s.order_quantity * p.product_price)
            AS modelled_sales_value
    FROM clean.v_sales AS s
    JOIN clean.v_products AS p
        ON s.product_key = p.product_key
    WHERE (
        s.order_date >= DATE '2016-01-01'
        AND s.order_date <= DATE '2016-06-30'
    ) OR (
        s.order_date >= DATE '2017-01-01'
        AND s.order_date <= DATE '2017-06-30'
    )
    GROUP BY EXTRACT(YEAR FROM s.order_date)
),
comparison AS (
    SELECT
        MAX(modelled_sales_value) FILTER (WHERE sales_year = 2016)
            AS h1_2016,
        MAX(modelled_sales_value) FILTER (WHERE sales_year = 2017)
            AS h1_2017
    FROM yearly_sales
)
SELECT
    h1_2016,
    h1_2017,
    100.0 * (h1_2017 - h1_2016)
        / NULLIF(h1_2016, 0) AS yoy_growth_pct
FROM comparison;


--- 10.8. H1 2017 month-by-month comparison

WITH monthly_sales AS (
    SELECT
        EXTRACT(MONTH FROM s.order_date)::INTEGER AS month_number,
        SUM(s.order_quantity * p.product_price)
            FILTER (WHERE EXTRACT(YEAR FROM s.order_date) = 2016)
            AS sales_2016,
        SUM(s.order_quantity * p.product_price)
            FILTER (WHERE EXTRACT(YEAR FROM s.order_date) = 2017)
            AS sales_2017
    FROM clean.v_sales AS s
    JOIN clean.v_products AS p
        ON s.product_key = p.product_key
    WHERE (
        s.order_date >= DATE '2016-01-01'
        AND s.order_date < DATE '2016-07-01'
    ) OR (
        s.order_date >= DATE '2017-01-01'
        AND s.order_date < DATE '2017-07-01'
    )
    GROUP BY EXTRACT(MONTH FROM s.order_date)
)
SELECT
    month_number,
    sales_2016,
    sales_2017,
    100.0 * (sales_2017 - sales_2016)
        / NULLIF(sales_2016, 0) AS yoy_growth_pct
FROM monthly_sales
ORDER BY month_number;


-- 10.9. US & Australia share of H1 2017 modelled sales value

WITH country_sales AS (
    SELECT
        t.country,
        SUM(s.order_quantity * p.product_price)
            AS modelled_sales_value
    FROM clean.v_sales AS s
    JOIN clean.v_products AS p
        ON s.product_key = p.product_key
    JOIN clean.v_territories AS t
        ON s.territory_key = t.territory_key
    WHERE s.order_date >= DATE '2017-01-01'
      AND s.order_date <  DATE '2017-07-01'
    GROUP BY t.country
)
SELECT
    country,
    modelled_sales_value,
    100.0 * modelled_sales_value
        / NULLIF(SUM(modelled_sales_value) OVER (), 0)
        AS sales_share_pct
FROM country_sales
ORDER BY modelled_sales_value DESC;




-- CLIENTS PROFILE
-- 10.10. Education and home ownership

SELECT
    education_level,
    home_owner,
    COUNT(*) AS customer_records
FROM clean.v_customers
GROUP BY education_level, home_owner
ORDER BY education_level, home_owner;


-- 10. 11. Clients who purchased on H1 2017

WITH buyers AS (
    SELECT DISTINCT customer_key
    FROM clean.v_sales
    WHERE order_date >= DATE '2017-01-01'
      AND order_date <  DATE '2017-07-01'
)
SELECT
    c.education_level,
    c.home_owner,
    COUNT(*) AS distinct_buyers
FROM buyers AS b
JOIN clean.v_customers AS c
    ON b.customer_key = c.customer_key
GROUP BY c.education_level, c.home_owner
ORDER BY c.education_level, c.home_owner;



-- 7.12. Top products purchased by clients in H1 2017

SELECT
    p.model_name,
    COUNT(DISTINCT s.customer_key) AS distinct_buyers
FROM clean.v_sales AS s
JOIN clean.v_products AS p
    ON s.product_key = p.product_key
WHERE s.order_date >= DATE '2017-01-01'
  AND s.order_date <  DATE '2017-07-01'
GROUP BY p.model_name
ORDER BY distinct_buyers DESC, p.model_name ASC
LIMIT 5;



-- 7.13. Customer gender counts
SELECT
    c.gender,
    COUNT(DISTINCT s.customer_key) AS distinct_buyers
FROM clean.v_sales AS s
JOIN clean.v_customers AS c
    ON s.customer_key = c.customer_key
WHERE s.order_date >= DATE '2017-01-01'
  AND s.order_date < DATE '2017-07-01'
GROUP BY c.gender
ORDER BY distinct_buyers DESC;


-- 7.14. Customer ages count

WITH buyer_ages AS (
    SELECT DISTINCT
        s.customer_key,
        EXTRACT(YEAR FROM AGE(
    DATE '2017-06-30',
    TO_DATE(c.birth_date, 'MM/DD/YYYY')
)) AS age
    FROM clean.v_sales AS s
    JOIN clean.v_customers AS c
        ON s.customer_key = c.customer_key
    WHERE s.order_date >= DATE '2017-01-01'
      AND s.order_date < DATE '2017-07-01'
)
SELECT
    CASE
        WHEN age IS NULL OR age < 0 THEN 'Unknown'
        WHEN age < 35 THEN 'Under 35'
        WHEN age < 45 THEN '35–44'
        WHEN age < 55 THEN '45–54'
        ELSE '55+'
    END AS age_group,
    COUNT(*) AS distinct_buyers
FROM buyer_ages
GROUP BY age_group
ORDER BY age_group;


-- 7.15. Customer income count
WITH buyers AS (
    SELECT DISTINCT
        s.customer_key,
        NULLIF(
            TRIM(REPLACE(REPLACE(c.annual_income, '$', ''), ',', '')),
            ''
        )::numeric AS income
    FROM clean.v_sales AS s
    JOIN clean.v_customers AS c
        ON s.customer_key = c.customer_key
    WHERE s.order_date >= DATE '2017-01-01'
      AND s.order_date < DATE '2017-07-01'
),
bands AS (
    SELECT
        CASE
            WHEN income IS NULL OR income < 0 THEN 'Unknown'
            WHEN income < 40000 THEN 'Under 40,000'
            WHEN income < 80000 THEN '40,000–79,999'
            WHEN income < 120000 THEN '80,000–119,999'
            ELSE '120,000+'
        END AS income_band
    FROM buyers
)
SELECT income_band, COUNT(*) AS distinct_buyers
FROM bands
GROUP BY income_band
ORDER BY distinct_buyers DESC;