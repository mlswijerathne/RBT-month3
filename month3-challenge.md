# Month 3 Challenge: Database Design & Optimization

## Challenge Brief

| Attribute    | Details                          |
|--------------|----------------------------------|
| Role         | Database designer for an e-commerce platform |
| Time         | 4 hours (in-session) + ongoing offline work |
| Deliverables | 4 artifacts                      |

---

## Context

### Project Profile

| Attribute | Details                          |
|-----------|----------------------------------|
| Project   | ShopFlow E-Commerce Platform     |
| Domain    | Online retail marketplace        |
| Scale     | 10K+ products, 50K+ users, 100K+ orders |
| Requirements | Fast queries, data integrity, analytics support |

### Business Requirements

- Product catalog with categories and variants
- User accounts with addresses and payment methods
- Shopping cart and wishlist functionality
- Order management with status tracking
- Inventory management
- Reviews and ratings
- Promotions and discounts

---

## Challenge Tasks

### Part 1: Schema Design (30 min)

Design Normalized Schema (10+ tables):

```
Core tables required:
1. users           - Customer accounts
2. addresses       - User addresses (shipping/billing)
3. categories      - Product categories (hierarchical)
4. products        - Product catalog
5. product_variants - Size, color variants
6. inventory       - Stock levels per variant
7. carts           - Shopping carts
8. cart_items      - Items in cart
9. orders          - Customer orders
10. order_items    - Items in order
11. reviews        - Product reviews
12. promotions     - Discount codes
```

**ERD Requirements:**
- Show all tables with columns
- Mark primary and foreign keys
- Indicate relationship types
- Include indexes notation

---

### Part 2: Migration Scripts (25 min)

Create Complete SQL Migrations:

```sql
-- Example: products table
CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(255) UNIQUE NOT NULL,
  description TEXT,
  category_id INTEGER REFERENCES categories(id),
  base_price DECIMAL(10, 2) NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index for common queries
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_slug ON products(slug);
CREATE INDEX idx_products_active ON products(is_active) WHERE is_active = true;
```

**Migration Checklist:**
- [ ] All 10+ tables created
- [ ] Foreign key constraints defined
- [ ] Indexes for common query patterns
- [ ] Check constraints where appropriate
- [ ] Default values set

---

### Part 3: Complex Queries (35 min)

Write 10 Complex Queries:

```sql
-- Query 1: Top selling products by category
SELECT
  c.name as category,
  p.name as product,
  SUM(oi.quantity) as total_sold,
  SUM(oi.quantity * oi.unit_price) as revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.id
JOIN categories c ON p.category_id = c.id
JOIN orders o ON oi.order_id = o.id
WHERE o.status = 'completed'
  AND o.created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY c.id, p.id
ORDER BY revenue DESC
LIMIT 10;

-- Query 2:  Customer lifetime value
-- Query 3:  Inventory low stock alert
-- Query 4:  Review statistics by product
-- Query 5:  Cart abandonment analysis
-- Query 6:  Order status breakdown
-- Query 7:  Category hierarchy with counts
-- Query 8:  User purchase history
-- Query 9:  Promotion usage report
-- Query 10: Revenue by time period
```

**Query Requirements:**
- Use JOINs (inner, left, right)
- Include aggregations (COUNT, SUM, AVG)
- Use subqueries or CTEs
- Include window functions
- Add date/time filtering

---

### Part 4: Query Optimization (30 min)

Optimize Slow Queries:

```sql
-- Before optimization
EXPLAIN ANALYZE
SELECT * FROM orders o
JOIN order_items oi ON o.id = oi.order_id
JOIN products p ON oi.product_id = p.id
WHERE o.user_id = 123;

-- Document:
-- 1. Original execution time
-- 2. Query plan analysis
-- 3. Indexes added
-- 4. Optimized execution time
-- 5. Improvement percentage
```

**Optimization Report Template:**

```markdown
## Query Optimization Report

### Query 1: [Description]
**Original Query:**
[SQL]

**Execution Time Before:** X ms

**Analysis:**
- Sequential scan on [table]
- Missing index on [column]
- Suboptimal join order

**Optimizations Applied:**
1. Added index: CREATE INDEX idx_name ON table(column)
2. Rewrote subquery as JOIN
3. Added WHERE clause to filter early

**Execution Time After:** Y ms
**Improvement:** Z%
```

---

## Seed Data Requirements

Generate Realistic Test Data:

```js
// seed.js - Generate 10K+ records
const seedData = {
  users: 1000,
  categories: 50,
  products: 500,
  variants: 2000,
  orders: 5000,
  orderItems: 15000,
  reviews: 3000
};

// Use faker.js or similar for realistic data
// Include edge cases (nulls, empty strings, max lengths)
```

---

## Submission Requirements

### Required Files

| File | Description |
|------|-------------|
| `[name]-month3-erd.png` | ERD diagram |
| `[name]-month3-migrations.sql` | All migration scripts |
| `[name]-month3-optimization-report.md` | Query analysis |
| `[name]-month3-seed.sql` | Seed data script |

---

## Evaluation Criteria

| Criteria         | Points | What Evaluators Look For                          |
|------------------|--------|---------------------------------------------------|
| Schema Design    | 25     | Normalized, complete, well-structured             |
| Migration Quality| 20     | Constraints, indexes, clean SQL                   |
| Query Complexity | 25     | JOINs, aggregations, CTEs, windows                |
| Optimization     | 20     | Measurable improvements, good analysis            |
| Documentation    | 10     | Clear ERD, thorough optimization report           |
| **Total**        | **100**|                                                   |

---

## Tips for Success

1. **Normalize first** - Then denormalize only where needed
2. **Think about queries** - Design for how data will be accessed
3. **Index selectively** - Not everything needs an index
4. **Use EXPLAIN** - Always check query plans
5. **Test with data** - Empty tables don't show performance issues
6. **Document decisions** - Why did you choose this design?
