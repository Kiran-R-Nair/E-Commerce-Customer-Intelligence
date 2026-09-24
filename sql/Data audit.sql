CREATE DATABASE IF NOT EXISTS ecommerce_customer_intelligence;

USE ecommerce_customer_intelligence;
SHOW tables;

# ROW COUNT FOR ALL TABLES
# Purpose: Determine the number of records in each table.

SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM customers
UNION ALL
SELECT 'inventory_snapshots', COUNT(*)
FROM inventory_snapshots
UNION ALL
SELECT 'meta_ads_campaigns', COUNT(*)
FROM meta_ads_campaigns
UNION ALL
SELECT 'order_line_items', COUNT(*)
FROM order_line_items
UNION ALL
SELECT 'orders', COUNT(*)
FROM orders
UNION ALL
SELECT 'purchase_orders', COUNT(*)
FROM purchase_orders
UNION ALL
SELECT 'sku_catalog', COUNT(*)
FROM sku_catalog
UNION ALL
SELECT 'website_daily', COUNT(*)
FROM website_daily
UNION ALL
SELECT 'website_sessions', COUNT(*)
FROM website_sessions;

# COLUMN COUNT
# Purpose: Determine the number of columns/attributes
# available in each source table.

SELECT
    TABLE_NAME,
    COUNT(*) AS column_count
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'ecommerce_customer_intelligence'
GROUP BY TABLE_NAME
ORDER BY TABLE_NAME;

# COLUMN-LEVEL SCHEMA INFORMATION
# Purpose: Identify column names, data types, NULL
# allowance, and key information for all 9 tables.

SELECT
    TABLE_NAME,
    ORDINAL_POSITION,
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_KEY
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'ecommerce_customer_intelligence'
ORDER BY
    TABLE_NAME,
    ORDINAL_POSITION;
    
# SAMPLE DATA INSPECTION
# Purpose: View a small number of records from each table

# Customer information
SELECT *
FROM customers
LIMIT 5;


# Inventory information
SELECT *
FROM inventory_snapshots
LIMIT 5;


# Marketing campaign information
SELECT *
FROM meta_ads_campaigns
LIMIT 5;


# Order line-item information
SELECT *
FROM order_line_items
LIMIT 5;


# Order information
SELECT *
FROM orders
LIMIT 5;


# Purchase-order information
SELECT *
FROM purchase_orders
LIMIT 5;


# Product/SKU information
SELECT *
FROM sku_catalog
LIMIT 5;


# Daily website information
SELECT *
FROM website_daily
LIMIT 5;


# Website session information
SELECT *
FROM website_sessions
LIMIT 5;


-- PRIMARY KEY INVESTIGATION - CUSTOMERS
-- Candidate key: Customer ID
--
-- Purpose:
-- Check whether Customer ID uniquely identifies each
-- customer record.

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT `Customer ID`) AS unique_customer_ids
FROM customers;

-- Check whether any Customer ID appears more than once.

SELECT
    `Customer ID`,
    COUNT(*) AS occurrence_count
FROM customers
GROUP BY `Customer ID`
HAVING COUNT(*) > 1;

-- PRIMARY KEY INVESTIGATION - ORDERS
-- Candidate key: Order ID
--
-- Purpose:
-- Determine whether each order has a unique Order ID.


SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT `Order ID`) AS unique_order_ids
FROM orders;

-- Check for duplicate Order IDs.

SELECT
    `Order ID`,
    COUNT(*) AS occurrence_count
FROM orders
GROUP BY `Order ID`
HAVING COUNT(*) > 1;

-- PRIMARY KEY INVESTIGATION - ORDER LINE ITEMS
--
-- Order ID may repeat because one order can contain
-- multiple products.

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT `Order ID`) AS unique_order_ids,
    COUNT(DISTINCT `SKU ID`) AS unique_skus
FROM order_line_items;

-- Check whether the combination of Order ID + SKU ID
-- uniquely identifies each line item.

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CONCAT(`Order ID`, '|', `SKU ID`))
        AS unique_order_sku_pairs
FROM order_line_items;

-- Find duplicate Order ID + SKU ID combinations.

SELECT
    `Order ID`,
    `SKU ID`,
    COUNT(*) AS occurrence_count
FROM order_line_items
GROUP BY
    `Order ID`,
    `SKU ID`
HAVING COUNT(*) > 1;


-- PRIMARY KEY INVESTIGATION - SKU CATALOG
-- Candidate key: SKU

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT SKU) AS unique_skus
FROM sku_catalog;

-- Check for duplicate SKUs.

SELECT
    SKU,
    COUNT(*) AS occurrence_count
FROM sku_catalog
GROUP BY SKU
HAVING COUNT(*) > 1;

-- PRIMARY KEY INVESTIGATION - WEBSITE SESSIONS
-- Candidate key: session_id

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT session_id) AS unique_session_ids
FROM website_sessions;

-- Check for duplicate session IDs.

SELECT
    session_id,
    COUNT(*) AS occurrence_count
FROM website_sessions
GROUP BY session_id
HAVING COUNT(*) > 1;


-- PRIMARY KEY INVESTIGATION - INVENTORY
-- Inventory is time-based, so the same SKU can appear
-- on multiple dates.
-- Candidate composite key: SKU + date

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CONCAT(SKU, '|', `date`))
        AS unique_sku_date_pairs
FROM inventory_snapshots;

-- Find duplicate SKU + date combinations.

SELECT
    SKU,
    `date`,
    COUNT(*) AS occurrence_count
FROM inventory_snapshots
GROUP BY
    SKU,
    `date`
HAVING COUNT(*) > 1;

-- PURCHASE ORDERS
-- No explicit Purchase Order ID exists in the imported data.
-- Therefore, we investigate possible composite identifiers
-- instead of inventing a primary key.

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CONCAT(
        SKU, '|',
        Vendor, '|',
        `Order date`
    )) AS unique_candidate_keys
FROM purchase_orders;

-- Check duplicate SKU + Vendor + Order Date combinations.

SELECT
    SKU,
    Vendor,
    `Order date`,
    COUNT(*) AS occurrence_count
FROM purchase_orders
GROUP BY
    SKU,
    Vendor,
    `Order date`
HAVING COUNT(*) > 1;


-- STEP 6H: META ADS CAMPAIGNS
-- No explicit campaign ID exists.
-- Test whether date + campaign + adset uniquely identifies
-- each campaign record.

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CONCAT(
        `date`, '|',
        campaign_name, '|',
        adset_name
    )) AS unique_candidate_keys
FROM meta_ads_campaigns;

-- Check for duplicate date + campaign + adset combinations.

SELECT
    `date`,
    campaign_name,
    adset_name,
    COUNT(*) AS occurrence_count
FROM meta_ads_campaigns
GROUP BY
    `date`,
    campaign_name,
    adset_name
HAVING COUNT(*) > 1;


-- WEBSITE DAILY
--
-- Multiple records can exist for the same date because
-- website activity is segmented by source, campaign,
-- device, and city.


SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CONCAT(
        `date`, '|',
        traffic_source, '|',
        campaign_name, '|',
        device_category, '|',
        city
    )) AS unique_candidate_keys
FROM website_daily;

-- Check for duplicate combinations.

SELECT
    `date`,
    traffic_source,
    campaign_name,
    device_category,
    city,
    COUNT(*) AS occurrence_count
FROM website_daily
GROUP BY
    `date`,
    traffic_source,
    campaign_name,
    device_category,
    city
HAVING COUNT(*) > 1;


-- FOREIGN KEY / RELATIONSHIP AUDIT


-- 1. orders → customers
SELECT
    COUNT(*) AS total_orders,
    COUNT(DISTINCT o.`Customer ID`) AS unique_customers_in_orders,
    COUNT(DISTINCT c.`Customer ID`) AS matched_customers
FROM orders o
LEFT JOIN customers c
    ON o.`Customer ID` = c.`Customer ID`;

-- 2. order_line_items → orders
SELECT
    COUNT(*) AS total_line_items,
    COUNT(DISTINCT oli.`Order ID`) AS line_item_orders,
    COUNT(DISTINCT o.`Order ID`) AS matched_orders
FROM order_line_items oli
LEFT JOIN orders o
    ON oli.`Order ID` = o.`Order ID`;

-- 3. order_line_items → sku_catalog
SELECT
    COUNT(*) AS total_line_items,
    COUNT(DISTINCT oli.`SKU ID`) AS line_item_skus,
    COUNT(DISTINCT s.`SKU`) AS matched_skus
FROM order_line_items oli
LEFT JOIN sku_catalog s
    ON oli.`SKU ID` = s.`SKU`;

-- 4. inventory_snapshots → sku_catalog
SELECT
    COUNT(*) AS inventory_rows,
    COUNT(DISTINCT i.`SKU`) AS inventory_skus,
    COUNT(DISTINCT s.`SKU`) AS matched_skus
FROM inventory_snapshots i
LEFT JOIN sku_catalog s
    ON i.`SKU` = s.`SKU`;

-- 5. purchase_orders → sku_catalog
SELECT
    COUNT(*) AS purchase_order_rows,
    COUNT(DISTINCT p.`SKU`) AS purchase_order_skus,
    COUNT(DISTINCT s.`SKU`) AS matched_skus
FROM purchase_orders p
LEFT JOIN sku_catalog s
    ON p.`SKU` = s.`SKU`;

-- 6. website_sessions → customers
SELECT
    COUNT(*) AS session_rows,
    COUNT(DISTINCT ws.`customer_id`) AS session_customers,
    COUNT(DISTINCT c.`Customer ID`) AS matched_customers
FROM website_sessions ws
LEFT JOIN customers c
    ON ws.`customer_id` = c.`Customer ID`;

-- 7. website_sessions → orders
SELECT
    COUNT(*) AS session_rows,
    COUNT(DISTINCT ws.`order_id`) AS session_orders,
    COUNT(DISTINCT o.`Order ID`) AS matched_orders
FROM website_sessions ws
LEFT JOIN orders o
    ON ws.`order_id` = o.`Order ID`;
    
-- =========================================================
-- INVESTIGATE UNMATCHED WEBSITE SESSION CUSTOMER IDs

SELECT DISTINCT
    ws.`customer_id`
FROM website_sessions ws
LEFT JOIN customers c
    ON ws.`customer_id` = c.`Customer ID`
WHERE ws.`customer_id` IS NOT NULL
  AND ws.`customer_id` <> ''
  AND c.`Customer ID` IS NULL;
  
  
-- INVESTIGATE UNMATCHED WEBSITE SESSION ORDER IDs

SELECT DISTINCT
    ws.`order_id`
FROM website_sessions ws
LEFT JOIN orders o
    ON ws.`order_id` = o.`Order ID`
WHERE ws.`order_id` IS NOT NULL
  AND ws.`order_id` <> ''
  AND o.`Order ID` IS NULL;
  
-- SHOW THE SESSION RECORD WITH UNMATCHED CUSTOMER ID


SELECT *
FROM website_sessions ws
LEFT JOIN customers c
    ON ws.`customer_id` = c.`Customer ID`
WHERE ws.`customer_id` IS NOT NULL
  AND ws.`customer_id` <> ''
  AND c.`Customer ID` IS NULL;
  
-- SHOW THE SESSION RECORD WITH UNMATCHED ORDER ID


SELECT *
FROM website_sessions ws
LEFT JOIN orders o
    ON ws.`order_id` = o.`Order ID`
WHERE ws.`order_id` IS NOT NULL
  AND ws.`order_id` <> ''
  AND o.`Order ID` IS NULL;
  

-- GRAIN AUDIT: CUSTOMERS
-- Expected: 1 row per customer


SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT `Customer ID`) AS unique_customers
FROM customers;


-- GRAIN AUDIT: ORDERS
-- Expected: 1 row per order

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT `Order ID`) AS unique_orders
FROM orders;


-- GRAIN AUDIT: ORDER LINE ITEMS
-- Expected: multiple rows can belong to one order

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT `Order ID`) AS unique_orders,
    COUNT(DISTINCT `SKU ID`) AS unique_skus
FROM order_line_items;

-- =========================================================
-- NUMBER OF LINE ITEMS PER ORDER
-- =========================================================

SELECT
    MIN(item_count) AS minimum_items,
    MAX(item_count) AS maximum_items,
    AVG(item_count) AS average_items
FROM
(
    SELECT
        `Order ID`,
        COUNT(*) AS item_count
    FROM order_line_items
    GROUP BY `Order ID`
) AS order_summary;


-- GRAIN AUDIT: SKU CATALOG
-- Expected: 1 row per SKU

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT `SKU`) AS unique_skus
FROM sku_catalog;

-- GRAIN AUDIT: INVENTORY SNAPSHOTS
-- Expected: 1 row per SKU per date

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CONCAT(`SKU`, '|', `date`)) AS unique_sku_date
FROM inventory_snapshots;

-- GRAIN AUDIT: PURCHASE ORDERS
-- Expected: 1 row per SKU + Vendor + Order Date

SELECT
    COUNT(*) AS total_rows,
    COUNT(
        DISTINCT CONCAT(
            `SKU`, '|',
            `Vendor`, '|',
            `Order date`
        )
    ) AS unique_purchase_events
FROM purchase_orders;


-- GRAIN AUDIT: META ADS CAMPAIGNS
-- Expected: 1 row per Date + Campaign + Adset

SELECT
    COUNT(*) AS total_rows,
    COUNT(
        DISTINCT CONCAT(
            `date`, '|',
            `campaign_name`, '|',
            `adset_name`
        )
    ) AS unique_campaign_records
FROM meta_ads_campaigns;

-- =========================================================
-- GRAIN AUDIT: WEBSITE DAILY
-- Expected candidate grain:
-- Date + Traffic Source + Campaign + Device + City
-- =========================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(
        DISTINCT CONCAT(
            `date`, '|',
            `traffic_source`, '|',
            `campaign_name`, '|',
            `device_category`, '|',
            `city`
        )
    ) AS unique_daily_records
FROM website_daily;

-- GRAIN AUDIT: WEBSITE SESSIONS
-- Expected: 1 row per website session

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT `session_id`) AS unique_sessions
FROM website_sessions;

-- =========================================================
-- NULL AUDIT: CUSTOMERS
-- Count missing values in every column
-- =========================================================

SELECT
    COUNT(*) AS total_rows,

    SUM(`Customer ID` IS NULL OR TRIM(`Customer ID`) = '') AS missing_customer_id,
    SUM(`Name` IS NULL OR TRIM(`Name`) = '') AS missing_name,
    SUM(`First order date` IS NULL OR TRIM(`First order date`) = '') AS missing_first_order_date,
    SUM(`Total orders` IS NULL) AS missing_total_orders,
    SUM(`Total revenue` IS NULL) AS missing_total_revenue,
    SUM(`Average order value` IS NULL) AS missing_aov,
    SUM(`Time to 2nd purchase` IS NULL OR TRIM(`Time to 2nd purchase`) = '') AS missing_time_to_2nd_purchase,
    SUM(`Last purchase date` IS NULL OR TRIM(`Last purchase date`) = '') AS missing_last_purchase_date,
    SUM(`City / tier` IS NULL OR TRIM(`City / tier`) = '') AS missing_city_tier,
    SUM(`Acquisition channel (first touch)` IS NULL OR TRIM(`Acquisition channel (first touch)`) = '') AS missing_acquisition_channel,
    SUM(`RePurchased` IS NULL OR TRIM(`RePurchased`) = '') AS missing_repurchase

FROM customers;

-- =========================================================
-- NULL AUDIT: ORDERS
-- =========================================================

SELECT
    COUNT(*) AS total_rows,

    SUM(`Order ID` IS NULL OR TRIM(`Order ID`) = '') AS missing_order_id,
    SUM(`Customer ID` IS NULL OR TRIM(`Customer ID`) = '') AS missing_customer_id,
    SUM(`Order date & time` IS NULL OR TRIM(`Order date & time`) = '') AS missing_order_datetime,
    SUM(`Product` IS NULL OR TRIM(`Product`) = '') AS missing_product,
    SUM(`Order value (gross, net)` IS NULL OR TRIM(`Order value (gross, net)`) = '') AS missing_order_value,
    SUM(`Order value (gross)` IS NULL) AS missing_gross_value,
    SUM(`Order value (net)` IS NULL) AS missing_net_value,
    SUM(`Discount applied (â‚¹)` IS NULL) AS missing_discount,
    SUM(`Discount applied (%)` IS NULL OR TRIM(`Discount applied (%)`) = '') AS missing_discount_pct,
    SUM(`Payment mode` IS NULL OR TRIM(`Payment mode`) = '') AS missing_payment_mode,
    SUM(`Shipping city` IS NULL OR TRIM(`Shipping city`) = '') AS missing_shipping_city,
    SUM(`Pincode` IS NULL) AS missing_pincode,
    SUM(`First order vs repeat` IS NULL OR TRIM(`First order vs repeat`) = '') AS missing_first_repeat,
    SUM(`Channel source (last touch)` IS NULL OR TRIM(`Channel source (last touch)`) = '') AS missing_channel,
    SUM(`Delivered / Returned / RTO` IS NULL OR TRIM(`Delivered / Returned / RTO`) = '') AS missing_order_status

FROM orders;

-- =========================================================
-- NULL AUDIT: ORDER LINE ITEMS
-- =========================================================

SELECT
    COUNT(*) AS total_rows,

    SUM(`Order ID` IS NULL OR TRIM(`Order ID`) = '') AS missing_order_id,
    SUM(`SKU ID` IS NULL OR TRIM(`SKU ID`) = '') AS missing_sku_id,
    SUM(`Category (top, bottom, outerwear, etc.)` IS NULL
        OR TRIM(`Category (top, bottom, outerwear, etc.)`) = '') AS missing_category,
    SUM(`Size` IS NULL OR TRIM(`Size`) = '') AS missing_size,
    SUM(`Color` IS NULL OR TRIM(`Color`) = '') AS missing_color,
    SUM(`MRP` IS NULL) AS missing_mrp,
    SUM(`Selling price` IS NULL) AS missing_selling_price,
    SUM(`Discount %` IS NULL) AS missing_discount_pct,
    SUM(`Returned? (Y/N)` IS NULL
        OR TRIM(`Returned? (Y/N)`) = '') AS missing_return_flag,
    SUM(`Return reason (if any)` IS NULL
        OR TRIM(`Return reason (if any)`) = '') AS missing_return_reason

FROM order_line_items;

-- =========================================================
-- CHECK WHETHER MISSING RETURN REASONS ARE VALID
-- Expected:
-- Returned = N  → return reason should generally be blank
-- =========================================================

SELECT
    `Returned? (Y/N)` AS returned_flag,
    COUNT(*) AS row_count,
    SUM(
        `Return reason (if any)` IS NULL
        OR TRIM(`Return reason (if any)`) = ''
    ) AS missing_return_reason
FROM order_line_items
GROUP BY `Returned? (Y/N)`;

-- =========================================================
-- NULL AUDIT: SKU CATALOG
-- =========================================================

SELECT
    COUNT(*) AS total_rows,

    SUM(`SKU` IS NULL OR TRIM(`SKU`) = '') AS missing_sku,
    SUM(`Category` IS NULL OR TRIM(`Category`) = '') AS missing_category,
    SUM(`Vendor` IS NULL OR TRIM(`Vendor`) = '') AS missing_vendor,
    SUM(`MRP` IS NULL) AS missing_mrp,
    SUM(`Cost_per_unit` IS NULL) AS missing_cost_per_unit

FROM sku_catalog;

-- =========================================================
-- NULL AUDIT: INVENTORY SNAPSHOTS
-- =========================================================

SELECT
    COUNT(*) AS total_rows,

    SUM(`SKU` IS NULL OR TRIM(`SKU`) = '') AS missing_sku,
    SUM(`Category` IS NULL OR TRIM(`Category`) = '') AS missing_category,
    SUM(`Size` IS NULL OR TRIM(`Size`) = '') AS missing_size,
    SUM(`Units in stock` IS NULL) AS missing_units_in_stock,
    SUM(`Units sold (last 7/30/60 days)` IS NULL
        OR TRIM(`Units sold (last 7/30/60 days)`) = '') AS missing_units_sold,
    SUM(`Days of inventory left` IS NULL) AS missing_inventory_days,
    SUM(`Dead stock flag` IS NULL OR TRIM(`Dead stock flag`) = '') AS missing_dead_stock_flag,
    SUM(`date` IS NULL OR TRIM(`date`) = '') AS missing_date

FROM inventory_snapshots;

-- =========================================================
-- NULL AUDIT: PURCHASE ORDERS
-- Purpose:
-- Identify missing values in procurement and supplier data.
-- =========================================================

SELECT
    COUNT(*) AS total_rows,

    SUM(`SKU` IS NULL OR TRIM(`SKU`) = '') AS missing_sku,
    SUM(`Vendor` IS NULL OR TRIM(`Vendor`) = '') AS missing_vendor,
    SUM(`Order quantity` IS NULL) AS missing_order_quantity,
    SUM(`Cost per unit` IS NULL) AS missing_cost_per_unit,
    SUM(`Order date` IS NULL OR TRIM(`Order date`) = '') AS missing_order_date,
    SUM(`Expected delivery` IS NULL OR TRIM(`Expected delivery`) = '') AS missing_expected_delivery,
    SUM(`Actual delivery` IS NULL OR TRIM(`Actual delivery`) = '') AS missing_actual_delivery,
    SUM(`Lead time` IS NULL) AS missing_lead_time

FROM purchase_orders;

-- =========================================================
-- NULL AUDIT: META ADS CAMPAIGNS
-- Purpose:
-- Identify missing values in advertising campaign data.
-- =========================================================

SELECT
    COUNT(*) AS total_rows,

    SUM(`date` IS NULL OR TRIM(`date`) = '') AS missing_date,
    SUM(`campaign_name` IS NULL OR TRIM(`campaign_name`) = '') AS missing_campaign,
    SUM(`adset_name` IS NULL OR TRIM(`adset_name`) = '') AS missing_adset,
    SUM(`Results` IS NULL) AS missing_results,
    SUM(`Amount spent (INR)` IS NULL) AS missing_amount_spent,
    SUM(`spend` IS NULL) AS missing_spend,
    SUM(`Reach` IS NULL) AS missing_reach,
    SUM(`impressions` IS NULL) AS missing_impressions,
    SUM(`frequency` IS NULL) AS missing_frequency,
    SUM(`link_clicks` IS NULL) AS missing_link_clicks,
    SUM(`ctr_link` IS NULL) AS missing_ctr,
    SUM(`add_to_cart` IS NULL) AS missing_add_to_cart,
    SUM(`initiate_checkout` IS NULL) AS missing_checkout,
    SUM(`purchases` IS NULL) AS missing_purchases,
    SUM(`purchase_conversion_value` IS NULL) AS missing_conversion_value,
    SUM(`cac` IS NULL) AS missing_cac,
    SUM(`roas` IS NULL) AS missing_roas,
    SUM(`creative_type` IS NULL OR TRIM(`creative_type`) = '') AS missing_creative_type,
    SUM(`launch_date` IS NULL OR TRIM(`launch_date`) = '') AS missing_launch_date,
    SUM(`Hook Rate` IS NULL) AS missing_hook_rate

FROM meta_ads_campaigns;

-- =========================================================
-- NULL AUDIT: WEBSITE DAILY
-- Purpose:
-- Identify missing values in daily website traffic,
-- conversion, and revenue data.
-- =========================================================

SELECT
    COUNT(*) AS total_rows,

    SUM(`date` IS NULL OR TRIM(`date`) = '') AS missing_date,
    SUM(`traffic_source` IS NULL OR TRIM(`traffic_source`) = '') AS missing_traffic_source,
    SUM(`campaign_name` IS NULL OR TRIM(`campaign_name`) = '') AS missing_campaign,
    SUM(`device_category` IS NULL OR TRIM(`device_category`) = '') AS missing_device,
    SUM(`sessions` IS NULL) AS missing_sessions,
    SUM(`product_views` IS NULL) AS missing_product_views,
    SUM(`add_to_cart` IS NULL) AS missing_add_to_cart,
    SUM(`begin_checkout` IS NULL) AS missing_begin_checkout,
    SUM(`purchases` IS NULL) AS missing_purchases,
    SUM(`revenue` IS NULL) AS missing_revenue,
    SUM(`conversion_rate` IS NULL) AS missing_conversion_rate,
    SUM(`aov` IS NULL) AS missing_aov,
    SUM(`country` IS NULL OR TRIM(`country`) = '') AS missing_country,
    SUM(`city` IS NULL OR TRIM(`city`) = '') AS missing_city,
    SUM(`purchased` IS NULL) AS missing_purchased

FROM website_daily;

-- =========================================================
-- INVESTIGATE MISSING CAMPAIGN NAMES
-- Purpose:
-- Determine whether missing campaign names are associated
-- with particular traffic sources.
-- =========================================================

SELECT
    `traffic_source`,
    COUNT(*) AS total_rows,

    SUM(
        `campaign_name` IS NULL
        OR TRIM(`campaign_name`) = ''
    ) AS missing_campaign,

    ROUND(
        100.0 * SUM(
            `campaign_name` IS NULL
            OR TRIM(`campaign_name`) = ''
        ) / COUNT(*),
        2
    ) AS missing_campaign_pct

FROM website_daily

GROUP BY `traffic_source`

ORDER BY missing_campaign DESC;

-- =========================================================
-- INVESTIGATE CAMPAIGN NAME PATTERNS
-- Purpose:
-- Compare populated and blank campaign values by
-- traffic source.
-- =========================================================

SELECT
    `traffic_source`,
    CASE
        WHEN `campaign_name` IS NULL
             OR TRIM(`campaign_name`) = ''
        THEN 'Missing'
        ELSE 'Present'
    END AS campaign_status,
    COUNT(*) AS row_count
FROM website_daily
GROUP BY
    `traffic_source`,
    campaign_status
ORDER BY
    `traffic_source`,
    campaign_status;
    
-- =========================================================
-- FINDING: WEBSITE DAILY CAMPAIGN NAME
--
-- 17,532 of 21,915 records (80%) have a blank campaign name.
--
-- Missing campaign names occur exclusively for:
--   Google
--   Influencer
--   Organic Instagram
--   Email/SMS
--
-- Meta records have campaign names populated in 100% of rows.
--
-- Therefore, the missing campaign values show a systematic
-- pattern based on traffic source and appear to represent
-- structural/business-related missingness rather than random
-- data loss.
--
-- Raw values will NOT be modified during the audit phase.
-- Treatment will be decided during data cleaning/feature
-- engineering.
-- =========================================================

-- =========================================================
-- NULL AUDIT: WEBSITE SESSIONS
-- Purpose:
-- Identify missing values in session-level behavioral data.
-- =========================================================

SELECT
    COUNT(*) AS total_rows,

    SUM(`session_id` IS NULL OR TRIM(`session_id`) = '') AS missing_session_id,
    SUM(`date` IS NULL OR TRIM(`date`) = '') AS missing_date,
    SUM(`traffic_source` IS NULL OR TRIM(`traffic_source`) = '') AS missing_traffic_source,
    SUM(`campaign_name` IS NULL OR TRIM(`campaign_name`) = '') AS missing_campaign,
    SUM(`device_category` IS NULL OR TRIM(`device_category`) = '') AS missing_device,
    SUM(`city` IS NULL OR TRIM(`city`) = '') AS missing_city,
    SUM(`sessions` IS NULL) AS missing_sessions,
    SUM(`product_views` IS NULL) AS missing_product_views,
    SUM(`add_to_cart` IS NULL) AS missing_add_to_cart,
    SUM(`begin_checkout` IS NULL) AS missing_begin_checkout,
    SUM(`purchased` IS NULL) AS missing_purchased,
    SUM(`order_id` IS NULL OR TRIM(`order_id`) = '') AS missing_order_id,
    SUM(`customer_id` IS NULL OR TRIM(`customer_id`) = '') AS missing_customer_id,
    SUM(`revenue` IS NULL) AS missing_revenue

FROM website_sessions;

-- =========================================================
-- INVESTIGATE MISSING ORDER/CUSTOMER IDs
-- Purpose:
-- Determine whether missing IDs are associated with
-- non-purchasing website sessions.
-- =========================================================

SELECT
    `purchased`,
    COUNT(*) AS total_sessions,

    SUM(
        `order_id` IS NULL
        OR TRIM(`order_id`) = ''
    ) AS missing_order_id,

    SUM(
        `customer_id` IS NULL
        OR TRIM(`customer_id`) = ''
    ) AS missing_customer_id

FROM website_sessions

GROUP BY `purchased`
ORDER BY `purchased`;

-- =========================================================
-- INVESTIGATE MISSING CAMPAIGN NAMES
-- Purpose:
-- Determine whether missing campaign names are systematically
-- associated with specific traffic sources.
-- =========================================================

SELECT
    `traffic_source`,
    COUNT(*) AS total_rows,

    SUM(
        `campaign_name` IS NULL
        OR TRIM(`campaign_name`) = ''
    ) AS missing_campaign,

    ROUND(
        100.0 * SUM(
            `campaign_name` IS NULL
            OR TRIM(`campaign_name`) = ''
        ) / COUNT(*),
        2
    ) AS missing_campaign_pct

FROM website_sessions

GROUP BY `traffic_source`

ORDER BY missing_campaign DESC;

-- =========================================================
-- INVESTIGATE PURCHASED SESSIONS WITH MISSING IDs
--
-- These sessions have purchased = 1 but no order_id
-- and no customer_id.
-- =========================================================

SELECT *
FROM website_sessions
WHERE `purchased` = 1
  AND (
      `order_id` IS NULL
      OR TRIM(`order_id`) = ''
      OR `customer_id` IS NULL
      OR TRIM(`customer_id`) = ''
  );
  
  -- =========================================================
-- CHECK REVENUE FOR PURCHASED SESSIONS WITH MISSING IDs
-- =========================================================

SELECT
    COUNT(*) AS affected_sessions,
    SUM(`revenue`) AS total_revenue,
    MIN(`revenue`) AS minimum_revenue,
    MAX(`revenue`) AS maximum_revenue,
    AVG(`revenue`) AS average_revenue
FROM website_sessions
WHERE `purchased` = 1
  AND (
      `order_id` IS NULL
      OR TRIM(`order_id`) = ''
      OR `customer_id` IS NULL
      OR TRIM(`customer_id`) = ''
  );
  
  -- =========================================================
-- INVESTIGATE PURCHASED FLAG
-- Purpose:
-- Understand whether purchased = 1 consistently represents
-- a completed transaction with revenue.
-- =========================================================

SELECT
    `purchased`,
    COUNT(*) AS total_sessions,

    SUM(`revenue` > 0) AS sessions_with_revenue,

    SUM(`revenue` = 0) AS sessions_with_zero_revenue,

    SUM(
        `order_id` IS NOT NULL
        AND TRIM(`order_id`) <> ''
    ) AS sessions_with_order_id,

    SUM(
        `customer_id` IS NOT NULL
        AND TRIM(`customer_id`) <> ''
    ) AS sessions_with_customer_id,

    ROUND(AVG(`revenue`), 2) AS average_revenue

FROM website_sessions

GROUP BY `purchased`
ORDER BY `purchased`;

# 258 website sessions have purchased = 1 but zero revenue and no order_id or customer_id. 
# These records require business-rule clarification before being used as confirmed purchase outcomes.

-- =========================================================
-- DATE COVERAGE AUDIT
-- Purpose:
-- Check the time period covered by the major transactional,
-- marketing, inventory, and website tables.
-- =========================================================

SELECT
    'orders' AS table_name,
    MIN(`Order date & time`) AS earliest_date,
    MAX(`Order date & time`) AS latest_date,
    COUNT(*) AS total_rows
FROM orders

UNION ALL

SELECT
    'inventory_snapshots',
    MIN(`date`),
    MAX(`date`),
    COUNT(*)
FROM inventory_snapshots

UNION ALL

SELECT
    'meta_ads_campaigns',
    MIN(`date`),
    MAX(`date`),
    COUNT(*)
FROM meta_ads_campaigns

UNION ALL

SELECT
    'purchase_orders',
    MIN(`Order date`),
    MAX(`Order date`),
    COUNT(*)
FROM purchase_orders

UNION ALL

SELECT
    'website_daily',
    MIN(`date`),
    MAX(`date`),
    COUNT(*)
FROM website_daily

UNION ALL

SELECT
    'website_sessions',
    MIN(`date`),
    MAX(`date`),
    COUNT(*)
FROM website_sessions;

-- =========================================================
-- ML TARGET AUDIT: REPURCHASE
-- Purpose:
-- Understand the distribution of the customer-level
-- repurchase target before building the ML dataset.
-- =========================================================

SELECT
    `RePurchased`,
    COUNT(*) AS customer_count,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM customers),
        2
    ) AS percentage
FROM customers
GROUP BY `RePurchased`
ORDER BY `RePurchased`;

-- =========================================================
-- ML TARGET VALIDATION
-- Purpose:
-- Check whether the RePurchased target contains
-- unexpected or missing values.
-- =========================================================

SELECT
    COUNT(*) AS total_customers,

    SUM(
        `RePurchased` IS NULL
        OR TRIM(`RePurchased`) = ''
    ) AS missing_target,

    COUNT(DISTINCT `RePurchased`) AS unique_target_values

FROM customers;


-- CUSTOMER TABLE STRUCTURE FOR ML
-- Review every column before feature engineering.

DESCRIBE customers;

-- =========================================================
-- INVESTIGATE AMBIGUOUS PURCHASE SESSIONS
--
-- purchased = 1
-- but no order/customer ID
-- and revenue = 0
--
-- Purpose:
-- Understand their behavior before deciding whether they
-- should remain part of the ML target.
-- =========================================================

SELECT
    COUNT(*) AS ambiguous_sessions,

    SUM(`sessions`) AS total_sessions,
    SUM(`product_views`) AS total_product_views,
    SUM(`add_to_cart`) AS total_add_to_cart,
    SUM(`begin_checkout`) AS total_checkouts,

    MIN(`product_views`) AS min_product_views,
    MAX(`product_views`) AS max_product_views,

    MIN(`add_to_cart`) AS min_add_to_cart,
    MAX(`add_to_cart`) AS max_add_to_cart,

    MIN(`begin_checkout`) AS min_checkout,
    MAX(`begin_checkout`) AS max_checkout

FROM website_sessions

WHERE `purchased` = 1
  AND (
      `order_id` IS NULL
      OR TRIM(`order_id`) = ''
  )
  AND (
      `customer_id` IS NULL
      OR TRIM(`customer_id`) = ''
  )
  AND `revenue` = 0;
  
  -- =========================================================
-- COMPARE CONFIRMED VS AMBIGUOUS PURCHASE SESSIONS
-- =========================================================

SELECT
    CASE
        WHEN `purchased` = 1
         AND `revenue` = 0
         AND (TRIM(`order_id`) = '' OR `order_id` IS NULL)
         AND (TRIM(`customer_id`) = '' OR `customer_id` IS NULL)
        THEN 'Ambiguous purchased'
        WHEN `purchased` = 1
        THEN 'Confirmed purchased'
    END AS purchase_group,

    COUNT(*) AS session_count,
    ROUND(AVG(`product_views`), 2) AS avg_product_views,
    ROUND(AVG(`add_to_cart`), 2) AS avg_add_to_cart,
    ROUND(AVG(`begin_checkout`), 2) AS avg_checkout,
    ROUND(AVG(`revenue`), 2) AS avg_revenue

FROM website_sessions

WHERE `purchased` = 1

GROUP BY purchase_group;

# website_sessions contains 258 sessions labeled purchased = 1 with zero revenue and no order/customer identifiers. 
# These records are retained because purchased is the source dataset's target variable, 
# but the inconsistency is documented and considered during model evaluation.

-- =========================================================
-- PURCHASE PREDICTION FEATURE PROFILING
-- Purpose:
-- Understand the range and distribution of numerical
-- session-level predictors before feature engineering.
-- =========================================================

SELECT
    COUNT(*) AS total_sessions,

    MIN(`sessions`) AS min_sessions,
    MAX(`sessions`) AS max_sessions,
    AVG(`sessions`) AS avg_sessions,

    MIN(`product_views`) AS min_product_views,
    MAX(`product_views`) AS max_product_views,
    AVG(`product_views`) AS avg_product_views,

    MIN(`add_to_cart`) AS min_add_to_cart,
    MAX(`add_to_cart`) AS max_add_to_cart,
    AVG(`add_to_cart`) AS avg_add_to_cart,

    MIN(`begin_checkout`) AS min_begin_checkout,
    MAX(`begin_checkout`) AS max_begin_checkout,
    AVG(`begin_checkout`) AS avg_begin_checkout

FROM website_sessions;

-- =========================================================
-- PURCHASE RATE BY DEVICE
-- =========================================================

SELECT
    `device_category`,
    COUNT(*) AS sessions,
    SUM(`purchased`) AS purchases,
    ROUND(AVG(`purchased`) * 100, 2) AS purchase_rate_pct
FROM website_sessions
GROUP BY `device_category`
ORDER BY purchase_rate_pct DESC;

-- =========================================================
-- PURCHASE RATE BY TRAFFIC SOURCE
-- =========================================================

SELECT
    `traffic_source`,
    COUNT(*) AS sessions,
    SUM(`purchased`) AS purchases,
    ROUND(AVG(`purchased`) * 100, 2) AS purchase_rate_pct
FROM website_sessions
GROUP BY `traffic_source`
ORDER BY purchase_rate_pct DESC;

-- =========================================================
-- PURCHASE PREDICTION DATASET
-- Base grain: 1 row = 1 website session
--
-- Target:
-- purchased
--
-- Excluded:
-- session_id  → identifier
-- order_id    → post/outcome-related identifier
-- customer_id → identifier / unavailable for many visitors
-- revenue     → outcome information / data leakage
-- sessions    → constant value of 1, therefore no predictive value
-- =========================================================

CREATE OR REPLACE VIEW purchase_prediction_raw AS

SELECT
    `date`,
    `traffic_source`,
    `campaign_name`,
    `device_category`,
    `city`,
    `product_views`,
    `add_to_cart`,
    `begin_checkout`,
    `purchased`

FROM website_sessions;

-- Check the number of rows in the ML dataset.

SELECT
    COUNT(*) AS total_rows
FROM purchase_prediction_raw;

-- Check the extracted columns.

SELECT *
FROM purchase_prediction_raw
LIMIT 10;

-- Confirm the target distribution.

SELECT
    purchased,
    COUNT(*) AS session_count,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM purchase_prediction_raw),
        2
    ) AS percentage
FROM purchase_prediction_raw
GROUP BY purchased
ORDER BY purchased;

SELECT *
FROM purchase_prediction_raw;

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    COLUMN_KEY
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'ecommerce_customer_intelligence'
ORDER BY TABLE_NAME, ORDINAL_POSITION;