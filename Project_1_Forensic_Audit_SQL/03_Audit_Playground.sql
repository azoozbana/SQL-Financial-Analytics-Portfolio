-- =========================================================================
-- MODULE 1: FinancePractice (Staging & General Ledger Auditing)
-- =========================================================================

USE FinancePractice;
GO

-- Audit Check: Retrieve expense transaction #7 for detail verification
SELECT *
FROM Company_Expenses
WHERE Transaction_ID = 4;
GO

-- Audit Check: Review all current company expenses
SELECT *
FROM Company_Expenses;
GO

-- Maintenance Purge: Delete specific transaction record for adjustment
DELETE FROM Company_Expenses
WHERE Transaction_ID = 4;
GO

-- Forensic Audit: Identify duplicate invoice entries (the "Sticky Note" check)
-- This query identifies duplicate invoice IDs posted to different departments
SELECT 
    Ledger_Sequence_ID,
    Invoice_ID,
    Department,
    Amount
FROM Corporate_Ledger
WHERE Invoice_ID IN (
    SELECT Invoice_ID
    FROM Corporate_Ledger
    GROUP BY Invoice_ID, Department
    HAVING COUNT(*) > 1
)
ORDER BY Invoice_ID DESC;
GO

-- Operational Update: Clean up legacy department names (HR -> Human Resources)
UPDATE Corporate_Ledger
SET Department = 'Human Resources'
WHERE Department = 'HR';
GO

-- Maintenance Purge: Delete specific sequence ID for ledger reconciliation
DELETE FROM Corporate_Ledger
WHERE Ledger_Sequence_ID = 204;
GO

-- Financial Classification: Segment invoice sizes into standard risk/value tiers
SELECT 
    Invoice_ID,
    Amount,
    CASE 
        WHEN Amount > 10000 THEN 'High Value' 
        ELSE 'Standard' 
    END AS Price_Tier
FROM Corporate_Ledger;
GO

-- Financial Metrics: Calculate overall spend and average invoice value
SELECT 
    SUM(Amount) AS Total_Spend,
    AVG(Amount) AS Average_Invoice_Value
FROM Corporate_Ledger;
GO

-- Reconciliation Join: Match general ledger entries to their approved managers
SELECT 
    cc.Invoice_ID,
    cc.Department,
    dd.Manager_Name,
    cc.Amount
FROM Corporate_Ledger AS cc
INNER JOIN Department_Directory AS dd ON cc.Department = dd.Department;
GO

-- Control Update: Reclassify high-value operations transactions to a separate department
UPDATE Corporate_Ledger
SET Department = 'High-Yield Ops'
WHERE Department = 'Operations'
  AND Amount > 25000;
GO

-- Risk Mitigation: Purge invalid transaction records with negative or empty values
DELETE FROM Corporate_Ledger
WHERE Amount <= 0
   OR Department = '';
GO

-- Executive Reporting: Filter ledger spend for transactions managed by Sarah Al-Otaibi
SELECT 
    cl.Invoice_ID,
    cl.Department,
    dd.Manager_Name,
    cl.Amount
FROM Corporate_Ledger AS cl
INNER JOIN Department_Directory AS dd ON cl.Department = dd.Department
WHERE dd.Manager_Name = 'Sarah Al-Otaibi';
GO

-- Audit Matrix: Map transactions to their required corporate approval routes
SELECT 
    cl.Invoice_ID,
    dd.Manager_Name,
    cl.Amount,
    CASE 
        WHEN Amount > 50000 THEN 'Requires Board Sign-off' 
        WHEN Amount > 10000 THEN 'Requires Manager Approval' 
        ELSE 'Auto-Approved' 
    END AS Approval_Route
FROM Corporate_Ledger AS cl
INNER JOIN Department_Directory AS dd ON cl.Department = dd.Department;
GO

-- High-Risk Audit: Identify high-value spend in key administrative departments
SELECT 
    Invoice_ID,
    Department,
    Amount
FROM Corporate_Ledger
WHERE Amount > 15000
  AND Department IN ('Finance', 'Human Resources');
GO

-- Governance Check: Identify transactions assigned to unmapped or unapproved departments
SELECT 
    cl.Invoice_ID,
    cl.Department,
    cl.Amount
FROM Corporate_Ledger AS cl
LEFT JOIN Department_Directory AS dd ON cl.Department = dd.Department
WHERE dd.Manager_Name IS NULL;
GO

-- System Comparison: Audit department codes that exist in the ledger but not in the master directory
SELECT DISTINCT 
    cl.Department AS Ledger_Department,
    dd.Department AS Directory_Department
FROM Corporate_Ledger AS cl
LEFT JOIN Department_Directory AS dd ON cl.Department = dd.Department;
GO

-- Alternative Directory Check: Double-check missing departments using a subquery
SELECT DISTINCT Department
FROM Corporate_Ledger
WHERE Department NOT IN (
    SELECT Department
    FROM Department_Directory
);
GO

-- Budget Controls: Identify managers whose average transactional spend exceeds $10k
SELECT 
    dd.Manager_Name,
    AVG(Amount) AS Average_Spend
FROM Corporate_Ledger AS cl
INNER JOIN Department_Directory AS dd ON cl.Department = dd.Department
GROUP BY dd.Manager_Name
HAVING AVG(Amount) > 10000;
GO

-- Volume Check: Identify active departments handling more than 2 transactions
SELECT 
    Department,
    COUNT(Invoice_ID) AS Number_Of_Invoices,
    MAX(Amount) AS Highest_Value
FROM Corporate_Ledger
GROUP BY Department
HAVING COUNT(*) > 2;
GO

-- Budget Check: Identify departments whose high-value spend (over $5k) totals more than $40k
SELECT 
    Department,
    SUM(Amount) AS Total_Spend
FROM Corporate_Ledger
WHERE Amount > 5000
GROUP BY Department
HAVING SUM(Amount) > 40000;
GO

-- Comprehensive Departmental Spend & Volume Audit
SELECT 
    dd.Manager_Name,
    cl.Department,
    SUM(cl.Amount) AS Total_Spend,
    COUNT(cl.Invoice_ID) AS Number_Of_Invoices_Done
FROM Corporate_Ledger AS cl
LEFT JOIN Department_Directory AS dd ON cl.Department = dd.Department
WHERE cl.Amount > 3000
GROUP BY cl.Department, dd.Manager_Name
HAVING SUM(cl.Amount) > 45000;
GO

-- Directory Audit: List all unique managers registered in the company
SELECT DISTINCT Manager_Name
FROM Department_Directory;
GO

-- Compliance Check: Audit specific finance transaction values
SELECT 
    Ledger_Sequence_ID,
    Invoice_ID,
    Department,
    Amount
FROM Corporate_Ledger
WHERE Amount IN (12000, 15000, 45000)
  AND Department = 'Finance';
GO

-- Exclude key operational departments to audit minor administrative spend
SELECT 
    Invoice_ID,
    Department,
    Amount
FROM Corporate_Ledger
WHERE Department NOT IN ('Finance', 'Operations')
   OR Department IS NULL;
GO

-- Transaction Control testing (Ensures rollback safe-guards are active)
BEGIN TRANSACTION;

UPDATE Department_Directory
SET Manager_Name = 'Sarah Jenkins-Miller'
WHERE Department = 'Finance';

SELECT * FROM Department_Directory;

ROLLBACK;
GO

-- Staging & Seeding Verification: Count total processed lines in the ledger
SELECT COUNT(*) AS Total_Rows FROM Corporate_Ledger;
GO

-- Complex Staging Audit: Filter, group, and sum administrative spend across key segments
SELECT 
    cl.Department,
    dd.Manager_Name,
    SUM(cl.Amount) AS Total_Audited_Spend,
    COUNT(DISTINCT cl.Invoice_ID) AS Unique_Invoice_Count
FROM Corporate_Ledger AS cl
LEFT JOIN Department_Directory AS dd ON cl.Department = dd.Department
WHERE cl.Amount NOT IN (3000, 5000, 10000)
  AND (cl.Department IN ('Finance', 'Operations') OR dd.Manager_Name IS NULL)
GROUP BY cl.Department, dd.Manager_Name
HAVING SUM(cl.Amount) > 15000;
GO

-- Multi-Condition Audit: Find high-value operational or unmapped department spend
SELECT 
    cl.Department,
    dd.Manager_Name,
    MAX(cl.Amount) AS Max_Single_Invoice,
    SUM(cl.Amount) AS Total_Spend
FROM Corporate_Ledger AS cl
LEFT JOIN Department_Directory AS dd ON cl.Department = dd.Department
WHERE cl.Amount > 1000
  AND (cl.Department = 'Operations' OR cl.Department IS NULL OR dd.Manager_Name = 'Sarah Jenkins')
GROUP BY cl.Department, dd.Manager_Name
HAVING MAX(cl.Amount) > 8000;
GO

-- Forensic Audit: Identify unapproved vendors and high-risk transactional exceptions
BEGIN TRANSACTION;
GO

SELECT 
    cl.Invoice_ID,
    cl.Department,
    cl.Amount,
    cl.Vendor AS Vendor_Name,
    CASE 
        WHEN av.Vendor_Name IS NULL THEN 'CRITICAL: UNAPPROVED VENDOR' 
        WHEN cl.Amount > 20000 THEN 'High Risk' 
        WHEN cl.Amount >= 5000 THEN 'Medium Risk' 
        ELSE 'Low Risk' 
    END AS Risk_Level
FROM Corporate_Ledger AS cl
LEFT JOIN Approved_Vendors AS av ON cl.Vendor = av.Vendor_Name
WHERE cl.Department IS NULL 
   OR (cl.Department != 'Human Resources' AND cl.Amount > 2000);
GO

ROLLBACK; -- Safety shield recovery anchor
GO

-- Inventory Valuation Audit: Identify obsolete, slow-moving, or unmapped warehouse stock
BEGIN TRANSACTION;
GO

SELECT 
    ins.Item_ID,
    ins.Category,
    ins.Unit_Cost,
    ins.Days_In_Storage,
    CASE 
        WHEN pm.Item_Name IS NULL THEN 'UNMAPPED ASSET - HOLD' 
        WHEN ins.Days_In_Storage > 365 THEN 'Obsolete - Write Off' 
        WHEN ins.Days_In_Storage >= 180 THEN 'Slow Moving - Provision Required' 
        ELSE 'Healthy Inventory' 
    END AS Valuation_Status
FROM Inventory_Stock AS ins
LEFT JOIN Price_Master AS pm ON ins.Item_Name = pm.Item_Name
WHERE ins.Category IS NULL 
   OR (ins.Category != 'Perishables' AND ins.Unit_Cost > 500);
GO

ROLLBACK; -- Safety shield recovery anchor
GO

-- Commission Integrity Audit: Identify unmapped personnel and unapproved contract states
BEGIN TRANSACTION;
GO

SELECT 
    sl.transaction_id,
    ar.region,
    sl.deal_amount,
    sl.Contract_Status,
    CASE 
        WHEN sl.Sales_Rep_Name IS NULL THEN 'INVESTIGATE: UNMAPPED PERSONNEL' 
        WHEN sl.Contract_Status IN ('Draft', 'Cancelled') THEN 'REVERSE COMMISSION - INVALID CONTRACT' 
        WHEN sl.deal_amount > 50000 THEN 'Executive Approval Required' 
        ELSE 'Process Standard Commission' 
    END AS Audit_Action
FROM SALES_LEDGER AS sl
LEFT JOIN Active_Roster AS ar ON sl.sales_rep_name = ar.rep_name
WHERE ar.region IS NULL 
   OR (ar.region != 'Europe' AND sl.deal_amount > 10000);
GO

ROLLBACK;
GO

-- Insurance Claims Audit: Identify unindexed procedure codes and over-limit claims
BEGIN TRANSACTION;
GO

SELECT 
    cl.claim_id,
    cl.procedure_code,
    cl.billed_amount,
    pm.category,
    CASE 
        WHEN pm.Proc_Code IS NULL THEN 'SUSPECT: UNINDEXED PROCEDURE' 
        WHEN cl.Approval_Status = 'Denied' THEN 'REJECTED CLAIM PAYOUT RISK' 
        WHEN cl.billed_amount > pm.Max_Allowed_Amount THEN 'OVER-LIMIT EXCEPTION' 
        ELSE 'Compliant Claim' 
    END AS Audit_Risk_Flag
FROM Claims_Ledger AS cl
LEFT JOIN Procedure_Master AS pm ON cl.Procedure_Code = pm.Proc_Code
WHERE pm.Proc_Code IS NULL
   OR (cl.Approval_Status != 'Cancelled' AND cl.Billed_Amount > 1000);
GO

ROLLBACK;
GO


-- =========================================================================
-- MODULE 2: AlNoorTrading (Core Enterprise Star Schema & Master Audits)
-- =========================================================================

USE AlNoorTrading;
GO

-- Credit Audit: Identify high-value wholesale customers in Riyadh with credit limits > $50k
SELECT 
    dc.customer_name,
    dc.city,
    dc.credit_limit
FROM dim_customers AS dc
WHERE dc.customer_type = 'Wholesale'
  AND dc.city = 'Riyadh'
  AND dc.credit_limit > 50000;
GO

-- Transaction Audit: Review active, high-volume Q1 2024 orders with active discounts
SELECT 
    fs.sale_id,
    fs.sale_date,
    fs.customer_id,
    fs.product_id,
    fs.quantity,
    fs.discount_pct
FROM fact_sales AS fs
WHERE fs.customer_id IS NOT NULL
  AND fs.discount_pct > 0.00
  AND fs.quantity > 5
  AND YEAR(fs.sale_date) = 2024
ORDER BY fs.sale_date DESC;
GO

-- Customer Audit: Identify active wholesale customers and their regional offices
SELECT DISTINCT 
    dc.customer_name, 
    dc.city
FROM dim_customers AS dc
INNER JOIN fact_sales AS fs ON dc.customer_id = fs.customer_id
WHERE dc.customer_type = 'Wholesale'
ORDER BY dc.customer_name ASC;
GO

-- Star Schema Check: Find completely inactive customer accounts with zero transaction history
SELECT 
    dc.customer_id, 
    dc.customer_name
FROM dim_customers AS dc
LEFT JOIN fact_sales AS fs ON dc.customer_id = fs.customer_id
GROUP BY dc.customer_id, dc.customer_name
HAVING COUNT(fs.sale_id) = 0 
ORDER BY dc.customer_id;
GO

-- Financial Performance: Calculate total revenue by category (excluding accessories) under $5,000
SELECT 
    dp.category,
    SUM(dp.unit_price * fs.quantity) AS Total_revenue
FROM dim_products AS dp
INNER JOIN fact_sales AS fs ON dp.product_id = fs.product_id
WHERE fs.sale_date IS NOT NULL 
  AND dp.category != 'Accessories'
GROUP BY dp.category
HAVING SUM(dp.unit_price * fs.quantity) < 5000
ORDER BY Total_revenue DESC;
GO

-- Operational Audit: Identify active, high-performing sales reps (minimum 2 sales)
SELECT 
    fs.employee_id,
    COUNT(fs.sale_id) AS total_sales,
    SUM(fs.quantity) AS total_quantity,
    ROUND(AVG(fs.discount_pct), 2) AS avg_discount
FROM fact_sales AS fs
WHERE fs.is_returned = 'No'
GROUP BY fs.employee_id
HAVING COUNT(fs.sale_id) > 2;
GO

-- Master 4-Table Join: Build a complete, detailed sales ledger with clean null placeholders
SELECT 
    fs.sale_id,
    fs.sale_date,
    dp.product_name,
    COALESCE(dc.customer_name, 'Walk-in Customer') AS customer_name,
    COALESCE(de.employee_name, 'Unassigned Employee') AS employee_name
FROM fact_sales AS fs
LEFT JOIN dim_products AS dp ON fs.product_id = dp.product_id
LEFT JOIN dim_customers AS dc ON fs.customer_id = dc.customer_id
LEFT JOIN dim_employees AS de ON fs.employee_id = de.employee_id;
GO

-- Customer Ledger: Display customer names, cities, and sales sorted alphabetically
SELECT 
    fs.sale_id,
    fs.sale_date,
    COALESCE(dc.customer_name, 'Individual Buyer') AS customer_name,
    COALESCE(dc.city, 'Direct Online Delivery') AS city
FROM fact_sales AS fs
LEFT JOIN dim_customers AS dc ON fs.customer_id = dc.customer_id
ORDER BY customer_name ASC;
GO

-- Subquery Check: Find sales transactions with quantities greater than the system average
SELECT 
    fs.sale_id,
    fs.sale_date,
    fs.quantity
FROM fact_sales AS fs
WHERE fs.quantity > (
    SELECT AVG(quantity) 
    FROM fact_sales
);
GO

-- CTE Study: Evaluate employee sales performance relative to their base salaries
WITH employee_revenue AS (
    SELECT 
        fs.employee_id,
        de.employee_name,
        de.salary,
        SUM(fs.quantity * (dp.unit_price * (1 - fs.discount_pct))) AS Total_revenue
    FROM fact_sales AS fs
    LEFT JOIN dim_employees AS de ON fs.employee_id = de.employee_id
    LEFT JOIN dim_products AS dp ON fs.product_id = dp.product_id
    GROUP BY fs.employee_id, de.employee_name, de.salary
)
SELECT 
    employee_name,
    salary,
    Total_revenue,
    CASE
        WHEN Total_revenue > (salary * 3) THEN 'High ROI'
        ELSE 'Standard ROI'
    END AS performance_status 
FROM employee_revenue;
GO

-- Credit Utilization CTE: Audit wholesale accounts' total purchases against their credit limits
WITH customer_sales_base AS (
    SELECT 
        fs.customer_id,
        dc.customer_name,
        dc.credit_limit,
        SUM(fs.quantity * (dp.unit_price * (1 - fs.discount_pct))) AS total_purchases
    FROM fact_sales AS fs
    LEFT JOIN dim_customers AS dc ON fs.customer_id = dc.customer_id
    LEFT JOIN dim_products AS dp ON fs.product_id = dp.product_id
    WHERE fs.is_returned = 'No'
    GROUP BY fs.customer_id, dc.customer_name, dc.credit_limit
)
SELECT 
    COALESCE(csb.customer_name, 'Walk-in Customer') AS customer_name,
    credit_limit,
    total_purchases,
    CASE
        WHEN total_purchases > (credit_limit * 0.50) THEN 'High Utilization'
        ELSE 'Low Utilization'
    END AS utilization_risk
FROM customer_sales_base AS csb
ORDER BY total_purchases DESC;
GO

-- Staging & Reconciling: Use a temporary table to isolate high-value product sales
SELECT 
    fs.product_id,
    dp.product_name,
    dp.category,
    SUM(fs.quantity * (dp.unit_price * (1 - fs.discount_pct))) AS Total_revenue
INTO #product_summary
FROM fact_sales AS fs 
LEFT JOIN dim_products AS dp ON fs.product_id = dp.product_id
WHERE TRIM(fs.is_returned) = 'No'
GROUP BY fs.product_id, dp.product_name, dp.category;

SELECT * 
FROM #product_summary
WHERE Total_revenue > 3000
ORDER BY Total_revenue ASC;

DROP TABLE #product_summary;
GO

-- Master Chained CTE: Compile a chronological Month-over-Month (MoM) revenue variance report
WITH monthly_revenue_summary AS (
    SELECT 
        MONTH(fs.sale_date) AS sale_month,
        SUM(fs.quantity * (dp.unit_price * (1 - fs.discount_pct))) AS total_monthly_revenue
    FROM fact_sales AS fs
    LEFT JOIN dim_products AS dp ON fs.product_id = dp.product_id
    WHERE fs.is_returned = 'No'
    GROUP BY MONTH(fs.sale_date)
),
previous_month AS (
    SELECT *, 
           LAG(total_monthly_revenue, 1) OVER(ORDER BY sale_month) AS prior_month_revenue
    FROM monthly_revenue_summary
)
SELECT *, 
       (total_monthly_revenue - prior_month_revenue) AS monthly_variance
FROM previous_month;
GO

-- Employee Salary Audit: Compare standard and dense ranking algorithms side-by-side
SELECT 
    COALESCE(employee_name, 'Contractor') AS employee_name,
    department,
    salary,
    RANK() OVER(ORDER BY salary DESC) AS salary_rank,
    DENSE_RANK() OVER(ORDER BY salary DESC) AS salary_dense_rank
FROM dim_employees;
GO

-- Customer Retention Audit: Use LEAD to calculate the next chronological purchase date for each customer
WITH purchase_ledger AS (
    SELECT 
        fs.sale_id,
        fs.customer_id,
        COALESCE(dc.customer_name, 'Walk-In') AS customer_name,
        fs.sale_date
    FROM fact_sales AS fs
    LEFT JOIN dim_customers AS dc ON fs.customer_id = dc.customer_id
    WHERE fs.is_returned = 'No'
)
SELECT *,
       LEAD(sale_date, 1) OVER(PARTITION BY customer_id ORDER BY sale_date ASC) AS next_purchase_date
FROM purchase_ledger
ORDER BY sale_date ASC;
GO


-- =========================================================================
-- MODULE 3: Advanced Quantitative Analytics Playground (Stock Market MA)
-- =========================================================================

USE FinancePractice;
GO

-- Quantitative Check: Calculate 50-day and 200-day moving averages chronologically
-- This CTE-based query stages chronological SPY closing prices and runs offset calculations
WITH create_seq AS (
    SELECT 
        ROW_NUMBER() OVER(ORDER BY Date_n) AS row_sequence,
        *
    FROM SPY_close_price_5Y
),
ma AS (
    SELECT 
        *,
        ROUND(LEAD(Close_n, 50) OVER(ORDER BY Date_n), 0) AS m50_ma,
        ROUND(LEAD(Close_n, 200) OVER(ORDER BY Date_n), 0) AS m200_ma
    FROM create_seq
),
av AS (
    SELECT 
        *,
        ROUND(AVG(m50_ma) OVER(ORDER BY date_n), 0) AS avg_50,
        ROUND(AVG(m200_ma) OVER(ORDER BY date_n), 0) AS avg_200
    FROM ma
)
SELECT * 
FROM av;
GO