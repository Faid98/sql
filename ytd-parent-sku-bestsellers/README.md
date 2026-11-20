# YTD Best Sellers by Parent SKU

I built this BigQuery report for an e-commerce operation with a catalogue of more than 300,000 products to prioritize product families for expansion to new marketplaces.

This BigQuery report identifies product families with the highest year-to-date unit sales. It gives the marketplace team a shortlist of proven sellers to consider for Temu, SHEIN, or another target channel.

An individual SKU identifies a sellable variant, such as a particular size or colour. Ranking by parent SKU combines sales across those variants so the team can evaluate the demand for the whole product family. For example, if sizes M, L, and XL sell 20, 15, and 10 units respectively, their shared parent contributes 45 units to the ranking.

## How to use the shortlist

1. Run the query to find the highest-selling parent SKUs across your available channels.
2. Pick a target marketplace and compare the shortlist with its active listings. If the listing export uses child SKUs, map them to parent SKUs through the product catalogue first.
3. Look for product families with no active listing on the target channel. For families already listed, check whether popular variants are missing before deciding what to add.
4. Review the variants to launch, the available stock, and channel-specific requirements such as category, size mapping, and pricing. Use the ranked list to prioritize that review.

The source-channel column shows where sales occurred during the reporting period. A product can have an active listing without recording any sales, so the target marketplace's listing data is needed to confirm a listing opportunity.

## How the query works

1. **Date window.** The script uses the current date in Europe/Sarajevo and sums orders from January 1 through yesterday. The reporting date is an exclusive upper bound.
2. **Roll up sales.** `sales_by_parent` trims the parent SKU, excludes blank or missing parents, and sums positive purchased quantities across child SKUs and channels. It also counts distinct child SKUs and lists distinct non-null sales channels.
3. **Rank by units.** `DENSE_RANK()` assigns the same rank to parents with equal unit totals. If two parents each sell 45 units and the next sells 42, their ranks are 1, 1, and 2.
4. **Keep the top 30 ranks.** `WHERE bestseller_rank <= 30` includes everyone tied within those ranks. The result can contain more than 30 parent SKUs. Within a tied rank, rows are sorted by parent SKU.

## Inputs and outputs

The script reads `Reference.orders` and assumes `processed_date` is a BigQuery DATE.

| Source column | Purpose |
|---|---|
| `parent_sku` | Product family used to group sizes and other variants |
| `sku` | Child SKU used to count distinct variants with sales |
| `sales_channel` | Channel where the order was recorded |
| `processed_date` | Determines whether the order falls inside the YTD window |
| `quantity_purchased` | Units on the order row |

| Output column | Meaning |
|---|---|
| `bestseller_rank` | Rank by year-to-date purchased units, with shared ranks for ties |
| `parent_sku` | Product family identifier |
| `units_sold_ytd` | Total positive purchased units across the family's variants and channels |
| `variants_sold_ytd` | Number of distinct child SKUs with recorded sales |
| `channels_with_sales_ytd` | Comma-separated list of channels with recorded sales |

## Run and verify

Open [ytd_parent_sku_bestsellers.sql](sql/ytd_parent_sku_bestsellers.sql) in the BigQuery editor. Adjust the table path if your orders table is in another dataset or project, then run the full script. To reproduce a reporting window, set `as_of_date` to a fixed date, such as `DATE '2026-11-20'`.

For a demo, choose one parent from the output and sum its child SKU quantities over the same dates. The result should match `units_sold_ytd`. If parents tie, check that they share a rank. Then compare one shortlisted family with the target marketplace's listing export.

## Assumptions

The report measures positive purchased units. If the orders table includes cancelled orders or repeated order-line snapshots, apply the appropriate status filter or deduplication before summing. Orders without a parent SKU are excluded, so check how many units are affected before using the ranking to prioritize launches.
