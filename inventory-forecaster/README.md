# Inventory Forecaster in BigQuery

This GoogleSQL query flags product models and colours that could run out of stock within 14 days. It estimates demand using the previous 30 completed calendar days and returns one row per model and colour.

## How it works

Orders are summed by SKU, then mapped to their model and colour through the product catalogue. Demand is rolled up to model and colour because inventory is shared at that level. Stock is also aggregated before the join to avoid multiplying stock and sales rows.

Average daily sales equal the 30-day quantity divided by 30, including days with zero sales. Projected demand is that daily average multiplied by 14. Days of cover are available units divided by average daily sales.

For example, 60 units sold in 30 days and 28 available units give 2 units per day and 14 days of cover. The row is flagged as `STOCKOUT_WITHIN_14_DAYS`.

## Inputs

| Table | Required columns |
|---|---|
| Products | `item_sku`, `department_name`, `color_code` |
| Orders | `sku`, `processed_date` (DATE), `quantity_purchased` |
| Inventory | `name`, `color_code`, `units` |

Each SKU should map to one model and colour. Inventory rows must represent distinct current stock if their units are summed. The query uses all order rows in the date window, so verify that the feed contains the sales you want to count.

## Run it

Open [sql/inventory_forecast.sql](sql/inventory_forecast.sql) in the BigQuery editor. Adjust the table paths and verify the exact table names in your project. Run the full script. The results are sorted by model and colour.

## Validation and limitations

The forecast estimates stock coverage from the last 30 completed days of
sales. It assumes sales continue at that average rate and uses current
available stock. Future replenishment and changes in demand can affect the
actual stockout date.
