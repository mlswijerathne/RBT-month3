-- ============================================================
-- ShopFlow E-Commerce Platform - Migration Script
-- Version: 001  |  Dialect: PostgreSQL
-- ============================================================

-- ── 1. categories ────────────────────────────────────────────

CREATE TABLE categories (
  id          SERIAL PRIMARY KEY,
  parent_id   INTEGER REFERENCES categories(id) ON DELETE SET NULL,
  name        VARCHAR(100) NOT NULL,
  slug        VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  is_active   BOOLEAN DEFAULT true,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_categories_parent ON categories(parent_id);
CREATE INDEX idx_categories_slug   ON categories(slug);
CREATE INDEX idx_categories_active ON categories(is_active) WHERE is_active = true;


-- ── 2. users ─────────────────────────────────────────────────

CREATE TABLE users (
  id            SERIAL PRIMARY KEY,
  email         VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  first_name    VARCHAR(100) NOT NULL,
  last_name     VARCHAR(100) NOT NULL,
  phone         VARCHAR(20),
  is_active     BOOLEAN DEFAULT true,
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email  ON users(email);
CREATE INDEX idx_users_active ON users(is_active) WHERE is_active = true;


-- ── 3. addresses ─────────────────────────────────────────────

CREATE TABLE addresses (
  id            SERIAL PRIMARY KEY,
  user_id       INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type          VARCHAR(20) NOT NULL CHECK (type IN ('shipping', 'billing')),
  address_line1 VARCHAR(255) NOT NULL,
  address_line2 VARCHAR(255),
  city          VARCHAR(100) NOT NULL,
  state         VARCHAR(100),
  postal_code   VARCHAR(20) NOT NULL,
  country       VARCHAR(100) NOT NULL,
  is_default    BOOLEAN DEFAULT false,
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_addresses_user ON addresses(user_id);


-- ── 4. products ──────────────────────────────────────────────

CREATE TABLE products (
  id          SERIAL PRIMARY KEY,
  category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
  name        VARCHAR(255) NOT NULL,
  slug        VARCHAR(255) NOT NULL UNIQUE,
  description TEXT,
  base_price  DECIMAL(10,2) NOT NULL CHECK (base_price >= 0),
  is_active   BOOLEAN DEFAULT true,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_slug     ON products(slug);
CREATE INDEX idx_products_active   ON products(is_active) WHERE is_active = true;


-- ── 5. product_variants ──────────────────────────────────────

CREATE TABLE product_variants (
  id             SERIAL PRIMARY KEY,
  product_id     INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  sku            VARCHAR(100) NOT NULL UNIQUE,
  size           VARCHAR(50),
  color          VARCHAR(50),
  price_modifier DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  is_active      BOOLEAN DEFAULT true,
  created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_variants_product ON product_variants(product_id);
CREATE INDEX idx_variants_sku     ON product_variants(sku);
CREATE INDEX idx_variants_active  ON product_variants(is_active) WHERE is_active = true;


-- ── 6. inventory ─────────────────────────────────────────────

CREATE TABLE inventory (
  id                  SERIAL PRIMARY KEY,
  variant_id          INTEGER NOT NULL UNIQUE REFERENCES product_variants(id) ON DELETE CASCADE,
  quantity_in_stock   INTEGER NOT NULL DEFAULT 0 CHECK (quantity_in_stock >= 0),
  quantity_reserved   INTEGER NOT NULL DEFAULT 0 CHECK (quantity_reserved >= 0),
  low_stock_threshold INTEGER NOT NULL DEFAULT 10,
  updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_inventory_variant   ON inventory(variant_id);
CREATE INDEX idx_inventory_low_stock ON inventory(quantity_in_stock) WHERE quantity_in_stock <= 10;


-- ── 7. promotions ────────────────────────────────────────────

CREATE TABLE promotions (
  id               SERIAL PRIMARY KEY,
  code             VARCHAR(50) NOT NULL UNIQUE,
  description      TEXT,
  discount_type    VARCHAR(20) NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
  discount_value   DECIMAL(10,2) NOT NULL CHECK (discount_value > 0),
  min_order_amount DECIMAL(10,2) DEFAULT 0.00,
  max_uses         INTEGER,
  used_count       INTEGER NOT NULL DEFAULT 0,
  starts_at        TIMESTAMP NOT NULL,
  expires_at       TIMESTAMP,
  is_active        BOOLEAN DEFAULT true,
  created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_promotions_code   ON promotions(code);
CREATE INDEX idx_promotions_active ON promotions(is_active) WHERE is_active = true;


-- ── 8. carts ─────────────────────────────────────────────────

CREATE TABLE carts (
  id         SERIAL PRIMARY KEY,
  user_id    INTEGER NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_carts_user ON carts(user_id);


-- ── 9. cart_items ────────────────────────────────────────────

CREATE TABLE cart_items (
  id         SERIAL PRIMARY KEY,
  cart_id    INTEGER NOT NULL REFERENCES carts(id) ON DELETE CASCADE,
  variant_id INTEGER NOT NULL REFERENCES product_variants(id) ON DELETE CASCADE,
  quantity   INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
  added_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (cart_id, variant_id)
);

CREATE INDEX idx_cart_items_cart    ON cart_items(cart_id);
CREATE INDEX idx_cart_items_variant ON cart_items(variant_id);


-- ── 10. orders ───────────────────────────────────────────────

CREATE TABLE orders (
  id              SERIAL PRIMARY KEY,
  user_id         INTEGER NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  address_id      INTEGER NOT NULL REFERENCES addresses(id) ON DELETE RESTRICT,
  promotion_id    INTEGER REFERENCES promotions(id) ON DELETE SET NULL,
  status          VARCHAR(30) NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled', 'refunded')),
  subtotal        DECIMAL(10,2) NOT NULL CHECK (subtotal >= 0),
  discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (discount_amount >= 0),
  tax_amount      DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (tax_amount >= 0),
  total_amount    DECIMAL(10,2) NOT NULL CHECK (total_amount >= 0),
  notes           TEXT,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_orders_user       ON orders(user_id);
CREATE INDEX idx_orders_status     ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at);
CREATE INDEX idx_orders_promotion  ON orders(promotion_id);


-- ── 11. order_items ──────────────────────────────────────────

CREATE TABLE order_items (
  id          SERIAL PRIMARY KEY,
  order_id    INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  variant_id  INTEGER NOT NULL REFERENCES product_variants(id) ON DELETE RESTRICT,
  quantity    INTEGER NOT NULL CHECK (quantity > 0),
  unit_price  DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
  total_price DECIMAL(10,2) NOT NULL CHECK (total_price >= 0)
);

CREATE INDEX idx_order_items_order   ON order_items(order_id);
CREATE INDEX idx_order_items_variant ON order_items(variant_id);


-- ── 12. reviews ──────────────────────────────────────────────

CREATE TABLE reviews (
  id          SERIAL PRIMARY KEY,
  user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_id  INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  rating      SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  title       VARCHAR(255),
  body        TEXT,
  is_verified BOOLEAN DEFAULT false,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (user_id, product_id)
);

CREATE INDEX idx_reviews_product ON reviews(product_id);
CREATE INDEX idx_reviews_user    ON reviews(user_id);
CREATE INDEX idx_reviews_rating  ON reviews(rating);
