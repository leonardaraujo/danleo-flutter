import 'package:flutter/material.dart';
import 'package:flutter_admin_scaffold/admin_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // Para seleccionar imágenes
import 'dart:io'; // Para manejar archivos de imagen

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _categoriaController = TextEditingController();
  File? _imageFile; // Para almacenar la imagen seleccionada
  String? _imageUrl; // Para almacenar la URL de la imagen
  String? _editingId;

  void _clearFields() {
    _nombreController.clear();
    _precioController.clear();
    _descripcionController.clear();
    _categoriaController.clear();
    _imageFile = null;
    _imageUrl = null;
    setState(() {});
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  void _guardarProducto() async {
    final nombre = _nombreController.text.trim();
    final precio = double.tryParse(_precioController.text) ?? 0.0;
    final descripcion = _descripcionController.text.trim();
    final categoria = _categoriaController.text.trim();

    if (nombre.isEmpty ||
        precio <= 0 ||
        descripcion.isEmpty ||
        categoria.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    try {
      final ref = FirebaseFirestore.instance.collection('productos');
      Map<String, dynamic> data = {
        'nombre': nombre,
        'precio': precio,
        'descripcion': descripcion,
        'categoria':
            categoria
                .split(',')
                .map((e) => e.trim())
                .toList(), // Convertir cadena a lista
        'createdAt': FieldValue.serverTimestamp(),
        'urlImagen': _imageUrl ?? '', // Almacena la URL de la imagen
      };

      if (_editingId == null) {
        await ref.add(data);
      } else {
        await ref.doc(_editingId).update(data);
      }

      _clearFields();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto guardado correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar producto: $e')));
    }
  }

  void _editarProducto(Map<String, dynamic> data, String id) {
    _nombreController.text = data['nombre'] ?? '';
    _precioController.text = data['precio'].toString();
    _descripcionController.text = data['descripcion'] ?? '';
    _categoriaController.text = (data['categoria'] as List?)?.join(', ') ?? '';
    _imageUrl = data['urlImagen'];
    _editingId = id;
  }

  void _eliminarProducto(String id) async {
    try {
      await FirebaseFirestore.instance.collection('productos').doc(id).delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Producto eliminado')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar producto: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      appBar: AppBar(title: const Text("Panel de Administración")),
      sideBar: SideBar(
        items: const [
          AdminMenuItem(title: 'Inicio', icon: Icons.home, route: '/'),
        ],
        selectedRoute: '/',
        onSelected: (item) {},
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _precioController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Precio'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descripcionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _categoriaController,
                      decoration: const InputDecoration(
                        labelText: 'Categorías (separadas por comas)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _pickImage,
                      child: const Text('Seleccionar Imagen'),
                    ),
                    if (_imageFile != null)
                      Image.file(
                        _imageFile!,
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _guardarProducto,
                            child: Text(
                              _editingId == null
                                  ? 'Agregar Producto'
                                  : 'Actualizar Producto',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _clearFields,
                            child: const Text('Limpiar Formulario'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('productos')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  return DataTable(
                    columns: const [
                      DataColumn(label: Text('Nombre')),
                      DataColumn(label: Text('Precio')),
                      DataColumn(label: Text('Categoría(s)')),
                      DataColumn(label: Text('Acciones')),
                    ],
                    rows:
                        docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final categorias =
                              (data['categoria'] as List?)
                                  ?.map((e) => e.toString())
                                  .toList()
                                  .join(', ') ??
                              'Sin categoría';

                          return DataRow(
                            cells: [
                              DataCell(Text(data['nombre'] ?? '')),
                              DataCell(Text('S/ ${data['precio']}')),
                              DataCell(Text(categorias)),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed:
                                          () => _editarProducto(data, doc.id),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed:
                                          () => _eliminarProducto(doc.id),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
