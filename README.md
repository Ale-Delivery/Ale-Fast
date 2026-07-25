# Ale Fast — Flutter + Supabase Customer App

> **IMPORTANT: Database Security**
>
> `supabase_schema.sql` is for **LOCAL DEVELOPMENT BOOTSTRAP ONLY**.
> Production schema changes must be managed through **Ale-Backend** Supabase migrations.
> Running `supabase_schema.sql` against production will overwrite secure RLS policies.
>
> See `tools/check_rls_security.ps1` to validate SQL files for unsafe patterns.

## Screens included

| Screen | File |
|--------|------|
| Splash | `splash_screen.dart` |
| Onboarding | `onboarding_screen.dart` |
| Login | `phone_auth_screen.dart` |
| Verification OTP | `verification_screen.dart` |
| Home | `home_screen.dart` |
| Search | `search_screen.dart` |
| Food Detail | `food_detail_screen.dart` |
| Restaurant View | `restaurant_view_screen.dart` |
| Cart | `cart_screen.dart` |

## Setup — Step by Step

### Step 1: Get dependencies
```bash
flutter pub get
```

### Step 2: Local Supabase setup (development only)
1. Create a Supabase project at https://supabase.com
2. Open **SQL Editor** → **New Query**
3. Paste and run `supabase_schema.sql`
4. Copy your **Project URL** and **anon public key**

### Step 3: Configure credentials
Update `lib/constants/app_constants.dart`:
```dart
static const String supabaseUrl = 'https://xxxx.supabase.co';
static const String supabaseAnonKey = 'eyJhbGc...';
```

### Step 4: Run
```bash
flutter run
```

## Supabase Tables

| Table | Purpose |
|-------|---------|
| `Restaurants` | Restaurant data |
| `Menu_Items` | Menu items |
| `Orders` | User orders |
| `Order_Items` | Items per order |
| `Reviews` | Customer reviews |
| `Saved_Addresses` | User delivery addresses |

## RLS Security

All tables have Row Level Security enabled with scoped policies.

**Principle of least privilege:**
- Customers can read public data (restaurants, menu items, reviews)
- Customers can write only their own orders, profiles, addresses, and reviews
- Merchants can write only their own restaurant and menu items
- No `OR true` bypasses exist in any policy
- Reviews are immutable after creation (no UPDATE/DELETE)

Run `tools/check_rls_security.ps1` to validate SQL policies.

## Dependencies

```yaml
supabase_flutter: ^2.12.4
cached_network_image: ^3.3.1
provider: ^6.1.1
shimmer: ^3.0.0
google_fonts: ^6.1.0
intl: ^0.19.0
flutter_map: ^6.1.0
geolocator: ^14.0.2
geocoding: ^4.0.0
lucide_icons_flutter: ^3.1.15
```
