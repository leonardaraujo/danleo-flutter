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
      if (!_isLoadingMore && _hasMoreData && _searchQuery.isEmpty) {
        _loadMoreProducts();
      }
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterProducts();
    });
  }

  void _filterProducts() {
    if (_searchQuery.isEmpty) {
      _filteredProducts = List.from(_products);
    } else {
      _filteredProducts = _products.where((product) {
        final name = product['nombre']?.toString().toLowerCase() ?? '';
        return name.contains(_searchQuery);
      }).toList();
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
      );

      setState(() {
        if (isRefresh) {
          _products = products;
        } else {
          _products.addAll(products);
        }

        _hasMoreData = products.length == _pageSize;
        _filterProducts();
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
      );

      setState(() {
        _products.addAll(newProducts);
        _hasMoreData = newProducts.length == _pageSize;
        _filterProducts();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryCream,
      body: Column(
        children: [
          // Header con degradado
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
            child: Padding(
              padding: const EdgeInsets.all(20.0),
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
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Encuentra lo que necesitas',
                            style: TextStyle(
                              fontSize: 16,
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
                              spreadRadius: 2,
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const CartButton(),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Barra de búsqueda
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: primaryGreen),
                      decoration: InputDecoration(
                        hintText: 'Buscar productos...',
                        hintStyle: TextStyle(color: primaryGreen.withOpacity(0.6)),
                        prefixIcon: Icon(Icons.search, color: primaryOrange),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: primaryOrange),
                                onPressed: _clearSearch,
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contador de resultados
          if (_searchQuery.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: primaryOrange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: primaryOrange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${_filteredProducts.length} resultado${_filteredProducts.length != 1 ? 's' : ''} encontrado${_filteredProducts.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      color: primaryOrange,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                                  _searchQuery.isNotEmpty
                                      ? Icons.search_off
                                      : Icons.shopping_bag_outlined,
                                  size: 60,
                                  color: primaryOrange,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _searchQuery.isNotEmpty
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
                                _searchQuery.isNotEmpty
                                    ? 'Intenta con otros términos de búsqueda'
                                    : 'Aún no hay productos en esta categoría',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: primaryGreen.withOpacity(0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (_searchQuery.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: _clearSearch,
                                  icon: const Icon(Icons.clear_all),
                                  label: const Text('Limpiar búsqueda'),
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