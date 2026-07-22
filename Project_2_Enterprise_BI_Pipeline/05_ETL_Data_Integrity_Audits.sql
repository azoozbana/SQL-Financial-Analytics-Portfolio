/* ============================================================
   05_ETL_Data_Integrity_Audits.sql
   ------------------------------------------------------------
   The reconciliation queries used to debug and verify the 
   vw_fact_orders pipeline. Kept as a running record of the 
   actual data-quality issues found and fixed during this build - 
   not just theoretical checks, these caught real bugs.
   ============================================================ */

USE portfolio;
GO

-- 1. Any order_ids where the raw returns data genuinely disagrees with itself
-- (one row said 'Yes', another said 'No' for the same order)
SELECT * 
FROM dim_returns_cleaned
WHERE is_returned = 'Conflicting Data';
GO

-- 2. Confirm the historical VAT lookup is actually picking the right rate 
-- per order date (2018-2020 orders should show 5%, 2020-07-01 onward should show 15%)
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

-- 3. Row count check - the whole point of this view is a clean 1:1 join, so 
-- these two counts must always match exactly. If they don't, something in 
-- the join logic is duplicating rows.
SELECT COUNT(*) AS raw_orders_count FROM fact_orders;
SELECT COUNT(*) AS view_orders_count FROM vw_fact_orders;
GO

-- 4. When the counts didn't match during development, this is how the 
-- mismatch got traced - comparing string lengths to spot hidden whitespace
SELECT TOP 5 order_id, LEN(order_id) AS len_orders FROM fact_orders;
SELECT TOP 5 order_id, LEN(order_id) AS len_returns FROM dim_returns_cleaned;
GO

-- 5. Testing whether TRIM-ing both sides of the join fixes the mismatch
SELECT COUNT(*) 
FROM fact_orders AS fo
INNER JOIN dim_returns_cleaned AS r 
    ON TRIM(fo.order_id) = TRIM(r.order_id);
GO

-- 6. Side-by-side comparison of raw order_id values, looking for anything 
-- that looks identical but isn't (turned out to be a source-file formatting issue)
SELECT TOP 10 order_id FROM fact_orders ORDER BY order_id;
SELECT TOP 10 order_id FROM dim_returns_cleaned ORDER BY order_id;
GO

-- 7. Confirm discount is correctly showing NULL (not 0) on the non-applicable 
-- side for returned orders - matters because this column gets averaged, and 
-- a fake 0 here would understate the real average discount
SELECT 
    is_returned, 
    discount, 
    discount_no_return, 
    discount_returned
FROM vw_fact_orders
WHERE is_returned = 'Yes';
GO