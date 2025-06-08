import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import "../../services/CartService.dart";

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito de Compras'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          ListenableBuilder(
            listenable: CartService(),
            builder: (context, child) {
              final cartService = CartService();
              if (cartService.itemCount > 0) {
                return TextButton(
                  onPressed: () {
                    _showClearCartDialog(context);
                  },
                  child: const Text(
                    'Limpiar',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: CartService(),
        builder: (context, child) {
          final cartService = CartService();
          final items = cartService.items.values.toList();

          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Tu carrito está vacío',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Agrega productos para comenzar',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildCartItem(context, item);
                  },
                ),
              ),
              _buildCartSummary(context, cartService),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.urlImagen,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'S/.${item.precio.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total: S/.${item.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        CartService().decreaseQuantity(item.id);
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.cantidad.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        CartService().increaseQuantity(item.id);
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    CartService().removeItem(item.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.nombre} eliminado del carrito'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text(
                    'Eliminar',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(BuildContext context, CartService cartService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total de productos:',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  cartService.totalQuantity.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total a pagar:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'S/.${cartService.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _showPurchaseConfirmationDialog(context, cartService);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Realizar compra',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Limpiar Carrito'),
          content: const Text(
            '¿Estás seguro de que quieres eliminar todos los productos del carrito?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                CartService().clearCart();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Carrito limpiado'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Limpiar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showPurchaseConfirmationDialog(
    BuildContext context,
    CartService cartService,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.shopping_cart_checkout,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              const Text('Confirmar Compra'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Estás seguro de que deseas realizar esta compra?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Productos:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text('${cartService.totalQuantity} items'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'S/.${cartService.totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _processPurchase(context, cartService);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processPurchase(
    BuildContext context,
    CartService cartService,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Procesando compra...'),
          ],
        ),
      ),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        navigator.pop(); // Cerrar loading
        throw Exception('Usuario no autenticado');
      }

      final items = cartService.items.values.toList();
      if (items.isEmpty) {
        navigator.pop(); // Cerrar loading
        throw Exception('El carrito está vacío');
      }

      // Obtener información completa de los productos
      final productosCompleto = await _getCompleteProductInfo(items);

      // Crear los datos de la compra con información completa
      final purchaseData = {
        'productos': productosCompleto,
        'fechaCompra': FieldValue.serverTimestamp(),
        'total': cartService.totalAmount,
        'cantidadItems': cartService.totalQuantity,
        'estado': 'completado',
      };

      // Guardar en la subcolección purchaseHistory del usuario
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('purchaseHistory')
          .add(purchaseData);

      // Limpiar el carrito
      cartService.clearCart();

      // Cerrar loading
      navigator.pop();

      // Cerrar CartPage
      navigator.pop();

      // Mostrar éxito
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('¡Compra realizada exitosamente!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Cerrar loading
      navigator.pop();

      // Mostrar error
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _getCompleteProductInfo(List<CartItem> items) async {
    final productosCompleto = <Map<String, dynamic>>[];

    for (final item in items) {
      try {
        // Obtener información adicional del producto desde Firestore
        final productDoc = await FirebaseFirestore.instance
            .collection('productos')
            .doc(item.id)
            .get();

        if (productDoc.exists) {
          productosCompleto.add({
            'id': item.id,
            'nombre': item.nombre,
            'precio': item.precio,
            'cantidad': item.cantidad,
            'urlImagen': item.urlImagen,
            // Puedes agregar más campos si son necesarios
            'descripcion': productDoc['descripcion'] ?? '',
            'categoria': productDoc['categoria'] ?? '',
          });
        } else {
          // Si no existe el documento, usar solo la información del carrito
          productosCompleto.add({
            'id': item.id,
            'nombre': item.nombre,
            'precio': item.precio,
            'cantidad': item.cantidad,
            'urlImagen': item.urlImagen,
          });
        }
      } catch (e) {
        debugPrint('Error obteniendo información del producto ${item.id}: $e');
        // Si hay error, usar solo la información básica
        productosCompleto.add({
          'id': item.id,
          'nombre': item.nombre,
          'precio': item.precio,
          'cantidad': item.cantidad,
          'urlImagen': item.urlImagen,
        });
      }
    }

    return productosCompleto;
  }
}
