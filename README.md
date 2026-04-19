# 🍔 Food App V2 — Flutter + Supabase

## Screens included

| Screen | File |
|--------|------|
| Splash | `splash_screen.dart` (Part 1 ekn copy karanna) |
| Onboarding | `onboarding_screen.dart` (Part 1 ekn copy karanna) |
| Login | `login_screen.dart` (Part 1 ekn copy karanna) |
| Sign Up | `signup_screen.dart` (Part 1 ekn copy karanna) |
| Verification OTP | `verification_screen.dart` (Part 1 ekn copy karanna) |
| Forgot Password | `forgot_password_screen.dart` (Part 1 ekn copy karanna) |
| **Home** | `home_screen.dart` ✅ |
| **Search** | `search_screen.dart` ✅ |
| **Food Detail** | `food_detail_screen.dart` ✅ |
| **Restaurant View** | `restaurant_view_screen.dart` ✅ |
| **Cart** | `cart_screen.dart` ✅ |

## Project Structure

```
lib/
├── main.dart
├── theme/
│   └── app_theme.dart         # Colors, theme, constants
├── models/
│   └── models.dart            # Restaurant, FoodItem, CartItem, Offer
├── services/
│   └── database_service.dart  # Supabase queries + mock fallback
├── providers/
│   └── cart_provider.dart     # Cart state management
├── widgets/
│   └── common_widgets.dart    # Reusable UI components
└── screens/
    ├── home_screen.dart
    ├── search_screen.dart
    ├── food_detail_screen.dart
    ├── restaurant_view_screen.dart
    └── cart_screen.dart
```

---

## Setup — Step by Step

### Step 1: Full project create karanna
```bash
flutter create food_app
cd food_app
```

### Step 2: Part 1 + Part 2 files copy karanna
`lib/` folder ekata files copy karanna. `pubspec.yaml` replace karanna.

### Step 3: Dependencies install karanna
```bash
flutter pub get
```

### Step 4: Supabase setup karanna

1. **https://supabase.com** gihilla free account hadanna
2. "New project" click karanna
3. Project create unama → **SQL Editor** → **New Query**
4. `supabase_schema.sql` file eke SQL eka paste karala **Run** karanna
5. **Project Settings → API** gihilla:
   - `Project URL` copy karanna
   - `anon public` key copy karanna

### Step 5: App ekata add karanna
`lib/theme/app_theme.dart` file eke:
```dart
static const String supabaseUrl = 'https://xxxx.supabase.co';  // ← oya url
static const String supabaseAnonKey = 'eyJhbGc...';             // ← oya key
```

### Step 6: Run!
```bash
flutter run
```

---

## Features

- ✅ **Mock data fallback** — Supabase connect nathnam local data use karanawa
- ✅ **Cart state** — Provider pakagaya use karala real-time cart
- ✅ **Shimmer loading** — Images load wenakan skeleton animation
- ✅ **Offer popup** — Auto-shows on home screen after 2 seconds
- ✅ **Category filter** — Click karala restaurants/food filter karana
- ✅ **Search** — Real-time Supabase search with suggestions
- ✅ **Cached images** — Once loaded images re-download wenne na
- ✅ **Size selector** — Food detail screen eke size choose karana

## Supabase Tables

| Table | Purpose |
|-------|---------|
| `restaurants` | Restaurant data |
| `food_items` | Menu items |
| `offers` | Promo codes & discounts |
| `orders` | User orders |
| `order_items` | Items per order |

---

## Dependencies

```yaml
supabase_flutter: ^2.3.4       # Database
cached_network_image: ^3.3.1   # Image caching
provider: ^6.1.1               # State management
shimmer: ^3.0.0                # Loading animation
google_fonts: ^6.1.0           # Nunito font
smooth_page_indicator: ^1.1.0  # Onboarding dots
flutter_rating_bar: ^4.0.1     # Star ratings
shared_preferences: ^2.2.2     # Local storage
```
