// ─── Restaurant Model ──────────────────────────────────────────
class Restaurant {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final bool freeDelivery;
  final int deliveryMin;
  final String category;
  final String description;
  final String address;

  const Restaurant({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.freeDelivery,
    required this.deliveryMin,
    required this.category,
    required this.description,
    required this.address,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) => Restaurant(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? '',
        imageUrl: json['image_url'] ?? '',
        rating: (json['rating'] ?? 0).toDouble(),
        freeDelivery: json['free_delivery'] ?? true,
        deliveryMin: json['delivery_min'] ?? 20,
        category: json['category'] ?? '',
        description: json['description'] ?? '',
        address: json['address'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'image_url': imageUrl,
        'rating': rating,
        'free_delivery': freeDelivery,
        'delivery_min': deliveryMin,
        'category': category,
        'description': description,
        'address': address,
      };
}

// ─── Food Item Model ───────────────────────────────────────────
class FoodItem {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final double rating;
  final bool freeDelivery;
  final int deliveryMin;
  final String restaurantName;
  final String restaurantId;
  final String category;
  final String description;
  final List<String> sizes;
  final List<String> ingredients;

  const FoodItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.rating,
    required this.freeDelivery,
    required this.deliveryMin,
    required this.restaurantName,
    required this.restaurantId,
    required this.category,
    required this.description,
    required this.sizes,
    required this.ingredients,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? '',
        imageUrl: json['image_url'] ?? '',
        price: (json['price'] ?? 0).toDouble(),
        rating: (json['rating'] ?? 0).toDouble(),
        freeDelivery: json['free_delivery'] ?? true,
        deliveryMin: json['delivery_min'] ?? 20,
        restaurantName: json['restaurant_name'] ?? '',
        restaurantId: json['restaurant_id']?.toString() ?? '',
        category: json['category'] ?? '',
        description: json['description'] ?? '',
        sizes: List<String>.from(json['sizes'] ?? ['10"', '14"', '16"']),
        ingredients: List<String>.from(json['ingredients'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'image_url': imageUrl,
        'price': price,
        'rating': rating,
        'free_delivery': freeDelivery,
        'delivery_min': deliveryMin,
        'restaurant_name': restaurantName,
        'restaurant_id': restaurantId,
        'category': category,
        'description': description,
        'sizes': sizes,
        'ingredients': ingredients,
      };
}

// ─── Category Model ────────────────────────────────────────────
class FoodCategory {
  final String id;
  final String name;
  final String emoji;
  final bool isSelected;

  const FoodCategory({
    required this.id,
    required this.name,
    required this.emoji,
    this.isSelected = false,
  });

  FoodCategory copyWith({bool? isSelected}) =>
      FoodCategory(id: id, name: name, emoji: emoji, isSelected: isSelected ?? this.isSelected);
}

// ─── Cart Item Model ───────────────────────────────────────────
class CartItem {
  final FoodItem food;
  int quantity;
  String selectedSize;

  CartItem({required this.food, this.quantity = 1, this.selectedSize = '10"'});

  double get total => food.price * quantity;
}

// ─── Offer Model ───────────────────────────────────────────────
class Offer {
  final String id;
  final String code;
  final int discountPercent;
  final String description;

  const Offer({
    required this.id,
    required this.code,
    required this.discountPercent,
    required this.description,
  });

  factory Offer.fromJson(Map<String, dynamic> json) => Offer(
        id: json['id']?.toString() ?? '',
        code: json['code'] ?? '',
        discountPercent: json['discount_percent'] ?? 0,
        description: json['description'] ?? '',
      );
}
