-- Run this in Supabase SQL Editor (buyer + seller dev setup)
-- Safe to re-run: uses IF NOT EXISTS / ON CONFLICT where possible

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

ALTER TABLE "Profiles" ADD COLUMN IF NOT EXISTS birthday DATE;
ALTER TABLE "Profiles" ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE "Profiles" ADD COLUMN IF NOT EXISTS gender TEXT;
ALTER TABLE "Profiles" ADD COLUMN IF NOT EXISTS email TEXT;

ALTER TABLE "Profiles" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all on Profiles" ON "Profiles";
CREATE POLICY "Allow all on Profiles" ON "Profiles" FOR ALL USING (true) WITH CHECK (true);

-- ── Restaurants (home + search + details) ──────────────────────
CREATE TABLE IF NOT EXISTS "Restaurants" (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  image_url TEXT,
  rating DECIMAL(3, 1) DEFAULT 4.5,
  delivery_fee TEXT DEFAULT 'Free',
  delivery_time TEXT DEFAULT '25 min',
  delivery_min INT DEFAULT 25,
  free_delivery BOOLEAN DEFAULT true,
  category TEXT,
  tags TEXT,
  description TEXT,
  address TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_restaurants_category ON "Restaurants"(category);

ALTER TABLE "Restaurants" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all on Restaurants" ON "Restaurants";
CREATE POLICY "Allow all on Restaurants" ON "Restaurants" FOR ALL USING (true) WITH CHECK (true);

-- ── Menu items ───────────────────────────────────────────────────
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
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_menu_items_restaurant ON "Menu_Items"(restaurant_id);

ALTER TABLE "Menu_Items" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all on Menu_Items" ON "Menu_Items";
CREATE POLICY "Allow all on Menu_Items" ON "Menu_Items" FOR ALL USING (true) WITH CHECK (true);

-- ── Orders (status starts as pending for seller to accept) ───────
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
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON "Order_Items"(order_id);

ALTER TABLE "Orders" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Order_Items" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all on Orders" ON "Orders";
CREATE POLICY "Allow all on Orders" ON "Orders" FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all on Order_Items" ON "Order_Items";
CREATE POLICY "Allow all on Order_Items" ON "Order_Items" FOR ALL USING (true) WITH CHECK (true);

-- Realtime for order tracking (ignore error if already added)
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE "Orders";
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- ── Seed data (sample restaurants + menu) ───────────────────────
INSERT INTO "Restaurants" (
  id, name, image_url, rating, delivery_fee, delivery_time, delivery_min,
  free_delivery, category, tags, description, address
) VALUES
  (
    'rest-burger-house',
    'Burger House',
    'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800',
    4.7, 'Free', '20 min', 20, true,
    'Burger', 'Burgers · Fast food · Lunch',
    'Smash burgers and crispy fries made fresh.',
    'Colombo 03'
  ),
  (
    'rest-pizza-palace',
    'Pizza Palace',
    'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800',
    4.5, 'Rs. 150', '30 min', 30, false,
    'Pizza', 'Pizza · Italian · Family',
    'Wood-fired pizzas and garlic bread.',
    'Colombo 05'
  ),
  (
    'rest-green-bowl',
    'Green Bowl Cafe',
    'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800',
    4.8, 'Free', '25 min', 25, true,
    'Sandwich', 'Healthy · Salads · Coffee',
    'Fresh bowls, wraps, and cold brew.',
    'Colombo 07'
  )
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  image_url = EXCLUDED.image_url,
  rating = EXCLUDED.rating,
  delivery_fee = EXCLUDED.delivery_fee,
  delivery_time = EXCLUDED.delivery_time,
  delivery_min = EXCLUDED.delivery_min,
  free_delivery = EXCLUDED.free_delivery,
  category = EXCLUDED.category,
  tags = EXCLUDED.tags,
  description = EXCLUDED.description,
  address = EXCLUDED.address;

INSERT INTO "Menu_Items" (
  id, restaurant_id, name, image_url, price, rating, category, description, sizes, ingredients
) VALUES
  (
    'menu-bh-classic',
    'rest-burger-house',
    'Classic Smash Burger',
    'https://images.unsplash.com/photo-1550547660-d9450f859349?w=600',
    1290, 4.8, 'Burger',
    'Double patty, cheddar, house sauce.',
    '["Regular", "Large"]'::jsonb,
    '["Beef", "Cheddar", "Lettuce", "Tomato"]'::jsonb
  ),
  (
    'menu-bh-chicken',
    'rest-burger-house',
    'Crispy Chicken Burger',
    'https://images.unsplash.com/photo-1606755962773-d324e788a531?w=600',
    1190, 4.6, 'Burger',
    'Fried chicken fillet with spicy mayo.',
    '["Regular", "Large"]'::jsonb,
    '["Chicken", "Mayo", "Pickles"]'::jsonb
  ),
  (
    'menu-bh-fries',
    'rest-burger-house',
    'Loaded Fries',
    'https://images.unsplash.com/photo-1573080496219-b080abfdc174?w=600',
    690, 4.5, 'Sides',
    'Cheese sauce, spring onion, bacon bits.',
    '["Regular"]'::jsonb,
    '["Potato", "Cheese", "Bacon"]'::jsonb
  ),
  (
    'menu-pp-margherita',
    'rest-pizza-palace',
    'Margherita Pizza',
    'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=600',
    1890, 4.7, 'Pizza',
    'Tomato, mozzarella, basil.',
    '["10\"", "14\"", "16\""]'::jsonb,
    '["Tomato", "Mozzarella", "Basil"]'::jsonb
  ),
  (
    'menu-pp-pepperoni',
    'rest-pizza-palace',
    'Pepperoni Feast',
    'https://images.unsplash.com/photo-1628840042765-356cda07504e?w=600',
    2190, 4.9, 'Pizza',
    'Extra pepperoni and cheese blend.',
    '["10\"", "14\"", "16\""]'::jsonb,
    '["Pepperoni", "Mozzarella", "Tomato sauce"]'::jsonb
  ),
  (
    'menu-pp-garlic',
    'rest-pizza-palace',
    'Garlic Bread',
    'https://images.unsplash.com/photo-1619535857770-99f9c2b7c4b0?w=600',
    590, 4.4, 'Sides',
    'Butter garlic bread with herbs.',
    '["Regular"]'::jsonb,
    '["Bread", "Garlic", "Butter"]'::jsonb
  ),
  (
    'menu-gb-buddha',
    'rest-green-bowl',
    'Buddha Bowl',
    'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600',
    1490, 4.8, 'Bowl',
    'Quinoa, roasted veggies, tahini dressing.',
    '["Regular", "Large"]'::jsonb,
    '["Quinoa", "Chickpeas", "Avocado", "Tahini"]'::jsonb
  ),
  (
    'menu-gb-wrap',
    'rest-green-bowl',
    'Grilled Chicken Wrap',
    'https://images.unsplash.com/photo-1626700051175-6818036a40a5?w=600',
    1290, 4.6, 'Sandwich',
    'Whole wheat wrap with yogurt sauce.',
    '["Regular"]'::jsonb,
    '["Chicken", "Lettuce", "Yogurt sauce"]'::jsonb
  ),
  (
    'menu-gb-smoothie',
    'rest-green-bowl',
    'Berry Smoothie',
    'https://images.unsplash.com/photo-1505252585461-04db1eb84665?w=600',
    790, 4.7, 'Coffee',
    'Mixed berries, yogurt, honey.',
    '["Regular", "Large"]'::jsonb,
    '["Berries", "Yogurt", "Honey"]'::jsonb
  )
ON CONFLICT (id) DO UPDATE SET
  restaurant_id = EXCLUDED.restaurant_id,
  name = EXCLUDED.name,
  image_url = EXCLUDED.image_url,
  price = EXCLUDED.price,
  rating = EXCLUDED.rating,
  category = EXCLUDED.category,
  description = EXCLUDED.description,
  sizes = EXCLUDED.sizes,
  ingredients = EXCLUDED.ingredients;
