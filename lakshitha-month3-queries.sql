-- ============================================================
-- ShopFlow E-Commerce Platform - Complex Queries
-- Dialect: SQL Server (T-SQL)
-- ============================================================


-- ── Query 1: Top Selling Products by Category ────────────────

SELECT TOP 10
  c.name                              AS category,
  p.name                              AS product,
  SUM(oi.quantity)                    AS total_units_sold,
  SUM(oi.quantity * oi.unit_price)    AS revenue
FROM order_items oi
JOIN orders       o  ON oi.order_id   = o.id
JOIN product_variants pv              ON oi.variant_id  = pv.id
JOIN products     p  ON pv.product_id = p.id
JOIN categories   c  ON p.category_id = c.id
WHERE o.status      = 'delivered'
  AND o.created_at >= DATEADD(day, -30, GETDATE())
GROUP BY c.id, c.name, p.id, p.name
ORDER BY revenue DESC;


-- ── Query 2: Customer Lifetime Value ─────────────────────────

WITH customer_stats AS (
  SELECT
    u.id,
    CONCAT(u.first_name, ' ', u.last_name)  AS full_name,
    u.email,
    COUNT(o.id)                              AS total_orders,
    SUM(o.total_amount)                      AS lifetime_value,
    AVG(o.total_amount)                      AS avg_order_value,
    MIN(o.created_at)                        AS first_order_at,
    MAX(o.created_at)                        AS last_order_at
  FROM users u
  JOIN orders o ON o.user_id = u.id
  WHERE o.status NOT IN ('cancelled', 'refunded')
  GROUP BY u.id, u.first_name, u.last_name, u.email
)
SELECT TOP 20
  full_name,
  email,
  total_orders,
  lifetime_value,
  ROUND(avg_order_value, 2)                        AS avg_order_value,
  CAST(first_order_at AS DATE)                     AS first_order,
  CAST(last_order_at  AS DATE)                     AS last_order,
  RANK() OVER (ORDER BY lifetime_value DESC)       AS clv_rank
FROM customer_stats
ORDER BY lifetime_value DESC;


-- ── Query 3: Inventory Low Stock Alert ───────────────────────

SELECT
  p.name                                        AS product,
  pv.sku,
  pv.size,
  pv.color,
  i.quantity_in_stock,
  i.quantity_reserved,
  (i.quantity_in_stock - i.quantity_reserved)   AS available_stock,
  i.low_stock_threshold
FROM inventory i
JOIN product_variants pv ON i.variant_id  = pv.id
JOIN products         p  ON pv.product_id = p.id
WHERE (i.quantity_in_stock - i.quantity_reserved) <= i.low_stock_threshold
  AND pv.is_active = 1
  AND p.is_active  = 1
ORDER BY available_stock ASC;


-- ── Query 4: Review Statistics by Product ────────────────────

SELECT
  p.name                                                          AS product,
  COUNT(r.id)                                                     AS total_reviews,
  ROUND(AVG(CAST(r.rating AS DECIMAL(4,2))), 2)                  AS avg_rating,
  SUM(CASE WHEN r.rating = 5  THEN 1 ELSE 0 END)                 AS five_star,
  SUM(CASE WHEN r.rating = 4  THEN 1 ELSE 0 END)                 AS four_star,
  SUM(CASE WHEN r.rating = 3  THEN 1 ELSE 0 END)                 AS three_star,
  SUM(CASE WHEN r.rating <= 2 THEN 1 ELSE 0 END)                 AS low_ratings,
  SUM(CASE WHEN r.is_verified = 1 THEN 1 ELSE 0 END)             AS verified_reviews
FROM products p
LEFT JOIN reviews r ON r.product_id = p.id
WHERE p.is_active = 1
GROUP BY p.id, p.name
HAVING COUNT(r.id) > 0
ORDER BY avg_rating DESC, total_reviews DESC;


-- ── Query 5: Cart Abandonment Analysis ───────────────────────

SELECT
  u.email,
  CONCAT(u.first_name, ' ', u.last_name)     AS full_name,
  COUNT(ci.id)                                AS items_in_cart,
  SUM(ci.quantity)                            AS total_quantity,
  SUM(ci.quantity * (
    p.base_price + pv.price_modifier
  ))                                          AS estimated_cart_value,
  c.updated_at                                AS last_activity
FROM carts c
JOIN users            u  ON c.user_id     = u.id
JOIN cart_items       ci ON ci.cart_id    = c.id
JOIN product_variants pv ON ci.variant_id = pv.id
JOIN products         p  ON pv.product_id = p.id
LEFT JOIN orders      o  ON o.user_id     = u.id
                        AND o.created_at  > c.updated_at
WHERE o.id IS NULL
  AND c.updated_at >= DATEADD(day, -7, GETDATE())
GROUP BY u.id, u.email, u.first_name, u.last_name, c.updated_at
ORDER BY estimated_cart_value DESC;


-- ── Query 6: Order Status Breakdown ──────────────────────────

SELECT
  status,
  COUNT(*)                        AS order_count,
  SUM(total_amount)               AS total_revenue,
  ROUND(AVG(total_amount), 2)     AS avg_order_value,
  ROUND(
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2
  )                               AS percentage
FROM orders
WHERE created_at >= DATEADD(day, 1 - DAY(GETDATE()), CAST(GETDATE() AS DATE))
GROUP BY status
ORDER BY order_count DESC;


-- ── Query 7: Category Hierarchy with Product Counts ──────────

WITH category_tree AS (
  SELECT
    id,
    name,
    parent_id,
    slug,
    0                   AS depth,
    CAST(name AS VARCHAR(1000)) AS path
  FROM categories
  WHERE parent_id IS NULL

  UNION ALL

  SELECT
    c.id,
    c.name,
    c.parent_id,
    c.slug,
    ct.depth + 1,
    CAST(ct.path + ' > ' + c.name AS VARCHAR(1000))
  FROM categories c
  JOIN category_tree ct ON c.parent_id = ct.id
)
SELECT
  ct.path,
  ct.depth,
  COUNT(p.id)                                         AS product_count,
  SUM(CASE WHEN p.is_active = 1 THEN 1 ELSE 0 END)   AS active_products
FROM category_tree ct
LEFT JOIN products p ON p.category_id = ct.id
GROUP BY ct.id, ct.path, ct.depth
ORDER BY ct.path;


-- ── Query 8: User Purchase History ───────────────────────────

WITH user_orders AS (
  SELECT
    u.id                                                AS user_id,
    CONCAT(u.first_name, ' ', u.last_name)             AS full_name,
    o.id                                                AS order_id,
    o.status,
    o.total_amount,
    o.created_at
  FROM users u
  JOIN orders o ON o.user_id = u.id
  WHERE o.status NOT IN ('cancelled', 'refunded')
)
SELECT
  full_name,
  order_id,
  status,
  total_amount,
  CAST(created_at AS DATE)                              AS order_date,
  SUM(total_amount)  OVER (PARTITION BY user_id
                           ORDER BY created_at)         AS running_total,
  ROW_NUMBER()       OVER (PARTITION BY user_id
                           ORDER BY created_at)         AS order_number,
  LAG(total_amount)  OVER (PARTITION BY user_id
                           ORDER BY created_at)         AS previous_order_amount
FROM user_orders
ORDER BY user_id, created_at;


-- ── Query 9: Promotion Usage Report ──────────────────────────

SELECT
  pr.code,
  pr.discount_type,
  pr.discount_value,
  pr.max_uses,
  COUNT(o.id)                                       AS times_used,
  CASE
    WHEN pr.max_uses IS NULL THEN NULL
    ELSE ROUND(COUNT(o.id) * 100.0 / pr.max_uses, 2)
  END                                               AS usage_percentage,
  SUM(o.discount_amount)                            AS total_discount_given,
  SUM(o.total_amount)                               AS revenue_with_promo,
  CAST(pr.expires_at AS DATE)                       AS expires_on
FROM promotions pr
LEFT JOIN orders o ON o.promotion_id = pr.id
               AND o.status NOT IN ('cancelled', 'refunded')
GROUP BY pr.id, pr.code, pr.discount_type, pr.discount_value,
         pr.max_uses, pr.expires_at
ORDER BY times_used DESC;


-- ── Query 10: Revenue by Time Period ─────────────────────────

WITH monthly_revenue AS (
  SELECT
    DATEADD(month, DATEDIFF(month, 0, created_at), 0)  AS month,
    COUNT(*)                                             AS order_count,
    SUM(total_amount)                                    AS revenue,
    SUM(discount_amount)                                 AS total_discounts
  FROM orders
  WHERE status NOT IN ('cancelled', 'refunded')
  GROUP BY DATEADD(month, DATEDIFF(month, 0, created_at), 0)
)
SELECT
  FORMAT(month, 'yyyy-MM')                              AS month,
  order_count,
  revenue,
  total_discounts,
  ROUND(
    (revenue - LAG(revenue) OVER (ORDER BY month))
    * 100.0
    / NULLIF(LAG(revenue) OVER (ORDER BY month), 0),
  2)                                                    AS mom_growth_pct
FROM monthly_revenue
ORDER BY month;
