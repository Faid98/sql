# Inventory Forecaster in BigQuery

I built this BigQuery forecast for an e-commerce operation with a catalogue of more than 300,000 products to help identify stockout risk.

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

Orders join to the product catalogue on `Orders.sku = Products.item_sku`. The catalogue supplies the model and colour for each SKU. After rolling up sales, the query joins to inventory using `Products.department_name = Inventory.name` and matching `color_code` values. Multiple size SKUs can share the same model and colour stock pool.

Each SKU should map to one model and colour. Inventory rows must represent distinct current stock if their units are summed. The query uses all order rows in the date window, so verify that the feed contains the sales you want to count.

## Run it

Open [sql/inventory_forecast.sql](sql/inventory_forecast.sql) in the BigQuery editor. Adjust the table paths and verify the exact table names in your project. Run the full script. The results are sorted by model and colour.

## Validation and limitations

During validation, some orders could not be mapped to a model and colour. I traced the issue to the BigQuery products table the query referenced. Switching to the correct catalogue resolved the mapping issue. Missing mappings can understate demand, while conflicting mappings can count a SKU's sales more than once.

Before using the output to reorder stock, reconcile recent sales against the catalogue and confirm that each model and colour matches inventory. The forecast assumes a constant sales rate and uses current stock without accounting for future replenishment.
