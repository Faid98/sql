DECLARE as_of_date DATE DEFAULT CURRENT_DATE('Europe/Sarajevo');
DECLARE latest_start DATE DEFAULT DATE_SUB(as_of_date, INTERVAL 30 DAY);
DECLARE previous_start DATE DEFAULT DATE_SUB(as_of_date, INTERVAL 60 DAY);

WITH sales_by_period AS (
    SELECT
        sales_channel,
        sku,
        SUM(IF(processed_date >= latest_start, quantity_purchased, 0))
            AS units_latest_30d,
        SUM(IF(processed_date < latest_start, quantity_purchased, 0))
            AS units_previous_30d
    FROM `Reference.orders`
    WHERE processed_date >= previous_start
      AND processed_date < as_of_date
      AND sku IS NOT NULL
      AND sales_channel IS NOT NULL
    GROUP BY sales_channel, sku
),
sales_changes AS (
    SELECT
        sales_channel,
        sku,
        units_previous_30d,
        units_latest_30d,
        units_latest_30d - units_previous_30d AS unit_change
    FROM sales_by_period
)
SELECT
    sales_channel,
    sku,
    units_previous_30d,
    units_latest_30d,
    unit_change,
    ROUND(SAFE_DIVIDE(unit_change, units_previous_30d) * 100, 2) AS pct_change,
    CASE
        WHEN unit_change > 0 THEN DENSE_RANK() OVER (
            PARTITION BY sales_channel
            ORDER BY unit_change DESC
        )
    END AS gain_rank
FROM sales_changes
ORDER BY sales_channel, unit_change DESC, sku;
