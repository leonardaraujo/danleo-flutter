import 'package:flutter/material.dart';
import 'ProductPage.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductCard({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductPage(product: product),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Imagen del producto
            AspectRatio(
              aspectRatio: 1.5,
              child: Image.network(
                product['urlImagen'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(child: Icon(Icons.broken_image, size: 40)),
                  );
                },
              ),
            ),

            // Información del producto
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nombre del producto
                    Text(
                      product['nombre'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Precio
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        'S/.${product['precio'].toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                    
                    // Valoración (estrellas)
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) => Icon(
                            index < 4 ? Icons.star : Icons.star_half,
                            color: Colors.amber,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(4.5)',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        )
                      ],
                    ),
                    
                    // Descripción
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        product['descripcion'],
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}