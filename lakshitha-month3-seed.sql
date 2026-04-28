-- ============================================================
-- ShopFlow E-Commerce Platform - Seed Data
-- Dialect: PostgreSQL  |  Records: 10K+
-- ============================================================


-- ── 1. categories (50) ───────────────────────────────────────

INSERT INTO categories (name, slug, description, is_active)
VALUES
  ('Electronics',   'electronics',  'Electronic devices and accessories', true),
  ('Clothing',      'clothing',     'Men and women apparel',              true),
  ('Home & Garden', 'home-garden',  'Home decor and garden tools',        true),
  ('Sports',        'sports',       'Sports and outdoor equipment',       true),
  ('Books',         'books',        'Books and literature',               true),
  ('Toys',          'toys',         'Toys and games for all ages',        true),
  ('Beauty',        'beauty',       'Beauty and personal care',           true),
  ('Automotive',    'automotive',   'Car parts and accessories',          true),
  ('Food & Drinks', 'food-drinks',  'Groceries and beverages',            true),
  ('Health',        'health',       'Health and wellness products',       true);

INSERT INTO categories (name, slug, description, is_active, parent_id)
SELECT t.name, t.slug, t.description, t.is_active,
  (SELECT id FROM categories WHERE slug = t.parent_slug)
FROM (VALUES
  ('Phones',         'phones',           'Smartphones and accessories',    true, 'electronics'),
  ('Laptops',        'laptops',          'Laptops and notebooks',          true, 'electronics'),
  ('Cameras',        'cameras',          'Digital cameras and lenses',     true, 'electronics'),
  ('Headphones',     'headphones',       'Wired and wireless headphones',  true, 'electronics'),
  ('Smart Home',     'smart-home',       'Smart home devices',             true, 'electronics'),
  ('Men Clothing',   'men-clothing',     'Clothing for men',               true, 'clothing'),
  ('Women Clothing', 'women-clothing',   'Clothing for women',             true, 'clothing'),
  ('Kids Clothing',  'kids-clothing',    'Clothing for kids',              true, 'clothing'),
  ('Shoes',          'shoes',            'Footwear for all',               true, 'clothing'),
  ('Accessories',    'accessories',      'Bags, belts, and wallets',       true, 'clothing'),
  ('Furniture',      'furniture',        'Indoor and outdoor furniture',   true, 'home-garden'),
  ('Kitchen',        'kitchen',          'Kitchen appliances and tools',   true, 'home-garden'),
  ('Bedding',        'bedding',          'Sheets, pillows, and blankets',  true, 'home-garden'),
  ('Garden Tools',   'garden-tools',     'Tools for gardening',            true, 'home-garden'),
  ('Lighting',       'lighting',         'Indoor and outdoor lighting',    true, 'home-garden'),
  ('Football',       'football',         'Football gear and equipment',    true, 'sports'),
  ('Gym Equipment',  'gym-equipment',    'Weights and machines',           true, 'sports'),
  ('Cycling',        'cycling',          'Bikes and cycling gear',         true, 'sports'),
  ('Swimming',       'swimming',         'Swimwear and pool accessories',  true, 'sports'),
  ('Outdoor',        'outdoor',          'Camping and hiking gear',        true, 'sports'),
  ('Fiction',        'fiction',          'Fiction novels and stories',     true, 'books'),
  ('Non-Fiction',    'non-fiction',      'Educational and informational',  true, 'books'),
  ('Children Books', 'children-books',   'Books for children',             true, 'books'),
  ('Comics',         'comics',           'Comics and graphic novels',      true, 'books'),
  ('Textbooks',      'textbooks',        'Academic and study books',       true, 'books'),
  ('Action Figures', 'action-figures',   'Action figures and collectibles',true, 'toys'),
  ('Board Games',    'board-games',      'Family board games',             true, 'toys'),
  ('Puzzles',        'puzzles',          'Jigsaw and brain puzzles',       true, 'toys'),
  ('Outdoor Toys',   'outdoor-toys',     'Outdoor play equipment',         true, 'toys'),
  ('Educational',    'educational-toys', 'Learning toys for kids',         true, 'toys'),
  ('Skincare',       'skincare',         'Face and body skincare',         true, 'beauty'),
  ('Haircare',       'haircare',         'Shampoos and styling products',  true, 'beauty'),
  ('Makeup',         'makeup',           'Cosmetics and makeup tools',     true, 'beauty'),
  ('Fragrances',     'fragrances',       'Perfumes and colognes',          true, 'beauty'),
  ('Nail Care',      'nail-care',        'Nail polish and tools',          true, 'beauty'),
  ('Car Audio',      'car-audio',        'Speakers and car stereos',       true, 'automotive'),
  ('Car Care',       'car-care',         'Cleaning and maintenance',       true, 'automotive'),
  ('Tires',          'tires',            'Tyres and wheels',               true, 'automotive'),
  ('Snacks',         'snacks',           'Chips, nuts, and snacks',        true, 'food-drinks'),
  ('Beverages',      'beverages',        'Juices, sodas, and water',       true, 'food-drinks'),
  ('Organic',        'organic',          'Organic and natural foods',      true, 'food-drinks'),
  ('Coffee & Tea',   'coffee-tea',       'Coffee beans and teas',          true, 'food-drinks'),
  ('Vitamins',       'vitamins',         'Vitamins and supplements',       true, 'health'),
  ('Medical Devices','medical-devices',  'Home medical equipment',         true, 'health'),
  ('Fitness',        'fitness',          'Fitness trackers and gear',      true, 'health'),
  ('Personal Care',  'personal-care',    'Hygiene and personal care',      true, 'health'),
  ('Mental Health',  'mental-health',    'Meditation and wellness',        true, 'health'),
  ('Baby Care',      'baby-care',        'Baby health products',           true, 'health'),
  ('Eye Care',       'eye-care',         'Glasses and eye drops',          true, 'health'),
  ('Dental Care',    'dental-care',      'Toothbrushes and dental tools',  true, 'health')
) AS t(name, slug, description, is_active, parent_slug);


-- ── 2. users (1000) ──────────────────────────────────────────

INSERT INTO users (email, password_hash, first_name, last_name, phone, is_active)
SELECT
  'user' || s || '@shopflow.com',
  md5(random()::TEXT),
  (ARRAY['James','Oliver','Harry','Jack','George','Noah','Charlie','Jacob',
         'Alfie','Freddie','Olivia','Emma','Ava','Sophia','Isabella','Mia',
         'Charlotte','Amelia','Harper','Evelyn'])[floor(random()*20+1)::INT],
  (ARRAY['Smith','Johnson','Williams','Brown','Jones','Garcia','Miller',
         'Davis','Wilson','Moore','Taylor','Anderson','Thomas','Jackson',
         'White','Harris','Martin','Thompson','Young','Lee'])[floor(random()*20+1)::INT],
  '+1' || (1000000000 + floor(random()*8999999999)::BIGINT)::TEXT,
  (random() > 0.05)
FROM generate_series(1, 1000) AS s;


-- ── 3. addresses (1500) ──────────────────────────────────────

INSERT INTO addresses (user_id, type, address_line1, city, state, postal_code, country, is_default)
SELECT
  u.id,
  CASE WHEN g = 1 THEN 'shipping' ELSE 'billing' END,
  floor(random()*999+1)::TEXT || ' ' ||
    (ARRAY['Main St','Oak Ave','Elm Rd','Park Blvd','Cedar Ln',
           'Maple Dr','Pine St','Lake Rd','Hill Ave','River Rd'])[floor(random()*10+1)::INT],
  (ARRAY['New York','Los Angeles','Chicago','Houston','Phoenix','Philadelphia',
         'San Antonio','San Diego','Dallas','San Jose','Austin','Jacksonville',
         'Fort Worth','Columbus','Charlotte','Indianapolis','Denver','Seattle'])[floor(random()*18+1)::INT],
  (ARRAY['NY','CA','IL','TX','AZ','PA','FL','OH','NC','WA','CO','GA'])[floor(random()*12+1)::INT],
  lpad(floor(random()*99999+1)::TEXT, 5, '0'),
  'United States',
  g = 1
FROM users u
CROSS JOIN generate_series(1, 2) AS g;


-- ── 4. products (500) ────────────────────────────────────────

INSERT INTO products (category_id, name, slug, description, base_price, is_active)
SELECT
  c.id,
  adj || ' ' || noun || ' ' || s,
  lower(adj) || '-' || lower(noun) || '-' || s,
  'High quality ' || lower(adj) || ' ' || lower(noun) || ' with excellent features.',
  ROUND((random() * 990 + 10)::NUMERIC, 2),
  (random() > 0.05)
FROM generate_series(1, 500) AS s
CROSS JOIN LATERAL (
  SELECT id FROM categories ORDER BY random() LIMIT 1
) c
CROSS JOIN LATERAL (
  SELECT adj FROM (VALUES
    ('Premium'),('Ultra'),('Pro'),('Smart'),('Eco'),
    ('Classic'),('Deluxe'),('Slim'),('Turbo'),('Elite')
  ) AS a(adj) ORDER BY random() LIMIT 1
) adjectives
CROSS JOIN LATERAL (
  SELECT noun FROM (VALUES
    ('Series'),('Edition'),('Model'),('Version'),('Pack')
  ) AS n(noun) ORDER BY random() LIMIT 1
) nouns;


-- ── 5. product_variants (2000) ───────────────────────────────

INSERT INTO product_variants (product_id, sku, size, color, price_modifier, is_active)
SELECT
  p.id,
  upper(md5(p.id::TEXT || s::TEXT || random()::TEXT)),
  (ARRAY['XS','S','M','L','XL','XXL','One Size'])[floor(random()*7+1)::INT],
  (ARRAY['Black','White','Red','Blue','Green','Yellow','Grey',
         'Navy','Pink','Purple','Orange','Brown'])[floor(random()*12+1)::INT],
  ROUND((random() * 50 - 10)::NUMERIC, 2),
  (random() > 0.08)
FROM products p
CROSS JOIN generate_series(1, 4) AS s;


-- ── 6. inventory (one per variant) ───────────────────────────

INSERT INTO inventory (variant_id, quantity_in_stock, quantity_reserved, low_stock_threshold)
SELECT
  id,
  floor(random() * 200)::INT,
  floor(random() * 10)::INT,
  floor(random() * 15 + 5)::INT
FROM product_variants;


-- ── 7. promotions (20) ───────────────────────────────────────

INSERT INTO promotions (code, description, discount_type, discount_value, min_order_amount, max_uses, starts_at, expires_at, is_active)
VALUES
  ('SAVE10',    '10% off all orders',        'percentage', 10.00,   0.00, 1000, NOW()-INTERVAL '60 days',  NOW()+INTERVAL '30 days',  true),
  ('SAVE20',    '20% off orders over $50',   'percentage', 20.00,  50.00,  500, NOW()-INTERVAL '30 days',  NOW()+INTERVAL '60 days',  true),
  ('FLAT5',     '$5 off any order',          'fixed',       5.00,   0.00, 2000, NOW()-INTERVAL '90 days',  NOW()+INTERVAL '90 days',  true),
  ('FLAT15',    '$15 off orders over $100',  'fixed',      15.00, 100.00,  300, NOW()-INTERVAL '10 days',  NOW()+INTERVAL '20 days',  true),
  ('WELCOME',   'Welcome discount 15%',      'percentage', 15.00,   0.00, NULL, NOW()-INTERVAL '180 days', NOW()+INTERVAL '180 days', true),
  ('SUMMER25',  'Summer sale 25% off',       'percentage', 25.00,  75.00,  800, NOW()-INTERVAL '45 days',  NOW()+INTERVAL '15 days',  true),
  ('FLASH30',   '30% flash sale',            'percentage', 30.00, 200.00,  100, NOW()-INTERVAL '2 days',   NOW()+INTERVAL '3 days',   true),
  ('BULK50',    '$50 off orders over $300',  'fixed',      50.00, 300.00,  200, NOW()-INTERVAL '20 days',  NOW()+INTERVAL '40 days',  true),
  ('NEWUSER',   'New user 12% discount',     'percentage', 12.00,   0.00, NULL, NOW()-INTERVAL '365 days', NOW()+INTERVAL '365 days', true),
  ('WEEKEND',   'Weekend special 8% off',    'percentage',  8.00,   0.00,  500, NOW()-INTERVAL '3 days',   NOW()+INTERVAL '4 days',   true),
  ('VIP20',     'VIP member 20% off',        'percentage', 20.00, 150.00,  250, NOW()-INTERVAL '15 days',  NOW()+INTERVAL '75 days',  true),
  ('HOLIDAY',   'Holiday season discount',   'percentage', 18.00,  50.00, 1000, NOW()-INTERVAL '5 days',   NOW()+INTERVAL '25 days',  true),
  ('FREESHIP',  '$10 off for free shipping', 'fixed',      10.00,  30.00, NULL, NOW()-INTERVAL '60 days',  NOW()+INTERVAL '60 days',  true),
  ('CLEARANCE', 'Clearance 35% off',         'percentage', 35.00, 100.00,  150, NOW()-INTERVAL '7 days',   NOW()+INTERVAL '7 days',   true),
  ('REFER10',   'Referral 10% bonus',        'percentage', 10.00,   0.00, NULL, NOW()-INTERVAL '120 days', NOW()+INTERVAL '120 days', true),
  ('APP15',     'App-only 15% discount',     'percentage', 15.00,  25.00,  600, NOW()-INTERVAL '30 days',  NOW()+INTERVAL '30 days',  true),
  ('EXPIRED5',  'Expired promo',             'fixed',       5.00,   0.00,  100, NOW()-INTERVAL '60 days',  NOW()-INTERVAL '10 days',  false),
  ('OLDCODE',   'Old seasonal code',         'percentage', 20.00,   0.00,  200, NOW()-INTERVAL '90 days',  NOW()-INTERVAL '30 days',  false),
  ('LAUNCH',    'Launch event discount',     'percentage', 22.00, 100.00,  500, NOW()-INTERVAL '200 days', NOW()-INTERVAL '170 days', false),
  ('EARLYBIRD', 'Early bird 5% off',         'percentage',  5.00,   0.00, 1000, NOW()-INTERVAL '300 days', NOW()-INTERVAL '270 days', false);


-- ── 8. carts (500) ───────────────────────────────────────────

INSERT INTO carts (user_id)
SELECT id
FROM users
ORDER BY random()
LIMIT 500;


-- ── 9. cart_items (~1000) ────────────────────────────────────

INSERT INTO cart_items (cart_id, variant_id, quantity)
SELECT DISTINCT ON (c.id, pv.id)
  c.id,
  pv.id,
  floor(random() * 4 + 1)::INT
FROM carts c
CROSS JOIN LATERAL (
  SELECT id FROM product_variants
  WHERE is_active = true
  ORDER BY random()
  LIMIT 3
) pv
ON CONFLICT (cart_id, variant_id) DO NOTHING;


-- ── 10. orders (5000) ────────────────────────────────────────

INSERT INTO orders (user_id, address_id, promotion_id, status, subtotal, discount_amount, tax_amount, total_amount, created_at)
SELECT
  u.id,
  a.id,
  CASE WHEN random() > 0.75
    THEN (SELECT id FROM promotions WHERE is_active = true ORDER BY random() LIMIT 1)
    ELSE NULL
  END,
  (ARRAY['pending','confirmed','shipped','delivered','cancelled','refunded'])[floor(random()*6+1)::INT],
  ROUND((random()*490+10)::NUMERIC, 2),
  ROUND((random()*30)::NUMERIC, 2),
  ROUND((random()*20)::NUMERIC, 2),
  ROUND((random()*490+10)::NUMERIC, 2),
  NOW() - (random() * INTERVAL '730 days')
FROM users u
JOIN LATERAL (
  SELECT id FROM addresses WHERE user_id = u.id LIMIT 1
) a ON true
CROSS JOIN generate_series(1, 5)
LIMIT 5000;


-- ── 11. order_items (15000) ──────────────────────────────────

INSERT INTO order_items (order_id, variant_id, quantity, unit_price, total_price)
SELECT
  o.id,
  pv.id,
  pv.qty,
  pv.unit_price,
  ROUND((pv.unit_price * pv.qty)::NUMERIC, 2)
FROM orders o
CROSS JOIN LATERAL (
  SELECT
    pv.id,
    floor(random()*4+1)::INT                                AS qty,
    ROUND((p.base_price + pv.price_modifier)::NUMERIC, 2)  AS unit_price
  FROM product_variants pv
  JOIN products p ON pv.product_id = p.id
  WHERE pv.is_active = true
  ORDER BY random()
  LIMIT 3
) pv
LIMIT 15000;


-- ── 12. reviews (3000) ───────────────────────────────────────

INSERT INTO reviews (user_id, product_id, rating, title, body, is_verified)
SELECT DISTINCT ON (u.id, p.id)
  u.id,
  p.id,
  floor(random()*5+1)::INT,
  (ARRAY[
    'Great product!','Highly recommend','Good value for money',
    'Exactly as described','Average quality','Disappointed',
    'Exceeded expectations','Would buy again','Not worth the price',
    'Perfect gift','Fast delivery','Could be better'
  ])[floor(random()*12+1)::INT],
  (ARRAY[
    'Really happy with this purchase. Quality is top notch.',
    'Delivery was quick and packaging was excellent.',
    'Good product but slightly overpriced for what it is.',
    'Works perfectly, exactly what I needed.',
    'Average product, nothing special.',
    'Would definitely recommend to friends and family.',
    'Not as good as the photos suggest.',
    'Very satisfied with the quality and finish.',
    'Had a minor issue but customer service resolved it quickly.',
    'Great addition to my collection!'
  ])[floor(random()*10+1)::INT],
  (random() > 0.3)
FROM (SELECT id FROM users ORDER BY random() LIMIT 1000) u
CROSS JOIN (SELECT id FROM products ORDER BY random() LIMIT 100) p
ORDER BY u.id, p.id, random()
LIMIT 3000;
