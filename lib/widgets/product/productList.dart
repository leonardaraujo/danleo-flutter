import 'package:flutter/material.dart';
import '../../services/ProductService.dart';
import '../cart/CartButton.dart';
import 'ProductCard.dart';

class ProductList extends StatefulWidget {
  const ProductList({super.key});

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  List<String> _selectedCategories = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  String _searchQuery = '';

  static const int _pageSize = 10;
  int _currentPage = 0;

  // Colores de la empresa
  static const Color primaryGreen = Color(0xFF00443F);
  static const Color primaryOrange = Color(0xFFFF7B00);
  static const Color secondaryCream = Color(0xFFF6E4D6);
  static const Color secondaryRed = Color(0xFFB10000);

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreData && _searchQuery.isEmpty && _selectedCategories.isEmpty) {
        _loadMoreProducts();
      }
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _loadProductsWithFilters();
    });
  }

  void _onCategoryChanged(String category, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedCategories.add(category);
      } else {
        _selectedCategories.remove(category);
      }
      
      _loadProductsWithFilters();
    });
  }

  Future<void> _loadProductsWithFilters() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _products.clear();
      _filteredProducts.clear();
      _hasMoreData = true;
    });
    _productService.resetPagination();

    try {
      final products = await _productService.getProductsPaginated(
        _currentPage,
        _pageSize,
        categoryFilter: _selectedCategories.isNotEmpty ? _selectedCategories : null,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      setState(() {
        _products = products;
        _filteredProducts = products;
        _hasMoreData = products.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar productos: $e'),
          backgroundColor: secondaryRed,
        ),
      );
    }
  }

  Future<void> _loadProducts({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _isLoading = true;
        _currentPage = 0;
        _products.clear();
        _filteredProducts.clear();
        _hasMoreData = true;
      });
      _productService.resetPagination();
    } else {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final products = await _productService.getProductsPaginated(
        _currentPage,
        _pageSize,
        categoryFilter: _selectedCategories.isNotEmpty ? _selectedCategories : null,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      setState(() {
        if (isRefresh) {
          _products = products;
        } else {
          _products.addAll(products);
        }

        _hasMoreData = products.length == _pageSize;
        _filteredProducts = _products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar productos: $e'),
          backgroundColor: secondaryRed,
        ),
      );
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      _currentPage++;
      final newProducts = await _productService.getProductsPaginated(
        _currentPage,
        _pageSize,
        categoryFilter: _selectedCategories.isNotEmpty ? _selectedCategories : null,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      setState(() {
        _products.addAll(newProducts);
        _hasMoreData = newProducts.length == _pageSize;
        _filteredProducts = _products;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
        _currentPage--;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar más productos: $e'),
          backgroundColor: secondaryRed,
        ),
      );
    }
  }

  Future<void> _onRefresh() async {
    await _loadProducts(isRefresh: true);
  }

  void _clearSearch() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategories.clear();
      _searchController.clear();
      _searchQuery = '';
    });
    _loadProducts(isRefresh: true);
  }

  void _showCategoryFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<String> tempSelectedCategories = List.from(_selectedCategories);
        
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header del diálogo
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: primaryGreen,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.filter_list, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Filtrar por categorías',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Contenido scrollable
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Contador y botón limpiar
                            if (tempSelectedCategories.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: primaryOrange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: primaryOrange.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      color: primaryOrange,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${tempSelectedCategories.length} categoría${tempSelectedCategories.length != 1 ? 's' : ''} seleccionada${tempSelectedCategories.length != 1 ? 's' : ''}',
                                        style: TextStyle(
                                          color: primaryOrange,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setStateDialog(() {
                                          tempSelectedCategories.clear();
                                        });
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        minimumSize: Size.zero,
                                      ),
                                      child: Text(
                                        'Limpiar',
                                        style: TextStyle(
                                          color: secondaryRed,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            
                            // Categorías
                            Text(
                              'Selecciona las categorías:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: primaryGreen,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: ProductService.availableCategories.map((category) {
                                final isSelected = tempSelectedCategories.contains(category);
                                return FilterChip(
                                  label: Text(
                                    category.toUpperCase(),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : primaryGreen,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setStateDialog(() {
                                      if (selected) {
                                        tempSelectedCategories.add(category);
                                      } else {
                                        tempSelectedCategories.remove(category);
                                      }
                                    });
                                  },
                                  backgroundColor: Colors.white,
                                  selectedColor: primaryOrange,
                                  checkmarkColor: Colors.white,
                                  side: BorderSide(
                                    color: isSelected ? primaryOrange : primaryGreen.withOpacity(0.3),
                                  ),
                                  elevation: isSelected ? 3 : 1,
                                  pressElevation: 4,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Botones de acción
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Colors.grey[400]!),
                                ),
                              ),
                              child: Text(
                                'Cancelar',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedCategories = List.from(tempSelectedCategories);
                                });
                                Navigator.of(context).pop();
                                _loadProductsWithFilters();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryOrange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                              child: Text(
                                tempSelectedCategories.isEmpty 
                                    ? 'Ver todos' 
                                    : 'Aplicar (${tempSelectedCategories.length})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryCream,
      body: Column(
        children: [
          // Header compacto con degradado
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryGreen, primaryGreen.withOpacity(0.8)],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Título y carrito
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Productos',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Encuentra lo que necesitas',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryGreen.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const CartButton(),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Barra de búsqueda compacta
                    Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: primaryGreen, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Buscar productos...',
                          hintStyle: TextStyle(
                            color: primaryGreen.withOpacity(0.6),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search, 
                            color: primaryOrange,
                            size: 20,
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Botón de filtro
                              Container(
                                margin: const EdgeInsets.only(right: 4),
                                child: Stack(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.filter_list,
                                        color: _selectedCategories.isNotEmpty 
                                            ? primaryOrange 
                                            : primaryGreen.withOpacity(0.6),
                                        size: 20,
                                      ),
                                      onPressed: _showCategoryFilterDialog,
                                    ),
                                    if (_selectedCategories.isNotEmpty)
                                      Positioned(
                                        right: 6,
                                        top: 6,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: primaryOrange,
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          child: Text(
                                            '${_selectedCategories.length}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Botón de limpiar búsqueda
                              if (_searchQuery.isNotEmpty)
                                IconButton(
                                  icon: Icon(
                                    Icons.clear, 
                                    color: primaryOrange,
                                    size: 20,
                                  ),
                                  onPressed: _clearSearch,
                                ),
                            ],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Contador de resultados y filtros activos
          if (_searchQuery.isNotEmpty || _selectedCategories.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primaryOrange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: primaryOrange, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_filteredProducts.length} resultado${_filteredProducts.length != 1 ? 's' : ''} encontrado${_filteredProducts.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            color: primaryOrange,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _clearAllFilters,
                        child: Text(
                          'Limpiar todo',
                          style: TextStyle(
                            color: primaryOrange,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedCategories.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: _selectedCategories.map((category) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryOrange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

          // Lista de productos
          Expanded(
            child: _isLoading && _products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: primaryOrange),
                        const SizedBox(height: 16),
                        Text(
                          'Cargando productos...',
                          style: TextStyle(
                            color: primaryGreen,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : _filteredProducts.isEmpty
                    ? Center(
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
                                  _searchQuery.isNotEmpty || _selectedCategories.isNotEmpty
                                      ? Icons.search_off
                                      : Icons.shopping_bag_outlined,
                                  size: 60,
                                  color: primaryOrange,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _searchQuery.isNotEmpty || _selectedCategories.isNotEmpty
                                    ? 'No se encontraron productos'
                                    : 'No hay productos disponibles',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: primaryGreen,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty || _selectedCategories.isNotEmpty
                                    ? 'Intenta con otros términos o categorías'
                                    : 'Aún no hay productos en esta categoría',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: primaryGreen.withOpacity(0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (_searchQuery.isNotEmpty || _selectedCategories.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: _clearAllFilters,
                                  icon: const Icon(Icons.clear_all),
                                  label: const Text('Limpiar filtros'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryOrange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _onRefresh,
                        color: primaryOrange,
                        backgroundColor: Colors.white,
                        child: Container(
                          margin: const EdgeInsets.all(12.0),
                          child: GridView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: _filteredProducts.length +
                                (_isLoadingMore ? 2 : 0),
                            itemBuilder: (context, index) {
                              if (index >= _filteredProducts.length) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        spreadRadius: 1,
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: primaryOrange,
                                      strokeWidth: 3,
                                    ),
                                  ),
                                );
                              }

                              final product = _filteredProducts[index];
                              return ProductCard(product: product);
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}