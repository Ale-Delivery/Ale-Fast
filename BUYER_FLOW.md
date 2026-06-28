# Buyer App — Final Flow

## Navigation map

```
Splash
  └─► Onboarding (first time)
        └─► Phone Auth
              └─► OTP Verification  (mock code: 1234)
                    └─► Profile Setup
                          └─► Home
                                ├─► Search
                                ├─► Restaurant Details
                                │     └─► Food Detail → Cart
                                ├─► Cart
                                │     └─► Delivery Address
                                │           └─► Checkout
                                │                 └─► Order Placed
                                │                       └─► Order Tracking
                                ├─► Order History
                                └─► Profile / Settings
```

## Screen files

| Step | File |
|------|------|
| Splash | `lib/screens/splash_screen.dart` |
| Onboarding | `lib/screens/onboarding_screen.dart` |
| Phone + OTP | `phone_auth_screen.dart`, `verification_screen.dart` |
| Profile | `profile_setup_screen.dart` |
| Home | `home_screen.dart` |
| Search | `search_screen.dart` |
| Restaurant | `details_screen.dart` |
| Food | `food_detail_screen.dart` |
| Cart | `cart_screen.dart` |
| Address | `delivery_address_screen.dart` |
| Checkout | `checkout_screen.dart` |
| Placed | `order_placed_screen.dart` |
| Tracking | `order_tracking_screen.dart` |
| History | `order_history_screen.dart` |
| Profile | `profile_screen.dart` |

## Navigation code

Use `BuyerNavigator` from `lib/navigation/buyer_navigator.dart` for all screen changes.

## Supabase setup

1. Supabase project → **SQL Editor** → New query  
2. Paste and **Run** all of `supabase_schema.sql`  
3. Creates: `Profiles`, `Restaurants`, `Menu_Items`, `Orders`, `Order_Items` + sample data  
4. **Database → Replication** → confirm `Orders` is enabled for Realtime (for track order)  
5. `lib/theme/app_theme.dart` — set your `supabaseUrl` and `supabaseAnonKey`

## Test order (buyer → seller)

1. Complete profile → Home  
2. Open restaurant → add item to cart  
3. Cart → Proceed to Checkout → address → Place Order  
4. Check Supabase `Orders` table — status should be `pending`  
5. Seller app accepts → buyer **Track Order** updates live  
