# KPI Mapping

| Business Question | KPI | Source Tables | Dashboard |
|-------------------|-----|---------------|-----------|
| How much revenue has been generated? | Total Revenue | order_items | Executive |
| How many orders were placed? | Total Orders | orders | Executive |
| What is the average order value? | Average Order Value | orders, order_items | Executive |
| Which products generate the highest revenue? | Top Products | order_items, products | Product |
| Which sellers generate the highest sales? | Top Sellers | sellers, order_items | Seller |
| Which customers spend the most? | Customer Lifetime Value | customers, orders, order_items | Customer |
| How satisfied are customers? | Average Review Score | reviews | Customer |
| How long does delivery take? | Average Delivery Time | orders | Executive |
| Which payment methods are most popular? | Payment Method Distribution | payments | Executive |
| Which states generate the highest revenue? | Revenue by State | customers, orders, order_items | Geographic |