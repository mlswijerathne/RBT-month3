-- ============================================================
-- ShopFlow E-Commerce Platform - Migration Script
-- Version: 001  |  Dialect: SQL Server (T-SQL)
-- ============================================================

-- ── 1. categories ────────────────────────────────────────────

CREATE TABLE categories (
  id          INT IDENTITY(1,1) PRIMARY KEY,
  parent_id   INT REFERENCES categories(id) ON DELETE NO ACTION,
  name        VARCHAR(100) NOT NULL,
  slug        VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  is_active   BIT NOT NULL DEFAULT 1,
  created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_categories_parent ON categories(parent_id);
CREATE INDEX idx_categories_slug   ON categories(slug);
CREATE INDEX idx_categories_active ON categories(is_active) WHERE is_active = 1;


-- ── 2. users ─────────────────────────────────────────────────

CREATE TABLE users (
  id            INT IDENTITY(1,1) PRIMARY KEY,
  email         VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  first_name    VARCHAR(100) NOT NULL,
  last_name     VARCHAR(100) NOT NULL,
  phone         VARCHAR(20),
  is_active     BIT NOT NULL DEFAULT 1,
  created_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email  ON users(email);
CREATE INDEX idx_users_active ON users(is_active) WHERE is_active = 1;


-- ── 3. addresses ─────────────────────────────────────────────

CREATE TABLE addresses (
  id            INT IDENTITY(1,1) PRIMARY KEY,
  user_id       INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type          VARCHAR(20) NOT NULL CHECK (type IN ('shipping', 'billing')),
  address_line1 VARCHAR(255) NOT NULL,
  address_line2 VARCHAR(255),
  city          VARCHAR(100) NOT NULL,
  state         VARCHAR(100),
  postal_code   VARCHAR(20) NOT NULL,
  country       VARCHAR(100) NOT NULL,
  is_default    BIT NOT NULL DEFAULT 0,
  created_at    DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_addresses_user ON addresses(user_id);


-- ── 4. products ──────────────────────────────────────────────

CREATE TABLE products (
  id          INT IDENTITY(1,1) PRIMARY KEY,
  category_id INT REFERENCES categories(id) ON DELETE SET NULL,
  name        VARCHAR(255) NOT NULL,
  slug        VARCHAR(255) NOT NULL UNIQUE,
  description TEXT,
  base_price  DECIMAL(10,2) NOT NULL CHECK (base_price >= 0),
  is_active   BIT NOT NULL DEFAULT 1,
  created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_slug     ON products(slug);
CREATE INDEX idx_products_active   ON products(is_active) WHERE is_active = 1;


-- ── 5. product_variants ──────────────────────────────────────

CREATE TABLE product_variants (
  id             INT IDENTITY(1,1) PRIMARY KEY,
  product_id     INT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  sku            VARCHAR(100) NOT NULL UNIQUE,
  size           VARCHAR(50),
  color          VARCHAR(50),
  price_modifier DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  is_active      BIT NOT NULL DEFAULT 1,
  created_at     DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_variants_product ON product_variants(product_id);
CREATE INDEX idx_variants_sku     ON product_variants(sku);
CREATE INDEX idx_variants_active  ON product_variants(is_active) WHERE is_active = 1;


-- ── 6. inventory ─────────────────────────────────────────────

CREATE TABLE inventory (
  id                  INT IDENTITY(1,1) PRIMARY KEY,
  variant_id          INT NOT NULL UNIQUE REFERENCES product_variants(id) ON DELETE CASCADE,
  quantity_in_stock   INT NOT NULL DEFAULT 0 CHECK (quantity_in_stock >= 0),
  quantity_reserved   INT NOT NULL DEFAULT 0 CHECK (quantity_reserved >= 0),
  low_stock_threshold INT NOT NULL DEFAULT 10,
  updated_at          DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_inventory_variant   ON inventory(variant_id);
CREATE INDEX idx_inventory_low_stock ON inventory(quantity_in_stock) WHERE quantity_in_stock <= 10;


-- ── 7. promotions ────────────────────────────────────────────

CREATE TABLE promotions (
  id               INT IDENTITY(1,1) PRIMARY KEY,
  code             VARCHAR(50) NOT NULL UNIQUE,
  description      TEXT,
  discount_type    VARCHAR(20) NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
  discount_value   DECIMAL(10,2) NOT NULL CHECK (discount_value > 0),
  min_order_amount DECIMAL(10,2) DEFAULT 0.00,
  max_uses         INT,
  used_count       INT NOT NULL DEFAULT 0,
  starts_at        DATETIME NOT NULL,
  expires_at       DATETIME,
  is_active        BIT NOT NULL DEFAULT 1,
  created_at       DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_promotions_code   ON promotions(code);
CREATE INDEX idx_promotions_active ON promotions(is_active) WHERE is_active = 1;


-- ── 8. carts ─────────────────────────────────────────────────

CREATE TABLE carts (
  id         INT IDENTITY(1,1) PRIMARY KEY,
  user_id    INT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_carts_user ON carts(user_id);


-- ── 9. cart_items ────────────────────────────────────────────

CREATE TABLE cart_items (
  id         INT IDENTITY(1,1) PRIMARY KEY,
  cart_id    INT NOT NULL REFERENCES carts(id) ON DELETE CASCADE,
  variant_id INT NOT NULL REFERENCES product_variants(id) ON DELETE CASCADE,
  quantity   INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
  added_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (cart_id, variant_id)
);

CREATE INDEX idx_cart_items_cart    ON cart_items(cart_id);
CREATE INDEX idx_cart_items_variant ON cart_items(variant_id);


-- ── 10. orders ───────────────────────────────────────────────

CREATE TABLE orders (
  id              INT IDENTITY(1,1) PRIMARY KEY,
  user_id         INT NOT NULL REFERENCES users(id) ON DELETE NO ACTION,
  address_id      INT NOT NULL REFERENCES addresses(id) ON DELETE NO ACTION,
  promotion_id    INT REFERENCES promotions(id) ON DELETE SET NULL,
  status          VARCHAR(30) NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled', 'refunded')),
  subtotal        DECIMAL(10,2) NOT NULL CHECK (subtotal >= 0),
  discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (discount_amount >= 0),
  tax_amount      DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (tax_amount >= 0),
  total_amount    DECIMAL(10,2) NOT NULL CHECK (total_amount >= 0),
  notes           TEXT,
  created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_orders_user       ON orders(user_id);
CREATE INDEX idx_orders_status     ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at);
CREATE INDEX idx_orders_promotion  ON orders(promotion_id);


-- ── 11. order_items ──────────────────────────────────────────

CREATE TABLE order_items (
  id          INT IDENTITY(1,1) PRIMARY KEY,
  order_id    INT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  variant_id  INT NOT NULL REFERENCES product_variants(id) ON DELETE NO ACTION,
  quantity    INT NOT NULL CHECK (quantity > 0),
  unit_price  DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
  total_price DECIMAL(10,2) NOT NULL CHECK (total_price >= 0)
);

CREATE INDEX idx_order_items_order   ON order_items(order_id);
CREATE INDEX idx_order_items_variant ON order_items(variant_id);


-- ── 12. reviews ──────────────────────────────────────────────

CREATE TABLE reviews (
  id          INT IDENTITY(1,1) PRIMARY KEY,
  user_id     INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_id  INT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  rating      SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  title       VARCHAR(255),
  body        TEXT,
  is_verified BIT NOT NULL DEFAULT 0,
  created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (user_id, product_id)
);

CREATE INDEX idx_reviews_product ON reviews(product_id);
CREATE INDEX idx_reviews_user    ON reviews(user_id);
CREATE INDEX idx_reviews_rating  ON reviews(rating);
