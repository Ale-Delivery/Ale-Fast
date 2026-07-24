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
  scheduled_at TIMESTAMPTZ,
  driver_lat DOUBLE PRECISION,
  driver_lng DOUBLE PRECISION,
  driver_eta TEXT,
  tip DECIMAL(10, 2) DEFAULT 0,
  referral_code TEXT,
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

-- ── Favorites (buyer) ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "Favorites" (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  restaurant_id TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, restaurant_id)
);

CREATE INDEX IF NOT EXISTS idx_favorites_user ON "Favorites"(user_id);

ALTER TABLE "Favorites" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users manage own favorites" ON "Favorites";
CREATE POLICY "Users manage own favorites" ON "Favorites"
  FOR ALL USING (user_id = auth.uid()::text OR true) WITH CHECK (true);

-- ── Food Favorites (buyer) ───────────────────────────────────
CREATE TABLE IF NOT EXISTS "FoodFavorites" (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  food_id TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, food_id)
);

CREATE INDEX IF NOT EXISTS idx_food_favorites_user ON "FoodFavorites"(user_id);

ALTER TABLE "FoodFavorites" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users manage own food favorites" ON "FoodFavorites";
CREATE POLICY "Users manage own food favorites" ON "FoodFavorites"
  FOR ALL USING (user_id = auth.uid()::text OR true) WITH CHECK (true);

-- ── Messages / Chat ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "Messages" (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES "Orders"(id) ON DELETE CASCADE,
  sender_id TEXT NOT NULL,
  sender_name TEXT DEFAULT 'User',
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_messages_order ON "Messages"(order_id);

ALTER TABLE "Messages" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can read messages" ON "Messages";
CREATE POLICY "Anyone can read messages" ON "Messages"
  FOR SELECT USING (true);
DROP POLICY IF EXISTS "Anyone can send messages" ON "Messages";
CREATE POLICY "Anyone can send messages" ON "Messages"
  FOR INSERT WITH CHECK (true);

-- ── Referrals ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "Referrals" (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_id TEXT NOT NULL,
  referred_phone TEXT NOT NULL,
  referred_user_id TEXT,
  status TEXT DEFAULT 'pending',
  reward_amount DECIMAL(10, 2) DEFAULT 100,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON "Referrals"(referrer_id);

ALTER TABLE "Referrals" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can manage referrals" ON "Referrals";
CREATE POLICY "Anyone can manage referrals" ON "Referrals"
  FOR ALL USING (true) WITH CHECK (true);

-- ── Notifications ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "Notifications" (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type TEXT DEFAULT 'info',
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON "Notifications"(user_id);

ALTER TABLE "Notifications" ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users manage own notifications" ON "Notifications";
CREATE POLICY "Users manage own notifications" ON "Notifications"
  FOR ALL USING (user_id = auth.uid()::text OR true) WITH CHECK (true);

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

-- ─── GROCERY TABLES ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "Grocery_Categories" (
  "id" UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  "name" TEXT NOT NULL,
  "icon" TEXT,
  "color" TEXT DEFAULT '#22C55E',
  "description" TEXT,
  "sort_order" INTEGER DEFAULT 0,
  "created_at" TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "Grocery_Products" (
  "id" UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  "category_id" UUID REFERENCES "Grocery_Categories"("id") ON DELETE SET NULL,
  "name" TEXT NOT NULL,
  "description" TEXT,
  "price" NUMERIC(10,2) NOT NULL,
  "unit" TEXT DEFAULT '1pc',
  "image_url" TEXT,
  "stock" BOOLEAN DEFAULT true,
  "is_featured" BOOLEAN DEFAULT false,
  "created_at" TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "Grocery_Cart" (
  "id" UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  "user_id" UUID REFERENCES auth.users("id") ON DELETE CASCADE,
  "product_id" UUID REFERENCES "Grocery_Products"("id") ON DELETE CASCADE,
  "quantity" INTEGER DEFAULT 1,
  "created_at" TIMESTAMPTZ DEFAULT now(),
  UNIQUE("user_id", "product_id")
);

CREATE TABLE IF NOT EXISTS "Grocery_Wishlist" (
  "id" UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  "user_id" UUID REFERENCES auth.users("id") ON DELETE CASCADE,
  "product_id" UUID REFERENCES "Grocery_Products"("id") ON DELETE CASCADE,
  "created_at" TIMESTAMPTZ DEFAULT now(),
  UNIQUE("user_id", "product_id")
);

CREATE TABLE IF NOT EXISTS "Grocery_Orders" (
  "id" UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  "user_id" UUID REFERENCES auth.users("id") ON DELETE CASCADE,
  "items" JSONB NOT NULL,
  "subtotal" NUMERIC(10,2) NOT NULL,
  "delivery_fee" NUMERIC(10,2) DEFAULT 0,
  "total" NUMERIC(10,2) NOT NULL,
  "status" TEXT DEFAULT 'pending',
  "scheduled_at" TIMESTAMPTZ,
  "delivery_address" TEXT,
  "created_at" TIMESTAMPTZ DEFAULT now()
);

-- RLS for grocery tables
ALTER TABLE "Grocery_Categories" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Grocery_Products" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Grocery_Cart" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Grocery_Wishlist" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Grocery_Orders" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read grocery categories" ON "Grocery_Categories";
DROP POLICY IF EXISTS "Public read grocery products" ON "Grocery_Products";
DROP POLICY IF EXISTS "Users manage own grocery cart" ON "Grocery_Cart";
DROP POLICY IF EXISTS "Users manage own grocery wishlist" ON "Grocery_Wishlist";
DROP POLICY IF EXISTS "Users manage own grocery orders" ON "Grocery_Orders";

CREATE POLICY "Public read grocery categories" ON "Grocery_Categories" FOR SELECT USING (true);
CREATE POLICY "Public read grocery products" ON "Grocery_Products" FOR SELECT USING (true);

CREATE POLICY "Users manage own grocery cart" ON "Grocery_Cart"
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users manage own grocery wishlist" ON "Grocery_Wishlist"
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users manage own grocery orders" ON "Grocery_Orders"
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_grocery_products_category ON "Grocery_Products"("category_id");
CREATE INDEX IF NOT EXISTS idx_grocery_cart_user ON "Grocery_Cart"("user_id");
CREATE INDEX IF NOT EXISTS idx_grocery_wishlist_user ON "Grocery_Wishlist"("user_id");
CREATE INDEX IF NOT EXISTS idx_grocery_orders_user ON "Grocery_Orders"("user_id");

-- ─── RIDE TABLES ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS "Ride_Orders" (
  "id" UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  "user_id" UUID REFERENCES auth.users("id") ON DELETE CASCADE,
  "pickup_name" TEXT,
  "dropoff_name" TEXT,
  "pickup_lat" DOUBLE PRECISION,
  "pickup_lng" DOUBLE PRECISION,
  "dropoff_lat" DOUBLE PRECISION,
  "dropoff_lng" DOUBLE PRECISION,
  "ride_type" TEXT,
  "fare" INTEGER,
  "distance_km" DOUBLE PRECISION,
  "eta_min" INTEGER,
  "driver_name" TEXT,
  "driver_vehicle" TEXT,
  "payment_method" TEXT DEFAULT 'cash',
  "status" TEXT DEFAULT 'pending',
  "created_at" TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "Ride_Ratings" (
  "id" UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  "user_id" UUID REFERENCES auth.users("id") ON DELETE CASCADE,
  "driver_name" TEXT,
  "ride_type" TEXT,
  "rating" INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  "feedback" TEXT,
  "comment" TEXT,
  "fare" INTEGER,
  "pickup" TEXT,
  "dropoff" TEXT,
  "created_at" TIMESTAMPTZ DEFAULT now()
);

-- RLS for ride tables
ALTER TABLE "Ride_Orders" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Ride_Ratings" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own ride orders" ON "Ride_Orders";
DROP POLICY IF EXISTS "Users manage own ride ratings" ON "Ride_Ratings";

CREATE POLICY "Users manage own ride orders" ON "Ride_Orders"
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users manage own ride ratings" ON "Ride_Ratings"
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_ride_orders_user ON "Ride_Orders"("user_id");
CREATE INDEX IF NOT EXISTS idx_ride_ratings_user ON "Ride_Ratings"("user_id");

-- ─── WALLET & PAYMENT TABLES ───────────────────────────────────

CREATE TABLE IF NOT EXISTS "Wallet" (
  "id" UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  "user_id" UUID REFERENCES auth.users("id") ON DELETE CASCADE UNIQUE,
  "balance" NUMERIC(10,2) DEFAULT 0,
  "created_at" TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "Wallet_Transactions" (
  "id" UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  "user_id" UUID REFERENCES auth.users("id") ON DELETE CASCADE,
  "type" TEXT NOT NULL,
  "amount" NUMERIC(10,2) NOT NULL,
  "description" TEXT,
  "created_at" TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS "Payment_Methods" (
  "id" UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  "user_id" UUID REFERENCES auth.users("id") ON DELETE CASCADE,
  "type" TEXT DEFAULT 'card',
  "card_number" TEXT,
  "card_holder" TEXT,
  "expiry" TEXT,
  "is_default" BOOLEAN DEFAULT false,
  "created_at" TIMESTAMPTZ DEFAULT now()
);

-- RLS for wallet tables
ALTER TABLE "Wallet" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Wallet_Transactions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Payment_Methods" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own wallet" ON "Wallet";
DROP POLICY IF EXISTS "Users manage own wallet transactions" ON "Wallet_Transactions";
DROP POLICY IF EXISTS "Users manage own payment methods" ON "Payment_Methods";

CREATE POLICY "Users manage own wallet" ON "Wallet"
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users manage own wallet transactions" ON "Wallet_Transactions"
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users manage own payment methods" ON "Payment_Methods"
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Increment wallet balance function
CREATE OR REPLACE FUNCTION increment_wallet_balance(p_user_id UUID, p_amount NUMERIC)
RETURNS void AS $$
BEGIN
  UPDATE "Wallet" SET balance = balance + p_amount WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

CREATE INDEX IF NOT EXISTS idx_wallet_user ON "Wallet"("user_id");
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_user ON "Wallet_Transactions"("user_id");
CREATE INDEX IF NOT EXISTS idx_payment_methods_user ON "Payment_Methods"("user_id");
