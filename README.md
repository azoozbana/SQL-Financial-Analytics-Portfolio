# SQL-Financial-Analytics-Portfolio
 data pipeline and financial analytics dashboard using SQL Server (T-SQL) and Power BI (DAX)

# Financial Analytics & Forensic Audit Portfolio
By **Abdulaziz Mohammed Banafa** — Jeddah, Saudi Arabia  
*Accounting Graduate specializing in Financial Data Analysis & Business Intelligence*

---

## Portfolio Overview
Welcome to my professional data analytics portfolio. This repository contains two distinct, high-impact projects designed to solve real-world corporate finance, auditing, and business intelligence challenges. 

Instead of relying on manual, fragile, and slow Excel spreadsheets, these projects demonstrate how to build robust, automated data pipelines directly from relational databases to executive-ready presentation layers.

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

### [Folder 2: Project 2 — Superstore BI Sales Pipeline](./Project_2_Enterprise_BI_Pipeline)
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

* **All four report pages are fully interactive with synced slicers 
filtering by year, region, or category on any page updates the 
entire report.

### Page 1: Executive Performance Dashboard (Executive P&L Summary)

<img width="976" height="727" alt="exec" src="https://github.com/user-attachments/assets/14f0bf72-c1e0-4e91-9b32-5e57ba9ae10c" />
<img width="981" height="721" alt="execu" src="https://github.com/user-attachments/assets/74e21bd8-98ab-41df-a398-14710ea9aa25" />


### Page 2: Manager & Regional Performance

<img width="1225" height="680" alt="mana" src="https://github.com/user-attachments/assets/0768eed8-5a64-4044-805e-cdeba393bd2e" />
<img width="1218" height="690" alt="manag" src="https://github.com/user-attachments/assets/3b9eb681-0763-4991-ad19-5788ccc76a32" />


### Page 3: Sales Trend & Time Intelligence

<img width="1225" height="682" alt="sales" src="https://github.com/user-attachments/assets/a577a931-b792-41db-83ea-aaae72236810" />


### Page 4: Product Returns & Discount Risk Analysis

<img width="1304" height="727" alt="ret" src="https://github.com/user-attachments/assets/225c5b13-6305-4ce2-bf77-fa770cf4cc36" />



## Contact
LinkedIn: www.linkedin.com/in/abdulazizbanafa
Email: Azoozbanafea666@outlook.com
