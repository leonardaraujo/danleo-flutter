import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrdersReport extends StatelessWidget {
  const OrdersReport({super.key});

  @override
  Widget build(BuildContext context) {
    final ordersStream = FirebaseFirestore.instance
        .collectionGroup('purchaseHistory')
        .orderBy('fechaCompra', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: ordersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No hay pedidos'));
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final orderId = docs[index].id;
            final timestamp = data['fechaCompra'] as Timestamp?;
            final date = timestamp != null
                ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
                : 'Sin fecha';
            final total = data['total']?.toString() ?? '0';
            final items = data['cantidadItems']?.toString() ?? '0';
            final userId = docs[index].reference.parent.parent?.id ?? '';
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.receipt_long),
                title: Text('Orden #$orderId'),
                subtitle: Text('Usuario: $userId\nTotal: S/ $total - $items items'),
                trailing: Text(date),
              ),
            );
          },
        );
      },
    );
  }
}
