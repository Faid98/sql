DECLARE as_of_date DATE DEFAULT CURRENT_DATE('Europe/Sarajevo');

WITH product_catalog AS (
    SELECT DISTINCT
        item_sku,
        department_name AS model_name,
        CAST(color_code AS STRING) AS color_key
    FROM `Reference.products`
    WHERE department_name IS NOT NULL
      AND color_code IS NOT NULL
),

model_colors AS (
    SELECT DISTINCT model_name, color_key
    FROM product_catalog
),

sales_by_sku AS (
    SELECT
        sku,
        SUM(quantity_purchased) AS units_sold_30d
    FROM `Reference.orders`
    WHERE processed_date >= DATE_SUB(as_of_date, INTERVAL 30 DAY)
      AND processed_date < as_of_date
    GROUP BY sku
),

sales_by_model_color AS (
    SELECT
        p.model_name,
        p.color_key,
        SUM(s.units_sold_30d) AS units_sold_30d
    FROM sales_by_sku s
    JOIN product_catalog p ON p.item_sku = s.sku
    GROUP BY p.model_name, p.color_key
),

current_stock AS (
    SELECT
        name AS model_name,
        CAST(color_code AS STRING) AS color_key,
        SUM(units) AS available_units
    FROM `Reference.inventory`
    GROUP BY model_name, color_key
),

model_color_metrics AS (
    SELECT
        p.model_name,
        p.color_key,
        COALESCE(s.units_sold_30d, 0) AS units_sold_30d,
        i.available_units
    FROM model_colors p
    LEFT JOIN sales_by_model_color s USING (model_name, color_key)
    LEFT JOIN current_stock i USING (model_name, color_key)
)

SELECT
    model_name,
    color_key,
    units_sold_30d,
    available_units,
    ROUND(units_sold_30d / NUMERIC '30', 2) AS avg_daily_sales,
    ROUND(units_sold_30d * NUMERIC '14' / 30, 2) AS projected_demand_14d,
    ROUND(
        SAFE_DIVIDE(available_units * NUMERIC '30', units_sold_30d),
        2
    ) AS days_of_cover,
    CASE
        WHEN available_units IS NULL THEN 'MISSING_INVENTORY'
        WHEN available_units <= 0 THEN 'OUT_OF_STOCK_NOW'
        WHEN units_sold_30d = 0 THEN 'NO_RECENT_SALES'
        WHEN available_units * NUMERIC '30' <= units_sold_30d * NUMERIC '14'
            THEN 'STOCKOUT_WITHIN_14_DAYS'
        ELSE 'OK'
    END AS stock_status
FROM model_color_metrics
ORDER BY model_name ASC, color_key ASC;
