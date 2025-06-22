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

  // Colores de la empresa
  static const Color primaryGreen = Color(0xFF00443F);
  static const Color primaryOrange = Color(0xFFFF7B00);
  static const Color secondaryCream = Color(0xFFF6E4D6);
  static const Color secondaryRed = Color(0xFFB10000);

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      backgroundColor: secondaryCream,
      body: Column(
        children: [
          // Header con diseño personalizado
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryGreen, primaryGreen.withOpacity(0.8)],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Historial de Compras',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Revisa tus pedidos anteriores',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Contenido principal
          Expanded(
            child: currentUser == null
                ? _buildNotAuthenticatedState()
                : StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('usuarios')
                        .doc(currentUser.uid)
                        .collection('purchaseHistory')
                        .orderBy('fechaCompra', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildLoadingState();
                      }

                      if (snapshot.hasError) {
                        return _buildErrorState(snapshot.error.toString());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildEmptyState();
                      }

                      final purchases = snapshot.data!.docs;
                      return _buildPurchasesList(purchases);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotAuthenticatedState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: secondaryRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_off,
                size: 60,
                color: secondaryRed,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Usuario no autenticado',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Inicia sesión para ver tu historial',
              style: TextStyle(
                fontSize: 16,
                color: primaryGreen.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryOrange),
          const SizedBox(height: 16),
          Text(
            'Cargando historial...',
            style: TextStyle(
              color: primaryGreen,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: secondaryRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 60,
                color: secondaryRed,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Error al cargar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Error: $error',
              style: TextStyle(
                fontSize: 14,
                color: primaryGreen.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryOrange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long,
                size: 60,
                color: primaryOrange,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sin compras registradas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aún no has realizado ninguna compra.\n¡Explora nuestros productos!',
              style: TextStyle(
                fontSize: 16,
                color: primaryGreen.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchasesList(List<QueryDocumentSnapshot> purchases) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      color: primaryOrange,
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: purchases.length,
        itemBuilder: (context, index) {
          final purchase = purchases[index].data() as Map<String, dynamic>;
          final purchaseId = purchases[index].id;
          final total = purchase['total']?.toString() ?? '0';
          final date = _parsePurchaseDate(purchase['fechaCompra']);
          final products = purchase['productos'] as List<dynamic>? ?? [];
          final status = purchase['estado']?.toString() ?? 'completado';
          final totalItems = _calculateTotalItems(products);

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _getProductsDetails(products),
            builder: (context, productsSnapshot) {
              if (productsSnapshot.connectionState == ConnectionState.waiting) {
                return _buildPurchaseLoadingCard(purchaseId, date, total);
              }

              final productDetails = productsSnapshot.data ?? [];

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header de la orden
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Orden #${purchaseId.substring(0, 6).toUpperCase()}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: primaryGreen,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, 
                                       size: 14, color: primaryGreen.withOpacity(0.7)),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('dd/MM/yyyy - HH:mm').format(date),
                                    style: TextStyle(
                                      color: primaryGreen.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: status == 'completado'
                                  ? primaryGreen.withOpacity(0.1)
                                  : primaryOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: status == 'completado'
                                    ? primaryGreen
                                    : primaryOrange,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                color: status == 'completado'
                                    ? primaryGreen
                                    : primaryOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Información de items y total
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: secondaryCream.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.shopping_cart, 
                                     size: 20, color: primaryOrange),
                                const SizedBox(width: 8),
                                Text(
                                  '$totalItems producto${totalItems != 1 ? 's' : ''}',
                                  style: TextStyle(
                                    color: primaryGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'S/${double.parse(total).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Lista de productos
                      if (productDetails.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Productos:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...productDetails.map((product) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: primaryOrange,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      product['nombre']?.toString() ?? 
                                          'Producto desconocido',
                                      style: TextStyle(
                                        color: primaryGreen,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: primaryOrange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'x${product['cantidad'] ?? 1}',
                                      style: TextStyle(
                                        color: primaryOrange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'S/${(product['precio'] * (product['cantidad'] ?? 1)).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: primaryGreen,
                                    ),
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
      ),
    );
  }

  Widget _buildPurchaseLoadingCard(String purchaseId, DateTime date, String total) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Orden #${purchaseId.substring(0, 6).toUpperCase()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: primaryGreen,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey, width: 1),
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
                Icon(Icons.calendar_today, 
                     size: 14, color: primaryGreen.withOpacity(0.7)),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM/yyyy - HH:mm').format(date),
                  style: TextStyle(
                    color: primaryGreen.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              color: primaryOrange,
              backgroundColor: primaryOrange.withOpacity(0.2),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateTotalItems(List<dynamic> products) {
    return products.fold(0, (total, item) {
      if (item is Map) {
        return total + (item['cantidad'] as int? ?? 1);
      }
      return total + 1;
    });
  }

  Future<List<Map<String, dynamic>>> _getProductsDetails(List<dynamic> products) async {
    final productDetails = <Map<String, dynamic>>[];
    
    for (final product in products) {
      try {
        if (product is Map) {
          if (product['nombre'] != null && product['precio'] != null) {
            productDetails.add({
              'nombre': product['nombre'],
              'precio': product['precio'] is num ? product['precio'] : 0,
              'cantidad': product['cantidad'] ?? 1,
            });
            continue;
          }
          
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
          final doc = await _firestore.collection('productos').doc(product.toString()).get();
          if (doc.exists) {
            productDetails.add({
              'nombre': doc['nombre'],
              'precio': doc['precio'] is num ? doc['precio'] : 0,
              'cantidad': 1,
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
}