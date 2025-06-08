import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Compras'),
      ),
      body: currentUser == null
          ? const Center(child: Text('Usuario no autenticado'))
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('usuarios')
                  .doc(currentUser.uid)
                  .collection('purchaseHistory')
                  .orderBy('fechaCompra', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 50, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No hay compras registradas'),
                      ],
                    ),
                  );
                }

                final purchases = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: purchases.length,
                  itemBuilder: (context, index) {
                    final purchase = purchases[index].data() as Map<String, dynamic>;
                    final purchaseId = purchases[index].id;
                    final total = purchase['total']?.toString() ?? '0';
                    final date = _parsePurchaseDate(purchase['fechaCompra']);
                    final products = purchase['productos'] as List<dynamic>? ?? [];
                    final status = purchase['estado']?.toString() ?? 'completado';
                    
                    // Obtener la cantidad total de items (sumando las cantidades)
                    final totalItems = _calculateTotalItems(products);

                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: _getProductsDetails(products),
                      builder: (context, productsSnapshot) {
                        if (productsSnapshot.connectionState == ConnectionState.waiting) {
                          return _buildPurchaseLoadingCard(purchaseId, date, total);
                        }

                        final productDetails = productsSnapshot.data ?? [];
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Orden #${purchaseId.substring(0, 6).toUpperCase()}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: status == 'completado'
                                            ? Colors.green[50]
                                            : Colors.orange[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: status == 'completado'
                                              ? Colors.green
                                              : Colors.orange,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: status == 'completado'
                                              ? Colors.green
                                              : Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('dd/MM/yyyy - HH:mm').format(date),
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.shopping_cart, size: 16),
                                    const SizedBox(width: 8),
                                    Text('$totalItems items'),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const SizedBox(width: 8),
                                    Text(
                                      'Total: S/${double.parse(total).toStringAsFixed(2)}', // Cambiado a S/
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                if (productDetails.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Productos:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  ...productDetails.map((product) => Padding(
                                        padding: const EdgeInsets.only(left: 8, top: 4),
                                        child: Row(
                                          children: [
                                            const Text('•', style: TextStyle(fontSize: 16)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                product['nombre']?.toString() ?? 'Producto desconocido',
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'x${product['cantidad'] ?? 1}',
                                              style: const TextStyle(color: Colors.grey),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'S/${(product['precio'] * (product['cantidad'] ?? 1)).toStringAsFixed(2)}', // Cambiado a S/
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      )),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  int _calculateTotalItems(List<dynamic> products) {
    return products.fold(0, (total, item) {
      if (item is Map) {
        return total + (item['cantidad'] as int? ?? 1);
      }
      return total + 1; // Si no hay cantidad especificada, asumir 1
    });
  }

  Future<List<Map<String, dynamic>>> _getProductsDetails(List<dynamic> products) async {
    final productDetails = <Map<String, dynamic>>[];
    
    for (final product in products) {
      try {
        if (product is Map) {
          // Si el producto ya tiene los datos necesarios (nombre, precio, cantidad)
          if (product['nombre'] != null && product['precio'] != null) {
            productDetails.add({
              'nombre': product['nombre'],
              'precio': product['precio'] is num ? product['precio'] : 0,
              'cantidad': product['cantidad'] ?? 1,
            });
            continue;
          }
          
          // Si solo tenemos el ID, obtener los detalles del producto
          if (product['id'] != null) {
            final doc = await _firestore.collection('productos').doc(product['id'].toString()).get();
            if (doc.exists) {
              productDetails.add({
                'nombre': doc['nombre'],
                'precio': doc['precio'] is num ? doc['precio'] : 0,
                'cantidad': product['cantidad'] ?? 1,
              });
            }
          }
        } else if (product is String) {
          // Si es solo un ID (formato antiguo)
          final doc = await _firestore.collection('productos').doc(product.toString()).get();
          if (doc.exists) {
            productDetails.add({
              'nombre': doc['nombre'],
              'precio': doc['precio'] is num ? doc['precio'] : 0,
              'cantidad': 1, // Asumir 1 si no se especifica cantidad
            });
          }
        }
      } catch (e) {
        debugPrint('Error obteniendo detalles del producto: $e');
      }
    }
    return productDetails;
  }

  DateTime _parsePurchaseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is Timestamp) return date.toDate();
    if (date is String) {
      try {
        return DateTime.parse(date);
      } catch (_) {
        return DateFormat('dd/MM/yyyy').parse(date);
      }
    }
    return DateTime.now();
  }

  Widget _buildPurchaseLoadingCard(String purchaseId, DateTime date, String total) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Orden #${purchaseId.substring(0, 6).toUpperCase()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'CARGANDO',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd/MM/yyyy - HH:mm').format(date),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}