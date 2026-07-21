# SQL-Financial-Analytics-Portfolio
 data pipeline and financial analytics dashboard using SQL Server (T-SQL) and Power BI (DAX)

# Financial Analytics & Forensic Audit Portfolio
By **Abdulaziz Mohammed Banafa** — Jeddah, Saudi Arabia  
*Accounting Graduate specializing in Financial Data Analysis & Business Intelligence*

---

## Portfolio Overview
Welcome to my professional data analytics portfolio. This repository contains two distinct, high-impact projects designed to solve real-world corporate finance, auditing, and business intelligence challenges. 

Instead of relying on manual, fragile, and slow Excel spreadsheets, these projects demonstrate how to build robust, automated, and secure data pipelines directly from relational databases to executive-ready presentation layers.

---

## Technical Skills Demonstrated
* **Database Design & T-SQL Development:** Relational schema design, primary/foreign key constraints, transactional indexing, and scripting batch control (`GO` / `USE`).
* **Advanced Query Design:** Chained Common Table Expressions (CTEs), nested subqueries, and advanced joins (`LEFT` / `INNER`).
* **Forensic Auditing:** Temporary staging tables (`#temp`) and conditional aggregation (`SUM(CASE WHEN...)`) to isolate fraudulent or anomalous transactions.
* **Time Intelligence:** Relational date arithmetic (`DATEDIFF`, `DATEADD`, `EOMONTH`) and system clock parameters (`GETDATE()`).
* **Data Modeling:** Power Query (M Language) ETL scripting, Star Schema modeling, and relationship cardinality.
* **Business Intelligence (DAX):** Advanced evaluation context manipulation (`CALCULATE`, `ALL`, `ISINSCOPE`), dynamic ranking (`RANKX`), and time-intelligence measures (`TOTALYTD`, `SAMEPERIODLASTYEAR`).

---

## Repository Structure

### [Folder 1: Project 1 — Forensic Audit & Staging Playground](./Project_1_Forensic_Audit_SQL)
*This folder contains my raw database playground and internal/forensic auditing scripts.*
*   **`01_Create_Tables.sql`:** The physical table creations for both FinancePractice and AlNoorTrading.
*   **`02_Insert_Data.sql`:** The data seeding scripts that populate the raw rows.
*   **`03_Audit_Playground.sql`:** Completed ledger, payroll, and credit audits for both practice databases.

### [Folder 2: Project 2 — Enterprise BI Sales Pipeline](./Project_2_Enterprise_BI_Pipeline)
*This folder contains my advanced data warehouse pipeline, ETL auditing, and Power BI visual assets.*
*   **`04_v_Orders_Analysis_Pipeline.sql`:** The advanced master view with the `OUTER APPLY` historical VAT lookup and dimensional split columns.
*   **`05_ETL_Data_Integrity_Audits.sql`:** Data reconciliation and troubleshooting queries, such as `TRIM`, `LEN()`, and row-count checks.
*   **`06_dim_calendar_m_code.txt`:** Custom Power Query M-code for the Saudi Friday/Saturday weekend calendar.
*   **`07_Superstore_Analytics_Dashboard.pbix`:** Completed, polished Power BI Desktop workbook containing four interactive visual pages.

---

## Core Business Scenarios Solved

### 1. Executive Performance & P&L Dashboard
* **The Business Need:** The CFO required a dynamic, drillable profit-and-loss summary by product category without collapsing individual transactional detail.
* **The Solution:** Connected a dynamic, hierarchical Matrix visual in Power BI to a flat, optimized SQL view. Implemented conditional formatting based on profit margin thresholds to immediately highlight margin compression (red) and target-achieving products (green).

### 2. Credit Exposure & Credit Limit Audit (Subsequent Testing)
* **The Business Need:** The Credit Control Director needed to identify high-risk wholesale accounts whose outstanding balances were approaching their approved credit limits.
* **The Solution:** Constructed a robust SQL query using `LEFT JOIN` and `COALESCE` starting from the master customer directory (to ensure inactive accounts with zero sales were not excluded). Added a conditional flag to highlight any customer whose active revenue crossed more than 10% of their credit limit.

### 3. Sales Commission & Return Rate Audit (Forensic Check)
* **The Business Need:** The Head of Internal Audit suspected sales representatives of artificially inflating their sales metrics by booking high-value orders that were subsequently returned by clients.
* **The Solution:** Designed a multi-stage script using a **Temporary Table** and **Conditional Aggregation** (`SUM(CASE WHEN...)`) to calculate gross bookings, return volumes, and true net sales representative performance side-by-side. Applied a dense ranking function to award performance bonuses fairly.

---

## Dashboard Presentation (Screenshots)

### Page 1: Executive Performance Dashboard (Executive P&L Summary)

<img width="1078" height="808" alt="Executive Performance Dashboard" src="https://github.com/user-attachments/assets/fe802466-a5c6-4c60-826c-2527ec5da73f" />

### Page 2: Manager & Regional Performance

<img width="1430" height="807" alt="Manager   Regional Performance" src="https://github.com/user-attachments/assets/e118427b-1f32-49d1-94b1-790d189241d2" />

### Page 3: Sales Trend & Time Intelligence

<img width="1414" height="794" alt="Sales Trend   Time Intelligence" src="https://github.com/user-attachments/assets/51a2b14f-acc3-474b-8d15-11218ebb67a6" />

### Page 4: Product Returns & Discount Risk Analysis

<img width="1416" height="795" alt="Product Returns   Discount Risk Analysis" src="https://github.com/user-attachments/assets/ef5316dd-b181-4c96-a073-12aa1a29c8a5" />
