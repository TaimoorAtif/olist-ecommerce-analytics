-- ============================================================================
-- OLIST E-COMMERCE ANALYTICS | SELECTED SQL QUERIES
-- ============================================================================
-- Author: Taimoor Atif
-- Source: Original Project 1 PostgreSQL working script (~7,000 lines)
-- Purpose: Short technical showcase of validation, transformation logic,
--          modelling checks, and business analysis.
--
-- REQUIREMENTS
--   PostgreSQL with the Olist project tables already loaded and modelled:
--      "RAW"."RAW - ..."  (original imported data)
--      stage.*            (cleaned/staged tables)
--      analytics.*        (fact and dimension tables)
--
-- IMPORTANT
--   * These are selected, reformatted queries from my actual project work.
--   * Each executable statement is a SELECT or WITH ... SELECT; no data is
--     created, inserted, changed, or deleted by running this showcase.
--   * Run one query at a time in the existing project database.
--   * This file is NOT an end-to-end database setup or ETL script.
--   * The full exploratory/development record is in olist-working-script.sql.
--   * Results depend on the original public 2016-2018 Olist dataset and model.
--   * I have not rerun this curated export against a database after formatting.
--
-- METRIC NOTE
--   Delivered Total Order Value (TOV) = item price + freight, summed over
--   delivered order items. These are dataset-based values, not company revenue.
-- ============================================================================

-- ============================================================================
-- 01 | SOURCE VALIDATION: COMPOSITE KEY
-- Identify duplicate (order_id, order_item_id) combinations in raw order items.
-- ============================================================================

-- A zero-row result supports this candidate composite key.
SELECT
    (order_id||'.'||order_item_id) AS comp_key,
    COUNT(*) AS total_count
FROM
    "RAW"."RAW - Order Items"
GROUP BY
    order_id,
    order_item_id
HAVING
                COUNT(*) > 1
ORDER BY
    total_count DESC;


-- ============================================================================
-- 02 | SOURCE VALIDATION: PAYMENT RECONCILIATION
-- Compare order-item totals against recorded order payments at order grain.
-- ============================================================================

-- Groups orders whose item totals differ from payment totals by size and type.
-- This check excludes orders with no payment record (SQL NULL comparison).
-- The original working script checks those separately.
WITH item_total AS
(
SELECT
    order_id,
    (SUM(((price::NUMERIC) + (freight_value::NUMERIC)))) AS sum_price
FROM
    "RAW"."RAW - Order Items"
GROUP BY
    order_id
),
payment_total AS
(
SELECT
    order_id,
    (SUM(payment_value::NUMERIC)) AS sum_payment,
    COUNT(*) AS num_of_rows,
    COUNT(DISTINCT(payment_type)) AS num_of_types,
    STRING_AGG(DISTINCT(payment_type), ', ') as pmt_types,
    MAX(payment_installments::NUMERIC) AS installments
FROM
    "RAW"."RAW - Payments"
GROUP BY
    order_id
),
reconciliation AS
(
SELECT
    it.order_id,
    it.sum_price,
    pt.sum_payment,
    ABS(pt.sum_payment - it.sum_price) AS abs_diff,
    pt.num_of_rows,
    pt.num_of_types,
    pt.pmt_types,
    pt.installments
FROM
    item_total it LEFT JOIN payment_total pt
                ON it.order_id = pt.order_id
WHERE
    sum_price <> sum_payment
)
SELECT
    COUNT(order_id) AS total_count,
    (CASE
        WHEN abs_diff <= 0.05 THEN '0.01 - 0.05'
        WHEN abs_diff <= 1.00 THEN '0.06 - 1.00'
        ELSE 'Over 1.00'
    END) AS class_diff,
    (CASE
        WHEN pmt_types = 'credit_card' AND installments > 1 THEN 'Credit Card >1 installments'
        WHEN pmt_types = 'credit_card' AND installments = 1 THEN 'Credit Card =1 installments'
        WHEN pmt_types = 'debit_card' THEN 'Debit Card'
        WHEN pmt_types = 'boleto' THEN 'Boleto'
        WHEN pmt_types = 'voucher' THEN 'Voucher'
        WHEN num_of_types > 1 THEN 'Mixed Payments'
    END) AS pmt_category
FROM
    reconciliation
GROUP BY
    pmt_category,
    class_diff
ORDER BY
    total_count DESC;


-- ============================================================================
-- 03 | GEOLOCATION TRANSFORMATION: ZIP-LEVEL REDUCTION
-- Preview the exact CTE logic used to create one geolocation row per ZIP.
-- ============================================================================

-- Adapted from the original INSERT INTO stage.geolocation ... WITH ... SELECT.
-- The INSERT has intentionally been removed so this showcase is read-only.
-- Method: distinct ZIP/coordinate pairs -> median lat/lng per ZIP -> most
-- frequent city and state per ZIP, with alphabetical tie-breakers.
WITH deduplication AS
(
SELECT
    DISTINCT
            geolocation_zip_code_prefix AS geo_zip,
            (geolocation_lat::NUMERIC) AS geo_lat,
            (geolocation_lng::NUMERIC) AS geo_lng
FROM
    "RAW"."RAW - Geolocation"
),
coordinates AS
(
SELECT
    geo_zip,
    (PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY geo_lat)) AS median_lat,
    (PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY geo_lng)) AS median_lng
FROM
    deduplication
GROUP BY
    geo_zip
),
city_frq AS
(
SELECT
    geolocation_zip_code_prefix,
    geolocation_city,
    COUNT(geolocation_city) AS city_frequency
FROM
    "RAW"."RAW - Geolocation"
GROUP BY
    geolocation_zip_code_prefix,
    geolocation_city
),
city_ranked AS
(
SELECT
    geolocation_zip_code_prefix,
    geolocation_city,
    city_frequency,
    ROW_NUMBER() OVER
        (
        PARTITION BY geolocation_zip_code_prefix
        ORDER BY city_frequency DESC, geolocation_city ASC
        ) AS city_rank
FROM
    city_frq
),
state_frq AS
(
SELECT
    geolocation_zip_code_prefix,
    geolocation_state,
    COUNT(geolocation_state) AS state_frequency
FROM
    "RAW"."RAW - Geolocation"
GROUP BY
    geolocation_zip_code_prefix,
    geolocation_state
),
state_ranked AS
(
SELECT
    geolocation_zip_code_prefix,
    geolocation_state,
    state_frequency,
    ROW_NUMBER() OVER
        (
        PARTITION BY geolocation_zip_code_prefix
        ORDER BY state_frequency DESC, geolocation_state ASC
        ) AS state_rank
FROM
    state_frq
)
SELECT
    cr.geolocation_zip_code_prefix,
    c.median_lat,
    c.median_lng,
    cr.geolocation_city,
    sr.geolocation_state
FROM
    city_ranked cr INNER JOIN coordinates c ON cr.geolocation_zip_code_prefix = c.geo_zip
                   INNER JOIN state_ranked sr ON c.geo_zip = sr.geolocation_zip_code_prefix
WHERE
    cr.city_rank = 1
    AND
    sr.state_rank = 1;


-- ============================================================================
-- 04 | DIMENSIONAL MODEL: GRAIN AND RELATIONSHIP CHECKS
-- Check coverage of core fact/dimension relationships after modelling.
-- ============================================================================

-- Expect zero unmatched fact_orders rows.
SELECT
    COUNT(fo.*)
FROM
    analytics.fact_orders fo LEFT JOIN analytics.dim_customers dc ON fo.customer_id = dc.customer_id
                LEFT JOIN analytics.dim_dates dd ON (fo.order_purchase_timestamp::DATE) = dd.date
WHERE
    dc.customer_id IS NULL
    OR
    dd.date IS NULL;

-- Expect zero unmatched fact_order_items rows.
SELECT
    COUNT(foi.*)
FROM
    analytics.fact_order_items foi LEFT JOIN analytics.dim_customers dc ON foi.customer_id = dc.customer_id
                LEFT JOIN analytics.dim_products dp ON foi.product_id = dp.product_id
                LEFT JOIN analytics.dim_sellers ds ON foi.seller_id = ds.seller_id
                LEFT JOIN analytics.dim_dates dd ON (foi.order_purchase_timestamp::DATE) = dd.date
WHERE
    dc.customer_id IS NULL OR
    dp.product_id IS NULL OR
    ds.seller_id IS NULL OR
    dd.date IS NULL;

-- The complete original working script also contains CREATE TABLE statements,
-- PK/FK constraints, staging loads, and post-transformation reconciliation.
-- They are omitted here because this is a read-only query showcase.


-- ============================================================================
-- 05 | EXECUTIVE PERFORMANCE: CORE KPIS
-- Calculate order activity, delivered order value and delivered customer counts.
-- ============================================================================

-- TOV includes item price plus freight; completed orders are delivered orders.
WITH overall_orders_metrics AS
(
SELECT
    COUNT(*) AS total_orders_placed
FROM
    analytics.fact_orders
),
delivered_commercial_metrics AS
(
SELECT
    COUNT(DISTINCT(order_id)) AS completed_orders,
    COUNT(*) AS total_units_sold,
    SUM(price) AS total_merchandise_sales_value,
    SUM(freight_value) AS total_freight_value,
    SUM(item_total_value) AS total_order_value,
    ROUND(((SUM(item_total_value)) / (COUNT(DISTINCT(order_id)))), 2) AS avg_order_value,
    ROUND(AVG(price), 2) AS avg_selling_price
FROM
    analytics.fact_order_items
WHERE
    order_status = 'delivered'
),
delivered_unique_customer_metrics AS
(
SELECT
      COUNT(DISTINCT(dc.customer_unique_id)) AS total_unique_customers
FROM
    analytics.dim_customers dc INNER JOIN analytics.fact_orders fo ON dc.customer_id = fo.customer_id
WHERE
    fo.order_status = 'delivered'
)
SELECT
    total_orders_placed,
    completed_orders,
    total_unique_customers,
    total_units_sold,
    total_merchandise_sales_value,
    total_freight_value,
    total_order_value,
    avg_order_value,
    avg_selling_price
FROM
    overall_orders_metrics oom CROSS JOIN delivered_commercial_metrics dcm
                CROSS JOIN delivered_unique_customer_metrics ducm;


-- ============================================================================
-- 06 | COMPARABLE PERIODS: JANUARY-AUGUST 2017 VS 2018
-- Compare like-for-like months instead of using incomplete full-year data.
-- ============================================================================

-- The YoY row is a percentage comparison, not an additional calendar period.
WITH orders_years_customers AS
(
SELECT
    dd.year,
    COUNT(fo.order_id) AS completed_orders,
    COUNT(DISTINCT(dc.customer_unique_id)) AS total_customers
FROM
    analytics.fact_orders fo INNER JOIN analytics.dim_customers dc ON fo.customer_id = dc.customer_id
                INNER JOIN analytics.dim_dates dd ON (fo.order_purchase_timestamp::DATE) = dd.date
WHERE
    fo.order_status = 'delivered'
    AND
    (EXTRACT(MONTH FROM fo.order_purchase_timestamp) BETWEEN 1 AND 8)
    AND
    dd.year IN (2017, 2018)
GROUP BY
    dd.year
),
delivered_commercial_metrics AS
(
SELECT
    dd.year,
    COUNT(foi.*) AS total_units_sold,
    SUM(foi.price) AS merchandise_sales_value,
    SUM(foi.item_total_value) AS total_order_value
FROM
    analytics.fact_order_items foi INNER JOIN analytics.dim_dates dd
                ON (foi.order_purchase_timestamp::DATE) = dd.date
WHERE
    foi.order_status = 'delivered'
    AND
    (EXTRACT(MONTH FROM foi.order_purchase_timestamp) BETWEEN 1 AND 8)
    AND
    dd.year IN (2017, 2018)
GROUP BY
    dd.year
),
comparison_metrics AS
(
SELECT
    'Jan - Aug'||' '||oyc.year AS period,
    oyc.year,
    oyc.completed_orders,
    oyc.total_customers,
    dcm.total_units_sold,
    dcm.merchandise_sales_value,
    dcm.total_order_value
FROM
    orders_years_customers oyc INNER JOIN delivered_commercial_metrics dcm
                ON oyc.year = dcm.year
)
SELECT
    period,
    completed_orders,
    total_customers,
    total_units_sold,
    merchandise_sales_value,
    total_order_value
FROM
    comparison_metrics
UNION ALL
SELECT
    'YoY %' AS period,
    ROUND((((y2018.completed_orders::NUMERIC - y2017.completed_orders::NUMERIC) / y2017.completed_orders::NUMERIC) * 100), 2) AS completed_orders,
    ROUND((((y2018.total_customers::NUMERIC - y2017.total_customers::NUMERIC) / y2017.total_customers::NUMERIC) * 100), 2) AS total_customers,
    ROUND((((y2018.total_units_sold::NUMERIC - y2017.total_units_sold::NUMERIC) / y2017.total_units_sold::NUMERIC) * 100), 2) AS total_units_sold,
    ROUND((((y2018.merchandise_sales_value - y2017.merchandise_sales_value) / y2017.merchandise_sales_value) * 100), 2) AS merchandise_sales_value,
    ROUND((((y2018.total_order_value - y2017.total_order_value) / y2017.total_order_value) * 100), 2) AS total_order_value
FROM
    comparison_metrics y2017 CROSS JOIN comparison_metrics y2018
WHERE
    y2017.year = 2017
    AND
    y2018.year = 2018;


-- ============================================================================
-- 07 | CUSTOMER INTELLIGENCE: REPEAT PURCHASING
-- Use persistent customer_unique_id rather than order-level customer_id.
-- ============================================================================

-- Repeat means more than one DELIVERED order in the dataset window.
-- This is an observed-period repeat rate, not a lifetime retention measure.
WITH order_count AS
(
SELECT
    dc.customer_unique_id,
    COUNT(DISTINCT(fo.order_id)) AS total_order_count,
    SUM(foi.item_total_value) AS total_order_value,
    SUM(foi.price) AS order_merch_price,
    COUNT(*) AS total_items_purchased
FROM
    analytics.dim_customers dc INNER JOIN analytics.fact_orders fo ON dc.customer_id = fo.customer_id
                INNER JOIN analytics.fact_order_items foi ON fo.order_id = foi.order_id
WHERE
    fo.order_status = 'delivered'
GROUP BY
    dc.customer_unique_id
)
SELECT
    (CASE
        WHEN total_order_count = 1 THEN 'One-time Customers'
        ELSE 'Repeat Customers'
    END) AS customer_type,
    COUNT(customer_unique_id) AS number_of_customers,
    SUM(total_order_count) AS customer_type_order_count,
    SUM(total_order_value) AS customer_type_tov,
    ROUND((((SUM(total_order_value)::NUMERIC) / (SUM(SUM(total_order_value)) OVER())) * 100), 2) AS pct_of_tov,
    ROUND(((SUM(total_order_value)::NUMERIC) / (SUM(total_order_count)::NUMERIC)), 2) AS avg_order_value,
    ROUND(((SUM(order_merch_price)::NUMERIC) / (SUM(total_items_purchased)::NUMERIC)), 2) AS avg_product_price,
    ROUND(((SUM(total_items_purchased)::NUMERIC) / SUM(total_order_count)), 2) AS avg_items_purchased
FROM
    order_count
GROUP BY
    customer_type;


-- ============================================================================
-- 08 | SELLER INTELLIGENCE: CONCENTRATION
-- Rank active sellers by delivered TOV and calculate contribution of the top 1/5/10%.
-- ============================================================================

-- Uses ROW_NUMBER() with seller_id tie-breaker and window COUNT().
WITH indv_seller_sales AS
(
SELECT
    seller_id,
    COUNT(*) AS units_sold,
    COUNT(DISTINCT(order_id)) AS completed_orders,
    SUM(item_total_value) AS total_order_value,
    ROUND(AVG(price), 2) AS avg_selling_price
FROM
    analytics.fact_order_items
WHERE
    order_status = 'delivered'
GROUP BY
    seller_id
),
seller_ranks AS
(
SELECT
    seller_id,
    total_order_value,
    ROW_NUMBER() OVER(ORDER BY total_order_value DESC, seller_id ASC) AS seller_rank,
    COUNT(seller_id) OVER() AS total_sellers
FROM
    indv_seller_sales
)
SELECT
    'Top 1%' AS seller_group,
    (COUNT(seller_id) FILTER (WHERE seller_rank <= CEIL((total_sellers::NUMERIC) * 0.01))) AS seller_count,
    (SUM(total_order_value) FILTER (WHERE seller_rank <= CEIL((total_sellers::NUMERIC) * 0.01))) AS top_total_order_value,
    ROUND(((((SUM(total_order_value) FILTER (WHERE seller_rank <= CEIL((total_sellers::NUMERIC) * 0.01)))::NUMERIC) / (SUM(total_order_value)::NUMERIC)) * 100), 2) AS share_of_marketplace_value_pct
FROM
    seller_ranks
UNION ALL
SELECT
    'Top 5%' AS seller_group,
    (COUNT(seller_id) FILTER (WHERE seller_rank <= CEIL((total_sellers::NUMERIC) * 0.05))) AS seller_count,
    (SUM(total_order_value) FILTER (WHERE seller_rank <= CEIL((total_sellers::NUMERIC) * 0.05))) AS top_total_order_value,
    ROUND(((((SUM(total_order_value) FILTER (WHERE seller_rank <= CEIL((total_sellers::NUMERIC) * 0.05)))::NUMERIC) / (SUM(total_order_value)::NUMERIC)) * 100), 2) AS share_of_marketplace_value_pct
FROM
    seller_ranks
UNION ALL
SELECT
    'Top 10%' AS seller_group,
    (COUNT(seller_id) FILTER (WHERE seller_rank <= CEIL((total_sellers::NUMERIC) * 0.1))) AS seller_count,
    (SUM(total_order_value) FILTER (WHERE seller_rank <= CEIL((total_sellers::NUMERIC) * 0.1))) AS top_total_order_value,
    ROUND(((((SUM(total_order_value) FILTER (WHERE seller_rank <= CEIL((total_sellers::NUMERIC) * 0.1)))::NUMERIC) / (SUM(total_order_value)::NUMERIC)) * 100), 2) AS share_of_marketplace_value_pct
FROM
    seller_ranks;


-- ============================================================================
-- 09 | GEOGRAPHIC DELIVERY PERFORMANCE
-- Compare late-delivery incidence across customer states using eligible deliveries.
-- ============================================================================

-- The late-delivery rate denominator is evaluable deliveries, not every order.
-- Association between delivery performance and reviews is examined separately.
SELECT
    dc.customer_state,
    COUNT(fo.order_id) AS delivered_orders,
    (COUNT(fo.order_id) FILTER (WHERE (fo.order_delivered_customer_date::DATE) <= fo.order_estimated_delivery_date)) AS on_time_deliveries,
    (COUNT(fo.order_id) FILTER (WHERE (fo.order_delivered_customer_date::DATE) > fo.order_estimated_delivery_date)) AS late_deliveries,
    COUNT(fo.order_id) FILTER (WHERE fo.order_delivered_customer_date IS NOT NULL AND fo.order_estimated_delivery_date IS NOT NULL) AS evaluable_deliveries,
    ROUND(COUNT(fo.order_id) FILTER (WHERE fo.order_delivered_customer_date::DATE <= fo.order_estimated_delivery_date)::NUMERIC / NULLIF(COUNT(fo.order_id) FILTER (WHERE fo.order_delivered_customer_date IS NOT NULL AND fo.order_estimated_delivery_date IS NOT NULL), 0) * 100, 2) AS on_time_rate_pct,
    ROUND(COUNT(fo.order_id) FILTER (WHERE fo.order_delivered_customer_date::DATE > fo.order_estimated_delivery_date)::NUMERIC / NULLIF(COUNT(fo.order_id) FILTER (WHERE fo.order_delivered_customer_date IS NOT NULL AND fo.order_estimated_delivery_date IS NOT NULL), 0) * 100, 2) AS late_rate_pct,
    ROUND(AVG(fo.delivery_duration_days), 2) AS avg_delivery_days,
    ROUND((AVG(fo.delivery_variance_days) FILTER (WHERE fo.delivery_performance = 'Late')), 2) AS avg_delay_days_late
FROM
    analytics.fact_orders fo INNER JOIN analytics.dim_customers dc
                ON fo.customer_id = dc.customer_id
WHERE
    fo.order_status = 'delivered'
GROUP BY
    dc.customer_state
ORDER BY
    late_rate_pct DESC;


-- ============================================================================
-- 10 | CUSTOMER REVIEWS: DELIVERY ASSOCIATION
-- Compare review scores for late versus on-time delivered orders.
-- ============================================================================

-- Review-score measures use review rows; reviewed_orders counts distinct orders.
-- Descriptive association only; this does not demonstrate causation.
SELECT
    fo.delivery_performance,
    COUNT(DISTINCT(fr.order_id)) AS reviewed_orders,
    COUNT(*) AS total_reviews,
    ROUND(AVG(fr.review_score), 2) AS avg_review_score,
    ROUND(((((COUNT(*) FILTER (WHERE fr.review_score IN (4, 5)))::NUMERIC) / (COUNT(*)::NUMERIC)) * 100), 2) AS positive_review_rate_pct,
    ROUND(((((COUNT(*) FILTER (WHERE fr.review_score IN (1, 2)))::NUMERIC) / (COUNT(*)::NUMERIC)) * 100), 2) AS negative_review_rate_pct
FROM
    analytics.fact_reviews fr INNER JOIN analytics.fact_orders fo
                ON fr.order_id = fo.order_id
WHERE
    fo.delivery_performance IS NOT NULL
    AND
    fo.order_status = 'delivered'
GROUP BY
    fo.delivery_performance;


-- ============================================================================
-- 11 | PAYMENT MIX: METHOD DISTRIBUTION
-- Compare payment-row share and value share without conflating their grains.
-- ============================================================================

-- A single order may have multiple payment component records.
SELECT
    payment_type,
    COUNT(*) AS payment_records,
    COUNT(DISTINCT(order_id)) AS distinct_orders,
    ROUND((((COUNT(*)::NUMERIC) / ((SUM(COUNT(*)) OVER())::NUMERIC)) * 100), 2) AS payments_records_share_pct,
    SUM(payment_value) AS total_payment_value,
    ROUND(((((SUM(payment_value)::NUMERIC) / (SUM(SUM(payment_value)) OVER())::NUMERIC)) * 100), 2) AS payment_value_share_pct,
    ROUND(AVG(payment_value), 2) AS avg_payment_value
FROM
    analytics.fact_payments
GROUP BY
    payment_type
ORDER BY
    payment_records DESC;


-- ============================================================================
-- 12 | ORDER ECONOMICS: FREIGHT BURDEN
-- Calculate freight as a percentage of merchandise value per delivered order.
-- ============================================================================

-- Aggregates order items to order level before assigning freight-percentage bands.
WITH freight_calc AS
(
SELECT
    order_id,
    SUM(price) AS merchandise_value,
    SUM(freight_value) AS freight_value,
    ROUND((((SUM(freight_value)::NUMERIC) / (NULLIF(SUM(price), 0))) * 100), 2) AS freight_pct
FROM
    analytics.fact_order_items
WHERE
    order_status = 'delivered'
GROUP BY
    order_id
)
SELECT
    (CASE
        WHEN freight_pct <= 10 THEN '0% - 10%'
        WHEN freight_pct <= 20 THEN '>10% - 20%'
        WHEN freight_pct <= 30 THEN '>20% - 30%'
        WHEN freight_pct <= 40 THEN '>30% - 40%'
        WHEN freight_pct <= 50 THEN '>40% - 50%'
        ELSE '>50%'
    END) AS freight_group,
    COUNT(order_id) AS total_orders,
    ROUND((((COUNT(order_id)::NUMERIC) / ((SUM(COUNT(order_id)) OVER())::NUMERIC)) * 100), 2) AS pct_of_delivered_orders
FROM
    freight_calc
GROUP BY
    freight_group
ORDER BY
    freight_group ASC;


-- ============================================================================
-- 13 | ORDER ECONOMICS: FREIGHT AND PRODUCT WEIGHT
-- Compare average freight charges across order-weight bands.
-- ============================================================================

-- First verify how many delivered orders have complete product-weight metadata.
WITH total_order_weight AS
(
SELECT
    foi.order_id,
    SUM(dp.product_weight_g) FILTER (WHERE dp.product_weight_g IS NOT NULL) AS total_order_weight_g,
    COUNT(foi.product_id) FILTER (WHERE dp.product_weight_g IS NOT NULL) AS total_products,
    COUNT(foi.product_id) FILTER (WHERE dp.product_weight_g IS NULL) AS products_in_order_without_weight
FROM
    analytics.fact_order_items foi INNER JOIN analytics.dim_products dp
                ON foi.product_id = dp.product_id
WHERE
    foi.order_status = 'delivered'
GROUP BY
    foi.order_id
)
SELECT
    COUNT(*) AS total_delivered_orders,
    COUNT(*) FILTER (WHERE products_in_order_without_weight = 0) AS order_with_complete_weight_data,
    COUNT(*) FILTER (WHERE products_in_order_without_weight > 0) AS orders_with_atleast_one_missing_weight
FROM
    total_order_weight;

-- Exclude orders with any missing product weight before comparing weight bands.
WITH total_order_weight AS
(
SELECT
    foi.order_id,
    SUM(dp.product_weight_g) FILTER (WHERE dp.product_weight_g IS NOT NULL) AS total_order_weight_g,
    SUM(foi.freight_value) AS freight_value
FROM
    analytics.fact_order_items foi INNER JOIN analytics.dim_products dp
                ON foi.product_id = dp.product_id
WHERE
    foi.order_status = 'delivered'
GROUP BY
    foi.order_id
HAVING
                (COUNT(foi.product_id) FILTER (WHERE dp.product_weight_g IS NULL)) = 0
)
SELECT
    (CASE
        WHEN total_order_weight_g <= 1000 THEN '≤ 1kg'
        WHEN total_order_weight_g <= 3000 THEN '>1kg - 3kg'
        WHEN total_order_weight_g <= 5000 THEN '>3kg - 5kg'
        WHEN total_order_weight_g <= 10000 THEN '>5kg - 10kg'
        ELSE '> 10kg'
    END) AS weight_group,
    COUNT(*) AS total_orders,
    ROUND(AVG(freight_value), 2) AS avg_freight,
    ROUND((((COUNT(*)::NUMERIC) / ((SUM(COUNT(*)) OVER())::NUMERIC)) * 100), 2) AS pct_of_total_orders
FROM
    total_order_weight
GROUP BY
    weight_group
ORDER BY
    avg_freight;

