-- =========================================================================
-- PART 2: Superstore ETL & Data-Integrity Reconciliations
-- =========================================================================

USE portfolio;
GO

-- 1. DATA INTEGRITY CHECK: Audit the returns view for conflicting customer records
-- (e.g., if one row says 'Yes' and another says 'No' for the same Order ID)
SELECT * 
FROM dim_returns_cleaned
WHERE is_returned = 'Conflicting Data'; -- Fixed: Column name is is_returned, not returned
GO

-- 2. DYNAMIC LOGIC CHECK: Verify that OUTER APPLY is pulling the correct historical VAT
-- (Ensures order dates in 2018 get 5% and order dates in 2021 get 15% VAT)
SELECT 
    fo.order_id,
    fo.order_date,
    v.vat_rate
FROM fact_orders AS fo
OUTER APPLY (
    SELECT TOP 1 vat_rate
    FROM dim_vat_rates
    WHERE effective_date <= fo.order_date
    ORDER BY effective_date DESC
) AS v;
GO

-- 3. RECONCILIATION CHECK: Verify row counts match to ensure no join "fan-out" (duplication)
-- The row count of your final reporting view MUST exactly match your raw orders table
SELECT COUNT(*) AS raw_orders_count FROM fact_orders;
SELECT COUNT(*) AS view_orders_count FROM vw_fact_orders;
GO

-- 4. FORENSIC DIAGNOSTIC: Investigate why the standard LEFT JOIN is missing returned orders
-- If the row counts don't match, we check if the raw Order IDs have hidden spaces
SELECT TOP 5 order_id, LEN(order_id) AS len_orders FROM fact_orders;
SELECT TOP 5 order_id, LEN(order_id) AS len_returns FROM dim_returns_cleaned;
GO

-- 5. THE TRIM FIX: Test if trimming trailing spaces fixes our join mismatch
SELECT COUNT(*) 
FROM fact_orders AS fo
INNER JOIN dim_returns_cleaned AS r 
    ON TRIM(fo.order_id) = TRIM(r.order_id);
GO

-- 6. SEQUENCE CHECK: Compare raw order ID characters to look for hidden symbols
SELECT TOP 10 order_id FROM fact_orders ORDER BY order_id;
SELECT TOP 10 order_id FROM dim_returns_cleaned ORDER BY order_id;
GO

-- 7. CALCULATION CHECK: Verify that returned discounts are safely zeroed out in the final view
SELECT 
    is_returned, 
    discount, 
    discount_no_return, 
    discount_returned
FROM vw_fact_orders
WHERE is_returned = 'Yes';
GO