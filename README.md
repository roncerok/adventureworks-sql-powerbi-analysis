# AdventureWorks — Commercial Performance Analysis

**PostgreSQL · Power BI · DAX · Data quality · KPI reporting**

By Kristian Roncero

An end-to-end data-analysis course project exploring sales growth, product profitability, market concentration and buyer profiles for the fictional AdventureWorks business.

I used PostgreSQL to audit and prepare the data, built a three-page Power BI report, and validated selected report results with SQL.

## Explore the project

- **[View the report — PDF](reports/AdventureWorks.pdf)** — all three pages, no Power BI installation required.
- [Technical documentation](docs/AdventureWorks_full.md) — methodology, DAX measures, findings and recorded validation results.
- [SQL scripts](sql/) — data preparation, audits and report validation.
- [Download the Power BI report](reports/AdventureWorks.pbix) — requires Power BI Desktop.

## Business questions

- How did modelled sales value change between January–June 2016 and January–June 2017?
- Which countries and product models contributed most to performance?
- How did product categories compare on modelled gross margin and returned-to-sold units ratios?
- What were the observed profiles of H1 2017 buyers, and which models reached the most distinct buyers?

## Key findings

| Finding | Result |
|---|---|
| H1 modelled sales value | Increased from 2.95 million in 2016 to 9.19 million in 2017: **+211.1%** |
| Market concentration | The United States and Australia contributed **60.3%** of H1 2017 modelled sales value |
| Product concentration | Five models contributed **75.8%** of H1 2017 modelled gross profit |
| Category performance | Bikes contributed **89.4%** of modelled gross profit; Accessories had the highest modelled gross margin at **62.8%** |
| Buyer reach | H1 2017 had **10,502 distinct buyers**; Sport-100 reached the most buyers at **3,313** |

## Approach

1. Imported the source CSVs into PostgreSQL raw tables with text columns.
2. Consolidated three yearly sales tables using `UNION ALL`.
3. Audited missing values, duplicate keys, relationships, numeric formats and dates.
4. Created clean views with trimmed values, converted data types and product hierarchy labels.
5. Built a Power BI model with separate sales and returns fact tables, shared dimensions and a DAX date table.
6. Created measures for modelled sales value, gross profit, margin, year-over-year growth, returns ratios and distinct buyers.
7. Recalculated selected totals and breakdowns in PostgreSQL and compared them with Power BI using matching periods and filters.

The technical documentation records the validation results. Individual outputs from the initial data-quality audits were not retained; the audit queries are included.

## SQL files

| Script | Purpose |
|---|---|
| [01_raw_schema_and_tables.sql](sql/01_raw_schema_and_tables.sql) | Create the raw schema and import tables |
| [02_sales_view.sql](sql/02_sales_view.sql) | Consolidate yearly sales and check row counts |
| [03_data_audit.sql](sql/03_data_audit.sql) | Audit data quality and relationships |
| [04_clean_views.sql](sql/04_clean_views.sql) | Create typed clean views and compare row counts |
| [05_SQL_validation.sql](sql/05_SQL_validation.sql) | Validate selected report figures |

## Data source and scope

The project uses a lightweight AdventureWorks dataset comprising **10 CSV files**, supplied by **Grimm Bildungszentrum** for the final data-analysis course project.

Sales cover 2015, 2016 and January–June 2017. The main comparison uses January–June in both 2016 and 2017 to compare equivalent periods.

The course materials use the AdventureWorksDW2022 project heading, but the precise upstream version of the supplied CSV extract has not been independently confirmed.

## Interpretation and limitations

- **Modelled sales value = quantity × fixed product price.** It is not actual transaction revenue.
- Modelled gross profit uses fixed product prices and costs and is calculated before returns. It is not actual historical profit.
- Currency is unspecified for the modelled financial values, so no currency symbol is assigned.
- The returned-to-sold units ratio compares units recorded during the same period. Returns cannot be linked to their original orders or customers.
- Buyer profiles describe observed purchasers. Customer attributes may not reflect circumstances at purchase; age is calculated at 30 June 2017.
- Buyers can purchase several models, so model-level buyer counts are not additive.
- Growth towards June in both comparison years does not establish seasonality.

## Viewing and reproducing the work

The PDF provides a static preview of the report. Interactive filtering was implemented in Power BI but is not available in the PDF.

The Power BI file includes the imported dataset. The original source CSVs are not included separately. Refreshing the report requires access to the source data and updating the data-source settings for your environment.

To reproduce the SQL workflow, obtain the same source CSVs, run script 01, import the files into their corresponding raw tables, and then work through scripts 02–05. Inspect audit results and resolve any issues before proceeding to type conversions.

The technical documentation lists the expected source filenames and columns. The scripts do not automate CSV loading, and the repository is not currently a self-contained reproduction package.
