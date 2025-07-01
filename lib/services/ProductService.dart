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

  // Lista de categorías disponibles
  static const List<String> availableCategories = [
    'mujer',
    'varon',
    'casaca',
    "niña",
    "niño",
    "polera",
    "pantalon",
    "jean",
    "chaqueta",
    "chompa",
    "sudadera",
    "polo",
  ];

  // Validar producto
  String? validateProduct(
    String name,
    double price,
    String description,
    String urlImage,
    List<String> categories,
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

    if (categories.isEmpty) {
      return 'Debe seleccionar al menos una categoría';
    }

    // Validar que todas las categorías sean válidas
    for (String category in categories) {
      if (!availableCategories.contains(category.toLowerCase())) {
        return 'La categoría "$category" no es válida';
      }
    }

    return null;
  }

  // Crear un producto
  Future<String> createProduct(
    String name,
    double price,
    String description,
    String urlImage,
    List<String> categories,
  ) async {
    try {
      // Validar los datos primero
      String? validationError = validateProduct(
        name,
        price,
        description,
        urlImage,
        categories,
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
        'categoria': categories.map((c) => c.toLowerCase()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      print('Error al crear producto: $e');
      return 'Error: $e';
    }
  }

  // Obtener productos con paginación y filtros
  Future<List<Map<String, dynamic>>> getProductsPaginated(
    int page,
    int pageSize, {
    List<String>? categoryFilter,
    String? searchQuery,
  }) async {
    try {
      Query query = _productsCollection;

      // Si hay filtro de categorías, aplicarlo SIN orderBy para evitar el error de índice
      if (categoryFilter != null && categoryFilter.isNotEmpty) {
        List<String> lowerCaseFilters =
            categoryFilter.map((c) => c.toLowerCase()).toList();
        query = query.where('categoria', arrayContainsAny: lowerCaseFilters);

        // Obtener TODOS los documentos que coincidan con las categorías
        QuerySnapshot querySnapshot = await query.get();

        // Convertir a lista y ordenar localmente
        List<Map<String, dynamic>> allProducts =
            querySnapshot.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            }).toList();

        // Ordenar por fecha de creación (más recientes primero)
        allProducts.sort((a, b) {
          Timestamp? aTime = a['createdAt'] as Timestamp?;
          Timestamp? bTime = b['createdAt'] as Timestamp?;

          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;

          return bTime.compareTo(aTime); // Descendente (más recientes primero)
        });

        // Filtrar por nombre si hay búsqueda
        if (searchQuery != null && searchQuery.isNotEmpty) {
          String searchLower = searchQuery.toLowerCase();
          allProducts =
              allProducts.where((product) {
                String name = product['nombre']?.toString().toLowerCase() ?? '';
                return name.contains(searchLower);
              }).toList();
        }

        // Aplicar paginación manualmente
        int startIndex = page * pageSize;
        int endIndex = startIndex + pageSize;

        if (startIndex >= allProducts.length) {
          return [];
        }

        endIndex =
            endIndex > allProducts.length ? allProducts.length : endIndex;
        List<Map<String, dynamic>> paginatedResults = allProducts.sublist(
          startIndex,
          endIndex,
        );

        return paginatedResults;
      }

      // Si NO hay filtro de categorías, usar orderBy normal
      query = query.orderBy('createdAt', descending: true);

      // Si hay búsqueda SIN filtro de categorías
      if (searchQuery != null && searchQuery.isNotEmpty) {
        QuerySnapshot allDocs = await query.get();

        List<Map<String, dynamic>> allProducts =
            allDocs.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            }).toList();

        // Filtrar por nombre localmente
        String searchLower = searchQuery.toLowerCase();
        List<Map<String, dynamic>> filteredProducts =
            allProducts.where((product) {
              String name = product['nombre']?.toString().toLowerCase() ?? '';
              return name.contains(searchLower);
            }).toList();

        // Aplicar paginación manualmente
        int startIndex = page * pageSize;
        int endIndex = startIndex + pageSize;

        if (startIndex >= filteredProducts.length) {
          return [];
        }

        endIndex =
            endIndex > filteredProducts.length
                ? filteredProducts.length
                : endIndex;
        return filteredProducts.sublist(startIndex, endIndex);
      }

      // Consulta normal sin filtros especiales - usar paginación nativa
      query = query.limit(pageSize);

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

      List<Map<String, dynamic>> results =
          querySnapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();

      return results;
    } catch (e) {
      print('❌ Error al obtener productos paginados: $e');
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

  // Buscar productos por nombre y categorías
  Future<List<Map<String, dynamic>>> searchProducts(
    String searchTerm, {
    List<String>? categoryFilter,
  }) async {
    try {
      Query query = _productsCollection;

      // Si hay filtro de categorías, aplicarlo SIN orderBy
      if (categoryFilter != null && categoryFilter.isNotEmpty) {
        query = query.where(
          'categoria',
          arrayContainsAny: categoryFilter.map((c) => c.toLowerCase()).toList(),
        );

        QuerySnapshot querySnapshot = await query.get();

        List<Map<String, dynamic>> allProducts =
            querySnapshot.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            }).toList();

        // Ordenar por fecha de creación localmente
        allProducts.sort((a, b) {
          Timestamp? aTime = a['createdAt'] as Timestamp?;
          Timestamp? bTime = b['createdAt'] as Timestamp?;

          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;

          return bTime.compareTo(aTime);
        });

        // Filtrar por nombre si hay término de búsqueda
        if (searchTerm.isNotEmpty) {
          String searchLower = searchTerm.toLowerCase();
          allProducts =
              allProducts.where((product) {
                String name = product['nombre']?.toString().toLowerCase() ?? '';
                return name.contains(searchLower);
              }).toList();
        }

        return allProducts;
      } else {
        // Si no hay filtro de categorías, usar orderBy normal
        query = query.orderBy('createdAt', descending: true);

        QuerySnapshot querySnapshot = await query.get();

        List<Map<String, dynamic>> allProducts =
            querySnapshot.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            }).toList();

        // Filtrar por nombre si hay término de búsqueda
        if (searchTerm.isNotEmpty) {
          String searchLower = searchTerm.toLowerCase();
          allProducts =
              allProducts.where((product) {
                String name = product['nombre']?.toString().toLowerCase() ?? '';
                return name.contains(searchLower);
              }).toList();
        }

        return allProducts;
      }
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
    List<String> categories,
  ) async {
    try {
      // Validar los datos primero
      String? validationError = validateProduct(
        name,
        price,
        description,
        urlImage,
        categories,
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
        'categoria': categories.map((c) => c.toLowerCase()).toList(),
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

  // Obtener todas las categorías disponibles
  List<String> getAvailableCategories() {
    return List.from(availableCategories);
  }

  // Obtener categorías únicas de los productos existentes
  Future<List<String>> getUsedCategories() async {
    try {
      QuerySnapshot querySnapshot = await _productsCollection.get();
      Set<String> categories = {};

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<dynamic>? productCategories = data['categoria'];

        if (productCategories != null) {
          List<String> stringCategories =
              productCategories.map((c) => c.toString()).toList();
          categories.addAll(stringCategories);
        }
      }

      return categories.toList();
    } catch (e) {
      print('❌ Error al obtener categorías usadas: $e');
      return [];
    }
  }

  // Obtener productos por categorías (sin paginación, todos)
  Future<List<Map<String, dynamic>>> getProductsByCategories(List<String> categories) async {
    try {
      Query query = _productsCollection;
      if (categories.isNotEmpty) {
        List<String> lowerCaseFilters = categories.map((c) => c.toLowerCase()).toList();
        query = query.where('categoria', arrayContainsAny: lowerCaseFilters);
      }
      QuerySnapshot querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error al obtener productos por categorías: $e');
      return [];
    }
  }
}
