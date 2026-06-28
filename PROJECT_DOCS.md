# Alee-App — සම්පූර්ණ Project Documentation

> **App Name:** Food App (aleeapp)  
> **Package:** `food_app` v1.0.0+1  
> **Tech Stack:** Flutter 3.x + Supabase + Provider  
> **Platforms:** Android · iOS · Web · Windows · macOS · Linux  
> **Language:** Dart (Sinhala comments)

---

## 1. Project Overview

මේක Flutter වලින් හදපු **Food Delivery** mobile app එකක්. Buyer/Customer side එක විතරයි — restaurant browse කරන්න, menu බලන්න, cart එකට add කරන්න, order කරන්න, real-time tracking බලන්න පුළුවන්.

Backend එක විදියට **Supabase** (PostgreSQL + Realtime + Auth) use කරලා තියෙනවා. Supabase connect නැත්තම් local mock data fallback system එකකුත් දාලා තියෙනවා.

---

## 2. File Structure

```
E:\Projects\Alee-App\
├── lib/                              # Main Dart source code
│   ├── main.dart                     # Entry point — Supabase init + MultiProvider
│   ├── constants/
│   │   └── app_constants.dart        # Supabase URL, Anon Key, Google Maps API Key
│   ├── theme/
│   │   └── app_theme.dart            # Colors (orange theme), Material 3 theme
│   ├── models/
│   │   └── models.dart               # All data models (Restaurant, FoodItem, CartItem, Order, etc.)
│   ├── services/
│   │   ├── auth_service.dart         # Phone OTP auth + profile save
│   │   ├── database_service.dart     # Supabase queries (restaurants, menu, search)
│   │   ├── order_service.dart        # Place order, fetch orders, realtime tracking
│   │   ├── local_storage_service.dart # SharedPreferences wrapper
│   │   └── google_maps_service.dart  # Autocomplete + geocoding (Google → OSM → Mock)
│   ├── providers/
│   │   └── cart_provider.dart        # ChangeNotifier — cart state management
│   ├── widgets/
│   │   ├── common_widgets.dart       # AppNetworkImage, RestaurantCard, FoodCard, etc.
│   │   ├── custom_button.dart        # Orange full-width button
│   │   ├── custom_input.dart         # Text field (password toggle)
│   │   ├── auth_header.dart          # Dark blue auth screen header
│   │   └── dark_widgets.dart         # Dark theme variants
│   ├── navigation/
│   │   ├── app_routes.dart           # Route name constants (17 routes)
│   │   └── buyer_navigator.dart      # Central navigation helper (all screen transitions)
│   └── screens/                      # 18 screen files
│       ├── splash_screen.dart
│       ├── onboarding_screen.dart
│       ├── phone_auth_screen.dart
│       ├── verification_screen.dart
│       ├── profile_setup_screen.dart
│       ├── home_screen.dart
│       ├── search_screen.dart
│       ├── details_screen.dart
│       ├── restaurant_view_screen.dart
│       ├── food_detail_screen.dart
│       ├── cart_screen.dart
│       ├── delivery_address_screen.dart
│       ├── checkout_screen.dart
│       ├── order_placed_screen.dart
│       ├── order_tracking_screen.dart
│       ├── order_history_screen.dart
│       ├── profile_screen.dart
│       └── location_picker_screen.dart
├── android/                          # Android native (Kotlin + Gradle)
├── ios/                              # iOS native (Swift)
├── web/                              # Web entry (HTML/JS)
├── windows/                          # Windows native (C++/CMake)
├── linux/                            # Linux native (C++/CMake)
├── macos/                            # macOS native
├── assets/images/                    # Local images (currently empty — all from network)
├── test/                             # Tests (currently empty)
├── pubspec.yaml                      # Flutter dependencies
├── pubspec.lock                      # Dependency lock file
├── supabase_schema.sql               # Database schema + seed data
├── analysis_options.yaml             # Dart lint rules
├── README.md                         # Setup guide
├── BUYER_FLOW.md                     # UX flow + navigation map
└── package.json                      # Node.js (Supabase SSR — not used by Flutter app)
```

---

## 3. Architecture

### 3.1 Architecture Pattern

```
┌─────────────────────────────────────────────┐
│  Screens (UI Layer)                         │
│  splash, home, cart, checkout, etc.         │
├─────────────────────────────────────────────┤
│  Providers (State)       Navigator          │
│  CartProvider            BuyerNavigator     │
├─────────────────────────────────────────────┤
│  Services (Business Logic)                  │
│  AuthService · DatabaseService              │
│  OrderService · LocalStorageService         │
│  GoogleMapsService                           │
├─────────────────────────────────────────────┤
│  Models (Data)                              │
│  Restaurant · FoodItem · CartItem · Order   │
├─────────────────────────────────────────────┤
│  Supabase Backend                           │
│  PostgreSQL · Realtime · Auth               │
└─────────────────────────────────────────────┘
```

### 3.2 Key Design Patterns

| Pattern | Implementation |
|---------|---------------|
| **Provider (State Management)** | `CartProvider` extends `ChangeNotifier`, consumed via `context.watch<CartProvider>()` |
| **Service Layer** | Business logic separated into service classes (no direct Supabase calls in screens) |
| **Centralized Navigation** | `BuyerNavigator` class — all screen transitions in one place |
| **Route Constants** | `AppRoutes` abstract class — all route name strings |
| **Graceful Degradation** | Mock data fallback when Supabase unavailable; multi-tier geocoding fallback |
| **Model-View separation** | Data models handle JSON serialization; screens handle UI only |

---

## 4. Database Schema (Supabase)

### 4.1 Tables

#### `Profiles` — User profiles
| Column | Type | Notes |
|--------|------|-------|
| `id` | TEXT (PK) | User UUID |
| `name` | TEXT | NOT NULL |
| `email` | TEXT | Optional |
| `gender` | TEXT | Optional |
| `birthday` | DATE | Optional |
| `phone` | TEXT | Optional |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() |

#### `Restaurants` — Restaurant listing
| Column | Type | Notes |
|--------|------|-------|
| `id` | TEXT (PK) | e.g. `rest-burger-house` |
| `name` | TEXT | NOT NULL |
| `image_url` | TEXT | Unsplash CDN URLs |
| `rating` | DECIMAL(3,1) | DEFAULT 4.5 |
| `delivery_fee` | TEXT | e.g. 'Free', 'Rs. 150' |
| `delivery_time` | TEXT | e.g. '20 min' |
| `delivery_min` | INT | Numeric minutes |
| `free_delivery` | BOOLEAN | DEFAULT true |
| `category` | TEXT | e.g. 'Burger', 'Pizza' |
| `tags` | TEXT | e.g. 'Burgers · Fast food' |
| `description` | TEXT | Short description |
| `address` | TEXT | e.g. 'Colombo 03' |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() |

#### `Menu_Items` — Food items per restaurant
| Column | Type | Notes |
|--------|------|-------|
| `id` | TEXT (PK) | e.g. `menu-bh-classic` |
| `restaurant_id` | TEXT (FK) | References `Restaurants.id` ON DELETE CASCADE |
| `name` | TEXT | NOT NULL |
| `image_url` | TEXT | Unsplash CDN |
| `price` | DECIMAL(10,2) | NOT NULL |
| `rating` | DECIMAL(3,1) | DEFAULT 4.5 |
| `category` | TEXT | e.g. 'Burger', 'Pizza', 'Sides' |
| `description` | TEXT | Short description |
| `sizes` | JSONB | e.g. `["Regular", "Large"]` or `["10\"", "14\"", "16\""]` |
| `ingredients` | JSONB | e.g. `["Beef", "Cheddar", "Lettuce"]` |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() |

#### `Orders` — Customer orders
| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID (PK) | Auto-generated |
| `user_id` | TEXT | NOT NULL |
| `restaurant_id` | TEXT | NOT NULL |
| `restaurant_name` | TEXT | Denormalized for display |
| `status` | TEXT | DEFAULT 'pending' (accepted/preparing/ready/on_the_way/delivered/cancelled) |
| `subtotal` | DECIMAL(10,2) | NOT NULL |
| `delivery_fee` | DECIMAL(10,2) | DEFAULT 0 |
| `total` | DECIMAL(10,2) | NOT NULL |
| `delivery_address` | TEXT | NOT NULL |
| `delivery_phone` | TEXT | |
| `delivery_notes` | TEXT | |
| `payment_method` | TEXT | DEFAULT 'cash' |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() |
| `updated_at` | TIMESTAMPTZ | DEFAULT NOW() |

#### `Order_Items` — Line items per order
| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID (PK) | Auto-generated |
| `order_id` | UUID (FK) | References `Orders.id` ON DELETE CASCADE |
| `food_item_id` | TEXT | |
| `name` | TEXT | NOT NULL |
| `price` | DECIMAL(10,2) | NOT NULL |
| `quantity` | INT | DEFAULT 1 |
| `selected_size` | TEXT | e.g. 'Large', '14"' |
| `image_url` | TEXT | |

### 4.2 Row Level Security (RLS)

All tables have RLS enabled with open "Allow all" policies (development mode). Production-ready policies need to be added before deployment.

### 4.3 Realtime

`Orders` table is added to Supabase Realtime publication for live order tracking.

### 4.4 Seed Data

3 restaurants + 9 menu items pre-loaded with Sri Lankan locale addresses:
- **Burger House** (Colombo 03) — 3 items (Classic Smash Burger, Crispy Chicken Burger, Loaded Fries)
- **Pizza Palace** (Colombo 05) — 3 items (Margherita, Pepperoni Feast, Garlic Bread)
- **Green Bowl Cafe** (Colombo 07) — 3 items (Buddha Bowl, Grilled Chicken Wrap, Berry Smoothie)

---

## 5. Navigation Flow

```
SplashScreen
  └─► OnboardingScreen (first time users)
        └─► PhoneAuthScreen
              └─► VerificationScreen (OTP: 1234)
                    └─► ProfileSetupScreen
                          └─► HomeScreen
                                ├─► SearchScreen
                                ├─► DetailsScreen / RestaurantViewScreen
                                │     └─► FoodDetailScreen
                                │           └─► CartScreen
                                ├─► CartScreen
                                │     └─► DeliveryAddressScreen
                                │           ├─► LocationPickerScreen (map)
                                │           └─► CheckoutScreen
                                │                 └─► OrderPlacedScreen
                                │                       └─► OrderTrackingScreen (realtime)
                                ├─► OrderHistoryScreen
                                └─► ProfileScreen
```

### Route Names (`AppRoutes`)
```
/                          → splash
/onboarding                → onboarding
/phone-auth                → phoneAuth
/verification              → verification
/profile-setup             → profileSetup
/home                      → home
/search                    → search
/restaurant                → restaurantDetails
/food                      → foodDetail
/cart                      → cart
/delivery-address          → deliveryAddress
/checkout                  → checkout
/order-placed              → orderPlaced
/order-tracking            → orderTracking
/order-history             → orderHistory
/profile                   → profile
/location-picker           → locationPicker
```

Navigation is handled by `BuyerNavigator` (lib/navigation/buyer_navigator.dart) — every screen transition has a static method.

---

## 6. Services Detail

### 6.1 AuthService (`lib/services/auth_service.dart`)
- **Phone OTP Login:** Uses `supabase.auth.verifyOTP()` with SMS type
- **Dummy OTP:** For testing without real SMS, returns hardcoded `1234`
- **Profile Save:** Upserts to `Profiles` table via Supabase
- **User ID:** Generates UUID-v4 if no authenticated user
- **User Check:** `checkUserExists()` checks Profiles table by phone

### 6.2 DatabaseService (`lib/services/database_service.dart`)
- **getRestaurants():** Fetches all rows from `Restaurants` table
- **getMenuItems(restaurantId):** Fetches items from `Menu_Items` filtered by restaurant
- **search(query):** Client-side text matching across restaurant names, categories, and food names
- **foodItemFromMenuRow():** Factory to convert Supabase row JSON to `FoodItem` model
- **foodItemFromMenuAndRestaurant():** Combines menu item + restaurant data into FoodItem
- Uses `Supabase.instance.client` singleton

### 6.3 OrderService (`lib/services/order_service.dart`)
- **placeOrder():** Inserts into `Orders` + `Order_Items` tables
- **getUserOrders():** Fetches user's orders ordered by created_at DESC
- **getOrder():** Fetches single order by ID
- **getOrderItems():** Fetches line items for an order
- **watchOrder():** Supabase Realtime stream for live order status updates
- ⚠️ **BUG:** Uses `from('Order')` but table name is `Orders` (plural). May fail at runtime.

### 6.4 LocalStorageService (`lib/services/local_storage_service.dart`)
- Wraps `SharedPreferences` for:
  - Profile completion status + user info (id, name, phone)
  - Delivery address (label, address, phone)
  - Session management (`clearSession()`)

### 6.5 GoogleMapsService (`lib/services/google_maps_service.dart`)
- **Autocomplete:** Google Places API → Nominatim OSM → Mock (hardcoded LK locations)
- **Geocoding:** Google Geocode → Nominatim Reverse → Geocoding package → Coordinates fallback
- **Mock Locations:** 9 Sri Lankan addresses (Colombo, Moratuwa, Kotte, Nugegoda, etc.)
- Multi-tier fallback ensures app works without Google Maps API key

---

## 7. Data Models (`lib/models/models.dart`)

| Model | Fields | Notes |
|-------|--------|-------|
| `Restaurant` | id, name, imageUrl, rating, freeDelivery, deliveryMin, category, description, address | fromJson/toJson |
| `FoodItem` | id, name, imageUrl, price, rating, freeDelivery, deliveryMin, restaurantName, restaurantId, category, description, sizes, ingredients | fromJson/toJson |
| `FoodCategory` | id, name, emoji, isSelected | copyWith for selection toggle |
| `CartItem` | food (FoodItem), quantity, selectedSize | total = price × quantity |
| `OrderStatus` | enum: pending/accepted/preparing/ready/on_the_way/delivered/cancelled | has label, stepIndex |
| `Order` | id, userId, restaurantId, restaurantName, status, subtotal, deliveryFee, total, deliveryAddress, deliveryPhone, etc. | fromJson/toJson |
| `OrderItemLine` | id, orderId, foodItemId, name, price, quantity, selectedSize, imageUrl | lineTotal = price × quantity |
| `Offer` | id, code, discountPercent, description | fromJson |

Helper functions: `_toDouble()`, `_toInt()` — null-safe parsing with fallback values.

---

## 8. State Management — CartProvider

`lib/providers/cart_provider.dart` (56 lines)

```dart
class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);
  double get subtotal => _items.fold(0, (sum, i) => sum + i.total);
  double get deliveryFee => _items.any((i) => !i.food.freeDelivery) ? 5.0 : 0.0;
  double get total => subtotal + deliveryFee;
  
  void addItem(FoodItem food, {String size = '10"'}) { ... }
  void removeItem(String foodId, String size) { ... }
  void clearCart() { ... }
  int getQuantity(String foodId) { ... }
}
```

- Items are unique by `food.id + size` combination
- `addItem`: If same food+size exists, increments quantity; otherwise adds new CartItem
- `removeItem`: If quantity > 1, decrements; otherwise removes item completely
- `clearCart`: Empties all items
- Provider is registered in `main.dart` via `MultiProvider`

---

## 9. Widgets Library

### `common_widgets.dart`
| Widget | Purpose |
|--------|---------|
| `AppNetworkImage` | CachedNetworkImage wrapper with shimmer placeholder |
| `InfoRow` | Icon + text row (for restaurant info display) |
| `RestaurantCard` | Restaurant card with image, rating, delivery time, free badge |
| `FoodCard` | Food item card with add-to-cart button |
| `CategoryChip` | Category filter chip with emoji |
| `AddButton` | Circular +/- quantity button |
| `SectionHeader` | Title + "See All" action row |
| `ShimmerList` | Loading skeleton placeholder |

### Other Widgets
| File | Widgets |
|------|---------|
| `auth_header.dart` | Dark blue header with title, subtitle, back button |
| `custom_button.dart` | Orange `ElevatedButton` — full width |
| `custom_input.dart` | TextFormField with animated password visibility toggle |
| `dark_widgets.dart` | `DarkTextField`, `OrangeButton`, `SocialButton` |

---

## 10. Theme (`lib/theme/app_theme.dart`)

### Color Palette
| Name | Hex | Usage |
|------|-----|-------|
| `orange` | `#FF6B35` | Primary brand color, buttons |
| `orangeLight` | `#FFF3EE` | Light orange backgrounds |
| `darkBg` | `#1A1A2E` | Dark backgrounds (auth screens) |
| `white` | `#FFFFFF` | Cards, app bar |
| `lightBg` | `#F5F5F5` | Scaffold background |
| `grey` | `#888888` | Text, icons |
| `greyLight` | `#EEEEEE` | Dividers, borders |
| `dark` | `#1C1C1C` | Primary text |
| `star` | `#FFC107` | Rating stars |
| `green` | `#4CAF50` | Success indicators |

### Theme Configuration
- Material 3 enabled
- Color scheme seeded from orange
- Font: **Nunito** (via Google Fonts)
- AppBar: white background, no elevation
- ElevatedButton: orange background, white text, 12px rounded corners

---

## 11. Dependencies

### Flutter/Dart (`pubspec.yaml`)
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter` | SDK | Core framework |
| `google_fonts` | ^6.1.0 | Nunito font |
| `smooth_page_indicator` | ^1.1.0 | Onboarding carousel dots |
| `supabase_flutter` | ^2.12.4 | Supabase backend (auth + DB + realtime) |
| `cached_network_image` | ^3.3.1 | Image caching with placeholders |
| `provider` | ^6.1.1 | State management |
| `shimmer` | ^3.0.0 | Skeleton loading animation |
| `shared_preferences` | ^2.2.2 | Local key-value storage |
| `intl` | ^0.19.0 | Date/number formatting |
| `flutter_map` | ^6.1.0 | OpenStreetMap widget (location picker) |
| `latlong2` | ^0.9.0 | LatLng data type |
| `geolocator` | ^11.0.0 | Device GPS |
| `geocoding` | ^3.0.0 | Address ⟷ coordinates |

**Dev Dependencies:** `flutter_test`, `flutter_lints: ^3.0.0`

### Node.js (`package.json`) — Not used by Flutter app
| Package | Version |
|---------|---------|
| `@supabase/ssr` | ^0.10.2 |
| `@supabase/supabase-js` | ^2.103.3 |

---

## 12. Known Issues & TODOs

| Issue | Location | Description |
|-------|----------|-------------|
| 🐛 Table name mismatch | `order_service.dart:45,71,83,99` | Uses `from('Order')` but schema has `Orders` (plural) |
| 🐛 Table name mismatch | `order_service.dart:61,90` | Uses `from('Order_Items')` — this one matches schema |
| 📝 Empty test directory | `test/` | No automated tests written yet |
| 📝 Empty assets | `assets/images/` | All images come from Unsplash CDN URLs |
| 🔑 Hardcoded Supabase keys | `app_constants.dart` | Anon key is public (fine), but should use env vars for production |
| 🔑 Missing Google Maps key | `app_constants.dart:6` | Falls back to OSM Nominatim + mock data |
| ⚠️ RLS open policies | `supabase_schema.sql` | All tables have "Allow all" — production needs proper policies |
| 📝 No error handling on Supabase connect failure | Various services | Try-catch exists but no user-facing error UI |

---

## 13. Setup Instructions

### Prerequisites
- Flutter SDK (≥3.0.0, <4.0.0)
- Supabase account (free tier)
- Android Studio / VS Code with Flutter plugin

### Step-by-Step

```bash
# 1. Clone & get dependencies
cd E:\Projects\Alee-App
flutter pub get

# 2. Supabase setup
#    • Go to https://supabase.com → Create project
#    • SQL Editor → New Query → Paste supabase_schema.sql → Run
#    • Project Settings → API → Copy URL + anon key
#    • Update lib/constants/app_constants.dart with your keys

# 3. Run
flutter run
```

### Dummy OTP
Testing OTP is hardcoded as `1234`. Enter `1234` in the verification screen.

---

## 14. Test Order Flow

1. App launch → Splash → Onboarding → Phone Auth (enter any number) → Enter OTP `1234`
2. Complete profile → Home Screen loads
3. Browse restaurants → Open restaurant → Tap food item → Select size → Add to Cart
4. Cart → Proceed to Checkout → Enter delivery address → Place Order
5. Order Placed screen → Track Order (real-time status from Supabase)
6. Check Supabase Database → `Orders` table should show your order with status `pending`

---

## 15. Platform-Specific Notes

| Platform | Key Config |
|----------|-----------|
| **Android** | Package: `aleeapp` · Permissions: INTERNET, ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION · Min SDK from Gradle |
| **iOS** | Standard Flutter iOS setup · Location permissions needed for geolocator |
| **Web** | PWA manifest included · `flutter_bootstrap.js` entry |
| **Desktop** (Windows/Linux) | C++ Flutter embedding · CMake build · Win32 native window |

---

## 16. Code Conventions

- **Comments:** Sinhala + English mix
- **File naming:** `snake_case.dart`
- **Class naming:** `PascalCase`
- **Constants:** `camelCase` (e.g. `freeDelivery`, `selectedSize`)
- **Imports:** Grouped — Dart SDK first, then packages, then project files
- **const constructors:** Used where possible
- **No code generation:** All models are hand-written with `fromJson`/`toJson` factories

---

*Last updated: 2026-06-27*
