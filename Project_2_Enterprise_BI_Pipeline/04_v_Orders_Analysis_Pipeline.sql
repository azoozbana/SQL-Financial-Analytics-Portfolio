/* ============================================================
   04_v_Orders_Analysis_Pipeline.sql
   ------------------------------------------------------------
   Builds the core reporting layer for the Superstore project.

   Assumes these raw tables already exist in the database 
   (imported manually via SQL Server's Import Wizard from the 
   Superstore Excel file - not created by this script):
     - fact_orders   (raw order line items)
     - dim_returns   (raw return records, may contain duplicates)
     - dim_managers  (region -> manager lookup)
   ============================================================ */

-- Create the portfolio database if it doesn't already exist
IF DB_ID('portfolio') IS NULL
BEGIN
    CREATE DATABASE portfolio;
END
GO

USE portfolio;
GO


-- =========================================================================
-- STEP 1: DEDUPLICATE RETURNS (dim_returns_cleaned)
-- =========================================================================

-- Check for duplicate order_ids in the raw returns table before building the view
SELECT 
    order_id,
    COUNT(order_id) AS duplicate_count
FROM dim_returns
GROUP BY order_id
HAVING COUNT(*) > 1;
GO

DROP VIEW IF EXISTS dim_returns_cleaned;
GO

-- Cleaned returns view - collapses duplicate order_ids down to one row each.
-- MAX() is only a tie-breaker for genuine conflicts (flagged separately below) - 
-- when all rows for an order_id already agree, MAX just passes that single value through.
CREATE VIEW dim_returns_cleaned AS
SELECT 
    order_id,
    CASE 
        WHEN COUNT(DISTINCT returned) > 1 THEN 'Conflicting Data'
        ELSE MAX(returned)
    END AS is_returned
FROM dim_returns
GROUP BY order_id;
GO


-- =========================================================================
-- STEP 2: HISTORICAL TAX MATRIX (dim_vat_rates)
-- =========================================================================

DROP TABLE IF EXISTS dim_vat_rates;
GO

-- Tracks Saudi VAT rate changes over time, so each order gets taxed at 
-- whatever rate was actually in effect on its own transaction date, 
-- not today's rate applied retroactively
CREATE TABLE dim_vat_rates (
    vat_rate DECIMAL(4,2),
    effective_date DATE 
);
GO

INSERT INTO dim_vat_rates (vat_rate, effective_date) 
VALUES
    (0.05, '2018-01-01'), -- original 5% VAT
    (0.15, '2020-07-01'); -- ZATCA adjustment to 15%
GO


-- =========================================================================
-- STEP 3: THE MASTER DATA PIPELINE (vw_fact_orders)
-- =========================================================================

DROP VIEW IF EXISTS vw_fact_orders;
GO

CREATE VIEW vw_fact_orders AS

-- Pulls the cleaned return status, defaulting to 'No' if COALESCE 
-- ever hits a genuinely missing value inside dim_returns_cleaned itself
WITH return_cte AS (
    SELECT 
        order_id, 
        COALESCE(drc.is_returned, 'No') AS is_returned
    FROM dim_returns_cleaned AS drc
),

-- Joins orders to their return status. This COALESCE is the important one - 
-- most orders have NO matching row in dim_returns at all (never returned), 
-- so the LEFT JOIN gives NULL here, which this converts to 'No'.
staged_orders AS (
    SELECT 
        fo.*,
        COALESCE(rc.is_returned, 'No') AS clean_is_returned
    FROM fact_orders AS fo
    LEFT JOIN return_cte AS rc ON fo.order_id = rc.order_id
)

SELECT 
    so.row_id,
    so.order_id,
    so.order_date,
    so.ship_date,
    so.ship_mode,
    so.customer_id,
    so.customer_name,
    so.segment,
    so.country_region,
    so.city,
    so.state,
    so.postal_code,
    so.region,
    so.product_id,
    so.category,
    so.sub_category,
    so.product_name,

    -- Sales & splits (0 is fine here - these get SUMMED, so 0 doesn't distort a total)
    CAST(so.sales AS DECIMAL(10,2)) AS sales,
    CASE WHEN so.clean_is_returned = 'No'  THEN CAST(so.sales AS DECIMAL(10,2)) ELSE 0.00 END AS sales_no_return,
    CASE WHEN so.clean_is_returned = 'Yes' THEN CAST(so.sales AS DECIMAL(10,2)) ELSE 0.00 END AS sales_returned,

    -- VAT & splits - rate comes from the historical lookup below, not a fixed constant
    CAST(COALESCE(v.vat_rate, 0) * so.sales AS DECIMAL(10,2)) AS vat_15,
    CASE WHEN so.clean_is_returned = 'No'  THEN CAST(COALESCE(v.vat_rate, 0) * so.sales AS DECIMAL(10,2)) ELSE 0.00 END AS vat_no_return,
    CASE WHEN so.clean_is_returned = 'Yes' THEN CAST(COALESCE(v.vat_rate, 0) * so.sales AS DECIMAL(10,2)) ELSE 0.00 END AS vat_returned,

    so.quantity,
    CASE WHEN so.clean_is_returned = 'No'  THEN so.quantity ELSE 0 END AS quantity_no_return,
    CASE WHEN so.clean_is_returned = 'Yes' THEN so.quantity ELSE 0 END AS quantity_returned,

    -- Discount & splits - NULL (not 0) on the "wrong side", since this gets AVERAGED, 
    -- not summed. A fake 0% here would drag the average down incorrectly.
    so.discount,
    CASE WHEN so.clean_is_returned = 'No'  THEN so.discount ELSE NULL END AS discount_no_return,
    CASE WHEN so.clean_is_returned = 'Yes' THEN so.discount ELSE NULL END AS discount_returned,

    -- Discount as a dollar amount - this one IS summed, so 0 is correct here
    CAST(so.sales * so.discount AS DECIMAL(10,2)) AS discount_amount,
    CASE WHEN so.clean_is_returned = 'No'  THEN CAST((so.sales * so.discount) AS DECIMAL(10,2)) ELSE 0.00 END AS discount_amount_no_return,
    CASE WHEN so.clean_is_returned = 'Yes' THEN CAST((so.sales * so.discount) AS DECIMAL(10,2)) ELSE 0.00 END AS discount_amount_returned,

    so.profit,
    CASE WHEN so.clean_is_returned = 'No'  THEN CAST(so.profit AS DECIMAL(10,2)) ELSE 0.00 END AS profit_no_return,
    CASE WHEN so.clean_is_returned = 'Yes' THEN CAST(so.profit AS DECIMAL(10,2)) ELSE 0.00 END AS profit_returned,

    -- COGS - deliberately just sales minus profit; VAT has nothing to do with 
    -- cost of goods and was intentionally kept out of this formula
    CAST(so.sales - so.profit AS DECIMAL(10,2)) AS cogs,
    CASE WHEN so.clean_is_returned = 'No'  THEN CAST((so.sales - so.profit) AS DECIMAL(10,2)) ELSE 0.00 END AS cogs_no_return,
    CASE WHEN so.clean_is_returned = 'Yes' THEN CAST((so.sales - so.profit) AS DECIMAL(10,2)) ELSE 0.00 END AS cogs_returned,

    -- Profit margin - guarded against divide-by-zero if sales is ever 0
    CAST(CASE WHEN so.sales = 0 THEN NULL ELSE so.profit / CAST(so.sales AS DECIMAL(10,2)) END AS DECIMAL(5,4)) AS profit_margin,
    CASE WHEN so.clean_is_returned = 'No'  THEN CAST(CASE WHEN so.sales = 0 THEN NULL ELSE so.profit / CAST(so.sales AS DECIMAL(10,2)) END AS DECIMAL(5,4)) ELSE NULL END AS profit_margin_no_return,
    CASE WHEN so.clean_is_returned = 'Yes' THEN CAST(CASE WHEN so.sales = 0 THEN NULL ELSE so.profit / CAST(so.sales AS DECIMAL(10,2)) END AS DECIMAL(5,4)) ELSE NULL END AS profit_margin_returned,

    so.clean_is_returned AS is_returned,
    CASE WHEN so.clean_is_returned = 'Yes' THEN 1 ELSE 0 END AS return_count

FROM staged_orders AS so
-- Point-in-time VAT lookup: grabs whichever rate was actually in effect 
-- on this order's own date, not today's rate applied retroactively
OUTER APPLY (
    SELECT TOP 1 vat_rate
    FROM dim_vat_rates
    WHERE effective_date <= so.order_date
    ORDER BY effective_date DESC
) AS v;
GO