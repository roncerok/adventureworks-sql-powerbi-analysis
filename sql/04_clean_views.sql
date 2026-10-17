
CREATE SCHEMA IF NOT EXISTS clean;

---1. SALES CLEAN SCHEMA
CREATE OR REPLACE VIEW clean.v_sales AS
SELECT
    TO_DATE(BTRIM(order_date), 'MM/DD/YYYY') AS order_date,
    BTRIM(order_number)                    AS order_number,
    BTRIM(product_key)::INTEGER            AS product_key,
    BTRIM(customer_key)::INTEGER           AS customer_key,
    BTRIM(territory_key)::INTEGER          AS territory_key,
    BTRIM(order_line_item)::INTEGER        AS order_line_item,
    BTRIM(order_quantity)::INTEGER         AS order_quantity
FROM raw.v_sales_all;

---Oveview of the result

SELECT *
FROM clean.v_sales
LIMIT 20;



--- ALL REMAINING CSV FILES

-- 2. PRODUCTS (INCL. CATEGORY AND SUBCAT. LABELS)
CREATE OR REPLACE VIEW clean.v_products AS
SELECT
    BTRIM(p.product_key::TEXT)::INTEGER AS product_key,
    BTRIM(p.product_name::TEXT) AS product_name,
    BTRIM(p.model_name::TEXT) AS model_name,
    BTRIM(s.subcategory_name::TEXT) AS subcategory_name,
    BTRIM(c.categoryname::TEXT) AS category_name,
    BTRIM(p.product_cost::TEXT)::NUMERIC AS product_cost,
    BTRIM(p.product_price::TEXT)::NUMERIC AS product_price
FROM raw.products AS p
LEFT JOIN raw.product_subcategories AS s
    ON BTRIM(p.product_subcategory_key::TEXT)
     = BTRIM(s.product_subcategory_key::TEXT)
LEFT JOIN raw.product_categories AS c
    ON BTRIM(s.product_category_key::TEXT)
     = BTRIM(c.product_category_key::TEXT);


-- 3. TERRITORIES
CREATE OR REPLACE VIEW clean.v_territories AS
SELECT
    BTRIM(sales_territory_key::TEXT)::INTEGER AS territory_key,
    BTRIM(region::TEXT) AS region,
    BTRIM(country::TEXT) AS country,
    BTRIM(continent::TEXT) AS continent
FROM raw.territories;


-- 4. RETURNS
CREATE OR REPLACE VIEW clean.v_returns AS
SELECT
    TO_DATE(BTRIM(return_date), 'MM/DD/YYYY') AS return_date,
    BTRIM(territory_key)::INTEGER AS territory_key,
    BTRIM(product_key)::INTEGER AS product_key,
    BTRIM(return_quantity)::INTEGER AS return_quantity
FROM raw.returns;


-- 5. CUSTOMERS
CREATE OR REPLACE VIEW clean.v_customers AS
SELECT
    BTRIM(customer_key)::INTEGER AS customer_key,
    BTRIM(prefix) AS prefix,
    BTRIM(first_name) AS first_name,
    BTRIM(last_name) AS last_name,
    BTRIM(birth_date) AS birth_date,
    BTRIM(marital_status) AS marital_status,
    BTRIM(gender) AS gender,
    BTRIM(email_address) AS email_address,
    BTRIM(annual_income) AS annual_income,
    BTRIM(total_children) AS total_children,
    BTRIM(education_level) AS education_level,
    BTRIM(occupation) AS occupation,
    BTRIM(home_owner) AS home_owner
FROM raw.customers;


-- 6. CALENDAR
CREATE OR REPLACE VIEW clean.v_calendar AS
SELECT
    TO_DATE(BTRIM("date"), 'MM/DD/YYYY') AS "date"
FROM raw.calendar;


-- 7. COMBINED ROW CHECK

SELECT
    'products' AS dataset,
    (SELECT COUNT(*) FROM raw.products) AS raw_rows,
    (SELECT COUNT(*) FROM clean.v_products) AS clean_rows

UNION ALL

SELECT
    'territories',
    (SELECT COUNT(*) FROM raw.territories),
    (SELECT COUNT(*) FROM clean.v_territories)

UNION ALL

SELECT
    'returns',
    (SELECT COUNT(*) FROM raw.returns),
    (SELECT COUNT(*) FROM clean.v_returns)

UNION ALL

SELECT
    'customers',
    (SELECT COUNT(*) FROM raw.customers),
    (SELECT COUNT(*) FROM clean.v_customers)

UNION ALL

SELECT
    'calendar',
    (SELECT COUNT(*) FROM raw.calendar),
    (SELECT COUNT(*) FROM clean.v_calendar);


---RETURN-DATE RANGE CHECK
SELECT
    MIN(return_date) AS first_return_date,
    MAX(return_date) AS last_return_date
FROM clean.v_returns;