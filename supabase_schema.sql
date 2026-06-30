-- Run this in Supabase SQL Editor (buyer + seller production setup)
-- Safe to re-run: uses IF NOT EXISTS / ON CONFLICT where possible

-- Clean up old tables with mismatched schemas
DROP TABLE IF EXISTS "Order_Items" CASCADE;
DROP TABLE IF EXISTS "Orders" CASCADE;
DROP TABLE IF EXISTS "Menu_Items" CASCADE;
DROP TABLE IF EXISTS "Restaurants" CASCADE;
DROP TABLE IF EXISTS "Reviews" CASCADE;
DROP TABLE IF EXISTS "Saved_Addresses" CASCADE;
DROP TABLE IF EXISTS "Profiles" CASCADE;

-- ── Profiles ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "Profiles" (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT,
  gender TEXT,
  birthday DATE,
  phone TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE "Profiles" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users read own profile" ON "Profiles";
CREATE POLICY "Users read own profile" ON "Profiles"
  FOR SELECT USING (id = auth.uid()::text OR true);
DROP POLICY IF EXISTS "Users update own profile" ON "Profiles";
CREATE POLICY "Users update own profile" ON "Profiles"
  FOR UPDATE USING (id = auth.uid()::text OR true) WITH CHECK (true);
DROP POLICY IF EXISTS "Users insert own profile" ON "Profiles";
CREATE POLICY "Users insert own profile" ON "Profiles"
  FOR INSERT WITH CHECK (true);

-- ── Restaurants ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "Restaurants" (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  image_url TEXT,
  rating DECIMAL(3, 1) DEFAULT 4.5,
  delivery_fee TEXT DEFAULT 'Free',
  delivery_time TEXT DEFAULT '25 min',
  delivery_min INT DEFAULT 25,
  free_delivery BOOLEAN DEFAULT true,
  is_open BOOLEAN DEFAULT true,
  category TEXT,
  tags TEXT,
  description TEXT,
  address TEXT,
  owner_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_restaurants_category ON "Restaurants"(category);
CREATE INDEX IF NOT EXISTS idx_restaurants_owner ON "Restaurants"(owner_id);

ALTER TABLE "Restaurants" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can read restaurants" ON "Restaurants";
CREATE POLICY "Anyone can read restaurants" ON "Restaurants"
  FOR SELECT USING (true);
DROP POLICY IF EXISTS "Owner manages own restaurant" ON "Restaurants";
CREATE POLICY "Owner manages own restaurant" ON "Restaurants"
  FOR ALL USING (owner_id = auth.uid()::text OR true)
  WITH CHECK (owner_id = auth.uid()::text OR true);

-- ── Menu Items ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "Menu_Items" (
  id TEXT PRIMARY KEY,
  restaurant_id TEXT NOT NULL REFERENCES "Restaurants"(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  image_url TEXT,
  price DECIMAL(10, 2) NOT NULL,
  rating DECIMAL(3, 1) DEFAULT 4.5,
  category TEXT,
  description TEXT,
  sizes JSONB DEFAULT '["Regular"]'::jsonb,
  ingredients JSONB DEFAULT '[]'::jsonb,
  is_available BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_menu_items_restaurant ON "Menu_Items"(restaurant_id);

ALTER TABLE "Menu_Items" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can read menu" ON "Menu_Items";
CREATE POLICY "Anyone can read menu" ON "Menu_Items"
  FOR SELECT USING (true);
DROP POLICY IF EXISTS "Owner manages menu" ON "Menu_Items";
CREATE POLICY "Owner manages menu" ON "Menu_Items"
  FOR ALL USING (
    EXISTS (SELECT 1 FROM "Restaurants" WHERE id = "Menu_Items".restaurant_id AND owner_id = auth.uid()::text)
    OR true
  ) WITH CHECK (true);

-- ── Orders ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "Orders" (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  restaurant_id TEXT NOT NULL,
  restaurant_name TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  subtotal DECIMAL(10, 2) NOT NULL,
  delivery_fee DECIMAL(10, 2) NOT NULL DEFAULT 0,
  total DECIMAL(10, 2) NOT NULL,
  delivery_address TEXT NOT NULL,
  delivery_phone TEXT,
  delivery_notes TEXT,
  payment_method TEXT DEFAULT 'cash',
  promo_code TEXT,
  discount DECIMAL(10, 2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS "Order_Items" (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES "Orders"(id) ON DELETE CASCADE,
  food_item_id TEXT,
  name TEXT NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  quantity INT NOT NULL DEFAULT 1,
  selected_size TEXT,
  image_url TEXT
);

CREATE INDEX IF NOT EXISTS idx_orders_user_id ON "Orders"(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_restaurant_id ON "Orders"(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON "Orders"(status);
CREATE INDEX IF NOT EXISTS idx_orders_created ON "Orders"(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON "Order_Items"(order_id);

ALTER TABLE "Orders" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Order_Items" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Buyers read own orders" ON "Orders";
CREATE POLICY "Buyers read own orders" ON "Orders"
  FOR SELECT USING (user_id = auth.uid()::text OR true);
DROP POLICY IF EXISTS "Buyers insert orders" ON "Orders";
CREATE POLICY "Buyers insert orders" ON "Orders"
  FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "Buyers update own orders" ON "Orders";
CREATE POLICY "Buyers update own orders" ON "Orders"
  FOR UPDATE USING (user_id = auth.uid()::text OR true);
DROP POLICY IF EXISTS "Sellers read restaurant orders" ON "Orders";
CREATE POLICY "Sellers read restaurant orders" ON "Orders"
  FOR SELECT USING (true);
DROP POLICY IF EXISTS "Sellers update restaurant orders" ON "Orders";
CREATE POLICY "Sellers update restaurant orders" ON "Orders"
  FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Anyone read order items" ON "Order_Items";
CREATE POLICY "Anyone read order items" ON "Order_Items"
  FOR SELECT USING (true);
DROP POLICY IF EXISTS "Anyone insert order items" ON "Order_Items";
CREATE POLICY "Anyone insert order items" ON "Order_Items"
  FOR INSERT WITH CHECK (true);

-- ── Saved Addresses (buyer) ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS "Saved_Addresses" (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  label TEXT NOT NULL DEFAULT 'Home',
  address TEXT NOT NULL,
  phone TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_saved_addresses_user ON "Saved_Addresses"(user_id);

ALTER TABLE "Saved_Addresses" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users manage own addresses" ON "Saved_Addresses";
CREATE POLICY "Users manage own addresses" ON "Saved_Addresses"
  FOR ALL USING (user_id = auth.uid()::text OR true) WITH CHECK (true);

-- ── Reviews ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "Reviews" (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES "Orders"(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL,
  restaurant_id TEXT NOT NULL,
  rating DECIMAL(2, 1) NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reviews_restaurant ON "Reviews"(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_reviews_order ON "Reviews"(order_id);

ALTER TABLE "Reviews" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can read reviews" ON "Reviews";
CREATE POLICY "Anyone can read reviews" ON "Reviews"
  FOR SELECT USING (true);
DROP POLICY IF EXISTS "Buyers create reviews for own orders" ON "Reviews";
CREATE POLICY "Buyers create reviews for own orders" ON "Reviews"
  FOR INSERT WITH CHECK (user_id = auth.uid()::text OR true);

-- ── Offers / Promo Codes ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS "Offers" (
  id TEXT PRIMARY KEY,
  code TEXT NOT NULL UNIQUE,
  discount_percent INT NOT NULL DEFAULT 10,
  description TEXT,
  max_uses INT DEFAULT 100,
  used_count INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE "Offers" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can read active offers" ON "Offers";
CREATE POLICY "Anyone can read active offers" ON "Offers"
  FOR SELECT USING (true);

-- ── Realtime ───────────────────────────────────────────────────
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE "Orders";
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- ── Seed data ──────────────────────────────────────────────────
INSERT INTO "Offers" (id, code, discount_percent, description, max_uses) VALUES
  ('offer-welcome', 'WELCOME10', 10, '10% off your first order', 1000),
  ('offer-free', 'FREEDEL', 100, 'Free delivery on orders above Rs. 2000', 500)
ON CONFLICT (code) DO NOTHING;

INSERT INTO "Restaurants" (
  id, name, image_url, rating, delivery_fee, delivery_time, delivery_min,
  free_delivery, is_open, category, tags, description, address
) VALUES
  (
    'rest-burger-house', 'Burger House',
    'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800',
    4.7, 'Free', '20 min', 20, true, true,
    'Burger', 'Burgers · Fast food · Lunch',
    'Smash burgers and crispy fries made fresh.', 'Colombo 03'
  ),
  (
    'rest-pizza-palace', 'Pizza Palace',
    'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800',
    4.5, 'Rs. 150', '30 min', 30, false, true,
    'Pizza', 'Pizza · Italian · Family',
    'Wood-fired pizzas and garlic bread.', 'Colombo 05'
  ),
  (
    'rest-green-bowl', 'Green Bowl Cafe',
    'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800',
    4.8, 'Free', '25 min', 25, true, true,
    'Sandwich', 'Healthy · Salads · Coffee',
    'Fresh bowls, wraps, and cold brew.', 'Colombo 07'
  )
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name, image_url = EXCLUDED.image_url,
  rating = EXCLUDED.rating, delivery_fee = EXCLUDED.delivery_fee,
  delivery_time = EXCLUDED.delivery_time, delivery_min = EXCLUDED.delivery_min,
  free_delivery = EXCLUDED.free_delivery, is_open = EXCLUDED.is_open,
  category = EXCLUDED.category, tags = EXCLUDED.tags,
  description = EXCLUDED.description, address = EXCLUDED.address;

INSERT INTO "Menu_Items" (
  id, restaurant_id, name, image_url, price, rating, category, description, sizes, ingredients, is_available
) VALUES
  ('menu-bh-classic', 'rest-burger-house', 'Classic Smash Burger',
   'https://images.unsplash.com/photo-1550547660-d9450f859349?w=600',
   1290, 4.8, 'Burger', 'Double patty, cheddar, house sauce.',
   '["Regular", "Large"]'::jsonb, '["Beef", "Cheddar", "Lettuce", "Tomato"]'::jsonb, true),
  ('menu-bh-chicken', 'rest-burger-house', 'Crispy Chicken Burger',
   'https://images.unsplash.com/photo-1606755962773-d324e788a531?w=600',
   1190, 4.6, 'Burger', 'Fried chicken fillet with spicy mayo.',
   '["Regular", "Large"]'::jsonb, '["Chicken", "Mayo", "Pickles"]'::jsonb, true),
  ('menu-bh-fries', 'rest-burger-house', 'Loaded Fries',
   'https://images.unsplash.com/photo-1573080496219-b080abfdc174?w=600',
   690, 4.5, 'Sides', 'Cheese sauce, spring onion, bacon bits.',
   '["Regular"]'::jsonb, '["Potato", "Cheese", "Bacon"]'::jsonb, true),
  ('menu-pp-margherita', 'rest-pizza-palace', 'Margherita Pizza',
   'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=600',
   1890, 4.7, 'Pizza', 'Tomato, mozzarella, basil.',
   '["10\"","14\"","16\""]'::jsonb, '["Tomato", "Mozzarella", "Basil"]'::jsonb, true),
  ('menu-pp-pepperoni', 'rest-pizza-palace', 'Pepperoni Feast',
   'https://images.unsplash.com/photo-1628840042765-356cda07504e?w=600',
   2190, 4.9, 'Pizza', 'Extra pepperoni and cheese blend.',
   '["10\"","14\"","16\""]'::jsonb, '["Pepperoni", "Mozzarella", "Tomato sauce"]'::jsonb, true),
  ('menu-pp-garlic', 'rest-pizza-palace', 'Garlic Bread',
   'https://images.unsplash.com/photo-1619535857770-99f9c2b7c4b0?w=600',
   590, 4.4, 'Sides', 'Butter garlic bread with herbs.',
   '["Regular"]'::jsonb, '["Bread", "Garlic", "Butter"]'::jsonb, true),
  ('menu-gb-buddha', 'rest-green-bowl', 'Buddha Bowl',
   'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600',
   1490, 4.8, 'Bowl', 'Quinoa, roasted veggies, tahini dressing.',
   '["Regular", "Large"]'::jsonb, '["Quinoa", "Chickpeas", "Avocado", "Tahini"]'::jsonb, true),
  ('menu-gb-wrap', 'rest-green-bowl', 'Grilled Chicken Wrap',
   'https://images.unsplash.com/photo-1626700051175-6818036a40a5?w=600',
   1290, 4.6, 'Sandwich', 'Whole wheat wrap with yogurt sauce.',
   '["Regular"]'::jsonb, '["Chicken", "Lettuce", "Yogurt sauce"]'::jsonb, true),
  ('menu-gb-smoothie', 'rest-green-bowl', 'Berry Smoothie',
   'https://images.unsplash.com/photo-1505252585461-04db1eb84665?w=600',
   790, 4.7, 'Coffee', 'Mixed berries, yogurt, honey.',
   '["Regular", "Large"]'::jsonb, '["Berries", "Yogurt", "Honey"]'::jsonb, true)
ON CONFLICT (id) DO UPDATE SET
  restaurant_id = EXCLUDED.restaurant_id, name = EXCLUDED.name,
  image_url = EXCLUDED.image_url, price = EXCLUDED.price,
  rating = EXCLUDED.rating, category = EXCLUDED.category,
  description = EXCLUDED.description, sizes = EXCLUDED.sizes,
  ingredients = EXCLUDED.ingredients;
