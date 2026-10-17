# AdventureWorks — Commercial Performance Analysis
  by Kristian Roncero

## 0. Data origin
This is a class project based on fictional dummy data created by Microsoft under the name "Adventure Works", a fictional bike and accesories supplier which is available online. For the premises of the exercise, I used an abbreviated version of it.

## 1. Project brief

**Audience:** Potential investors considering buying shares in AdventureWorks.

**Purpose:** Explore sales growth, product economics and dependence on particular products or territories.

**Main question:** What do AdventureWorks' sales trends and product mix reveal about its commercial strengths and potential vulnerabilities?

### Supporting questions

1. How has sales performance changed over comparable periods?
2. Which products and countries contribute most to performance?
3. How does product mix influence modelled gross margin and profit concentration?
4. Which product categories have the highest returned-to-sold units ratios?
5. What are the observed profiles of H1 2017 buyers, and which models reach the most distinct buyers?


## 2. Scope and tools

- PostgreSQL: import, inspect and validate the necessary data.
- Power BI: build the data model, measures and report.
- Three report pages:
    1. Growth and market distribution.
    2. Product profitability and concentration, including returns relative to sales by category.
    3. Observed buyer profiles: education, home ownership, gender, age, recorded annual income and the five models reaching the most distinct buyers.
- Buyer profiles cover January–June 2017. Age is calculated at 30 June 2017.
- Selecting a model filters the buyer card and demographic charts to its buyers.

## 3. Assumptions and limitations

- Sales records contain quantities but no transaction-level prices or costs.
- There is no information on product cost after taxes.
- Modelled sales value will use quantity × fixed product price.
- Modelled gross profit will use quantity × (product price − product cost).
- These estimates do not represent actual historical revenue or profit.
- Sales cover 2015–2016 and January–June 2017.
- The main year comparison will use January–June 2017 versus January–June 2016.
- Customer attributes may not reflect circumstances at purchase. Age is calculated at 30 June 2017. 
- Recorded annual income contains a dollar symbol in the source, but the specific dollar currency is not confirmed.
- No operating expenses, debt or cash-flow data are available.
- This report supports a commercial assessment; it does not establish company valuation or whether buying shares is advisable.  


## 4. Data inspection
### 4.1. First glance at `.csv` files
**AdventureWorks_Calendar.csv**

Headers: Date

**AdventureWorks_Customers.csv**

Headers: CustomerKey, Prefix, FirstName, LastName, BirthDate, MaritalStatus, Gender, EmailAddress, AnnualIncome, TotalChildren, EducationLevel, Occupation, HomeOwner

**AdventureWorks_Product_Categories.csv**

Headers: ProductCategoryKey, CategoryName

**AdventureWorks_Product_Subcategories.csv**

Headers: ProductSubcategoryKey, SubcategoryName, ProductCategoryKey

**AdventureWorks_Products.csv**

Headers: ProductKey, ProductSubcategoryKey, ProductSKU, ProductName, ModelName, ProductDescription, ProductColor, ProductSize, ProductStyle, ProductCost, ProductPrice

**AdventureWorks_Returns.csv**

Headers: ReturnDate, TerritoryKey, ProductKey, ReturnQuantity

**AdventureWorks_Sales_2015.csv, AdventureWorks_Sales_2016.csv and AdventureWorks_Sales_2017.csv**

Shared headers: OrderDate, StockDate, OrderNumber, ProductKey, CustomerKey, TerritoryKey, OrderLineItem, OrderQuantity

First three rows from AdventureWorks_Sales_2015.csv:

```csv
OrderDate,StockDate,OrderNumber,ProductKey,CustomerKey,TerritoryKey,OrderLineItem,OrderQuantity
1/1/2015,9/21/2001,SO45080,332,14657,1,1,1
1/1/2015,12/5/2001,SO45079,312,29255,4,1,1
1/1/2015,10/29/2001,SO45082,350,11455,9,1,1
```

**AdventureWorks_Territories.csv**

Headers: SalesTerritoryKey, Region, Country, Continent

### 4.2. Initial observations

- A sales row appears to represent an order line, not an entire order.
  Check whether OrderNumber + OrderLineItem uniquely identifies each row.
- The three yearly sales files have the same columns.
- Dates use month/day/year, as shown by StockDate values such as 9/21/2001.
- Sales connect to products through ProductKey.
- Sales TerritoryKey connects to territories SalesTerritoryKey.
- Products connect to subcategories, which connect to categories.
- StockDate needs clarification and will not be treated as a shipment date.
- Customer analysis was outside the initial scope and was later added as the third report page.

### 4.3. Schema creation

- AdventureWorks: raw import tables
- All source columns initially stored as TEXT.
- Dates and numbers will be converted after validation.
- PascalCase column names in source files will be converted to snake_case in the database

**SQL script: 01_raw_schema_and_tables.sql**

```sql

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
```
### 4.4. Data preparation and Power BI model

#### 4.4.1. Sales consolidation — **SQL script: 02_sales_view.sql**

- I checked row counts and compared column names, positions and data types across the three yearly sales tables.
- I combined them into raw.v_sales_all using UNION ALL, which preserves all rows. Duplicate checks were performed separately in ``SQL script: 03_data_audit.sql``.
- The script also checks the combined sales row count.

#### 4.4.2. Data audit — **SQL script: 03_data_audit.sql** 

- I performed the following audit tests: 

| Area | Checks performed |
|---|---|
| Sales records | Duplicate order-number/line-item combinations; missing order identifiers, dates, keys and quantities; positive-integer formats for keys, quantities and line numbers. |
| Sales relationships | Sales product, territory and customer keys matched their reference tables; product and territory keys were checked for uniqueness. |
| Sales dates | Month/day/year format, valid calendar dates and date ranges for each yearly sales file. |
| Products | Missing keys, names, SKUs and model names; valid numeric prices/costs; non-positive prices/costs and costs exceeding prices. |
| Product hierarchy | Products matched subcategories; subcategories matched categories; category/subcategory keys were checked for missing values, duplicates and invalid formats, alongside missing names. |
| Returns | Required fields, positive-integer keys and quantities, matching products and territories, and return-date format. |
| Customers | Missing, invalid or duplicate customer keys; null or blank demographic fields. Literal values such as `NA` were not treated as blanks. |
| Imported calendar | Missing, blank or duplicate dates; date range, unique-date count and daily coverage. |

- No issues were found in the checks above. Individual audit outputs were not retained; the queries are preserved in the script.


#### 4.4.3. Clean views — **SQL script:04_clean_views.sql**

- After auditing the raw data, I created views in the clean schema. These read from the raw tables and sales view without changing the source data.
- I trimmed surrounding whitespace, converted sales and return dates from MM/DD/YYYY, and converted keys, quantities and sales line numbers to integers.
- `clean.v_sales` reads from `raw.v_sales_all` and excludes `StockDate`.
- `clean.v_products` joins products to subcategories and categories, converts prices and costs to numeric, and exposes categoryname as `category_name`.
- I also created clean views for territories, returns, customers and the supplied calendar.
- The script includes raw-versus-clean row-count comparisons for products, territories, returns, customers and calendar, plus a return-date range check.  
- The products view brings together product, subcategory and category information, including fixed product prices and costs.
  
### 4.5. Import check — sales_2015
- Imported 2,630 rows.
- Corrected CSV-to-table column mapping.
- Removed empty duplicate columns created during the first import attempt.
- Inspected a sample of the remaining eight snake_case columns.


### 4.6. Power BI model and calendar

- Sales and returns are separate fact tables. Products, territories and DimDate provide shared dimensions; customers connect to sales.
- Returns cannot be linked to individual orders or customers.
- Customer birth dates and annual income remained text in the SQL view. In Power BI, I converted birth dates to dates and annual income to a fixed decimal number using US locale.
- I imported the supplied calendar CSV during data preparation, but the final Power BI model uses DimDate, created with DAX.
- DimDate provides a continuous date range from 1 January 2015 to 30 June 2017, with year and month fields for filtering and time-intelligence calculations.


## 5. Measures

### 5.1. Units sold
- I create a measure that sums the order_quantity column in the sales table.

``` dax
Units Sold = 
SUM('sales_clean'[order_quantity])
```

### 5.2. Returns quantity
``` dax
Units Returned = 
SUM('returns_clean'[return_quantity])
```

### 5.3. Units sold minus returns quantity
Units sold minus units returned during the selected period. Returns are not linked to the original sales, so this does not measure units retained from those specific orders.

``` dax
Units Sold Less Returns = 
[Units Sold] - [Units Returned]
```
### 5.4. Modelled sales value (quantity × product price)
- I create a measure that calculates a value for each sales row, then adds them up. 
- "Modelled" because the prices are fixed product prices, not actual transaction prices
``` dax
Modelled Sales Value = 
SUMX(
    'sales_clean',
    'sales_clean'[order_quantity]
        * RELATED('products_clean'[product_price])
)
```
### 5.5. Modelled returns value (quantity × product price)
- I create a measure that calculates a value for each returns row, then adds them up.
- It represents modelled returned-goods value, not actual refunds or financial loss.
``` dax
Modelled Returned-Goods Value =
SUMX(
    'returns_clean',
    'returns_clean'[return_quantity]
        * RELATED('products_clean'[product_price])
)
```
### 5.6. Modelled gross profit (quantity × (product price − product cost))
- Modelled gross profit before returns, calculated using fixed product prices and costs.
``` dax
Modelled Gross Profit =
SUMX(
    'sales_clean',
    'sales_clean'[order_quantity]
        * (
            RELATED('products_clean'[product_price])
            - RELATED('products_clean'[product_cost])
        )
)
```
### 5.7. Modelled gross margin
- I create a measure that divides modelled gross profit by modelled sales value.
``` dax
Modelled Gross Margin =
DIVIDE(
    [Modelled Gross Profit],
    [Modelled Sales Value]
)
```
### 5.8. Modelled GP on Returned Units
- Gross profit associated with returned units at fixed product prices and costs. Used in an illustrative scenario assuming full recovery of product cost and no handling costs.
``` dax
Modelled GP on Returned Units =
SUMX(
    'returns_clean',
    'returns_clean'[return_quantity]
        * (
            RELATED('products_clean'[product_price])
            - RELATED('products_clean'[product_cost])
        )
)
```
### 5.9. Returned-to-sold units ratio
- Returned units divided by sold units in the same period. This is not an order-based return rate or the proportion of that period’s sales subsequently returned.
``` dax
Returned-to-Sold Units Ratio =
DIVIDE(
    [Units Returned],
    [Units Sold])
```

### 5.10. Modelled GP After Returns Scenario
- I create a measure that subtracts the modelled gross profit on returned units from the modelled gross profit to estimate the impact of returns on profitability. This measure is not a true historical gross profit calculation, but rather an estimate of the impact of returns on modelled gross profit.
- Illustrative period-based gross-profit scenario after reversing the margin associated with returned units. It does not establish the actual financial impact of returns.
``` dax
Modelled GP After Returns Scenario =
[Modelled Gross Profit] - [Modelled GP on Returned Units]
```

### 5.11. Modelled sales value for the same period last year
- In preparation for the main year growth comparison.
``` dax
Modelled Sales Value LY =
CALCULATE(
    [Modelled Sales Value],
    SAMEPERIODLASTYEAR('DimDate'[Date])
)
```

### 5.12. Modelled sales value year-over-year percentage growth
``` dax
Modelled Sales Value YoY % =
DIVIDE(
    [Modelled Sales Value] - [Modelled Sales Value LY],
    [Modelled Sales Value LY])
```
### 5.13. Distinct clients
``` dax
Distinct Buyers =
DISTINCTCOUNT('sales_clean'[customer_key])
```

### 5.14. Client ages

- I use 30 June 2017 as the reference date for age calculations.
- The calculated column assigns each customer to “Under 35”, “35–44”, “45–54” or “55+”, based on completed years of age.
- Missing or future birth dates return “Unknown”.
- The chart uses [Distinct Buyers] to count H1 2017 buyers in each age group.
``` dax
Age Group = 
VAR BirthDate = 'customers_clean'[birth_date]
VAR ReferenceDate = DATE(2017, 6, 30)
VAR Age =
    YEAR(ReferenceDate) - YEAR(BirthDate)
        - IF(
            MONTH(BirthDate) * 100 + DAY(BirthDate) > 630,
            1,
            0
        )
RETURN
    SWITCH(
        TRUE(),
        ISBLANK(BirthDate) || BirthDate > ReferenceDate, "Unknown",
        Age < 35, "Under 35",
        Age < 45, "35–44",
        Age < 55, "45–54",
        "55+"
    )
```

### 5.15. Clients’ income bands
- I create a calculated column to classify clients by recorded annual income.
- Missing or negative income values return “Unknown”.
- The chart uses [Distinct Buyers] to count H1 2017 buyers in each income band.
``` dax
    Income Band = 
VAR Income = 'customers_clean'[annual_income]
RETURN
    SWITCH(
        TRUE(),
        ISBLANK(Income) || Income < 0, "Unknown",
        Income < 40000, "Under 40,000",
        Income < 80000, "40,000–79,999",
        Income < 120000, "80,000–119,999",
        "120,000+"
    )
```

## 6. Initial findings
### 6.1. First report page: growth and market distribution
- Fixed comparison period: January–June 2017 versus January–June 2016. Measures respond dynamically to report filters.
- January–June modelled sales value increased from 2,952,867.55  in 2016 to 9,185,449.45 in 2017: +211.1%.
- Every month exceeded its corresponding 2016 value; monthly growth ranged from 182.4% to 242.2%.
- Both years showed an overall rise towards June, but this alone does not establish seasonality.
- Market concentration: the United States and Australia account for 60.3% of H1 2017 modelled sales value.
- Report structure: Page 1 contains three KPI cards, a monthly comparison line chart, a country bar chart, a takeaway and a methodology note. Diagnostic tables are preserved on Working checks.
- Visual corrections: both sales-value lines share one Y-axis. Gross margin displays the measure directly, formatted as a percentage; the previous percent of grand total setting was removed.

### 6.2. Second report page: Product category analysis
#### 6.2.1 Measure: calculate the top five models’ combined share of modelled gross profit. 
- Top 5 Models GP Share ignores model_name filters so selecting an individual model does not reduce the comparison to that model alone. Date and category filters still apply
- The five models with the highest H1 2017 modelled gross profit are Mountain-200, Touring-1000, Road-350-W, Road-250 and Road-550-W. Together they contribute 75.8% of modelled gross profit.
``` dax
Top 5 Models GP Share =
CALCULATE(
    VAR TopModels =
        TOPN(
            5,
            VALUES('products_clean'[model_name]),
            [Modelled Gross Profit], DESC,
            'products_clean'[model_name], ASC
        )
    RETURN
        DIVIDE(
            SUMX(TopModels, [Modelled Gross Profit]),
            [Modelled Gross Profit]
        ),
    REMOVEFILTERS('products_clean'[model_name])
)
```

#### 6.2.2 Page #2 findings
- Bikes contribute 89.4% of H1 2017 modelled gross profit. Accessories have the highest modelled gross margin at 62.8%.
- Returned-to-sold units ratios are 3.0% for Bikes, 2.3% for Clothing and 2.0% for Accessories; overall, 2.1%. These compare units recorded in the same period, not returns linked to the original sales.
- Page 2 contains three KPI cards, a top-five-model gross-profit bar chart, category profitability and returns matrices, a takeaway and a methodology note.
- Findings were independently validated in PostgreSQL and matched Power BI. Report interactions were tested. Working checks is hidden but preserved.

### 6.3. Third report page: observed buyer profiles
- H1 2017 had 10,502 distinct buyers.
- Bachelors was the largest education group: 3,105 buyers.
- 68.0% were recorded as homeowners.
- Recorded gender: 5,284 M, 5,139 F and 79 NA.
- 81.4% were aged 45+ at 30 June 2017.
- The largest recorded annual-income band was 40,000–79,999: 4,997 buyers (47.6%).
- Sport-100 reached the most distinct buyers: 3,313.
- All overall counts matched PostgreSQL. Model selection filters the buyer card and demographic charts.
- Buyers may purchase several models, so model-level counts are not additive. These are observed profiles; customer attributes may not reflect circumstances at purchase.

#### 6.3.1. Assumptions and limitations
- Customer attributes may not reflect circumstances at purchase. Age is calculated at 30 June 2017. Recorded annual income contains a dollar symbol in the source, but the specific dollar currency is not confirmed.

## 7. SQL validation queries
- Key report figures were independently recalculated in PostgreSQL and reconciled with Power BI.
-  These queries validate report totals and breakdowns by category, model, country and buyer attributes. Results were compared with Power BI using the same reporting period and filters. Section 7.10 explores all customer records; it is not restricted to H1 2017 buyers.
-  For SQL validation of buyer profiles, I converted birth dates using `TO_DATE` with `MM/DD/YYYY`, and removed dollar symbols and commas before converting income to numeric.
  **SQL script: 05_SQL_validation.sql**

### 7.1. Modelled sales value and gross profit | H1 2017
```sql
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

```
#### Results: 
modelled_sales_value 9185449.4473,	modelled_gross_profit: 3889028.9748
Matched Power BI.


  
### 7.2. Gross margin, orders and units sold for H1 2017
```sql
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
```
#### Results: 
orders: 11839;	 units_sold: 45314; modelled_gross_margin_pct: 42.3390166927885434
Matched Power BI.

### 7.3. Units returned and the returned-to-sold units ratio
```sql
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
```
#### Results
Units returned = 972; returned-to-sold units ratio = 2.145%. Matched Power BI before display rounding.

### 7.4. Sales value, gross profit and margin by category
```sql
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
```
#### Results
| Category | Modelled sales value | Modelled gross profit | Modelled gross margin |
|---|---:|---:|---:|
| Bikes | 8,468,854.5300 | 3,477,544.9233 | 41.0628% |
| Accessories | 507,330.9892 | 318,823.9380 | 62.8434% |
| Clothing | 209,263.9281 | 92,660.1135 | 44.2791% | 

### 7.5. Category returns matrix (aggregating sales and returns separately)
```sql
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
```
#### Results:

| Category | Units sold | Units returned | Returned-to-sold units ratio % |
|---|---:|---:|---:|
| Accessories | 32493 | 639 | 1.9665774166743606 |
| Clothing | 7132 | 162 | 2.2714526079641054 |
| Bikes | 5689 | 171 | 3.0058006679557040 |


### 7.6 Top five models by modelled gross profit and their combined share
```sql
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
```

#### Results
| Rank | Model | Modelled gross profit |
|---:|---|---:| 
|1 |	Mountain-200 |	1366645.8297 |
|2 |	Touring-1000 |	717195.0195 |
|3 |	Road-350-W |	371088.00 |
|4 |	Road-250 |	255680.9739 |
|5 |	Road-550-W |	237267.7683 |	

The top five models together account for 75.7998% of H1 2017 modelled gross profit, displayed as 75.8% in Power BI. Matched Power BI.


### 7.7 H1 sales-value growth from 2016 to 2017
```sql
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
```

#### Results
H1 2016 modelled sales value = 2,952,867.5457; H1 2017 = 9,185,449.4473; YoY growth = 211.0688%. Matched Power BI.
### 7.8. H1 2016 and H1 2017 month-by-month comparison
```sql
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
```
#### Results
The monthly findings are confirmed: every H1 2017 month exceeded its 2016 counterpart. Growth ranged from 182.4% in February to 242.2% in June.


### 7.9. US & Australia share of H1 2017 modelled sales value
```sql
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
```
#### Results


| Country | Modelled sales value | Share of total % |
|---|---:|---:|
| United States |	3130759.1044 | 	34.0838967364875674|
| Australia	| 2408104.8710 | 26.2165165114249902|
| United Kingdom	| 1119087.7631	| 12.1832662573625963|
| Germany	| 1015657.3339	| 11.0572415615280047|
| France	| 873754.2831	| 9.5123737614911603|
| Canada	| 638086.0918	| 6.9467051717056811|

The United States and Australia together account for 60.3004% of H1 2017 modelled sales value. Matched Power BI.

## CLIENTS PROFILES
### 7.10. Customers' educational attaintment and home ownership
Exploratory counts for all customer records; not restricted to H1 2017 buyers.
```sql
SELECT
    education_level,
    home_owner,
    COUNT(*) AS customer_records
FROM clean.v_customers
GROUP BY education_level, home_owner
ORDER BY education_level, home_owner;
```
#### Results
| Education level | Home owner | Customer records |
|---|---|---:|
| Bachelors | N | 1559 |
| Bachelors | Y | 3702 |
| Graduate Degree | N | 692 |
| Graduate Degree | Y | 2433 |
| High School | N | 1256 |
| High School | Y | 1985 |
| Partial College | N | 1691 |
| Partial College | Y | 3275 |
| Partial High School | N | 690 |
| Partial High School | Y | 865 |

### 7.11. Educational attainment and home ownership of clients who purchased on H1 2017
```sql
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
```
#### Results
Education level | Home owner | Distinct buyers |
|---|---|---:|
| Bachelors | N | 921 |
| Bachelors | Y | 2184 |
| Graduate Degree | N | 399 |
| Graduate Degree | Y | 1366 |
| High School | N | 706 |
| High School | Y | 1166 |
| Partial College | N | 964 |
| Partial College | Y | 1936 |
| Partial High School | N | 367 |
| Partial High School | Y | 493 |

Total: 10502 distinct buyers. Aggregated education and home-ownership totals matched Power BI.

### 7.12. Top products purchased by clients in H1 2017
```sql
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
```
#### Results
All five counts matched Power BI. Buyers can purchase several models, so these counts are not additive.

| Model | Distinct buyers |
|---|---:|
| Sport-100 | 3,313 |
| Water Bottle | 2,244 |
| Patch kit | 1,552 |
| Mountain Tire Tube | 1,521 |
| Mountain-200 | 1,441 |

### 7.13. Customer gender counts
```sql
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
```

#### Results
M = 5284; F = 5139;  NA = 79. Matched Power BI.



### 7.14. Customer age counts
```sql
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
```
#### Results

| Age group | Distinct buyers |
|---|---:|
| 35–44 | 1954 |
| 45–54 | 3635 |
| 55+ | 4913 |

Matched Power BI. No H1 2017 buyers fell into “Under 35” or “Unknown”.

### 7.15. Customer (recorded) annual income counts
```sql
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
```
#### Results

| Annual income | Distinct buyers |
|---|---:|
| 40,000–79999 | 4997 |
| Under 40000 | 2895 |
| 80000–119999 | 1919 |
| 120000+ | 691 |

Matched Power BI. No H1 2017 buyers fell into “Unknown”.

## 8. Exporting the report

- Exported the three report pages to PDF and reviewed the layout.
- Working checks remains hidden and is excluded from the export.
- The PDF shows the overall results with no active visual selections. Interactive filtering remains available in Power BI.
- The small NA gender label is omitted in the PDF, but its legend remains. The validated count is 79 buyers.