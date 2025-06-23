import 'package:flutter/material.dart';
import 'ProductPage.dart';
import '../../services/CartService.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductCard({super.key, required this.product});

  String _formatCategories(List<dynamic>? categories) {
    if (categories == null || categories.isEmpty) return '';
    return categories.map((c) => c.toString().toUpperCase()).join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Column(
        children: [
          // Imagen del producto con ícono de información
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductPage(product: product),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    child: Image.network(
                      product['urlImagen'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.broken_image, size: 40),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Ícono de información
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenido del producto
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nombre del producto
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductPage(product: product),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: Text(
                      product['nombre'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Precio
                Text(
                  'S/.${product['precio'].toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.green.shade700,
                  ),
                ),

                const SizedBox(height: 4),

                // Categorías
                SizedBox(
                  height: 16,
                  child: Text(
                    _formatCategories(product['categoria']),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 6),

                // Botón de agregar al carrito
                SizedBox(
                  width: double.infinity,
                  height: 30,
                  child: ListenableBuilder(
                    listenable: CartService(),
                    builder: (context, child) {
                      final cartService = CartService();
                      final isInCart = cartService.isInCart(product['id']);
                      final quantity = cartService.getQuantity(product['id']);

                      if (isInCart) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade300, width: 0.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              InkWell(
                                onTap: () {
                                  cartService.decreaseQuantity(product['id']);
                                },
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  child: const Icon(
                                    Icons.remove,
                                    size: 14,
                                  ),
                                ),
                              ),
                              
                              Expanded(
                                child: Text(
                                  quantity.toString(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              
                              InkWell(
                                onTap: () {
                                  cartService.addItem(product);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${product['nombre']} agregado',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      backgroundColor: Colors.green,
                                      duration: const Duration(milliseconds: 600),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  child: const Icon(
                                    Icons.add,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ElevatedButton.icon(
                        onPressed: () {
                          cartService.addItem(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${product['nombre']} agregado',
                                style: const TextStyle(fontSize: 11),
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(milliseconds: 600),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.add_shopping_cart,
                          size: 12,
                        ),
                        label: const Text(
                          'Agregar',
                          style: TextStyle(fontSize: 10),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 1,
                          minimumSize: const Size(0, 30),
                          maximumSize: const Size(double.infinity, 30),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}