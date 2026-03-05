import 'package:flutter/foundation.dart';

class CartItem {
  final int id;
  final String name;
  final double price;
  final String image;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.quantity,
  });
}

class CartProvider with ChangeNotifier {
  final Map<int, CartItem> _items = {};

  // Returns a copy of the internal map (Map<int, CartItem>)
  Map<int, CartItem> get items => {..._items};

  // Use this for the count badge on your cart icon
  int get itemCount => _items.length;

  // Use this for displaying total in cart screen
  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  bool isItemInCart(int productId) {
    return _items.containsKey(productId);
  }

  // Call this from product cards to add/remove items
  void toggleCartStatus(
      int productId, String name, double price, String image) {
    if (isItemInCart(productId)) {
      _items.remove(productId);
    } else {
      _items.putIfAbsent(
        productId,
            () => CartItem(
          id: productId,
          name: name,
          price: price,
          image: image,
          quantity: 1,
        ),
      );
    }
    notifyListeners();
  }

  // Call this from the cart screen + button
  void incrementItem(int productId) {
    if (!_items.containsKey(productId)) return;
    _items[productId]!.quantity++;
    notifyListeners();
  }

  // Call this from the cart screen - button
  void decrementItem(int productId) {
    if (!_items.containsKey(productId)) return;
    if (_items[productId]!.quantity > 1) {
      _items[productId]!.quantity--;
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  // Call this from the cart screen delete button
  void removeItem(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}