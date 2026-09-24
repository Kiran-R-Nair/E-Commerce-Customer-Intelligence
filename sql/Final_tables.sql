-- =========================================================
-- INVENTORY: INSPECT UNITS SOLD FIELD
-- Purpose:
-- Understand how the 7/30/60-day sales information is
-- represented before deciding how to clean it.
-- =========================================================

SELECT DISTINCT
    `Units sold (last 7/30/60 days)`
FROM inventory_snapshots
LIMIT 30;

-- =========================================================
-- INVENTORY DATA VALIDATION
-- Purpose:
-- Check whether the 7/30/60-day sales values follow
-- the expected cumulative relationship:
--
-- 7-day sales <= 30-day sales <= 60-day sales
-- =========================================================

SELECT
    COUNT(*) AS invalid_sales_progression
FROM inventory_snapshots
WHERE
    CAST(SUBSTRING_INDEX(`Units sold (last 7/30/60 days)`, '/', 1) AS UNSIGNED)
    >
    CAST(
        SUBSTRING_INDEX(
            SUBSTRING_INDEX(`Units sold (last 7/30/60 days)`, '/', 2),
            '/',
            -1
        ) AS UNSIGNED
    )

    OR

    CAST(
        SUBSTRING_INDEX(
            SUBSTRING_INDEX(`Units sold (last 7/30/60 days)`, '/', 2),
            '/',
            -1
        ) AS UNSIGNED
    )
    >
    CAST(
        SUBSTRING_INDEX(`Units sold (last 7/30/60 days)`, '/', -1)
        AS UNSIGNED
    );
    
    -- =========================================================
-- CLEAN INVENTORY SNAPSHOTS
--
-- Purpose:
-- 1. Convert date from TEXT to DATE.
-- 2. Split the combined 7/30/60-day sales field.
-- 3. Convert the three sales measures to integers.
-- 4. Standardize text fields.
-- 5. Preserve the raw inventory table unchanged.
-- =========================================================

DROP TABLE IF EXISTS inventory_snapshots_clean;

CREATE TABLE inventory_snapshots_clean AS

SELECT
    TRIM(`SKU`) AS SKU,

    TRIM(`Category`) AS Category,

    TRIM(`Size`) AS Size,

    `Units in stock`,

    CAST(
        SUBSTRING_INDEX(
            `Units sold (last 7/30/60 days)`,
            '/',
            1
        ) AS UNSIGNED
    ) AS units_sold_7d,

    CAST(
        SUBSTRING_INDEX(
            SUBSTRING_INDEX(
                `Units sold (last 7/30/60 days)`,
                '/',
                2
            ),
            '/',
            -1
        ) AS UNSIGNED
    ) AS units_sold_30d,

    CAST(
        SUBSTRING_INDEX(
            `Units sold (last 7/30/60 days)`,
            '/',
            -1
        ) AS UNSIGNED
    ) AS units_sold_60d,

    `Days of inventory left`,

    UPPER(TRIM(`Dead stock flag`)) AS dead_stock_flag,

    STR_TO_DATE(`date`, '%Y-%m-%d') AS snapshot_date

FROM inventory_snapshots;

-- =========================================================
-- CHECK CLEAN INVENTORY TABLE STRUCTURE
-- =========================================================

DESCRIBE inventory_snapshots_clean;

-- =========================================================
-- RAW VS CLEAN ROW COUNT
-- =========================================================

SELECT
    (SELECT COUNT(*) FROM inventory_snapshots) AS raw_rows,
    (SELECT COUNT(*) FROM inventory_snapshots_clean) AS clean_rows;
    
-- =========================================================
-- VERIFY 7/30/60-DAY SALES SPLIT
-- =========================================================

SELECT
    SKU,
    units_sold_7d,
    units_sold_30d,
    units_sold_60d
FROM inventory_snapshots_clean
LIMIT 20;

-- =========================================================
-- POST-CLEANING DUPLICATE CHECK
-- Grain:
-- 1 row = 1 SKU snapshot on 1 date
-- =========================================================

SELECT
    SKU,
    snapshot_date,
    COUNT(*) AS duplicate_count
FROM inventory_snapshots_clean
GROUP BY
    SKU,
    snapshot_date
HAVING COUNT(*) > 1;

DESCRIBE purchase_orders;

SELECT
    COUNT(*) AS total_rows,

    SUM(`Order date` IS NULL OR TRIM(`Order date`) = '') AS missing_order_date,
    SUM(`Expected delivery` IS NULL OR TRIM(`Expected delivery`) = '') AS missing_expected_delivery,
    SUM(`Actual delivery` IS NULL OR TRIM(`Actual delivery`) = '') AS missing_actual_delivery,

    SUM(STR_TO_DATE(`Order date`, '%Y-%m-%d') IS NULL) AS invalid_order_date,
    SUM(STR_TO_DATE(`Expected delivery`, '%Y-%m-%d') IS NULL) AS invalid_expected_delivery,
    SUM(STR_TO_DATE(`Actual delivery`, '%Y-%m-%d') IS NULL) AS invalid_actual_delivery

FROM purchase_orders;

SELECT
    COUNT(*) AS total_rows,
    SUM(`SKU` IS NULL OR TRIM(`SKU`) = '') AS missing_sku,
    SUM(`Category` IS NULL OR TRIM(`Category`) = '') AS missing_category,
    SUM(`Size` IS NULL OR TRIM(`Size`) = '') AS missing_size,
    SUM(`Color` IS NULL OR TRIM(`Color`) = '') AS missing_color,
    SUM(`MRP` IS NULL) AS missing_mrp,
    SUM(`Selling Price` IS NULL) AS missing_selling_price,
    SUM(`Discount %` IS NULL) AS missing_discount_pct
FROM sku_catalog;

DESCRIBE sku_catalog;

SELECT
    `First order date`,
    `Last purchase date`,
    `Time to 2nd purchase`,
    `RePurchased`
FROM customers
LIMIT 20;

CREATE TABLE customers_clean AS
SELECT
    CAST(TRIM(`Customer ID`) AS CHAR(50)) AS `Customer ID`,
    CAST(TRIM(`Name`) AS CHAR(150)) AS `Name`,

    STR_TO_DATE(TRIM(`First order date`), '%Y-%m-%d')
        AS `First order date`,

    CAST(`Total orders` AS SIGNED) AS `Total orders`,

    CAST(`Total revenue` AS DECIMAL(12,2))
        AS `Total revenue`,

    CAST(`Average order value` AS DECIMAL(12,2))
        AS `Average order value`,

    CASE
        WHEN TRIM(`Time to 2nd purchase`) = '' THEN NULL
        ELSE CAST(`Time to 2nd purchase` AS DECIMAL(10,0))
    END AS `Time to 2nd purchase`,

    STR_TO_DATE(TRIM(`Last purchase date`), '%Y-%m-%d')
        AS `Last purchase date`,

    CAST(TRIM(`City / tier`) AS CHAR(100)) AS `City / tier`,

    CAST(
        TRIM(`Acquisition channel (first touch)`)
        AS CHAR(100)
    ) AS `Acquisition channel (first touch)`,

    CAST(TRIM(`RePurchased`) AS CHAR(1)) AS `RePurchased`

FROM customers;

-- =========================================================
-- VALIDATE CUSTOMERS_CLEAN DATA TYPES
-- =========================================================

DESCRIBE customers_clean;

DESCRIBE orders;

-- =========================================================
-- CLEAN ORDERS TABLE
-- Purpose:
-- 1. Convert Order date & time from TEXT → DATETIME
-- 2. Convert monetary values → DECIMAL
-- 3. Convert Discount % → DECIMAL
-- 4. Convert Pincode → VARCHAR
-- 5. Standardize text fields with TRIM
-- 6. Preserve the original raw table
-- =========================================================

DROP TABLE IF EXISTS orders_clean;

CREATE TABLE orders_clean AS

SELECT
    CAST(TRIM(`Order ID`) AS CHAR(50)) AS `Order ID`,

    CAST(TRIM(`Customer ID`) AS CHAR(50)) AS `Customer ID`,

    STR_TO_DATE(
        TRIM(`Order date & time`),
        '%Y-%m-%d %H:%i:%s'
    ) AS `Order date & time`,

    CAST(TRIM(`Product`) AS CHAR(100)) AS `Product`,

    CAST(
        TRIM(`Order value (gross, net)`)
        AS CHAR(50)
    ) AS `Order value (gross, net)`,

    CAST(
        `Order value (gross)`
        AS DECIMAL(12,2)
    ) AS `Order value (gross)`,

    CAST(
        `Order value (net)`
        AS DECIMAL(12,2)
    ) AS `Order value (net)`,

    CAST(
        TRIM(`Discount applied (â‚¹ + %)`)
        AS CHAR(50)
    ) AS `Discount applied (â‚¹ + %)`,

    CAST(
        `Discount applied (â‚¹)`
        AS DECIMAL(12,2)
    ) AS `Discount applied (â‚¹)`,

    CAST(
        REPLACE(
            TRIM(`Discount applied (%)`),
            '%',
            ''
        )
        AS DECIMAL(5,2)
    ) AS `Discount applied (%)`,

    CAST(TRIM(`Payment mode`) AS CHAR(50))
        AS `Payment mode`,

    CAST(TRIM(`Shipping city`) AS CHAR(100))
        AS `Shipping city`,

    CAST(`Pincode` AS CHAR(10))
        AS `Pincode`,

    CAST(TRIM(`First order vs repeat`) AS CHAR(20))
        AS `First order vs repeat`,

    CAST(TRIM(`Channel source (last touch)`) AS CHAR(100))
        AS `Channel source (last touch)`,

    CAST(TRIM(`Delivered / Returned / RTO`) AS CHAR(30))
        AS `Delivered / Returned / RTO`

FROM orders;

-- CHECK CLEAN ORDERS STRUCTURE

DESCRIBE orders_clean;

-- =========================================================
-- CREATE CLEAN ORDER LINE ITEMS TABLE
-- =========================================================

DROP TABLE IF EXISTS order_line_items_clean;

CREATE TABLE order_line_items_clean AS

SELECT
    CAST(TRIM(`Order ID`) AS CHAR(50))
        AS `Order ID`,

    CAST(TRIM(`SKU ID`) AS CHAR(50))
        AS `SKU ID`,

    CAST(
        TRIM(`Category (top, bottom, outerwear, etc.)`)
        AS CHAR(100)
    ) AS `Category (top, bottom, outerwear, etc.)`,

    CAST(TRIM(`Size`) AS CHAR(30))
        AS `Size`,

    CAST(TRIM(`Color`) AS CHAR(50))
        AS `Color`,

    CAST(`MRP` AS DECIMAL(12,2))
        AS `MRP`,

    CAST(`Selling price` AS DECIMAL(12,2))
        AS `Selling price`,

    CAST(`Discount %` AS DECIMAL(5,2))
        AS `Discount %`,

    UPPER(TRIM(`Returned? (Y/N)`))
        AS `Returned? (Y/N)`,

    CASE
        WHEN TRIM(COALESCE(`Return reason (if any)`, '')) = ''
        THEN NULL
        ELSE TRIM(`Return reason (if any)`)
    END AS `Return reason (if any)`

FROM order_line_items;

-- =========================================================
-- RAW VS CLEAN ROW COUNT
-- =========================================================

SELECT
    (SELECT COUNT(*) FROM order_line_items) AS raw_rows,
    (SELECT COUNT(*) FROM order_line_items_clean) AS clean_rows;
    
    -- =========================================================
-- CHECK CLEAN TABLE STRUCTURE
-- =========================================================

DESCRIBE order_line_items_clean;

-- =========================================================
-- CHECK RETURN REASON AFTER CLEANING
-- =========================================================

SELECT
    `Returned? (Y/N)` AS returned_flag,
    COUNT(*) AS row_count,
    SUM(`Return reason (if any)` IS NULL) AS null_return_reason
FROM order_line_items_clean
GROUP BY `Returned? (Y/N)`;

-- =========================================================
-- STANDARDIZE RETURN FLAG DATA TYPE
-- =========================================================

ALTER TABLE order_line_items_clean
MODIFY COLUMN `Returned? (Y/N)` CHAR(1);

ALTER TABLE order_line_items_clean
MODIFY COLUMN `Return reason (if any)` VARCHAR(150);

-- =========================================================
-- FINAL STRUCTURE CHECK
-- =========================================================

DESCRIBE order_line_items_clean;

-- =========================================================
-- CREATE CLEAN PURCHASE ORDERS TABLE
-- =========================================================

DROP TABLE IF EXISTS purchase_orders_clean;

CREATE TABLE purchase_orders_clean AS

SELECT
    CAST(TRIM(`SKU`) AS CHAR(50)) AS `SKU`,

    CAST(TRIM(`Vendor`) AS CHAR(100)) AS `Vendor`,

    CAST(`Order quantity` AS SIGNED) AS `Order quantity`,

    CAST(`Cost per unit` AS DECIMAL(12,2))
        AS `Cost per unit`,

    STR_TO_DATE(
        TRIM(`Order date`),
        '%Y-%m-%d'
    ) AS `Order date`,

    STR_TO_DATE(
        TRIM(`Expected delivery`),
        '%Y-%m-%d'
    ) AS `Expected delivery`,

    STR_TO_DATE(
        TRIM(`Actual delivery`),
        '%Y-%m-%d'
    ) AS `Actual delivery`,

    CAST(`Lead time` AS SIGNED) AS `Lead time`

FROM purchase_orders;

DESCRIBE purchase_orders_clean;

-- =========================================================
-- CHECK CATEGORY VALUES
-- =========================================================

SELECT
    `Category`,
    COUNT(*) AS row_count
FROM sku_catalog
GROUP BY `Category`
ORDER BY row_count DESC;

-- =========================================================
-- CREATE CLEAN SKU CATALOG
--
-- Grain:
-- 1 row = 1 SKU
--
-- Purpose:
-- Convert identifiers/text and monetary fields to
-- appropriate SQL data types while preserving the
-- original raw table.
-- =========================================================

DROP TABLE IF EXISTS sku_catalog_clean;

CREATE TABLE sku_catalog_clean AS

SELECT
    CAST(TRIM(`SKU`) AS CHAR(50)) AS `SKU`,

    CAST(TRIM(`Category`) AS CHAR(100)) AS `Category`,

    CAST(TRIM(`Color`) AS CHAR(50)) AS `Color`,

    CAST(`MRP` AS DECIMAL(12,2)) AS `MRP`,

    CAST(`Cost_per_unit` AS DECIMAL(12,2))
        AS `Cost_per_unit`

FROM sku_catalog;

-- =========================================================
-- CHECK CLEAN SKU CATALOG STRUCTURE
-- =========================================================

DESCRIBE sku_catalog;

DROP TABLE IF EXISTS sku_catalog_clean;

CREATE TABLE sku_catalog_clean AS
SELECT
    CAST(TRIM(`SKU`) AS CHAR(50)) AS `SKU`,
    CAST(TRIM(`Category`) AS CHAR(100)) AS `Category`,
    CAST(TRIM(`Vendor`) AS CHAR(100)) AS `Vendor`,
    CAST(`MRP` AS DECIMAL(12,2)) AS `MRP`,
    CAST(`Cost_per_unit` AS DECIMAL(12,2)) AS `Cost_per_unit`
FROM sku_catalog;

DESCRIBE sku_catalog_clean;

DESCRIBE meta_ads_campaigns;

DROP TABLE IF EXISTS meta_ads_campaigns_clean;

CREATE TABLE meta_ads_campaigns_clean AS
SELECT
    STR_TO_DATE(TRIM(`date`), '%Y-%m-%d') AS `date`,

    CAST(TRIM(`campaign_name`) AS CHAR(150)) AS `campaign_name`,

    CAST(TRIM(`adset_name`) AS CHAR(150)) AS `adset_name`,

    CAST(`Results` AS SIGNED) AS `Results`,

    CAST(`Amount spent (INR)` AS DECIMAL(12,2))
        AS `Amount spent (INR)`,

    CAST(`spend` AS DECIMAL(12,2)) AS `spend`,

    CAST(`Reach` AS SIGNED) AS `Reach`,

    CAST(`impressions` AS SIGNED) AS `impressions`,

    CAST(`frequency` AS DECIMAL(10,4)) AS `frequency`,

    CAST(`link_clicks` AS SIGNED) AS `link_clicks`,

    CAST(`ctr_link` AS DECIMAL(10,4)) AS `ctr_link`,

    CAST(`add_to_cart` AS SIGNED) AS `add_to_cart`,

    CAST(`initiate_checkout` AS SIGNED)
        AS `initiate_checkout`,

    CAST(`purchases` AS SIGNED) AS `purchases`,

    CAST(`purchase_conversion_value` AS DECIMAL(14,2))
        AS `purchase_conversion_value`,

    CAST(`cac` AS DECIMAL(12,2)) AS `cac`,

    CAST(`roas` AS DECIMAL(10,4)) AS `roas`,

    CAST(TRIM(`creative_type`) AS CHAR(50))
        AS `creative_type`,

    STR_TO_DATE(TRIM(`launch_date`), '%Y-%m-%d')
        AS `launch_date`,

    CAST(`Hook Rate` AS DECIMAL(10,4)) AS `Hook Rate`

FROM meta_ads_campaigns;

DESCRIBE meta_ads_campaigns_clean;

SELECT
    (SELECT COUNT(*) FROM meta_ads_campaigns) AS raw_rows,
    (SELECT COUNT(*) FROM meta_ads_campaigns_clean) AS clean_rows;
    
    DESCRIBE website_daily;
    
    DROP TABLE IF EXISTS website_daily_clean;

CREATE TABLE website_daily_clean AS
SELECT
    STR_TO_DATE(TRIM(`date`), '%Y-%m-%d') AS `date`,

    CAST(TRIM(`traffic_source`) AS CHAR(50))
        AS `traffic_source`,

    CAST(TRIM(`campaign_name`) AS CHAR(150))
        AS `campaign_name`,

    CAST(TRIM(`device_category`) AS CHAR(30))
        AS `device_category`,

    CAST(`sessions` AS SIGNED) AS `sessions`,

    CAST(`product_views` AS SIGNED) AS `product_views`,

    CAST(`add_to_cart` AS SIGNED) AS `add_to_cart`,

    CAST(`begin_checkout` AS SIGNED) AS `begin_checkout`,

    CAST(`purchases` AS SIGNED) AS `purchases`,

    CAST(`revenue` AS DECIMAL(14,2)) AS `revenue`,

    CAST(`conversion_rate` AS DECIMAL(10,4))
        AS `conversion_rate`,

    CAST(`aov` AS DECIMAL(12,2)) AS `aov`,

    CAST(TRIM(`country`) AS CHAR(50)) AS `country`,

    CAST(TRIM(`city`) AS CHAR(100)) AS `city`,

    CAST(`purchased` AS UNSIGNED) AS `purchased`

FROM website_daily;

DESCRIBE website_daily_clean;

SELECT
    `traffic_source`,
    COUNT(*) AS total_rows,
    SUM(`campaign_name` IS NULL) AS missing_campaign
FROM website_daily_clean
GROUP BY `traffic_source`
ORDER BY `traffic_source`;

DESCRIBE website_sessions;

-- =========================================================
-- CREATE CLEAN WEBSITE SESSIONS TABLE
--
-- Grain:
-- 1 row = 1 website session
--
-- This table is especially important for the
-- purchase-prediction dataset.
-- =========================================================

DROP TABLE IF EXISTS website_sessions_clean;

CREATE TABLE website_sessions_clean AS

SELECT
    CAST(TRIM(`session_id`) AS CHAR(50))
        AS `session_id`,

    STR_TO_DATE(
        TRIM(`date`),
        '%Y-%m-%d'
    ) AS `date`,

    CAST(TRIM(`traffic_source`) AS CHAR(50))
        AS `traffic_source`,

    CAST(TRIM(`campaign_name`) AS CHAR(150))
        AS `campaign_name`,

    CAST(TRIM(`device_category`) AS CHAR(30))
        AS `device_category`,

    CAST(TRIM(`city`) AS CHAR(100))
        AS `city`,

    CAST(`sessions` AS SIGNED) AS `sessions`,

    CAST(`product_views` AS SIGNED)
        AS `product_views`,

    CAST(`add_to_cart` AS SIGNED)
        AS `add_to_cart`,

    CAST(`begin_checkout` AS SIGNED)
        AS `begin_checkout`,

    CAST(`purchased` AS UNSIGNED)
        AS `purchased`,

    CASE
        WHEN TRIM(COALESCE(`order_id`, '')) = ''
        THEN NULL
        ELSE CAST(TRIM(`order_id`) AS CHAR(50))
    END AS `order_id`,

    CASE
        WHEN TRIM(COALESCE(`customer_id`, '')) = ''
        THEN NULL
        ELSE CAST(TRIM(`customer_id`) AS CHAR(50))
    END AS `customer_id`,

    CAST(`revenue` AS DECIMAL(14,2))
        AS `revenue`

FROM website_sessions;

DESCRIBE website_sessions_clean;

SELECT
    `session_id`,
    COUNT(*) AS duplicate_count
FROM website_sessions_clean
GROUP BY `session_id`
HAVING COUNT(*) > 1;

SELECT
    `purchased`,
    COUNT(*) AS session_count,
    SUM(`order_id` IS NOT NULL) AS sessions_with_order_id,
    SUM(`customer_id` IS NOT NULL) AS sessions_with_customer_id,
    SUM(`revenue` > 0) AS sessions_with_revenue
FROM website_sessions_clean
GROUP BY `purchased`
ORDER BY `purchased`;

-- =========================================================
-- ENRICH PURCHASE PREDICTION DATASET
-- Add non-leaky customer attributes.
-- =========================================================

ALTER TABLE purchase_prediction_raw
ADD COLUMN `customer_city_tier` VARCHAR(100),
ADD COLUMN `customer_acquisition_channel` VARCHAR(100);

SHOW CREATE VIEW purchase_prediction_raw;

DROP VIEW IF EXISTS purchase_prediction_raw;

CREATE VIEW purchase_prediction_raw AS
SELECT
    `session_id`,
    `date`,
    `traffic_source`,
    `campaign_name`,
    `device_category`,
    `city`,
    `product_views`,
    `add_to_cart`,
    `begin_checkout`,
    `purchased`,
    `order_id`,
    `customer_id`,
    `revenue`
FROM website_sessions_clean;

DESCRIBE purchase_prediction_raw;

-- =========================================================
-- PURCHASE PREDICTION DATASET
--
-- Grain:
-- 1 row = 1 website session
--
-- Target:
-- purchased
--
-- Features are restricted to behavior/context available
-- at the session level.
-- =========================================================

DROP VIEW IF EXISTS purchase_prediction_dataset;

CREATE VIEW purchase_prediction_dataset AS
SELECT
    session_id,
    date,
    traffic_source,
    campaign_name,
    device_category,
    city,
    product_views,
    add_to_cart,
    begin_checkout,
    purchased
FROM purchase_prediction_raw;

-- =========================================================
-- STEP 4A: SESSION + CUSTOMER JOIN
--
-- Grain:
-- 1 row = 1 website session
--
-- Base table:
-- website_sessions_clean
--
-- Enrichment:
-- customers_clean
-- =========================================================

DROP TABLE IF EXISTS purchase_prediction_joined;

CREATE TABLE purchase_prediction_joined AS

SELECT
    ws.`session_id`,
    ws.`date`,
    ws.`traffic_source`,
    ws.`campaign_name`,
    ws.`device_category`,
    ws.`city`,
    ws.`product_views`,
    ws.`add_to_cart`,
    ws.`begin_checkout`,
    ws.`purchased`,

    c.`City / tier` AS `customer_city_tier`,
    c.`Acquisition channel (first touch)`
        AS `customer_acquisition_channel`

FROM website_sessions_clean ws

LEFT JOIN customers_clean c
    ON ws.`customer_id` = c.`Customer ID`;
    
SELECT COUNT(*) AS total_rows
FROM purchase_prediction_joined;

-- =========================================================
-- CUSTOMER + ORDER DATASET
--
-- Grain:
-- 1 row = 1 order
--
-- Each order is enriched with customer attributes.
-- =========================================================

DROP TABLE IF EXISTS customer_orders;

CREATE TABLE customer_orders AS
SELECT
    o.`Order ID`,
    o.`Customer ID`,
    o.`Order date & time`,
    o.`Product`,
    o.`Order value (gross, net)`,
    o.`Order value (gross)`,
    o.`Order value (net)`,
    o.`Discount applied (â‚¹ + %)`,
    o.`Discount applied (â‚¹)`,
    o.`Discount applied (%)`,
    o.`Payment mode`,
    o.`Shipping city`,
    o.`Pincode`,
    o.`First order vs repeat`,
    o.`Channel source (last touch)`,
    o.`Delivered / Returned / RTO`,

    c.`Name`,
    c.`First order date`,
    c.`Total orders`,
    c.`Total revenue`,
    c.`Average order value`,
    c.`City / tier`,
    c.`Acquisition channel (first touch)`,
    c.`RePurchased`

FROM orders_clean o

LEFT JOIN customers_clean c
    ON o.`Customer ID` = c.`Customer ID`;
    
-- =========================================================
-- STEP 2: AGGREGATE ORDER LINE ITEMS TO ORDER LEVEL
--
-- Grain:
-- 1 row = 1 order
--
-- This prevents one order with multiple items from
-- creating duplicate order rows.
-- =========================================================

DROP TABLE IF EXISTS order_item_summary;

CREATE TABLE order_item_summary AS
SELECT
    `Order ID`,

    COUNT(*) AS `item_count`,

    COUNT(DISTINCT `SKU ID`) AS `unique_sku_count`,

    SUM(`MRP`) AS `total_item_mrp`,

    SUM(`Selling price`) AS `total_item_selling_price`,

    AVG(`Discount %`) AS `average_item_discount_pct`,

    SUM(
        CASE
            WHEN `Returned? (Y/N)` = 'Y'
            THEN 1
            ELSE 0
        END
    ) AS `returned_item_count`

FROM order_line_items_clean

GROUP BY `Order ID`;

-- =========================================================
-- STEP 2B: CUSTOMER + ORDER + ITEM SUMMARY
--
-- Grain:
-- 1 row = 1 order
-- =========================================================

DROP TABLE IF EXISTS customer_order_items;

CREATE TABLE customer_order_items AS

SELECT
    co.*,

    oi.`item_count`,
    oi.`unique_sku_count`,
    oi.`total_item_mrp`,
    oi.`total_item_selling_price`,
    oi.`average_item_discount_pct`,
    oi.`returned_item_count`

FROM customer_orders co

LEFT JOIN order_item_summary oi
    ON co.`Order ID` = oi.`Order ID`;
    
    DROP TABLE IF EXISTS order_item_summary;

CREATE TABLE order_item_summary AS
SELECT
    `Order ID`,
    COUNT(*) AS `item_count`,
    COUNT(DISTINCT `SKU ID`) AS `unique_sku_count`,
    SUM(`MRP`) AS `total_item_mrp`,
    SUM(`Selling price`) AS `total_item_selling_price`,
    CAST(AVG(`Discount %`) AS DECIMAL(10,4))
        AS `average_item_discount_pct`,
    SUM(
        CASE
            WHEN `Returned? (Y/N)` = 'Y' THEN 1
            ELSE 0
        END
    ) AS `returned_item_count`
FROM order_line_items_clean
GROUP BY `Order ID`;

DROP TABLE IF EXISTS order_item_summary;

CREATE TABLE order_item_summary AS
SELECT
    `Order ID`,
    COUNT(*) AS `item_count`,
    COUNT(DISTINCT `SKU ID`) AS `unique_sku_count`,
    SUM(`MRP`) AS `total_item_mrp`,
    SUM(`Selling price`) AS `total_item_selling_price`,
    CAST(AVG(`Discount %`) AS DECIMAL(10,4))
        AS `average_item_discount_pct`,
    SUM(
        CASE
            WHEN `Returned? (Y/N)` = 'Y' THEN 1
            ELSE 0
        END
    ) AS `returned_item_count`
FROM order_line_items_clean
GROUP BY `Order ID`;

DROP TABLE IF EXISTS customer_order_items;

CREATE TABLE customer_order_items AS
SELECT
    co.*,
    oi.`item_count`,
    oi.`unique_sku_count`,
    oi.`total_item_mrp`,
    oi.`total_item_selling_price`,
    oi.`average_item_discount_pct`,
    oi.`returned_item_count`
FROM customer_orders co
LEFT JOIN order_item_summary oi
    ON co.`Order ID` = oi.`Order ID`;
    
DROP TABLE IF EXISTS order_sku_summary;

CREATE TABLE order_sku_summary AS
SELECT
    oli.`Order ID`,
    COUNT(DISTINCT oli.`SKU ID`) AS `unique_sku_count`,
    GROUP_CONCAT(DISTINCT s.`SKU` ORDER BY s.`SKU` SEPARATOR ', ') AS `sku_list`,
    GROUP_CONCAT(DISTINCT s.`Category` ORDER BY s.`Category` SEPARATOR ', ') AS `category_list`,
    GROUP_CONCAT(DISTINCT s.`Vendor` ORDER BY s.`Vendor` SEPARATOR ', ') AS `vendor_list`
FROM order_line_items_clean oli
LEFT JOIN sku_catalog_clean s
    ON oli.`SKU ID` = s.`SKU`
GROUP BY oli.`Order ID`;

DROP TABLE IF EXISTS inventory_summary;


CREATE TABLE inventory_summary AS
SELECT
    `SKU`,
    `snapshot_date`,
    MAX(`Units in stock`) AS `units_in_stock`,
    MAX(`units_sold_7d`) AS `units_sold_7d`,
    MAX(`units_sold_30d`) AS `units_sold_30d`,
    MAX(`units_sold_60d`) AS `units_sold_60d`,
    MAX(`Days of inventory left`) AS `days_of_inventory_left`,
    MAX(`dead_stock_flag`) AS `dead_stock_flag`
FROM inventory_snapshots_clean
GROUP BY
    `SKU`,
    `snapshot_date`;
    
DROP TABLE IF EXISTS purchase_order_summary;

CREATE TABLE purchase_order_summary AS
SELECT
    `SKU`,
    `Order date` AS `date`,
    SUM(`Order quantity`) AS `total_order_quantity`,
    AVG(`Cost per unit`) AS `avg_cost_per_unit`,
    AVG(`Lead time`) AS `avg_lead_time`,
    MIN(`Expected delivery`) AS `expected_delivery`,
    MAX(`Actual delivery`) AS `actual_delivery`
FROM purchase_orders_clean
GROUP BY
    `SKU`,
    `Order date`;
    
DROP TABLE IF EXISTS sku_inventory_supply;

CREATE TABLE sku_inventory_supply AS
SELECT
    i.`SKU`,
    i.`snapshot_date`,
    i.`units_in_stock`,
    i.`units_sold_7d`,
    i.`units_sold_30d`,
    i.`units_sold_60d`,
    i.`days_of_inventory_left`,
    i.`dead_stock_flag`,

    p.`total_order_quantity`,
    p.`avg_cost_per_unit`,
    p.`avg_lead_time`,
    p.`expected_delivery`,
    p.`actual_delivery`

FROM inventory_summary i

LEFT JOIN purchase_order_summary p
    ON i.`SKU` = p.`SKU`
    AND i.`snapshot_date` = p.`date`;
    
DROP TABLE IF EXISTS meta_campaign_summary;

CREATE TABLE meta_campaign_summary AS
SELECT
    `date`,
    `campaign_name`,
    SUM(`Amount spent (INR)`) AS `meta_spend`,
    SUM(`Reach`) AS `meta_reach`,
    SUM(`impressions`) AS `meta_impressions`,
    SUM(`link_clicks`) AS `meta_link_clicks`,
    SUM(`add_to_cart`) AS `meta_add_to_cart`,
    SUM(`initiate_checkout`) AS `meta_checkouts`,
    SUM(`purchases`) AS `meta_purchases`,
    SUM(`purchase_conversion_value`) AS `meta_conversion_value`
FROM meta_ads_campaigns_clean
GROUP BY
    `date`,
    `campaign_name`;
    
DROP TABLE IF EXISTS marketing_website_summary;

CREATE TABLE marketing_website_summary AS
SELECT
    w.`date`,
    w.`traffic_source`,
    w.`campaign_name`,
    w.`device_category`,
    w.`country`,
    w.`city`,
    w.`sessions`,
    w.`product_views`,
    w.`add_to_cart`,
    w.`begin_checkout`,
    w.`purchases`,
    w.`revenue`,
    w.`conversion_rate`,
    w.`aov`,

    m.`meta_spend`,
    m.`meta_reach`,
    m.`meta_impressions`,
    m.`meta_link_clicks`,
    m.`meta_add_to_cart`,
    m.`meta_checkouts`,
    m.`meta_purchases`,
    m.`meta_conversion_value`

FROM website_daily_clean w

LEFT JOIN meta_campaign_summary m
    ON w.`date` = m.`date`
    AND w.`campaign_name` = m.`campaign_name`
    AND w.`traffic_source` = 'Meta';
    
DROP TABLE IF EXISTS purchase_prediction_ml;

CREATE TABLE purchase_prediction_ml AS
SELECT
    `session_id`,
    `date`,
    `traffic_source`,
    `campaign_name`,
    `device_category`,
    `city`,
    `product_views`,
    `add_to_cart`,
    `begin_checkout`,
    `customer_city_tier`,
    `customer_acquisition_channel`,
    `purchased`
FROM purchase_prediction_joined;

SELECT * FROM customer_order_product;

DROP TABLE IF EXISTS customer_order_product;

CREATE TABLE customer_order_product AS
SELECT
    coi.*,
    os.`sku_list`,
    os.`category_list`,
    os.`vendor_list`
FROM customer_order_items coi
LEFT JOIN order_sku_summary os
    ON coi.`Order ID` = os.`Order ID`;
    
SELECT COUNT(*) AS total_rows
FROM customer_order_product;

SELECT * FROM customer_order_product;

SELECT * FROM sku_inventory_supply;

SELECT * FROM marketing_website_summary;

SELECT * FROM purchase_prediction_ml;

DESCRIBE purchase_prediction_joined;

SELECT *
FROM purchase_prediction_joined
LIMIT 5;

DESCRIBE website_sessions;

SELECT *
FROM website_sessions
LIMIT 5;

DROP TABLE IF EXISTS purchase_prediction_base;

CREATE TABLE purchase_prediction_base AS
SELECT
    ws.`session_id`,
    ws.`date`,
    ws.`traffic_source`,
    ws.`campaign_name`,
    ws.`device_category`,
    ws.`city`,
    ws.`product_views`,
    ws.`add_to_cart`,
    ws.`begin_checkout`,
    ws.`customer_id`,
    ws.`purchased`
FROM website_sessions_clean ws;

DESCRIBE purchase_prediction_base;

SELECT COUNT(*) AS total_rows
FROM purchase_prediction_base;

DROP TABLE IF EXISTS session_customer_history;

CREATE TABLE session_customer_history AS
SELECT
    p.`session_id`,

    COUNT(o.`Order ID`) AS `previous_order_count`,

    COALESCE(
        SUM(o.`Order value (net)`),
        0
    ) AS `previous_total_spend`,

    COALESCE(
        AVG(o.`Order value (net)`),
        0
    ) AS `previous_avg_order_value`,

    CASE
        WHEN MAX(o.`Order date & time`) IS NULL THEN NULL
        ELSE DATEDIFF(
            p.`date`,
            DATE(MAX(o.`Order date & time`))
        )
    END AS `days_since_previous_purchase`

FROM purchase_prediction_base p

LEFT JOIN orders_clean o
    ON p.`customer_id` = o.`Customer ID`
    AND DATE(o.`Order date & time`) < p.`date`

WHERE TRIM(COALESCE(p.`customer_id`, '')) <> ''

GROUP BY
    p.`session_id`,
    p.`date`;
    
DROP TABLE IF EXISTS session_customer_history;

CREATE TABLE session_customer_history AS
SELECT
    p.`session_id`,

    COUNT(o.`Order ID`) AS `previous_order_count`,

    COALESCE(
        SUM(o.`Order value (net)`),
        0
    ) AS `previous_total_spend`,

    COALESCE(
        AVG(o.`Order value (net)`),
        0
    ) AS `previous_avg_order_value`,

    CASE
        WHEN MAX(o.`Order date & time`) IS NULL THEN NULL
        ELSE DATEDIFF(
            p.`date`,
            DATE(MAX(o.`Order date & time`))
        )
    END AS `days_since_previous_purchase`

FROM purchase_prediction_base p

LEFT JOIN orders_clean o
    ON TRIM(COALESCE(p.`customer_id`, '')) <> ''
    AND p.`customer_id` = o.`Customer ID`
    AND DATE(o.`Order date & time`) < p.`date`

GROUP BY
    p.`session_id`,
    p.`date`;
    
SELECT COUNT(*) AS total_rows
FROM session_customer_history;

DROP TABLE IF EXISTS purchase_prediction_ml_v2;

CREATE TABLE purchase_prediction_ml_v2 AS
SELECT
    p.`session_id`,
    p.`date`,
    p.`traffic_source`,
    p.`campaign_name`,
    p.`device_category`,
    p.`city`,
    p.`product_views`,
    p.`add_to_cart`,
    p.`begin_checkout`,

    h.`previous_order_count`,
    h.`previous_total_spend`,
    h.`previous_avg_order_value`,
    h.`days_since_previous_purchase`,

    p.`purchased`

FROM purchase_prediction_base p

LEFT JOIN session_customer_history h
    ON p.`session_id` = h.`session_id`;
    
SELECT COUNT(*) AS total_rows
FROM purchase_prediction_ml_v2;

DESCRIBE purchase_prediction_ml_v2;

-- Check whether the historical customer features were created correctly
-- for all 26,611 prediction sessions.

SELECT
    COUNT(*) AS total_sessions,                         -- Total number of sessions

    SUM(previous_order_count > 0) AS sessions_with_previous_orders,
                                                        -- Sessions where the customer
                                                        -- had at least one earlier order

    SUM(previous_order_count = 0) AS sessions_without_previous_orders,
                                                        -- Sessions where the customer
                                                        -- had no earlier order

    MIN(previous_order_count) AS min_previous_orders,   -- Minimum number of previous orders

    MAX(previous_order_count) AS max_previous_orders,   -- Maximum number of previous orders

    MIN(previous_total_spend) AS min_previous_spend,    -- Minimum historical customer spend

    MAX(previous_total_spend) AS max_previous_spend,    -- Maximum historical customer spend

    MIN(days_since_previous_purchase) AS min_days_since_previous_purchase,
                                                        -- Minimum days since the customer's
                                                        -- previous purchase

    MAX(days_since_previous_purchase) AS max_days_since_previous_purchase
                                                        -- Maximum days since the customer's
                                                        -- previous purchase

FROM purchase_prediction_ml_v2;

-- Check how many sessions actually have a customer ID
-- and how many purchased sessions have a customer ID.

SELECT
    COUNT(*) AS total_sessions,

    SUM(
        TRIM(COALESCE(customer_id, '')) <> ''
    ) AS sessions_with_customer_id,

    SUM(
        purchased = 1
    ) AS purchased_sessions,

    SUM(
        purchased = 1
        AND TRIM(COALESCE(customer_id, '')) <> ''
    ) AS purchased_with_customer_id

FROM purchase_prediction_base;

-- Create previous-day Meta campaign spend.
-- We use the previous day's spend to avoid target leakage.

DROP TABLE IF EXISTS meta_campaign_previous_day;

CREATE TABLE meta_campaign_previous_day AS
SELECT
    `date`,
    `campaign_name`,
    SUM(`Amount spent (INR)`) AS `previous_day_meta_spend`
FROM meta_ads_campaigns_clean
GROUP BY
    `date`,
    `campaign_name`;
    
-- Final session-level ML dataset.
-- Meta spend is shifted by one day so that it represents
-- information available before the current session date.

DROP TABLE IF EXISTS purchase_prediction_final;

CREATE TABLE purchase_prediction_final AS
SELECT
    p.`session_id`,
    p.`date`,
    p.`traffic_source`,
    p.`campaign_name`,
    p.`device_category`,
    p.`city`,
    p.`product_views`,
    p.`add_to_cart`,
    p.`begin_checkout`,

    m.`previous_day_meta_spend`,

    p.`purchased`

FROM purchase_prediction_base p

LEFT JOIN meta_campaign_previous_day m
    ON p.`traffic_source` = 'Meta'
    AND p.`campaign_name` = m.`campaign_name`
    AND m.`date` = DATE_SUB(p.`date`, INTERVAL 1 DAY);
    
SELECT COUNT(*) AS total_rows
FROM purchase_prediction_final;

SELECT
    COUNT(*) AS total_sessions,
    SUM(previous_day_meta_spend IS NOT NULL) AS sessions_with_previous_day_meta_spend,
    SUM(previous_day_meta_spend IS NULL) AS sessions_without_previous_day_meta_spend
FROM purchase_prediction_final;

-- Check the campaign names available in website sessions
-- for Meta traffic.

SELECT
    DISTINCT `campaign_name`
FROM website_sessions_clean
WHERE `traffic_source` = 'Meta'
ORDER BY `campaign_name`;

-- Check the campaign names available in Meta Ads data.

SELECT
    DISTINCT `campaign_name`
FROM meta_ads_campaigns_clean
ORDER BY `campaign_name`;

-- Compare the date ranges of the two datasets.

SELECT
    MIN(`date`) AS min_date,
    MAX(`date`) AS max_date
FROM website_sessions_clean;

SELECT
    MIN(`date`) AS min_date,
    MAX(`date`) AS max_date
FROM meta_ads_campaigns_clean;

-- Remove the failed Meta Ads feature because there is
-- no valid date/campaign overlap with the session data.

DROP TABLE IF EXISTS purchase_prediction_final;

CREATE TABLE purchase_prediction_final AS
SELECT
    `session_id`,
    `date`,
    `traffic_source`,
    `campaign_name`,
    `device_category`,
    `city`,
    `product_views`,
    `add_to_cart`,
    `begin_checkout`,
    `purchased`
FROM purchase_prediction_base;

SELECT COUNT(*) AS total_rows
FROM purchase_prediction_final;

-- Final validation of the purchase prediction dataset.

SELECT
    COUNT(*) AS total_sessions,

    SUM(`purchased` = 1) AS purchased_sessions,
    SUM(`purchased` = 0) AS non_purchased_sessions,

    ROUND(
        100 * AVG(`purchased`),
        2
    ) AS purchase_rate_pct,

    MIN(`product_views`) AS min_product_views,
    MAX(`product_views`) AS max_product_views,

    MIN(`add_to_cart`) AS min_add_to_cart,
    MAX(`add_to_cart`) AS max_add_to_cart,

    MIN(`begin_checkout`) AS min_begin_checkout,
    MAX(`begin_checkout`) AS max_begin_checkout

FROM purchase_prediction_final;

SELECT *
FROM purchase_prediction_final;