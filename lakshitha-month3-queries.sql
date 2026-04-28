-- ============================================================
-- ShopFlow E-Commerce Platform - Complex Queries
-- Dialect: PostgreSQL
-- ============================================================


-- ── Query 1: Top Selling Products by Category ────────────────

SELECT
  c.name                              AS category,
  p.name                              AS product,
  SUM(oi.quantity)                    AS total_units_sold,
  SUM(oi.quantity * oi.unit_price)    AS revenue
FROM order_items oi
JOIN orders           o  ON oi.order_id   = o.id
JOIN product_variants pv ON oi.variant_id = pv.id
JOIN products         p  ON pv.product_id = p.id
JOIN categories       c  ON p.category_id = c.id
WHERE o.status      = 'delivered'
  AND o.created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY c.id, c.name, p.id, p.name
ORDER BY revenue DESC
LIMIT 10;


-- ── Query 2: Customer Lifetime Value ─────────────────────────

WITH customer_stats AS (
  SELECT
    u.id,
    u.first_name || ' ' || u.last_name   AS full_name,
    u.email,
    COUNT(o.id)                           AS total_orders,
    SUM(o.total_amount)                   AS lifetime_value,
    AVG(o.total_amount)                   AS avg_order_value,
    MIN(o.created_at)                     AS first_order_at,
    MAX(o.created_at)                     AS last_order_at
  FROM users u
  JOIN orders o ON o.user_id = u.id
  WHERE o.status NOT IN ('cancelled', 'refunded')
  GROUP BY u.id, u.first_name, u.last_name, u.email
)
SELECT
  full_name,
  email,
  total_orders,
  lifetime_value,
  ROUND(avg_order_value, 2)                        AS avg_order_value,
  first_order_at::DATE                             AS first_order,
  last_order_at::DATE                              AS last_order,
  RANK() OVER (ORDER BY lifetime_value DESC)       AS clv_rank
FROM customer_stats
ORDER BY lifetime_value DESC
LIMIT 20;


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
  AND pv.is_active = true
  AND p.is_active  = true
ORDER BY available_stock ASC;


-- ── Query 4: Review Statistics by Product ────────────────────

SELECT
  p.name                                                        AS product,
  COUNT(r.id)                                                   AS total_reviews,
  ROUND(AVG(r.rating), 2)                                       AS avg_rating,
  COUNT(r.id) FILTER (WHERE r.rating = 5)                       AS five_star,
  COUNT(r.id) FILTER (WHERE r.rating = 4)                       AS four_star,
  COUNT(r.id) FILTER (WHERE r.rating = 3)                       AS three_star,
  COUNT(r.id) FILTER (WHERE r.rating <= 2)                      AS low_ratings,
  COUNT(r.id) FILTER (WHERE r.is_verified = true)               AS verified_reviews
FROM products p
LEFT JOIN reviews r ON r.product_id = p.id
WHERE p.is_active = true
GROUP BY p.id, p.name
HAVING COUNT(r.id) > 0
ORDER BY avg_rating DESC, total_reviews DESC;


-- ── Query 5: Cart Abandonment Analysis ───────────────────────

SELECT
  u.email,
  u.first_name || ' ' || u.last_name         AS full_name,
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
  AND c.updated_at >= CURRENT_DATE - INTERVAL '7 days'
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
WHERE created_at >= DATE_TRUNC('month', CURRENT_DATE)
GROUP BY status
ORDER BY order_count DESC;


-- ── Query 7: Category Hierarchy with Product Counts ──────────

WITH RECURSIVE category_tree AS (
  SELECT
    id,
    name,
    parent_id,
    slug,
    0           AS depth,
    name::TEXT  AS path
  FROM categories
  WHERE parent_id IS NULL

  UNION ALL

  SELECT
    c.id,
    c.name,
    c.parent_id,
    c.slug,
    ct.depth + 1,
    ct.path || ' > ' || c.name
  FROM categories c
  JOIN category_tree ct ON c.parent_id = ct.id
)
SELECT
  ct.path,
  ct.depth,
  COUNT(p.id)                                           AS product_count,
  COUNT(p.id) FILTER (WHERE p.is_active = true)         AS active_products
FROM category_tree ct
LEFT JOIN products p ON p.category_id = ct.id
GROUP BY ct.id, ct.path, ct.depth
ORDER BY ct.path;


-- ── Query 8: User Purchase History ───────────────────────────

WITH user_orders AS (
  SELECT
    u.id                                              AS user_id,
    u.first_name || ' ' || u.last_name               AS full_name,
    o.id                                              AS order_id,
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
  created_at::DATE                                    AS order_date,
  SUM(total_amount)  OVER (PARTITION BY user_id
                           ORDER BY created_at)       AS running_total,
  ROW_NUMBER()       OVER (PARTITION BY user_id
                           ORDER BY created_at)       AS order_number,
  LAG(total_amount)  OVER (PARTITION BY user_id
                           ORDER BY created_at)       AS previous_order_amount
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
  pr.expires_at::DATE                               AS expires_on
FROM promotions pr
LEFT JOIN orders o ON o.promotion_id = pr.id
               AND o.status NOT IN ('cancelled', 'refunded')
GROUP BY pr.id, pr.code, pr.discount_type, pr.discount_value,
         pr.max_uses, pr.expires_at
ORDER BY times_used DESC;


-- ── Query 10: Revenue by Time Period ─────────────────────────

WITH monthly_revenue AS (
  SELECT
    DATE_TRUNC('month', created_at)   AS month,
    COUNT(*)                           AS order_count,
    SUM(total_amount)                  AS revenue,
    SUM(discount_amount)               AS total_discounts
  FROM orders
  WHERE status NOT IN ('cancelled', 'refunded')
  GROUP BY DATE_TRUNC('month', created_at)
)
SELECT
  TO_CHAR(month, 'YYYY-MM')           AS month,
  order_count,
  revenue,
  total_discounts,
  ROUND(
    (revenue - LAG(revenue) OVER (ORDER BY month))
    * 100.0
    / NULLIF(LAG(revenue) OVER (ORDER BY month), 0),
  2)                                  AS mom_growth_pct
FROM monthly_revenue
ORDER BY month;
