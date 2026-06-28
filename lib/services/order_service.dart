import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../providers/cart_provider.dart';
import 'local_storage_service.dart';

class OrderService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Places order with status `pending` so seller app can accept.
  static Future<Order> placeOrder({
    required CartProvider cart,
    required String deliveryAddress,
    required String deliveryPhone,
    String? deliveryNotes,
    String paymentMethod = 'cash',
  }) async {
    if (cart.items.isEmpty) {
      throw Exception('Cart is empty');
    }

    final userId = await LocalStorageService.getUserId();
    if (userId == null || userId.isEmpty) {
      throw Exception('Please complete your profile first');
    }

    final firstItem = cart.items.first.food;
    final restaurantId = firstItem.restaurantId;
    final restaurantName = firstItem.restaurantName;

    final orderData = {
      'user_id': userId,
      'restaurant_id': restaurantId,
      'restaurant_name': restaurantName,
      'status': OrderStatus.pending.value,
      'subtotal': cart.subtotal,
      'delivery_fee': cart.deliveryFee,
      'total': cart.total,
      'delivery_address': deliveryAddress,
      'delivery_phone': deliveryPhone,
      'delivery_notes': deliveryNotes,
      'payment_method': paymentMethod,
    };

    final orderResponse =
        await _client.from('Orders').insert(orderData).select().single();

    final orderId = orderResponse['id']?.toString() ?? '';

    final orderItems = cart.items
        .map((item) => {
              'order_id': orderId,
              'food_item_id': item.food.id,
              'name': item.food.name,
              'price': item.food.price,
              'quantity': item.quantity,
              'selected_size': item.selectedSize,
              'image_url': item.food.imageUrl,
            })
        .toList();

    await _client.from('Order_Items').insert(orderItems);

    return Order.fromJson(Map<String, dynamic>.from(orderResponse));
  }

  static Future<List<Order>> getUserOrders() async {
    final userId = await LocalStorageService.getUserId();
    if (userId == null) return [];

    final response = await _client
        .from('Orders')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((o) => Order.fromJson(Map<String, dynamic>.from(o)))
        .toList();
  }

  static Future<Order?> getOrder(String orderId) async {
    final response =
        await _client.from('Orders').select().eq('id', orderId).maybeSingle();
    if (response == null) return null;
    return Order.fromJson(Map<String, dynamic>.from(response));
  }

  static Future<List<OrderItemLine>> getOrderItems(String orderId) async {
    final response =
        await _client.from('Order_Items').select().eq('order_id', orderId);

    return (response as List)
        .map((i) => OrderItemLine.fromJson(Map<String, dynamic>.from(i)))
        .toList();
  }

  /// Buyer can cancel if order is pending or accepted (before restaurant starts preparing).
  static Future<void> cancelOrder(String orderId) async {
    await _client
        .from('Orders')
        .update({'status': OrderStatus.cancelled.value})
        .eq('id', orderId);
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
}
