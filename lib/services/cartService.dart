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
      precio: (product['precio'] is int) 
          ? (product['precio'] as int).toDouble() 
          : product['precio'],
      urlImagen: product['urlImagen'],
    );
  }
}

class CartService extends ChangeNotifier {
  // Singleton para asegurar una única instancia
  static final CartService _instance = CartService._internal();
  
  factory CartService() => _instance;
  
  CartService._internal();

  // Almacenamiento interno de los productos en el carrito
  final Map<String, CartItem> _items = {};

  // Getter para acceder a los items (como copia inmutable)
  Map<String, CartItem> get items => Map.unmodifiable(_items);
  
  // Número total de productos diferentes en el carrito
  int get itemCount => _items.length;
  
  // Cantidad total de productos (sumando cantidades)
  int get totalQuantity {
    if (_items.isEmpty) return 0;
    return _items.values.fold(0, (sum, item) => sum + item.cantidad);
  }
  
  // Monto total a pagar
  double get totalAmount {
    if (_items.isEmpty) return 0.0;
    return _items.values.fold(0.0, (sum, item) => sum + item.total);
  }

  // Añadir un producto al carrito
  void addItem(Map<String, dynamic> product) {
    final productId = product['id'];
    
    if (_items.containsKey(productId)) {
      // Si ya existe, aumentar cantidad
      _items[productId]!.cantidad++;
    } else {
      // Si es nuevo, crearlo
      _items[productId] = CartItem.fromProduct(product);
    }
    
    // Notificar a los oyentes (widgets) que el carrito cambió
    notifyListeners();
    
    // Imprimir para debug
    print('Producto agregado. Total en carrito: ${totalQuantity}');
  }

  // Remover un producto del carrito
  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  // Actualizar la cantidad de un producto
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

  // Aumentar cantidad de un producto
  void increaseQuantity(String productId) {
    if (_items.containsKey(productId)) {
      _items[productId]!.cantidad++;
      notifyListeners();
    }
  }

  // Disminuir cantidad de un producto
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

  // Limpiar todo el carrito
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // Verificar si un producto está en el carrito
  bool isInCart(String productId) {
    return _items.containsKey(productId);
  }

  // Obtener cantidad de un producto específico
  int getQuantity(String productId) {
    return _items[productId]?.cantidad ?? 0;
  }
}