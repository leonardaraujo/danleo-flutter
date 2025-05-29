import 'package:cloud_firestore/cloud_firestore.dart';

class ProductService {
  final CollectionReference _productsCollection = FirebaseFirestore.instance
      .collection('productos');

  // Regex para validaciones
  final RegExp _descriptionRegex = RegExp(r'^[a-zA-Z0-9 .,!?()-]+$');
  final RegExp _nameRegex = RegExp(r'^[a-zA-Z0-9 ]+$');
  final RegExp _urlRegex = RegExp(
    r'^https?:\/\/.*\.(jpeg|jpg|gif|png)(\?.*)?$',
    caseSensitive: false,
  );

  // Variable para almacenar el último documento para paginación
  DocumentSnapshot? _lastDocument;

  // Validar producto
  String? validateProduct(
    String name,
    double price,
    String description,
    String urlImage,
  ) {
    if (name.isEmpty) {
      return 'El nombre no puede estar vacío';
    }
    if (!_nameRegex.hasMatch(name)) {
      return 'El nombre solo puede contener letras, números y espacios';
    }

    if (price <= 0) {
      return 'El precio debe ser mayor a 0';
    }

    if (description.isEmpty) {
      return 'La descripción no puede estar vacía';
    }
    if (!_descriptionRegex.hasMatch(description)) {
      return 'La descripción solo puede contener letras, números y algunos caracteres básicos';
    }

    if (urlImage.isEmpty) {
      return 'La URL de la imagen no puede estar vacía';
    }
    if (!_urlRegex.hasMatch(urlImage)) {
      return 'La URL de la imagen no es válida. Debe ser una URL de imagen (jpg, png, gif, jpeg)';
    }

    return null;
  }

  // Crear un producto
  Future<String> createProduct(
    String name,
    double price,
    String description,
    String urlImage,
  ) async {
    try {
      // Validar los datos primero
      String? validationError = validateProduct(
        name,
        price,
        description,
        urlImage,
      );
      if (validationError != null) {
        return 'Error de validación: $validationError';
      }

      // Crear documento con los datos validados
      DocumentReference docRef = await _productsCollection.add({
        'nombre': name.trim(),
        'precio': price,
        'descripcion': description.trim(),
        'urlImagen': urlImage.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      print('Error al crear producto: $e');
      return 'Error: $e';
    }
  }

  // Obtener productos con paginación usando cursores de Firestore
  Future<List<Map<String, dynamic>>> getProductsPaginated(
    int page,
    int pageSize,
  ) async {
    try {
      Query query = _productsCollection
          .orderBy('createdAt', descending: true)
          .limit(pageSize);

      // Si es la primera página, resetear el cursor
      if (page == 0) {
        _lastDocument = null;
      }

      // Si hay un documento anterior y no es la primera página, usar startAfterDocument
      if (_lastDocument != null && page > 0) {
        query = query.startAfterDocument(_lastDocument!);
      }

      QuerySnapshot querySnapshot = await query.get();

      // Actualizar el último documento para la próxima página
      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
      }

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error al obtener productos paginados: $e');
      return [];
    }
  }

  // Método para resetear la paginación (útil para refresh)
  void resetPagination() {
    _lastDocument = null;
  }

  // Obtener todos los productos (mantener para compatibilidad)
  Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      QuerySnapshot querySnapshot =
          await _productsCollection
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error al obtener productos: $e');
      return [];
    }
  }

  // Buscar productos por nombre
  Future<List<Map<String, dynamic>>> searchProducts(String searchTerm) async {
    try {
      // Convertir a minúsculas para búsqueda insensible a mayúsculas
      String searchLower = searchTerm.toLowerCase();

      QuerySnapshot querySnapshot =
          await _productsCollection
              .orderBy('nombre')
              .where('nombre', isGreaterThanOrEqualTo: searchLower)
              .where('nombre', isLessThanOrEqualTo: '$searchLower\uf8ff')
              .get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error al buscar productos: $e');
      return [];
    }
  }

  // Obtener un producto por ID
  Future<Map<String, dynamic>?> getProductById(String id) async {
    try {
      DocumentSnapshot doc = await _productsCollection.doc(id).get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      } else {
        return null;
      }
    } catch (e) {
      print('Error al obtener producto: $e');
      return null;
    }
  }

  // Actualizar un producto
  Future<bool> updateProduct(
    String id,
    String name,
    double price,
    String description,
    String urlImage,
  ) async {
    try {
      // Validar los datos primero
      String? validationError = validateProduct(
        name,
        price,
        description,
        urlImage,
      );
      if (validationError != null) {
        print('Error de validación: $validationError');
        return false;
      }

      await _productsCollection.doc(id).update({
        'nombre': name.trim(),
        'precio': price,
        'descripcion': description.trim(),
        'urlImagen': urlImage.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error al actualizar producto: $e');
      return false;
    }
  }

  // Eliminar un producto
  Future<bool> deleteProduct(String id) async {
    try {
      await _productsCollection.doc(id).delete();
      return true;
    } catch (e) {
      print('Error al eliminar producto: $e');
      return false;
    }
  }
}
