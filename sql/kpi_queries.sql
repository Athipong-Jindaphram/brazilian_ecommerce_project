-- =============================================================================
-- BRAZILIAN E-COMMERCE (OLIST) - BUSINESS ANALYTICS QUERIES
-- File: sql/kpi_queries.sql
-- Description: Analytical queries mapped to Business Objectives & KPIs
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 1: Overall Revenue & Order Overview (Business Objective #1)
-- -----------------------------------------------------------------------------
SELECT 
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(i.price)::numeric, 2) AS total_item_revenue,
    ROUND(SUM(i.freight_value)::numeric, 2) AS total_freight_revenue,
    ROUND((SUM(i.price) + SUM(i.freight_value))::numeric, 2) AS gross_merchandise_value,
    ROUND((SUM(i.price) / COUNT(DISTINCT o.order_id))::numeric, 2) AS average_order_value
FROM orders o
JOIN order_items i ON o.order_id = i.order_id
WHERE o.order_status = 'delivered';


-- -----------------------------------------------------------------------------
-- Query 2: Top 10 Product Categories by Revenue (Business Objective #2, #3)
-- -----------------------------------------------------------------------------
SELECT 
    p.product_category_name_english AS category_name,
    COUNT(DISTINCT i.order_id) AS total_orders,
    ROUND(SUM(i.price)::numeric, 2) AS total_revenue,
    ROUND(AVG(i.price)::numeric, 2) AS avg_item_price
FROM order_items i
JOIN products p ON i.product_id = p.product_id
JOIN orders o ON i.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name_english
ORDER BY total_revenue DESC
LIMIT 10;


-- -----------------------------------------------------------------------------
-- Query 3: Top 10 Sellers Contribution (Business Objective #4)
-- -----------------------------------------------------------------------------
SELECT 
    s.seller_id,
    s.seller_state,
    COUNT(DISTINCT i.order_id) AS total_orders_fulfilled,
    ROUND(SUM(i.price)::numeric, 2) AS total_seller_revenue
FROM sellers s
JOIN order_items i ON s.seller_id = i.seller_id
JOIN orders o ON i.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_id, s.seller_state
ORDER BY total_seller_revenue DESC
LIMIT 10;


-- -----------------------------------------------------------------------------
-- Query 4: Customer Satisfaction vs Delivery Latency (Business Objective #5, #8)
-- -----------------------------------------------------------------------------
SELECT 
    r.review_score,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(AVG(o.order_delivered_customer_date::timestamp::date - o.order_purchase_timestamp::timestamp::date)::numeric, 1) AS avg_actual_delivery_days,
    ROUND(AVG(o.order_estimated_delivery_date::timestamp::date - o.order_delivered_customer_date::timestamp::date)::numeric, 1) AS avg_days_early_delivery
FROM orders o
JOIN reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered' 
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY r.review_score
ORDER BY r.review_score DESC;


-- -----------------------------------------------------------------------------
-- Query 5: Payment Methods Breakdown (Business Objective #6)
-- -----------------------------------------------------------------------------
SELECT 
    payment_type,
    COUNT(DISTINCT order_id) AS total_transactions,
    ROUND(SUM(payment_value)::numeric, 2) AS total_payment_value,
    ROUND(AVG(payment_installments)::numeric, 2) AS avg_installments
FROM payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;


-- -----------------------------------------------------------------------------
-- Query 6: Revenue & Order Distribution by Customer State (Business Objective #9)
-- -----------------------------------------------------------------------------
SELECT 
    c.customer_state,
    COUNT(DISTINCT c.customer_unique_id) AS total_unique_customers,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(i.price)::numeric, 2) AS total_revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items i ON o.order_id = i.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY total_revenue DESC;

-- =============================================================================
-- ADDITIONAL ANALYTICAL QUERIES
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Query 7: Monthly Revenue Growth & MoM Rate (Business Objective #1, #10)
-- ใช้ Window Function (LAG) เพื่อดูการเติบโตรายเดือน
-- -----------------------------------------------------------------------------
WITH monthly_revenue AS (
    SELECT 
        DATE_TRUNC('month', o.order_purchase_timestamp::timestamp) AS month,
        ROUND(SUM(i.price)::numeric, 2) AS revenue
    FROM orders o
    JOIN order_items i ON o.order_id = i.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY 1
)
SELECT 
    TO_CHAR(month, 'YYYY-MM') AS year_month,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS prev_month_revenue,
    ROUND(((revenue - LAG(revenue) OVER (ORDER BY month)) / LAG(revenue) OVER (ORDER BY month) * 100)::numeric, 2) AS mom_growth_percent
FROM monthly_revenue
ORDER BY year_month;


-- -----------------------------------------------------------------------------
-- Query 8: Repeat Customer Rate & High-Value Customers (Business Objective #7)
-- วิเคราะห์อัตราการซื้อซ้ำและพฤติกรรมลูกค้าทรงคุณค่า
-- -----------------------------------------------------------------------------
WITH customer_orders AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders,
        ROUND(SUM(i.price)::numeric, 2) AS total_spent
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items i ON o.order_id = i.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT 
    COUNT(CASE WHEN total_orders > 1 THEN 1 END) AS repeat_customers,
    COUNT(*) AS total_customers,
    ROUND((COUNT(CASE WHEN total_orders > 1 THEN 1 END)::numeric / COUNT(*) * 100), 2) AS repeat_customer_rate_percent,
    ROUND(AVG(total_spent)::numeric, 2) AS avg_customer_lifetime_value
FROM customer_orders;


-- -----------------------------------------------------------------------------
-- Query 9: Late Delivery Rate & Fulfillment Performance (Business Objective #8)
-- สรุปประสิทธิภาพการจัดส่งและอัตราการส่งล่าช้า
-- -----------------------------------------------------------------------------
SELECT 
    COUNT(order_id) AS total_delivered_orders,
    SUM(CASE WHEN order_delivered_customer_date::timestamp::date > order_estimated_delivery_date::timestamp::date THEN 1 ELSE 0 END) AS late_orders,
    ROUND((SUM(CASE WHEN order_delivered_customer_date::timestamp::date > order_estimated_delivery_date::timestamp::date THEN 1 ELSE 0 END)::numeric / COUNT(order_id) * 100), 2) AS late_delivery_rate_percent,
    ROUND(AVG(order_delivered_customer_date::timestamp::date - order_purchase_timestamp::timestamp::date)::numeric, 1) AS avg_delivery_days
FROM orders
WHERE order_status = 'delivered' 
  AND order_delivered_customer_date IS NOT NULL;


-- -----------------------------------------------------------------------------
-- Query 10: Pareto 80/20 Rule for Product Categories (Business Objective #3, #10)
-- คำนวณหายอดขายสะสมด้วย Cumulative Sum Window Function
-- -----------------------------------------------------------------------------
WITH category_sales AS (
    SELECT 
        p.product_category_name_english AS category,
        SUM(i.price) AS total_revenue
    FROM order_items i
    JOIN products p ON i.product_id = p.product_id
    JOIN orders o ON i.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY p.product_category_name_english
),
ranked_sales AS (
    SELECT 
        category,
        total_revenue,
        SUM(total_revenue) OVER (ORDER BY total_revenue DESC) AS running_total,
        SUM(total_revenue) OVER () AS grand_total
    FROM category_sales
)
SELECT 
    category,
    ROUND(total_revenue::numeric, 2) AS total_revenue,
    ROUND((running_total / grand_total * 100)::numeric, 2) AS cumulative_sales_percent
FROM ranked_sales
ORDER BY total_revenue DESC;