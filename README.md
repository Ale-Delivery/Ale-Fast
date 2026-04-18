# 🍔 Food App — Flutter UI

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── theme/
│   └── app_theme.dart                 # Colors & theme
├── screens/
│   ├── splash_screen.dart             # Animated splash
│   ├── onboarding_screen.dart         # 3-slide onboarding
│   ├── login_screen.dart              # Login with social buttons
│   ├── signup_screen.dart             # Sign up form
│   ├── verification_screen.dart       # OTP with custom numpad
│   └── forgot_password_screen.dart    # Forgot password
└── widgets/
    └── dark_widgets.dart              # Reusable: DarkTextField, OrangeButton, SocialButton
```

## Setup

### 1. Flutter install කරන්න (නොතිබේ නම්)
https://docs.flutter.dev/get-started/install

### 2. Project create කරන්න
```bash
flutter create food_app
cd food_app
```

### 3. Files copy කරන්න
ඔය zip එකේ files ටික `lib/` folder එකට copy කරන්න, `pubspec.yaml` root එකට.

### 4. Dependencies install කරන්න
```bash
flutter pub get
```

### 5. Run කරන්න
```bash
flutter run
```

## Dependencies

| Package | Use |
|---------|-----|
| `google_fonts` | Nunito font |
| `smooth_page_indicator` | Onboarding dots animation |

## Screen Flow

```
SplashScreen (3s)
    └── OnboardingScreen
            └── LoginScreen ──── ForgotPasswordScreen
                    │                     └── VerificationScreen
                    └── SignupScreen
                            └── VerificationScreen
```

## Colors

| Name | Hex |
|------|-----|
| Orange (primary) | `#FF6B35` |
| Dark Background | `#1A1A2E` |
| White | `#FFFFFF` |
| Light Background | `#F0F2F5` |
