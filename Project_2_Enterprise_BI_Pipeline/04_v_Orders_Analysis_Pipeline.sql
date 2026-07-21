-- =========================================================================
-- DATABASE SETUP & CLEANUP
-- =========================================================================

-- Create the master portfolio database
CREATE DATABASE portfolio;
GO

USE portfolio;
GO

-- Note: 'fact_orders' must be physically imported from your CSV before running this script
DROP TABLE IF EXISTS fact_orders;
GO


-- =========================================================================
-- STEP 1: DEDUPLICATE RETURNS (dim_returns_cleaned)
-- =========================================================================

-- Check for duplicate returns in the raw table before creating the view
SELECT 
    order_id,
    COUNT(order_id) AS duplicate_count
FROM dim_returns
GROUP BY order_id
HAVING COUNT(*) > 1;
GO

DROP VIEW IF EXISTS dim_returns_cleaned;
GO

-- Cleaned returns view (Handles conflicts and preserves the unique order_id grain)
CREATE VIEW dim_returns_cleaned AS
SELECT 
    order_id,
    CASE 
        WHEN COUNT(DISTINCT returned) > 1 THEN 'Conflicting Data'
        ELSE MAX(returned) -- Using MAX avoids grouping by 'returned', preserving the order grain
    END AS is_returned
FROM dim_returns
GROUP BY order_id;
GO


-- =========================================================================
-- STEP 2: HISTORICAL TAX MATRIX (dim_vat_rates)
-- =========================================================================

DROP TABLE IF EXISTS dim_vat_rates;
GO

-- Staging table to track Saudi historical VAT rate changes
CREATE TABLE dim_vat_rates (
    vat_rate DECIMAL (4,2),
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

-- Master analytical reporting view
CREATE VIEW vw_fact_orders AS

-- CTE 1: Select returns with a clean default fallback
WITH return_cte AS (
    SELECT 
        order_id, 
        COALESCE(drc.is_returned, 'No') AS is_returned
    FROM dim_returns_cleaned AS drc
),

-- CTE 2: Staged Orders (Joins the tables and runs COALESCE once to prevent redundant code)
staged_orders AS (
    SELECT 
        fo.*,
        COALESCE(rc.is_returned, 'No') AS clean_is_returned
    FROM fact_orders AS fo
    LEFT JOIN return_cte AS rc ON fo.order_id = rc.order_id
)

-- Final SELECT: Formats datatypes, calculates splits, and runs the historical VAT lookup
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

    -- 1. Sales & Sales Splits (excluding returns)
    CAST(so.sales AS DECIMAL(10,2)) AS sales,
    CASE WHEN so.clean_is_returned = 'No'  THEN CAST(so.sales AS DECIMAL(10,2)) ELSE 0.00 END AS sales_no_return,
    CASE WHEN so.clean_is_returned = 'Yes' THEN CAST(so.sales AS DECIMAL(10,2)) ELSE 0.00 END AS sales_returned,

    -- 2. VAT & VAT Splits (Dynamic lookup based on historical transaction dates)
    CAST(COALESCE(v.vat_rate, 0) * so.sales AS DECIMAL(10,2)) AS vat_15,
    CASE WHEN so.clean_is_returned = 'No'  THEN CAST(COALESCE(v.vat_rate, 0) * so.sales AS DECIMAL(10,2)) ELSE 0.00 END AS vat_no_return,
    CASE WHEN so.clean_is_returned = 'Yes' THEN CAST(COALESCE(v.vat_rate, 0) * so.sales AS DECIMAL(10,2)) ELSE 0.00 END AS vat_returned,

    so.quantity,
    -- Quantity Splits
    CASE WHEN so.clean_is_returned = 'No'  THEN so.quantity ELSE 0 END AS quantity_no_return,
    CASE WHEN so.clean_is_returned = 'Yes' THEN so.quantity ELSE 0 END AS quantity_returned,

    so.discount,
    -- Discount Splits
    CASE WHEN so.clean_is_returned = 'No'  THEN so.discount ELSE NULL END AS discount_no_return,
    CASE WHEN so.clean_is_returned = 'Yes' THEN so.discount ELSE NULL END AS discount_returned,

    -- 3. Discount Dollar Amounts
    CAST(so.sales * so.discount AS DECIMAL(10,2)) AS discount_amount,
    CASE WHEN so.clean_is_returned = 'No'  THEN CAST((so.sales * so.discount) AS DECIMAL(10,2)) ELSE 0.00 END AS discount_amount_no_return,
    CASE WHEN so.clean_is_returned = 'Yes' THEN CAST((so.sales * so.discount) AS DECIMAL(10,2)) ELSE 0.00 END AS discount_amount_returned,

    so.profit,
    -- Profit Splits
    CASE WHEN so.clean_is_returned = 'No'  THEN CAST(so.profit AS DECIMAL(10,2)) ELSE 0.00 END AS profit_no_return,
    CASE WHEN so.clean_is_returned = 'Yes' THEN CAST(so.profit AS DECIMAL(10,2)) ELSE 0.00 END AS profit_returned,

    -- 4. Cost of Goods Sold (COGS) & COGS Splits
    CAST(so.sales - so.profit AS DECIMAL(10,2)) AS cogs,
    CASE WHEN so.clean_is_returned = 'No'  THEN CAST((so.sales - so.profit) AS DECIMAL(10,2)) ELSE 0.00 END AS cogs_no_return,
    CASE WHEN so.clean_is_returned = 'Yes' THEN CAST((so.sales - so.profit) AS DECIMAL(10,2)) ELSE 0.00 END AS cogs_returned,

    -- 5. Profit Margins (With division-by-zero protection)
    CAST(CASE WHEN so.sales = 0 THEN NULL ELSE so.profit / CAST(so.sales AS DECIMAL(10,2)) END AS DECIMAL(5,4)) AS profit_margin,
    -- Profit Margin Splits
    CASE WHEN so.clean_is_returned = 'No'  THEN CAST(CASE WHEN so.sales = 0 THEN NULL ELSE so.profit / CAST(so.sales AS DECIMAL(10,2)) END AS DECIMAL(5,4)) ELSE NULL END AS profit_margin_no_return,
    CASE WHEN so.clean_is_returned = 'Yes' THEN CAST(CASE WHEN so.sales = 0 THEN NULL ELSE so.profit / CAST(so.sales AS DECIMAL(10,2)) END AS DECIMAL(5,4)) ELSE NULL END AS profit_margin_returned,

    -- 6. Returns Metadata
    so.clean_is_returned AS is_returned,
    CASE WHEN so.clean_is_returned = 'Yes' THEN 1 ELSE 0 END AS return_count

FROM staged_orders AS so
-- Point-in-time lookup to grab the active VAT rate based on the order date
OUTER APPLY (
    SELECT TOP 1 vat_rate
    FROM dim_vat_rates
    WHERE effective_date <= so.order_date
    ORDER BY effective_date DESC
) AS v;
GO