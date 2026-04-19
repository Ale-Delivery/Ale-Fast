import 'package:flutter/foundation.dart';
import '../models/models.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);

  double get subtotal => _items.fold(0, (sum, i) => sum + i.total);

  double get deliveryFee => _items.any((i) => !i.food.freeDelivery) ? 5.0 : 0.0;

  double get total => subtotal + deliveryFee;

  void addItem(FoodItem food, {String size = '10"'}) {
    final idx = _items.indexWhere(
        (i) => i.food.id == food.id && i.selectedSize == size);
    if (idx >= 0) {
      _items[idx].quantity++;
    } else {
      _items.add(CartItem(food: food, selectedSize: size));
    }
    notifyListeners();
  }

  void removeItem(String foodId, String size) {
    final idx = _items.indexWhere(
        (i) => i.food.id == foodId && i.selectedSize == size);
    if (idx >= 0) {
      if (_items[idx].quantity > 1) {
        _items[idx].quantity--;
      } else {
        _items.removeAt(idx);
      }
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  int getQuantity(String foodId) {
    final item = _items.where((i) => i.food.id == foodId);
    return item.isEmpty ? 0 : item.first.quantity;
  }
}
