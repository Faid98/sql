DECLARE as_of_date DATE DEFAULT CURRENT_DATE('Europe/Sarajevo');
DECLARE year_start DATE DEFAULT DATE_TRUNC(as_of_date, YEAR);

WITH sales_by_parent AS (
    SELECT
        TRIM(parent_sku) AS parent_sku,
        SUM(quantity_purchased) AS units_sold_ytd,
        COUNT(DISTINCT sku) AS variants_sold_ytd,
        STRING_AGG(
            DISTINCT sales_channel, ', ' ORDER BY sales_channel
        ) AS channels_with_sales_ytd
    FROM `Reference.orders`
    WHERE processed_date >= year_start
      AND processed_date < as_of_date
      AND NULLIF(TRIM(parent_sku), '') IS NOT NULL
      AND quantity_purchased > 0
    GROUP BY 1
),

ranked AS (
    SELECT
        *,
        DENSE_RANK() OVER (ORDER BY units_sold_ytd DESC) AS bestseller_rank
    FROM sales_by_parent
)

SELECT
    bestseller_rank,
    parent_sku,
    units_sold_ytd,
    variants_sold_ytd,
    channels_with_sales_ytd
FROM ranked
WHERE bestseller_rank <= 30
ORDER BY bestseller_rank, parent_sku;
