import 'package:flutter/material.dart';
import '../../services/CartService.dart';
import 'CartPage.dart';

class CartButton extends StatelessWidget {
  const CartButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Asegurémonos de que la instancia de CartService esté disponible
    final cartService = CartService();
    
    return ListenableBuilder(
      listenable: cartService,
      builder: (context, child) {
        // Obtenemos el conteo total de productos en el carrito
        final itemCount = cartService.totalQuantity;
        
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Botón del carrito
            IconButton(
              icon: const Icon(
                Icons.shopping_cart,
                size: 28,
                color: Colors.black87,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(), // Eliminar restricciones de tamaño
              onPressed: () {
                // Navegar a la página del carrito
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CartPage(),
                  ),
                );
              },
            ),
            
            // Badge con el contador (solo se muestra si hay productos)
            if (itemCount > 0)
              Positioned(
                right: -5,
                top: -5,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Center(
                    child: Text(
                      itemCount > 99 ? '99+' : itemCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}