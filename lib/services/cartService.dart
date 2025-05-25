import 'package:flutter/foundation.dart';

class CartItem {
  final String id;
  final String nombre;
  final double precio;
  final String urlImagen;
  int cantidad;

  CartItem({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.urlImagen,
    this.cantidad = 1,
  });

  double get total => precio * cantidad;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'precio': precio,
      'urlImagen': urlImagen,
      'cantidad': cantidad,
    };
  }

  factory CartItem.fromProduct(Map<String, dynamic> product) {
    return CartItem(
      id: product['id'],
      nombre: product['nombre'],
      precio: product['precio'].toDouble(),
      urlImagen: product['urlImagen'],
    );
  }
}

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => Map.unmodifiable(_items);
  
  int get itemCount => _items.length;
  
  int get totalQuantity => _items.values.fold(0, (sum, item) => sum + item.cantidad);
  
  double get totalAmount => _items.values.fold(0.0, (sum, item) => sum + item.total);

  void addItem(Map<String, dynamic> product) {
    final productId = product['id'];
    
    if (_items.containsKey(productId)) {
      _items[productId]!.cantidad++;
    } else {
      _items[productId] = CartItem.fromProduct(product);
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (_items.containsKey(productId)) {
      if (quantity <= 0) {
        _items.remove(productId);
      } else {
        _items[productId]!.cantidad = quantity;
      }
      notifyListeners();
    }
  }

  void increaseQuantity(String productId) {
    if (_items.containsKey(productId)) {
      _items[productId]!.cantidad++;
      notifyListeners();
    }
  }

  void decreaseQuantity(String productId) {
    if (_items.containsKey(productId)) {
      if (_items[productId]!.cantidad > 1) {
        _items[productId]!.cantidad--;
      } else {
        _items.remove(productId);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  bool isInCart(String productId) {
    return _items.containsKey(productId);
  }

  int getQuantity(String productId) {
    return _items[productId]?.cantidad ?? 0;
  }
}