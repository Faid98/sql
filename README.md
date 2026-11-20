# SQL Portfolio

I built these BigQuery projects to answer practical e-commerce questions about inventory, sales trends, and marketplace expansion. The work draws on an e-commerce catalogue of more than 300,000 products.

## Projects

| Project | Business question | SQL techniques |
|---|---|---|
| Inventory Forecaster · [README](inventory-forecaster/README.md) · [SQL](inventory-forecaster/sql/inventory_forecast.sql) | Which products could run out of stock within 14 days at their recent sales rate? | CTEs, aggregation before joins, stock coverage calculations |
| Marketplace Sales Momentum · [README](marketplace-sales-momentum/README.md) · [SQL](marketplace-sales-momentum/sql/marketplace_sales_momentum.sql) | Which SKUs gained or lost the most unit sales on each marketplace compared with the previous 30 days? | Conditional aggregation, date windows, safe division, `DENSE_RANK()` |
| YTD Best Sellers by Parent SKU · [README](ytd-parent-sku-bestsellers/README.md) · [SQL](ytd-parent-sku-bestsellers/sql/ytd_parent_sku_bestsellers.sql) | Which product families should we review for expansion to Temu, SHEIN, or another marketplace? | Parent–child SKU rollups, distinct counts, window functions |

## Design decisions

- **Inventory Forecaster** rolls sales up to model and colour before joining inventory, because multiple size variants can share a stock pool.
- **Sales Momentum** reads both 30-day windows so a SKU that sold in the earlier period and dropped to zero still appears in the report. Equal gains share a rank.
- **YTD Best Sellers** combines sales across variants and keeps the top 30 ranks, including ties. Compare the shortlist with active listings to confirm which products could be added to a target marketplace.

## Run in BigQuery

1. Open a project README for its required input columns, assumptions, and example checks.
2. Open the SQL file in the BigQuery editor and point the table references to datasets you can query. Company source data is required to reproduce the original results. You can also use synthetic tables with matching columns.
3. Set a fixed reporting date to compare results across runs. Match the date filters to your source schema, including explicit `DATETIME` boundaries when `processed_date` is a `DATETIME`.
4. Verify one result against the inputs. Trace a forecast to its underlying sales and stock, a momentum rank to its two window totals, or a bestseller to its child SKUs.

**Author** · [Faid Mulaosmanovic](https://github.com/Faid98)
