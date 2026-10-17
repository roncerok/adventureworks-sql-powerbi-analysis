SELECT 'sales_2015' AS source_table, COUNT(*) AS row_count
FROM raw.sales_2015

UNION ALL

SELECT 'sales_2016', COUNT(*)
FROM raw.sales_2016

UNION ALL

SELECT 'sales_2017', COUNT(*)
FROM raw.sales_2017;



SELECT
    table_name,
    ordinal_position AS column_position,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'raw'
  AND table_name IN (
      'sales_2015',
      'sales_2016',
      'sales_2017'
  )
ORDER BY column_position, table_name;




CREATE VIEW raw.v_sales_all AS

SELECT
    order_date,
    stock_date,
    order_number,
    product_key,
    customer_key,
    territory_key,
    order_line_item,
    order_quantity
FROM raw.sales_2015

UNION ALL

SELECT
    order_date,
    stock_date,
    order_number,
    product_key,
    customer_key,
    territory_key,
    order_line_item,
    order_quantity
FROM raw.sales_2016

UNION ALL

SELECT
    order_date,
    stock_date,
    order_number,
    product_key,
    customer_key,
    territory_key,
    order_line_item,
    order_quantity
FROM raw.sales_2017;


SELECT COUNT(*) AS total_sales_rows
FROM raw.v_sales_all;