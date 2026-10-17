
CREATE SCHEMA IF NOT EXISTS raw;

-- 1. Calendar
CREATE TABLE IF NOT EXISTS raw.calendar (
    date TEXT
);

-- 2. Customers
CREATE TABLE IF NOT EXISTS raw.customers (
    customer_key    TEXT,
    prefix          TEXT,
    first_name      TEXT,
    last_name       TEXT,
    birth_date      TEXT,
    marital_status  TEXT,
    gender          TEXT,
    email_address   TEXT,
    annual_income   TEXT,
    total_children  TEXT,
    education_level TEXT,
    occupation      TEXT,
    home_owner      TEXT
);

-- 3. Product categories
CREATE TABLE IF NOT EXISTS raw.product_categories (
    product_category_key TEXT,
    categoryname        TEXT
);

-- 4. Product subcategories
CREATE TABLE IF NOT EXISTS raw.product_subcategories (
    product_subcategory_key TEXT,
    subcategory_name        TEXT,
    product_category_key    TEXT
);

-- 5. Products
CREATE TABLE IF NOT EXISTS raw.products (
    product_key             TEXT,
    product_subcategory_key  TEXT,
    product_sku             TEXT,
    product_name            TEXT,
    model_name              TEXT,
    product_description     TEXT,
    product_color           TEXT,
    product_size            TEXT,
    product_style           TEXT,
    product_cost            TEXT,
    product_price           TEXT
);

-- 6. Returns
CREATE TABLE IF NOT EXISTS raw.returns (
    return_date     TEXT,
    territory_key   TEXT,
    product_key     TEXT,
    return_quantity TEXT
);

-- 7. Sales: 2015
CREATE TABLE IF NOT EXISTS raw.sales_2015 (
    order_date      TEXT,
    stock_date      TEXT,
    order_number    TEXT,
    product_key     TEXT,
    customer_key    TEXT,
    territory_key   TEXT,
    order_line_item TEXT,
    order_quantity  TEXT
);

-- 8. Sales: 2016
CREATE TABLE IF NOT EXISTS raw.sales_2016 (
    order_date      TEXT,
    stock_date      TEXT,
    order_number    TEXT,
    product_key     TEXT,
    customer_key    TEXT,
    territory_key   TEXT,
    order_line_item TEXT,
    order_quantity  TEXT
);

-- 9. Sales: 2017
CREATE TABLE IF NOT EXISTS raw.sales_2017 (
    order_date      TEXT,
    stock_date      TEXT,
    order_number    TEXT,
    product_key     TEXT,
    customer_key    TEXT,
    territory_key   TEXT,
    order_line_item TEXT,
    order_quantity  TEXT
);

-- 10. Territories
CREATE TABLE IF NOT EXISTS raw.territories (
    sales_territory_key TEXT,
    region             TEXT,
    country            TEXT,
    continent          TEXT
);