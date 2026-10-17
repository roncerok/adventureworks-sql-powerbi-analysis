--Duplicate sales data audit
 
SELECT
    order_number,
    order_line_item,
    COUNT(*) AS row_count
FROM raw.v_sales_all
GROUP BY
    order_number,
    order_line_item
HAVING COUNT(*) > 1
ORDER BY row_count DESC;

-- Missing order number and missing line number audit

SELECT *
FROM raw.v_sales_all
WHERE order_number IS NULL
   OR BTRIM(order_number) = ''
   OR order_line_item IS NULL
   OR BTRIM(order_line_item) = '';

--Other missing data audit

SELECT
    COUNT(*) FILTER (
        WHERE order_date IS NULL OR BTRIM(order_date) = ''
    ) AS missing_order_date,

    COUNT(*) FILTER (
        WHERE product_key IS NULL OR BTRIM(product_key) = ''
    ) AS missing_product_key,

    COUNT(*) FILTER (
        WHERE customer_key IS NULL OR BTRIM(customer_key) = ''
    ) AS missing_customer_key,

    COUNT(*) FILTER (
        WHERE territory_key IS NULL OR BTRIM(territory_key) = ''
    ) AS missing_territory_key,

    COUNT(*) FILTER (
        WHERE order_quantity IS NULL OR BTRIM(order_quantity) = ''
    ) AS missing_order_quantity

FROM raw.v_sales_all;


--- Numeric format audit

SELECT
    COUNT(*) FILTER (
        WHERE BTRIM(order_quantity) !~ '^[1-9][0-9]*$'
    ) AS invalid_quantity,

    COUNT(*) FILTER (
        WHERE BTRIM(order_line_item) !~ '^[1-9][0-9]*$'
    ) AS invalid_line_number,

    COUNT(*) FILTER (
        WHERE BTRIM(product_key) !~ '^[1-9][0-9]*$'
    ) AS invalid_product_key,

    COUNT(*) FILTER (
        WHERE BTRIM(customer_key) !~ '^[1-9][0-9]*$'
    ) AS invalid_customer_key,

    COUNT(*) FILTER (
        WHERE BTRIM(territory_key) !~ '^[1-9][0-9]*$'
    ) AS invalid_territory_key

FROM raw.v_sales_all;


--- Product key match (raw.products vs. sales) audit

SELECT
    s.product_key,
    COUNT(*) AS affected_sales_rows
FROM raw.v_sales_all AS s
WHERE NOT EXISTS (
    SELECT 1
    FROM raw.products AS p
    WHERE BTRIM(p.product_key) = BTRIM(s.product_key)
)
GROUP BY s.product_key;



---Product key uniqueness audit

SELECT
    BTRIM(product_key) AS product_key,
    COUNT(*) AS row_count
FROM raw.products
GROUP BY BTRIM(product_key)
HAVING COUNT(*) > 1;


--- Terrytory key audit

----Orphan key audit

SELECT
    s.territory_key,
    COUNT(*) AS affected_sales_rows
FROM raw.v_sales_all AS s
WHERE NOT EXISTS (
    SELECT 1
    FROM raw.territories AS t
    WHERE BTRIM(t.sales_territory_key) = BTRIM(s.territory_key)
)
GROUP BY s.territory_key;

----- Non unique key audit

SELECT
    BTRIM(sales_territory_key) AS territory_key,
    COUNT(*) AS row_count
FROM raw.territories
GROUP BY BTRIM(sales_territory_key)
HAVING COUNT(*) > 1;



-- Order dates validity audit. US format?

--- Date consistency check (US format)
SELECT
    order_date,
    COUNT(*) AS affected_rows
FROM raw.v_sales_all
WHERE BTRIM(order_date)
      !~ '^(0?[1-9]|1[0-2])/(0?[1-9]|[12][0-9]|3[01])/[0-9]{4}$'
GROUP BY order_date
ORDER BY affected_rows DESC;


--- Check dates validity (e.g. no Feb 30th), split the date > find the month’s last day > flag a day beyond that limit
WITH date_parts AS (
    SELECT DISTINCT
        BTRIM(order_date) AS order_date,
        SPLIT_PART(BTRIM(order_date), '/', 1)::INTEGER AS month_num,
        SPLIT_PART(BTRIM(order_date), '/', 2)::INTEGER AS day_num,
        SPLIT_PART(BTRIM(order_date), '/', 3)::INTEGER AS year_num
    FROM raw.v_sales_all
)
SELECT *
FROM date_parts
WHERE CASE
    WHEN year_num < 1 THEN TRUE
    ELSE day_num > EXTRACT(
        DAY FROM (
            MAKE_DATE(year_num, month_num, 1)
            + INTERVAL '1 month'
            - INTERVAL '1 day'
        )
    )
END;


--- Date range audit

WITH sales_dates AS (
    SELECT
        'sales_2015' AS source_table,
        TO_DATE(BTRIM(order_date), 'MM/DD/YYYY') AS order_date
    FROM raw.sales_2015

    UNION ALL

    SELECT
        'sales_2016',
        TO_DATE(BTRIM(order_date), 'MM/DD/YYYY')
    FROM raw.sales_2016

    UNION ALL

    SELECT
        'sales_2017',
        TO_DATE(BTRIM(order_date), 'MM/DD/YYYY')
    FROM raw.sales_2017
)
SELECT
    source_table,
    MIN(order_date) AS earliest_date,
    MAX(order_date) AS latest_date
FROM sales_dates
GROUP BY source_table
ORDER BY source_table;




---------Products audit
--PRODUCT AUDIT

---Row uniqueness
SELECT
    BTRIM(product_key) AS product_key,
    COUNT(*) AS row_count
FROM raw.products
GROUP BY BTRIM(product_key)
HAVING COUNT(*) > 1;

---Missing keys, SKU and names

SELECT *
FROM raw.products p 
WHERE p.product_key  IS NULL
   OR BTRIM(p.product_key) = ''
   OR p.product_name  IS NULL
   OR BTRIM(p.product_name) = ''
	OR BTRIM(p.product_sku) = ''
   OR p.product_sku  IS NULL
	OR BTRIM(p.model_name ) = ''
   OR p.model_name  IS NULL;


-- Missing values or unexpected numeric formats
SELECT
    COUNT(*) FILTER (
        WHERE product_price IS NULL
           OR BTRIM(product_price) !~ '^[0-9]+([.][0-9]+)?$'
    ) AS invalid_or_missing_price,

    COUNT(*) FILTER (
        WHERE product_cost IS NULL
           OR BTRIM(product_cost) !~ '^[0-9]+([.][0-9]+)?$'
    ) AS invalid_or_missing_cost,

    COUNT(*) FILTER (
        WHERE product_key IS NULL
           OR BTRIM(product_key) !~ '^[1-9][0-9]*$'
    ) AS invalid_or_missing_product_key

FROM raw.products;

--Price + costs outliers (zero-cost)

SELECT
    product_key,
    product_name,
    product_price::NUMERIC AS price,
    product_cost::NUMERIC AS cost
FROM raw.products
WHERE product_price::NUMERIC <= 0
   OR product_cost::NUMERIC <= 0
   OR product_cost::NUMERIC > product_price::NUMERIC;

--Products without a matching sub-category

SELECT
    p.product_key,
    p.product_name,
    p.product_subcategory_key
FROM raw.products AS p
WHERE NOT EXISTS (
    SELECT 1
    FROM raw.product_subcategories AS s
    WHERE BTRIM(s.product_subcategory_key)
        = BTRIM(p.product_subcategory_key)
);

---Subcategories without a matching category

SELECT
    s.product_subcategory_key,
    s.subcategory_name,
    s.product_category_key
FROM raw.product_subcategories AS s
WHERE NOT EXISTS (
    SELECT 1
    FROM raw.product_categories AS c
    WHERE BTRIM(c.product_category_key::TEXT)
        = BTRIM(s.product_category_key::TEXT)
);


-- Category keys: missing, blank or duplicated
SELECT
    BTRIM(product_category_key::TEXT) AS category_key,
    COUNT(*) AS row_count
FROM raw.product_categories
GROUP BY BTRIM(product_category_key::TEXT)
HAVING BTRIM(product_category_key::TEXT) IS NULL
    OR BTRIM(product_category_key::TEXT) = ''
    OR COUNT(*) > 1;


-- Subcategory keys: missing, blank or duplicated
SELECT
    BTRIM(product_subcategory_key::TEXT) AS subcategory_key,
    COUNT(*) AS row_count
FROM raw.product_subcategories
GROUP BY BTRIM(product_subcategory_key::TEXT)
HAVING BTRIM(product_subcategory_key::TEXT) IS NULL
    OR BTRIM(product_subcategory_key::TEXT) = ''
    OR COUNT(*) > 1;


-- Categories: missing names or invalid key format
SELECT *
FROM raw.product_categories
WHERE categoryname IS NULL
   OR BTRIM(categoryname::TEXT) = ''
   OR BTRIM(product_category_key::TEXT) !~ '^[1-9][0-9]*$';


-- Subcategories: missing names or invalid hierarchy keys
SELECT *
FROM raw.product_subcategories
WHERE subcategory_name IS NULL
   OR BTRIM(subcategory_name::TEXT) = ''
   OR BTRIM(product_subcategory_key::TEXT) !~ '^[1-9][0-9]*$'
   OR product_category_key IS NULL
   OR BTRIM(product_category_key::TEXT) !~ '^[1-9][0-9]*$';



--RETURNS


-- Returns: essential fields and positive-integer formats
SELECT *
FROM raw.returns
WHERE return_date IS NULL
   OR BTRIM(return_date) = ''
   OR territory_key IS NULL
   OR BTRIM(territory_key) !~ '^[1-9][0-9]*$'
   OR product_key IS NULL
   OR BTRIM(product_key) !~ '^[1-9][0-9]*$'
   OR return_quantity IS NULL
   OR BTRIM(return_quantity) !~ '^[1-9][0-9]*$';


-- Returns without a matching product or territory
SELECT *
FROM raw.returns AS r
WHERE NOT EXISTS (
    SELECT 1
    FROM raw.products AS p
    WHERE BTRIM(p.product_key::TEXT)
        = BTRIM(r.product_key)
)
OR NOT EXISTS (
    SELECT 1
    FROM raw.territories AS t
    WHERE BTRIM(t.sales_territory_key::TEXT)
        = BTRIM(r.territory_key)
);


-- Return date format audit: unexpected date formats (expected MM/DD/YYYY)
SELECT
    return_date,
    COUNT(*) AS affected_rows
FROM raw.returns
WHERE BTRIM(return_date)
      !~ '^(0?[1-9]|1[0-2])/(0?[1-9]|[12][0-9]|3[01])/[0-9]{4}$'
GROUP BY return_date;



-- CUSTOMER AUDIT
--Extract the exact name of the columns
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'raw'
  AND table_name = 'customers'
ORDER BY ordinal_position;

--Customer key audit

-- Customers: missing, invalid or duplicate keys
SELECT
    BTRIM(customer_key) AS customer_key,
    COUNT(*) AS row_count
FROM raw.customers
GROUP BY BTRIM(customer_key)
HAVING BTRIM(customer_key) IS NULL
    OR BTRIM(customer_key) !~ '^[1-9][0-9]*$'
    OR COUNT(*) > 1;


-- Sales without a matching customer
SELECT
    BTRIM(s.customer_key) AS customer_key,
    COUNT(*) AS affected_sales_rows
FROM raw.v_sales_all AS s
WHERE NOT EXISTS (
    SELECT 1
    FROM raw.customers AS c
    WHERE BTRIM(c.customer_key) = BTRIM(s.customer_key)
)
GROUP BY BTRIM(s.customer_key);

--- Customers without demographic information

-- Customers: missing demographic information
SELECT
    customer_key,
    birth_date,
    marital_status,
    gender,
    annual_income,
    education_level,
    occupation,
    home_owner
FROM raw.customers
WHERE birth_date IS NULL OR BTRIM(birth_date) = ''
   OR marital_status IS NULL OR BTRIM(marital_status) = ''
   OR gender IS NULL OR BTRIM(gender) = ''
   OR annual_income IS NULL OR BTRIM(annual_income) = ''
   OR education_level IS NULL OR BTRIM(education_level) = ''
   OR occupation IS NULL OR BTRIM(occupation) = ''
   OR home_owner IS NULL OR BTRIM(home_owner) = '';


-- CALENDAR AUDIT


-- Calendar: missing, blank or duplicate date values
SELECT
    BTRIM("date"::TEXT) AS calendar_date,
    COUNT(*) AS row_count
FROM raw.calendar
GROUP BY BTRIM("date"::TEXT)
HAVING BTRIM("date"::TEXT) IS NULL
    OR BTRIM("date"::TEXT) = ''
    OR COUNT(*) > 1;


-- Calendar: date range and daily coverage
WITH calendar_dates AS (
    SELECT
        TO_DATE(BTRIM("date"), 'MM/DD/YYYY') AS calendar_date
    FROM raw.calendar
)
SELECT
    MIN(calendar_date) AS first_date,
    MAX(calendar_date) AS last_date,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT calendar_date) AS unique_dates,
    MAX(calendar_date) - MIN(calendar_date) + 1 AS expected_days,
    MAX(calendar_date) - MIN(calendar_date) + 1
        - COUNT(DISTINCT calendar_date) AS missing_days
FROM calendar_dates;