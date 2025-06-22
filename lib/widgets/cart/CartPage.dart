import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import "../../services/CartService.dart";

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  // Colores de la empresa
  static const Color primaryGreen = Color(0xFF00443F);
  static const Color primaryOrange = Color(0xFFFF7B00);
  static const Color secondaryCream = Color(0xFFF6E4D6);
  static const Color secondaryRed = Color(0xFFB10000);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryGreen),
        title: Text(
          'Carrito de Compras',
          style: TextStyle(
            color: primaryGreen,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          ListenableBuilder(
            listenable: CartService(),
            builder: (context, child) {
              final cartService = CartService();
              if (cartService.itemCount > 0) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: TextButton.icon(
                    onPressed: () {
                      _showClearCartDialog(context);
                    },
                    icon: Icon(Icons.delete_outline, color: secondaryRed, size: 20),
                    label: Text(
                      'Limpiar',
                      style: TextStyle(
                        color: secondaryRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: secondaryRed.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
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
            return Center(
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: primaryOrange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        size: 80,
                        color: primaryOrange,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Tu carrito está vacío',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Agrega productos para comenzar a comprar',
                      style: TextStyle(
                        fontSize: 16,
                        color: primaryGreen.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.shopping_bag),
                      label: const Text('Explorar Productos'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Header con información del carrito
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryGreen, primaryGreen.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shopping_cart,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${items.length} producto${items.length != 1 ? 's' : ''} en tu carrito',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Total: ${cartService.totalQuantity} item${cartService.totalQuantity != 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de productos
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildCartItem(context, item);
                  },
                ),
              ),

              // Resumen del carrito
              _buildCartSummary(context, cartService),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Imagen del producto más pequeña
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipRRect(
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
                      decoration: BoxDecoration(
                        color: secondaryCream,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.broken_image,
                        color: primaryGreen.withOpacity(0.5),
                        size: 24,
                      ),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Información del producto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nombre,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: primaryGreen,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.attach_money,
                        size: 14,
                        color: primaryOrange,
                      ),
                      Text(
                        '${item.precio.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: primaryOrange,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_cart,
                        size: 12,
                        color: primaryGreen.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'S/.${item.total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Controles de cantidad más compactos
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Controles de cantidad
                Container(
                  decoration: BoxDecoration(
                    color: secondaryCream.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryGreen.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          CartService().decreaseQuantity(item.id);
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.remove,
                            color: primaryOrange,
                            size: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.cantidad.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          CartService().increaseQuantity(item.id);
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.add,
                            color: primaryOrange,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Botón de eliminar más pequeño
                InkWell(
                  onTap: () {
                    CartService().removeItem(item.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.delete, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${item.nombre} eliminado',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: secondaryRed,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: secondaryRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: secondaryRed.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: secondaryRed,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Quitar',
                          style: TextStyle(
                            color: secondaryRed,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Indicador visual
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Resumen de compra
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: secondaryCream.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total de productos:',
                          style: TextStyle(
                            fontSize: 16,
                            color: primaryGreen,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryOrange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            cartService.totalQuantity.toString(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 1,
                      color: primaryGreen.withOpacity(0.2),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total a pagar:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                        Text(
                          'S/.${cartService.totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Botón de compra
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showPurchaseConfirmationDialog(context, cartService);
                  },
                  icon: const Icon(Icons.shopping_cart_checkout, size: 24),
                  label: const Text(
                    'Realizar Compra',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: primaryGreen.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: primaryOrange),
              const SizedBox(width: 8),
              Text(
                'Limpiar Carrito',
                style: TextStyle(color: primaryGreen),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de que quieres eliminar todos los productos del carrito?',
            style: TextStyle(color: primaryGreen.withOpacity(0.8)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancelar',
                style: TextStyle(color: primaryGreen),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                CartService().clearCart();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Carrito limpiado exitosamente'),
                      ],
                    ),
                    backgroundColor: primaryGreen,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Limpiar'),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.shopping_cart_checkout,
                color: primaryGreen,
              ),
              const SizedBox(width: 8),
              Text(
                'Confirmar Compra',
                style: TextStyle(color: primaryGreen),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Estás seguro de que deseas realizar esta compra?',
                style: TextStyle(
                  fontSize: 16,
                  color: primaryGreen.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: secondaryCream.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryGreen.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Productos:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: primaryGreen,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryOrange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${cartService.totalQuantity} items',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: primaryOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: primaryGreen,
                          ),
                        ),
                        Text(
                          'S/.${cartService.totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: primaryGreen,
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
              child: Text(
                'Cancelar',
                style: TextStyle(color: primaryGreen),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _processPurchase(context, cartService);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Row(
          children: [
            CircularProgressIndicator(color: primaryOrange),
            const SizedBox(width: 16),
            Text(
              'Procesando compra...',
              style: TextStyle(color: primaryGreen),
            ),
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
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('¡Compra realizada exitosamente!'),
            ],
          ),
          backgroundColor: primaryGreen,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
          backgroundColor: secondaryRed,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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