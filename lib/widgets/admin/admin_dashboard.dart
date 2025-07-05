import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_admin_scaffold/admin_scaffold.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../services/ProductService.dart';
import 'orders_report.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _urlImagenController = TextEditingController();
  List<String> _selectedCategories = [];
  String? _editingId;
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  final ProductService _productService = ProductService();

  // Colores de la empresa
  static const Color primaryGreen = Color(0xFF00443F);
  static const Color primaryOrange = Color(0xFFFF7B00);
  static const Color secondaryCream = Color(0xFFF6E4D6);
  static const Color secondaryRed = Color(0xFFB10000);

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _descripcionController.dispose();
    _urlImagenController.dispose();
    super.dispose();
  }

  void _clearFields() {
    _nombreController.clear();
    _precioController.clear();
    _descripcionController.clear();
    _urlImagenController.clear();
    _selectedCategories = [];
    _editingId = null;
    _pickedImage = null;
    setState(() {});
  }

  void _guardarProducto() async {
    final nombre = _nombreController.text.trim();
    final precio = double.tryParse(_precioController.text) ?? 0.0;
    final descripcion = _descripcionController.text.trim();
    String urlImagen = _urlImagenController.text.trim();
    final categorias = List<String>.from(_selectedCategories);

    if (_pickedImage != null) {
      final uploaded = await _uploadImage(_pickedImage!);
      if (uploaded != null) {
        urlImagen = uploaded;
        _urlImagenController.text = uploaded;
      }
    }

    // Validar usando ProductService
    final error = _productService.validateProduct(
      nombre,
      precio,
      descripcion,
      urlImagen,
      categorias,
    );
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: secondaryRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    try {
      if (_editingId == null) {
        await _productService.createProduct(
          nombre,
          precio,
          descripcion,
          urlImagen,
          categorias,
        );
      } else {
        await _productService.updateProduct(
          _editingId!,
          nombre,
          precio,
          descripcion,
          urlImagen,
          categorias,
        );
      }

      _clearFields();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editingId == null
              ? '✅ Producto guardado correctamente'
              : '✅ Producto actualizado correctamente'),
          backgroundColor: primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al guardar producto: $e'),
          backgroundColor: secondaryRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _editarProducto(Map<String, dynamic> data, String id) {
    _nombreController.text = data['nombre'] ?? '';
    _precioController.text = data['precio'].toString();
    _descripcionController.text = data['descripcion'] ?? '';
    _urlImagenController.text = data['urlImagen'] ?? '';
    _selectedCategories = (data['categoria'] as List?)?.map((e) => e.toString()).toList() ?? [];
    _editingId = id;
    setState(() {});
  }

  void _eliminarProducto(String id) async {
    // Mostrar diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: primaryOrange),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Confirmar eliminación',
                style: TextStyle(fontSize: MediaQuery.of(context).size.width < 600 ? 16 : 18),
              ),
            ),
          ],
        ),
        content: const Text('¿Estás seguro de que deseas eliminar este producto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _productService.deleteProduct(id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🗑️ Producto eliminado correctamente'),
            backgroundColor: primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al eliminar producto: $e'),
            backgroundColor: secondaryRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final fileName = 'productos/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hintText,
    Function(String)? onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
        style: TextStyle(color: primaryGreen),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          labelStyle: TextStyle(color: primaryGreen),
          hintStyle: TextStyle(color: primaryGreen.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: primaryOrange),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryGreen.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryOrange, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryGreen.withOpacity(0.3)),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFormulario() {
    final availableCategories = ProductService.availableCategories;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.white.withOpacity(0.95)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del formulario
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryGreen, primaryGreen.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _editingId == null ? Icons.add_box : Icons.edit,
                    color: Colors.white,
                    size: isMobile ? 24 : 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _editingId == null ? 'Agregar Producto' : 'Editar Producto',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Campo Nombre
                    _buildTextField(
                      controller: _nombreController,
                      label: 'Nombre del Producto',
                      icon: Icons.shopping_bag,
                    ),

                    // Campo Precio
                    _buildTextField(
                      controller: _precioController,
                      label: 'Precio (S/)',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                    ),

                    // Campo Descripción
                    _buildTextField(
                      controller: _descripcionController,
                      label: 'Descripción',
                      icon: Icons.description,
                      maxLines: 3,
                    ),

                    // Campo URL de Imagen
                    _buildTextField(
                      controller: _urlImagenController,
                      label: 'URL de la Imagen',
                      icon: Icons.image,
                      hintText: 'https://ejemplo.com/imagen.jpg',
                      onChanged: (value) => setState(() {}),
                    ),

                    // Botón para seleccionar imagen desde dispositivo
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Seleccionar imagen desde dispositivo'),
                      ),
                    ),

                    // Vista previa de imagen
                    if (_pickedImage != null || _urlImagenController.text.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: secondaryCream.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryOrange.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Vista Previa',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryGreen,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _pickedImage != null
                                  ? Image.file(
                                      _pickedImage!,
                                      height: isMobile ? 100 : 120,
                                      width: isMobile ? 100 : 120,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      _urlImagenController.text,
                                      height: isMobile ? 100 : 120,
                                      width: isMobile ? 100 : 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        height: isMobile ? 100 : 120,
                                        width: isMobile ? 100 : 120,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.broken_image, size: 40, color: Colors.grey[600]),
                                            const SizedBox(height: 4),
                                            Text('URL no válida', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),

                    // Sección de Categorías
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryOrange.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryOrange.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.category, color: primaryOrange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Categorías',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primaryGreen,
                                    fontSize: isMobile ? 14 : 16,
                                  ),
                                ),
                              ),
                              if (_selectedCategories.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primaryOrange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_selectedCategories.length} seleccionadas',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isMobile ? 10 : 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: isMobile ? 6 : 8,
                            runSpacing: isMobile ? 6 : 8,
                            children: availableCategories.map((category) {
                              final isSelected = _selectedCategories.contains(category);
                              return FilterChip(
                                label: Text(
                                  category.toUpperCase(),
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : primaryGreen,
                                    fontWeight: FontWeight.w600,
                                    fontSize: isMobile ? 10 : 12,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedCategories.add(category);
                                    } else {
                                      _selectedCategories.remove(category);
                                    }
                                  });
                                },
                                backgroundColor: Colors.white,
                                selectedColor: primaryOrange,
                                checkmarkColor: Colors.white,
                                side: BorderSide(
                                  color: isSelected ? primaryOrange : primaryGreen.withOpacity(0.3),
                                ),
                                elevation: isSelected ? 4 : 1,
                                pressElevation: 6,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Botones de acción
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _guardarProducto,
                            icon: Icon(_editingId == null ? Icons.add : Icons.save),
                            label: Text(
                              _editingId == null ? 'Agregar Producto' : 'Actualizar Producto',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _clearFields,
                            icon: const Icon(Icons.clear_all),
                            label: const Text(
                              'Limpiar',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryOrange,
                              side: BorderSide(color: primaryOrange, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildTablaProductos() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header de la tabla
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryOrange, primaryOrange.withOpacity(0.8)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.inventory_2, color: Colors.white, size: isMobile ? 24 : 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Lista de Productos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('productos').snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$count productos',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Tabla o Lista según el tamaño de pantalla
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('productos')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: primaryOrange),
                  );
                }

                final docs = snapshot.data!.docs;
                
                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory, size: isMobile ? 48 : 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No hay productos registrados',
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Agrega tu primer producto usando el formulario',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: isMobile ? 12 : 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (isMobile) {
                  // Vista de lista para móviles
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final categorias = (data['categoria'] as List?)
                              ?.map((e) => e.toString())
                              .toList()
                              .join(', ') ??
                          'Sin categoría';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      data['urlImagen'] ?? '',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(Icons.broken_image, size: 30, color: Colors.grey[600]),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['nombre'] ?? '',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: primaryGreen,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'S/ ${data['precio']?.toStringAsFixed(2) ?? '0.00'}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: primaryOrange,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          categorias,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _editarProducto(data, doc.id),
                                    icon: Icon(Icons.edit, size: 18, color: primaryOrange),
                                    label: Text('Editar', style: TextStyle(color: primaryOrange)),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () => _eliminarProducto(doc.id),
                                    icon: Icon(Icons.delete, size: 18, color: secondaryRed),
                                    label: Text('Eliminar', style: TextStyle(color: secondaryRed)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  // Vista de tabla para desktop
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: DataTable(
                      columnSpacing: 20,
                      headingRowColor: MaterialStateProperty.all(
                        primaryGreen.withOpacity(0.1),
                      ),
                      headingTextStyle: TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      dataTextStyle: TextStyle(color: primaryGreen.withOpacity(0.8)),
                      columns: const [
                        DataColumn(label: Text('Imagen')),
                        DataColumn(label: Text('Nombre')),
                        DataColumn(label: Text('Precio')),
                        DataColumn(label: Text('Categorías')),
                        DataColumn(label: Text('Acciones')),
                      ],
                      rows: docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final categorias = (data['categoria'] as List?)
                                ?.map((e) => e.toString())
                                .toList()
                                .join(', ') ??
                            'Sin categoría';

                        return DataRow(
                          cells: [
                            DataCell(
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  data['urlImagen'] ?? '',
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(Icons.broken_image, size: 20, color: Colors.grey[600]),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 120,
                                child: Text(
                                  data['nombre'] ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                'S/ ${data['precio']?.toStringAsFixed(2) ?? '0.00'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: primaryGreen,
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 100,
                                child: Text(
                                  categorias,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: primaryOrange),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    color: primaryOrange,
                                    onPressed: () => _editarProducto(data, doc.id),
                                    tooltip: 'Editar producto',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    color: secondaryRed,
                                    onPressed: () => _eliminarProducto(doc.id),
                                    tooltip: 'Eliminar producto',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1024;

    if (isMobile) {
      // Layout vertical para móviles
      return Scaffold(
        backgroundColor: secondaryCream,
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.admin_panel_settings, color: primaryOrange, size: 20),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Admin Panel",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Container(
                color: primaryGreen,
                child: TabBar(
                  indicatorColor: primaryOrange,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.7),
                  tabs: [
                    Tab(
                      icon: Icon(Icons.add_box, size: 20),
                      text: 'Agregar',
                    ),
                    Tab(
                      icon: Icon(Icons.inventory_2, size: 20),
                      text: 'Productos',
                    ),
                    Tab(
                      icon: Icon(Icons.receipt_long, size: 20),
                      text: 'Pedidos',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: secondaryCream,
                  child: TabBarView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildFormulario(),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildTablaProductos(),
                      ),
                      const OrdersReport(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Layout original para desktop/tablet
      return AdminScaffold(
        backgroundColor: secondaryCream,
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.admin_panel_settings, color: primaryOrange),
              ),
              const SizedBox(width: 12),
              const Text(
                "Panel de Administración",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        sideBar: SideBar(
          backgroundColor: primaryGreen,
          activeBackgroundColor: primaryOrange,
          activeTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          textStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
          items: [
            AdminMenuItem(
              title: 'Gestión de Productos',
              icon: Icons.inventory,
              route: '/',
            ),
            AdminMenuItem(
              title: 'Estadísticas',
              icon: Icons.analytics,
              route: '/stats',
            ),
            AdminMenuItem(
              title: 'Usuarios',
              icon: Icons.people,
              route: '/users',
            ),
          ],
          selectedRoute: '/',
          onSelected: (item) {},
        ),
        body: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Container(
                color: primaryGreen,
                child: TabBar(
                  indicatorColor: primaryOrange,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.7),
                  tabs: const [
                    Tab(icon: Icon(Icons.add_box), text: 'Agregar'),
                    Tab(icon: Icon(Icons.inventory_2), text: 'Productos'),
                    Tab(icon: Icon(Icons.receipt_long), text: 'Pedidos'),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: secondaryCream,
                  child: TabBarView(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(isTablet ? 16.0 : 24.0),
                        child: _buildFormulario(),
                      ),
                      Padding(
                        padding: EdgeInsets.all(isTablet ? 16.0 : 24.0),
                        child: _buildTablaProductos(),
                      ),
                      const OrdersReport(),
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
}