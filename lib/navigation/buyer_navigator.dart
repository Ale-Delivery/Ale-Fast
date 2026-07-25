import 'package:flutter/material.dart';
import '../models/models.dart';
import '../screens/cart_screen.dart';
import '../screens/checkout_screen.dart';
import '../screens/delivery_address_screen.dart';
import '../screens/details_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/food_detail_screen.dart';
import '../screens/food_screen.dart';
import '../screens/help_support_screen.dart';
import '../screens/home_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/order_history_screen.dart';
import '../screens/order_placed_screen.dart';
import '../screens/order_tracking_screen.dart';
import '../screens/parcel_screen.dart';
import '../screens/grocery_screen.dart';
import '../screens/phone_auth_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/profile_setup_screen.dart';
import '../screens/review_screen.dart';
import '../screens/rides_screen.dart';
import '../screens/search_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/verification_screen.dart';
import '../screens/location_picker_screen.dart';
import '../screens/chat_screen.dart';
import 'app_routes.dart';

/// Central navigation for the buyer app final flow.
class BuyerNavigator {
  BuyerNavigator._();

  static Route<T> _route<T>(Widget page, {String? name}) {
    return MaterialPageRoute<T>(
      builder: (_) => page,
      settings: name != null ? RouteSettings(name: name) : null,
    );
  }

  // ── Auth flow ─────────────────────────────────────────────────
  static void splash(BuildContext context) {
    Navigator.of(context).pushReplacement(
      _route(const SplashScreen(), name: AppRoutes.splash),
    );
  }

  static void onboarding(BuildContext context, {bool replace = true}) {
    final route = _route(const OnboardingScreen(), name: AppRoutes.onboarding);
    if (replace) {
      Navigator.of(context).pushReplacement(route);
    } else {
      Navigator.of(context).push(route);
    }
  }

  static void phoneAuth(BuildContext context, {bool replace = true}) {
    final route = _route(const PhoneAuthScreen(), name: AppRoutes.phoneAuth);
    if (replace) {
      Navigator.of(context).pushReplacement(route);
    } else {
      Navigator.of(context).push(route);
    }
  }

  static void verification(
    BuildContext context, {
    required String phoneNumber,
  }) {
    Navigator.of(context).push(
      _route(
        VerificationScreen(
          phoneNumber: phoneNumber,
        ),
        name: AppRoutes.verification,
      ),
    );
  }

  static void profileSetup(BuildContext context, {bool clearStack = true}) {
    final route =
        _route(const ProfileSetupScreen(), name: AppRoutes.profileSetup);
    if (clearStack) {
      Navigator.of(context).pushAndRemoveUntil(route, (_) => false);
    } else {
      Navigator.of(context).push(route);
    }
  }

  static void home(BuildContext context, {bool clearStack = true}) {
    final route = _route(const HomeScreen(), name: AppRoutes.home);
    if (clearStack) {
      Navigator.of(context).pushAndRemoveUntil(route, (_) => false);
    } else {
      Navigator.of(context).pushReplacement(route);
    }
  }

  // ── Browse & order ────────────────────────────────────────────
  static Future<void> search(BuildContext context) {
    return Navigator.of(context).push(
      _route(const SearchScreen(), name: AppRoutes.search),
    );
  }

  static void restaurantDetails(
    BuildContext context,
    Map<String, dynamic> restaurant,
  ) {
    Navigator.of(context).push(
      _route(
        DetailsScreen(restaurant: restaurant),
        name: AppRoutes.restaurantDetails,
      ),
    );
  }

  static void foodDetail(BuildContext context, FoodItem food) {
    Navigator.of(context).push(
      _route(FoodDetailScreen(food: food), name: AppRoutes.foodDetail),
    );
  }

  static Future<void> cart(BuildContext context) {
    return Navigator.of(context).push(
      _route(const CartScreen(), name: AppRoutes.cart),
    );
  }

  static Future<void> deliveryAddress(
    BuildContext context, {
    bool proceedToCheckout = true,
  }) {
    return Navigator.of(context).push(
      _route(
        DeliveryAddressScreen(proceedToCheckout: proceedToCheckout),
        name: AppRoutes.deliveryAddress,
      ),
    );
  }

  static void checkout(
    BuildContext context, {
    required String deliveryAddress,
    required String deliveryPhone,
    String? deliveryNotes,
    String addressLabel = 'Home',
  }) {
    Navigator.of(context).push(
      _route(
        CheckoutScreen(
          deliveryAddress: deliveryAddress,
          deliveryPhone: deliveryPhone,
          deliveryNotes: deliveryNotes,
          addressLabel: addressLabel,
        ),
        name: AppRoutes.checkout,
      ),
    );
  }

  static void orderPlaced(BuildContext context, Order order) {
    Navigator.of(context).pushAndRemoveUntil(
      _route(OrderPlacedScreen(order: order), name: AppRoutes.orderPlaced),
      (route) => route.isFirst,
    );
  }

  static void orderTracking(BuildContext context, String orderId) {
    Navigator.of(context).push(
      _route(
        OrderTrackingScreen(orderId: orderId),
        name: AppRoutes.orderTracking,
      ),
    );
  }

  static void chat(BuildContext context, String orderId, String orderName) {
    Navigator.of(context).push(
      _route(
        ChatScreen(orderId: orderId, orderName: orderName),
        name: AppRoutes.chat,
      ),
    );
  }

  static Future<void> orderHistory(BuildContext context) {
    return Navigator.of(context).push(
      _route(const OrderHistoryScreen(), name: AppRoutes.orderHistory),
    );
  }

  static Future<void> profile(BuildContext context) {
    return Navigator.of(context).push(
      _route(const ProfileScreen(), name: AppRoutes.profile),
    );
  }

  static Future<Map<String, dynamic>?> locationPicker(BuildContext context) {
    return Navigator.of(context).push<Map<String, dynamic>?>(
      _route(const LocationPickerScreen(), name: AppRoutes.locationPicker),
    );
  }

  // ── New features ─────────────────────────────────────────────
  static Future<void> favorites(BuildContext context) {
    return Navigator.of(context).push(
      _route(const FavoritesScreen(), name: AppRoutes.favorites),
    );
  }

  static Future<void> notifications(BuildContext context) {
    return Navigator.of(context).push(
      _route(const NotificationsScreen(), name: AppRoutes.notifications),
    );
  }

  static void review(
      BuildContext context, String orderId, String restaurantId) {
    Navigator.of(context).push(
      _route(
        ReviewScreen(orderId: orderId, restaurantId: restaurantId),
        name: AppRoutes.review,
      ),
    );
  }

  static Future<void> helpSupport(BuildContext context) {
    return Navigator.of(context).push(
      _route(const HelpSupportScreen(), name: AppRoutes.helpSupport),
    );
  }

  static Future<void> rides(BuildContext context) {
    return Navigator.of(context).push(
      _route(const RidesScreen(), name: AppRoutes.rides),
    );
  }

  static Future<void> parcel(BuildContext context) {
    return Navigator.of(context).push(
      _route(const ParcelScreen(), name: AppRoutes.parcel),
    );
  }

  static Future<void> food(BuildContext context) {
    return Navigator.of(context).push(
      _route(const FoodScreen(), name: AppRoutes.foodDetail),
    );
  }

  static Future<void> grocery(BuildContext context) {
    return Navigator.of(context).push(
      _route(const GroceryScreen(), name: AppRoutes.grocery),
    );
  }
}
