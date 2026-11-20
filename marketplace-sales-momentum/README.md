# Marketplace Sales Momentum

I built this BigQuery report for an e-commerce operation with a catalogue of more than 300,000 products to surface changes in sales across marketplaces.

This BigQuery report shows which products gained or lost sales volume on each marketplace. It returns one row per sales channel and SKU, with unit totals for two consecutive 30-day periods and a rank for products that gained sales.

## Run the query

Open [sql/marketplace_sales_momentum.sql](sql/marketplace_sales_momentum.sql) in the BigQuery editor and run the full GoogleSQL script. Update the table path if your orders table lives in another project or dataset.

| Input column | Meaning |
|---|---|
| `sales_channel` | Marketplace, such as Amazon |
| `sku` | Sellable product identifier |
| `processed_date` | Order processing date, stored as a DATE |
| `quantity_purchased` | Number of units on the order row |

By default, the report uses today's date in Europe/Sarajevo and excludes today. To reproduce a demo window, replace the default for `as_of_date` with a fixed date such as `DATE '2026-11-20'`.

## How the SQL works

1. **Filter to 60 completed days.** The previous window starts 60 days before the reporting date and ends just before the latest window. The latest window starts 30 days before the reporting date and ends just before the reporting date.
2. **Aggregate both periods in one step.** The `sales_by_period` CTE groups orders by channel and SKU. Each conditional sum counts units from its own window. Reading both windows keeps products that stopped selling in the latest period.
3. **Calculate the change.** The `sales_changes` CTE subtracts the previous total from the latest total. The final query calculates percentage change with `SAFE_DIVIDE`, which returns `NULL` for a zero baseline.
4. **Rank gains within each marketplace.** `DENSE_RANK` orders SKUs by unit change and gives ties the same rank. The `CASE` displays a rank only for positive changes. The final sort lists the largest gains first within each channel.

Conditional aggregation calculates both period totals from one filtered set of orders in a single grouping step. This avoids building and joining two period summaries, while keeping channel–SKU pairs that recorded sales in either period.

## Output columns

| Column | Meaning |
|---|---|
| `sales_channel` | Marketplace |
| `sku` | Product identifier on that marketplace |
| `units_previous_30d` | Units in the earlier period |
| `units_latest_30d` | Units in the latest period |
| `unit_change` | Latest units minus previous units |
| `pct_change` | Unit change divided by previous units, as a percentage rounded to two decimal places |
| `gain_rank` | Rank by unit gain within the marketplace. Flat and declining SKUs show `NULL`. |

## Example output

The SKU IDs below are synthetic. The first three rows illustrate the tie observed in an Amazon run.

| Channel | SKU | Previous units | Latest units | Unit change | Percentage change | Gain rank |
|---|---|---:|---:|---:|---:|---:|
| amazon | SKU-A | 0 | 2 | +2 | NULL | 1 |
| amazon | SKU-B | 0 | 2 | +2 | NULL | 1 |
| amazon | SKU-C | 0 | 2 | +2 | NULL | 1 |
| amazon | SKU-D | 4 | 5 | +1 | 25% | 2 |
| amazon | SKU-E | 12 | 0 | -12 | -100% | NULL |

The three gains of two units share rank 1. The next distinct gain gets rank 2. SKU-E stays visible because the query reads orders from both periods.

## Assumptions

The report uses units from all qualifying order rows. If the source includes cancellations or repeated snapshots of an order line, filter or deduplicate those records before aggregating. SKUs with no orders in either window are outside the report.
