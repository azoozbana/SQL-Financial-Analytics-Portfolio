/* ============================================================
   03_Audit_Playground.sql
   ------------------------------------------------------------
   Practice audit queries across two databases:
   - FinancePractice: expense/ledger/payroll/insurance audits
   - AlNoorTrading: the core star schema and its audit scenarios

   Sections that modify data are wrapped in BEGIN TRANSACTION / 
   ROLLBACK so this file can be run safely without permanently 
   altering the seed data.
   ============================================================ */


-- =========================================================================
-- MODULE 1: FinancePractice (Staging & General Ledger Auditing)
-- =========================================================================

USE FinancePractice;
GO

-- Quick lookup: check one specific expense record
SELECT *
FROM Company_Expenses
WHERE Transaction_ID = 4;
GO

-- Review all current expenses
SELECT *
FROM Company_Expenses;
GO

-- Removing a transaction, wrapped so it doesn't stick unless intended
BEGIN TRANSACTION;
DELETE FROM Company_Expenses
WHERE Transaction_ID = 4;
-- Uncomment to make this permanent: COMMIT;
ROLLBACK;
GO

-- Forensic check: duplicate invoice IDs posted across different departments 
-- (the kind of thing that shows up when someone double-books an expense)
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

-- Cleaning up a legacy department name, wrapped for safety
BEGIN TRANSACTION;
UPDATE Corporate_Ledger
SET Department = 'Human Resources'
WHERE Department = 'HR';
ROLLBACK;
GO

-- Removing a specific ledger entry during reconciliation, wrapped for safety
BEGIN TRANSACTION;
DELETE FROM Corporate_Ledger
WHERE Ledger_Sequence_ID = 204;
ROLLBACK;
GO

-- Segmenting invoices into a simple value tier
SELECT 
    Invoice_ID,
    Amount,
    CASE 
        WHEN Amount > 10000 THEN 'High Value' 
        ELSE 'Standard' 
    END AS Price_Tier
FROM Corporate_Ledger;
GO

-- Overall spend and average invoice size
SELECT 
    SUM(Amount) AS Total_Spend,
    AVG(Amount) AS Average_Invoice_Value
FROM Corporate_Ledger;
GO

-- Matching ledger entries to the manager who owns that department
SELECT 
    cc.Invoice_ID,
    cc.Department,
    dd.Manager_Name,
    cc.Amount
FROM Corporate_Ledger AS cc
INNER JOIN Department_Directory AS dd ON cc.Department = dd.Department;
GO

-- Reclassifying large Operations spend into its own bucket, wrapped for safety
BEGIN TRANSACTION;
UPDATE Corporate_Ledger
SET Department = 'High-Yield Ops'
WHERE Department = 'Operations'
  AND Amount > 25000;
ROLLBACK;
GO

-- Purging invalid transactions (negative amounts or blank department), wrapped for safety
BEGIN TRANSACTION;
DELETE FROM Corporate_Ledger
WHERE Amount <= 0
   OR Department = '';
ROLLBACK;
GO

-- All spend managed by one specific manager
SELECT 
    cl.Invoice_ID,
    cl.Department,
    dd.Manager_Name,
    cl.Amount
FROM Corporate_Ledger AS cl
INNER JOIN Department_Directory AS dd ON cl.Department = dd.Department
WHERE dd.Manager_Name = 'Sarah Al-Otaibi';
GO

-- Which approval route each transaction should go through, based on size
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

-- High-value spend specifically in Finance or HR
SELECT 
    Invoice_ID,
    Department,
    Amount
FROM Corporate_Ledger
WHERE Amount > 15000
  AND Department IN ('Finance', 'Human Resources');
GO

-- Transactions posted to a department that isn't in the official directory at all
SELECT 
    cl.Invoice_ID,
    cl.Department,
    cl.Amount
FROM Corporate_Ledger AS cl
LEFT JOIN Department_Directory AS dd ON cl.Department = dd.Department
WHERE dd.Manager_Name IS NULL;
GO

-- Same governance check, different angle: department codes in the ledger 
-- that don't exist in the master directory
SELECT DISTINCT 
    cl.Department AS Ledger_Department,
    dd.Department AS Directory_Department
FROM Corporate_Ledger AS cl
LEFT JOIN Department_Directory AS dd ON cl.Department = dd.Department;
GO

-- Same check again, written as a subquery instead of a join, for comparison
SELECT DISTINCT Department
FROM Corporate_Ledger
WHERE Department NOT IN (
    SELECT Department
    FROM Department_Directory
);
GO

-- Managers whose average transaction size looks unusually high
SELECT 
    dd.Manager_Name,
    AVG(Amount) AS Average_Spend
FROM Corporate_Ledger AS cl
INNER JOIN Department_Directory AS dd ON cl.Department = dd.Department
GROUP BY dd.Manager_Name
HAVING AVG(Amount) > 10000;
GO

-- Departments with more than 2 transactions on record
SELECT 
    Department,
    COUNT(Invoice_ID) AS Number_Of_Invoices,
    MAX(Amount) AS Highest_Value
FROM Corporate_Ledger
GROUP BY Department
HAVING COUNT(*) > 2;
GO

-- Departments whose spend on invoices over $5k adds up to more than $40k total
SELECT 
    Department,
    SUM(Amount) AS Total_Spend
FROM Corporate_Ledger
WHERE Amount > 5000
GROUP BY Department
HAVING SUM(Amount) > 40000;
GO

-- Combined spend and volume audit by manager and department
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

-- All registered managers
SELECT DISTINCT Manager_Name
FROM Department_Directory;
GO

-- Specific finance transaction values worth double-checking
SELECT 
    Ledger_Sequence_ID,
    Invoice_ID,
    Department,
    Amount
FROM Corporate_Ledger
WHERE Amount IN (12000, 15000, 45000)
  AND Department = 'Finance';
GO

-- Everything OUTSIDE the two biggest departments, to catch smaller admin spend
SELECT 
    Invoice_ID,
    Department,
    Amount
FROM Corporate_Ledger
WHERE Department NOT IN ('Finance', 'Operations')
   OR Department IS NULL;
GO

-- Confirming rollback actually works before relying on it elsewhere
BEGIN TRANSACTION;
UPDATE Department_Directory
SET Manager_Name = 'Sarah Jenkins-Miller'
WHERE Department = 'Finance';
SELECT * FROM Department_Directory;
ROLLBACK;
GO

-- Row count sanity check on the ledger
SELECT COUNT(*) AS Total_Rows FROM Corporate_Ledger;
GO

-- Combined filter: departments that are either Finance/Operations, or 
-- unmapped entirely, excluding a few common round-number amounts
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

-- High single-invoice spend in Operations, unmapped departments, or 
-- anything tied to one specific manager
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

-- Forensic check: unapproved vendors and risk-tiered exceptions
BEGIN TRANSACTION;
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
ROLLBACK;
GO

-- Inventory check: obsolete, slow-moving, or unmapped warehouse stock
BEGIN TRANSACTION;
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
ROLLBACK;
GO

-- Commission integrity check: unmapped reps and invalid contract states
BEGIN TRANSACTION;
SELECT 
    sl.Transaction_ID,
    ar.Region,
    sl.Deal_Amount,
    sl.Contract_Status,
    CASE 
        WHEN sl.Sales_Rep_Name IS NULL THEN 'INVESTIGATE: UNMAPPED PERSONNEL' 
        WHEN sl.Contract_Status IN ('Draft', 'Cancelled') THEN 'REVERSE COMMISSION - INVALID CONTRACT' 
        WHEN sl.Deal_Amount > 50000 THEN 'Executive Approval Required' 
        ELSE 'Process Standard Commission' 
    END AS Audit_Action
FROM Sales_Ledger AS sl
LEFT JOIN Active_Roster AS ar ON sl.Sales_Rep_Name = ar.Rep_Name
WHERE ar.Region IS NULL 
   OR (ar.Region != 'Europe' AND sl.Deal_Amount > 10000);
ROLLBACK;
GO

-- Insurance claims: unindexed procedures and over-limit claims
BEGIN TRANSACTION;
SELECT 
    cl.Claim_ID,
    cl.Procedure_Code,
    cl.Billed_Amount,
    pm.Category,
    CASE 
        WHEN pm.Proc_Code IS NULL THEN 'SUSPECT: UNINDEXED PROCEDURE' 
        WHEN cl.Approval_Status = 'Denied' THEN 'REJECTED CLAIM PAYOUT RISK' 
        WHEN cl.Billed_Amount > pm.Max_Allowed_Amount THEN 'OVER-LIMIT EXCEPTION' 
        ELSE 'Compliant Claim' 
    END AS Audit_Risk_Flag
FROM Claims_Ledger AS cl
LEFT JOIN Procedure_Master AS pm ON cl.Procedure_Code = pm.Proc_Code
WHERE pm.Proc_Code IS NULL
   OR (cl.Approval_Status != 'Cancelled' AND cl.Billed_Amount > 1000);
ROLLBACK;
GO


-- =========================================================================
-- MODULE 2: AlNoorTrading (Core Star Schema Audits)
-- =========================================================================

USE AlNoorTrading;
GO

-- High-value wholesale customers in Riyadh
SELECT 
    dc.customer_name,
    dc.city,
    dc.credit_limit
FROM dim_customers AS dc
WHERE dc.customer_type = 'Wholesale'
  AND dc.city = 'Riyadh'
  AND dc.credit_limit > 50000;
GO

-- Discounted, higher-quantity Q1 2024 orders
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

-- Wholesale customers with at least one real transaction on record
SELECT DISTINCT 
    dc.customer_name, 
    dc.city
FROM dim_customers AS dc
INNER JOIN fact_sales AS fs ON dc.customer_id = fs.customer_id
WHERE dc.customer_type = 'Wholesale'
ORDER BY dc.customer_name ASC;
GO

-- Customers with zero transaction history at all
SELECT 
    dc.customer_id, 
    dc.customer_name
FROM dim_customers AS dc
LEFT JOIN fact_sales AS fs ON dc.customer_id = fs.customer_id
GROUP BY dc.customer_id, dc.customer_name
HAVING COUNT(fs.sale_id) = 0 
ORDER BY dc.customer_id;
GO

-- Revenue by category, non-returned sales only, excluding Accessories, 
-- looking for smaller categories under $5,000
SELECT 
    dp.category,
    SUM(dp.unit_price * fs.quantity) AS Total_revenue
FROM dim_products AS dp
INNER JOIN fact_sales AS fs ON dp.product_id = fs.product_id
WHERE fs.is_returned = 'No'
  AND dp.category != 'Accessories'
GROUP BY dp.category
HAVING SUM(dp.unit_price * fs.quantity) < 5000
ORDER BY Total_revenue DESC;
GO

-- Reps with more than 2 completed sales - basic performance screen
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

-- Full sales ledger joined across all three dimension tables, with 
-- readable placeholders for missing customer/employee links
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

-- Sales by customer name and city, alphabetically
SELECT 
    fs.sale_id,
    fs.sale_date,
    COALESCE(dc.customer_name, 'Walk-in Customer') AS customer_name,
    COALESCE(dc.city, 'Unknown Location') AS city
FROM fact_sales AS fs
LEFT JOIN dim_customers AS dc ON fs.customer_id = dc.customer_id
ORDER BY customer_name ASC;
GO

-- Orders with an unusually high quantity, compared to the overall average
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

-- Employee revenue vs. salary - flagging anyone generating more than 
-- 3x their salary in net revenue as a high performer
WITH employee_revenue AS (
    SELECT 
        fs.employee_id,
        de.employee_name,
        de.salary,
        SUM(CASE WHEN fs.is_returned = 'No' 
                 THEN fs.quantity * (dp.unit_price * (1 - fs.discount_pct)) 
                 ELSE 0 END) AS total_revenue
    FROM fact_sales AS fs
    LEFT JOIN dim_employees AS de ON fs.employee_id = de.employee_id
    LEFT JOIN dim_products AS dp ON fs.product_id = dp.product_id
    GROUP BY fs.employee_id, de.employee_name, de.salary
)
SELECT 
    COALESCE(employee_name, 'Unassigned Employee') AS employee_name,
    salary,
    total_revenue,
    CASE
        WHEN total_revenue > (salary * 3) THEN 'High ROI'
        ELSE 'Standard ROI'
    END AS performance_status 
FROM employee_revenue;
GO

-- Credit utilization: wholesale customers' real purchases vs. their limit.
-- Starting from dim_customers (not fact_sales) so a customer with zero 
-- purchases still shows up in the report instead of disappearing.
WITH customer_sales_base AS (
    SELECT 
        dc.customer_id,
        dc.customer_name,
        dc.credit_limit,
        COALESCE(SUM(fs.quantity * (dp.unit_price * (1 - fs.discount_pct))), 0) AS total_purchases
    FROM dim_customers AS dc
    LEFT JOIN fact_sales AS fs 
        ON dc.customer_id = fs.customer_id 
        AND fs.is_returned = 'No'
    LEFT JOIN dim_products AS dp ON fs.product_id = dp.product_id
    WHERE dc.customer_type = 'Wholesale'
    GROUP BY dc.customer_id, dc.customer_name, dc.credit_limit
)
SELECT 
    customer_name,
    credit_limit,
    total_purchases,
    CASE
        WHEN total_purchases > (credit_limit * 0.50) THEN 'High Utilization'
        ELSE 'Low Utilization'
    END AS utilization_risk
FROM customer_sales_base
ORDER BY total_purchases DESC;
GO

-- Product revenue summary staged in a temp table, then filtered for 
-- items above $3,000 in total revenue
SELECT 
    fs.product_id,
    dp.product_name,
    dp.category,
    SUM(fs.quantity * (dp.unit_price * (1 - fs.discount_pct))) AS Total_revenue
INTO #product_summary
FROM fact_sales AS fs 
LEFT JOIN dim_products AS dp ON fs.product_id = dp.product_id
WHERE fs.is_returned = 'No'
GROUP BY fs.product_id, dp.product_name, dp.category;

SELECT * 
FROM #product_summary
WHERE Total_revenue > 3000
ORDER BY Total_revenue ASC;

DROP TABLE #product_summary;
GO

-- Month-over-month revenue variance, using LAG to compare each month 
-- against the one before it
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

-- Salary ranking, comparing RANK (skips numbers after a tie) against 
-- DENSE_RANK (doesn't skip) side by side
SELECT 
    COALESCE(employee_name, 'Unassigned Employee') AS employee_name,
    department,
    salary,
    RANK() OVER(ORDER BY salary DESC) AS salary_rank,
    DENSE_RANK() OVER(ORDER BY salary DESC) AS salary_dense_rank
FROM dim_employees;
GO

-- Customer retention: for each customer, find the date of their NEXT 
-- purchase after the current one, to spot gaps in buying pattern
WITH purchase_ledger AS (
    SELECT 
        fs.sale_id,
        fs.customer_id,
        COALESCE(dc.customer_name, 'Walk-in Customer') AS customer_name,
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