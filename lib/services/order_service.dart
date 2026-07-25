import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../providers/cart_provider.dart';

class OrderService {
  static final SupabaseClient _client = Supabase.instance.client;

  static String _getUserId() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Please sign in to place an order.');
    }
    return user.id;
  }

  static Future<Order> placeOrder({
    required CartProvider cart,
    required String deliveryAddress,
    required String deliveryPhone,
    String? deliveryNotes,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? savedAddressId,
    String paymentMethod = 'cash',
    String? promoCode,
    double discount = 0,
    DateTime? scheduledAt,
    double tip = 0,
    double deliveryFee = 0,
  }) async {
    _getUserId();

    if (cart.items.isEmpty) {
      throw Exception('Your cart is empty.');
    }

    final firstItem = cart.items.first.food;
    final restaurantId = firstItem.restaurantId;
    final restaurantName = firstItem.restaurantName;

    if (restaurantId.isEmpty) {
      throw Exception('Restaurant information is missing.');
    }

    if (deliveryAddress.trim().isEmpty) {
      throw Exception('Delivery address is required.');
    }

    if (deliveryPhone.trim().isEmpty) {
      throw Exception('Delivery phone number is required.');
    }

    final items = cart.items
        .map((item) => {
              'food_item_id': item.food.id,
              'name': item.food.name,
              'price': item.food.price,
              'quantity': item.quantity,
              'selected_size': item.selectedSize,
              'image_url': item.food.imageUrl,
            })
        .toList();

    try {
      final params = <String, dynamic>{
        'p_restaurant_id': restaurantId,
        'p_restaurant_name': restaurantName,
        'p_items': items,
        'p_delivery_address': deliveryAddress.trim(),
        'p_delivery_phone': deliveryPhone.trim(),
        'p_delivery_latitude': deliveryLatitude,
        'p_delivery_longitude': deliveryLongitude,
        'p_delivery_notes': deliveryNotes?.trim(),
        'p_payment_method': paymentMethod,
        'p_saved_address_id': savedAddressId,
        'p_delivery_fee': deliveryFee,
        'p_promo_code': promoCode,
        'p_discount': discount,
        'p_scheduled_at': scheduledAt?.toUtc().toIso8601String(),
        'p_tip': tip,
      };

      params.removeWhere((key, value) => value == null);

      final response =
          await _client.rpc('create_customer_order', params: params);

      if (response == null) {
        throw Exception('The order could not be created. Please try again.');
      }

      Order order;

      if (response is Map) {
        order = Order.fromJson(Map<String, dynamic>.from(response));
      } else {
        throw Exception('Invalid response from server.');
      }

      debugPrint('[OrderService] Order placed: ${order.id}');
      return order;
    } on PostgrestException catch (e) {
      debugPrint('[OrderService] Database error: ${e.message}');
      throw Exception(_friendlyError(e.message));
    } catch (e) {
      debugPrint('[OrderService] Error: $e');
      rethrow;
    }
  }

  static Future<List<Order>> getUserOrders({int limit = 50}) async {
    final userId = _getUserId();
    try {
      final response = await _client
          .from('Orders')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((o) => Order.fromJson(Map<String, dynamic>.from(o)))
          .toList();
    } catch (e) {
      debugPrint('[OrderService] getUserOrders error: $e');
      return [];
    }
  }

  static Future<Order?> getOrder(String orderId) async {
    try {
      final response =
          await _client.from('Orders').select().eq('id', orderId).maybeSingle();
      if (response == null) return null;
      return Order.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      debugPrint('[OrderService] getOrder error: $e');
      return null;
    }
  }

  static Future<List<OrderItemLine>> getOrderItems(String orderId) async {
    try {
      final response =
          await _client.from('Order_Items').select().eq('order_id', orderId);

      return (response as List)
          .map((i) => OrderItemLine.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    } catch (e) {
      debugPrint('[OrderService] getOrderItems error: $e');
      return [];
    }
  }

  static Future<void> cancelOrder(String orderId) async {
    try {
      await _client.rpc('cancel_customer_order', params: {
        'p_order_id': orderId,
      });
      debugPrint('[OrderService] Order cancelled: $orderId');
    } on PostgrestException catch (e) {
      throw Exception(_friendlyError(e.message));
    } catch (e) {
      debugPrint('[OrderService] cancelOrder error: $e');
      rethrow;
    }
  }

  static Stream<Order?> watchOrder(String orderId) {
    return _client
        .from('Orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .map((rows) {
          if (rows.isEmpty) return null;
          return Order.fromJson(Map<String, dynamic>.from(rows.first));
        });
  }

  static String _friendlyError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('authentication required')) {
      return 'Please sign in to continue.';
    }
    if (lower.contains('cart is empty')) {
      return 'Your cart is empty. Add items before placing an order.';
    }
    if (lower.contains('duplicate') || lower.contains('already exists')) {
      return 'This order was already submitted.';
    }
    if (lower.contains('not found')) {
      return 'Order not found. It may have been removed.';
    }
    if (lower.contains('permission denied') ||
        lower.contains('violates row-level security')) {
      return 'You do not have permission to perform this action.';
    }
    return 'Something went wrong. Please try again.';
  }
}
