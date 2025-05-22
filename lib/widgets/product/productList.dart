import 'package:flutter/material.dart';
import '../../services/ProductService.dart';
import 'ProductCard.dart';

class ProductList extends StatefulWidget {
  const ProductList({Key? key}) : super(key: key);

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  final ProductService _productService = ProductService();
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    final products = await _productService.getProducts();
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  Future<bool?> _confirmDelete(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar'),
            content: const Text('¿Estás seguro de eliminar este producto?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _products.isEmpty
              ? const Center(child: Text('No hay productos disponibles'))
              : Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return ProductCard(
                      product: product,
                      onEdit: () => _showProductForm(context, product),
                      onDelete: () async {
                        final shouldDelete = await _confirmDelete(context);
                        if (shouldDelete == true) {
                          await _productService.deleteProduct(product['id']);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Producto ${product['nombre']} eliminado',
                              ),
                            ),
                          );
                          _loadProducts();
                        }
                      },
                    );
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showProductForm(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showProductForm(
    BuildContext context, [
    Map<String, dynamic>? product,
  ]) async {
    final bool isEditing = product != null;
    final TextEditingController nameController = TextEditingController(
      text: isEditing ? product['nombre'] : '',
    );
    final TextEditingController priceController = TextEditingController(
      text: isEditing ? product['precio'].toString() : '',
    );
    final TextEditingController descriptionController = TextEditingController(
      text: isEditing ? product['descripcion'] : '',
    );
    final TextEditingController urlImageController = TextEditingController(
      text: isEditing ? product['urlImagen'] : '',
    );

    final formKey = GlobalKey<FormState>();
    String? errorMessage;

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(isEditing ? 'Editar Producto' : 'Añadir Producto'),
                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: priceController,
                          decoration: const InputDecoration(
                            labelText: 'Precio',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Descripción',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: urlImageController,
                          decoration: const InputDecoration(
                            labelText: 'URL de imagen',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (urlImageController.text.isNotEmpty)
                          Image.network(
                            urlImageController.text,
                            height: 100,
                            errorBuilder: (context, error, stackTrace) {
                              return const SizedBox(
                                height: 100,
                                child: Center(
                                  child: Text('URL de imagen inválida'),
                                ),
                              );
                            },
                          ),
                        if (errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final name = nameController.text;
                        final price =
                            double.tryParse(priceController.text) ?? 0;
                        final description = descriptionController.text;
                        final urlImage = urlImageController.text;

                        final validation = _productService.validateProduct(
                          name,
                          price,
                          description,
                          urlImage,
                        );

                        if (validation != null) {
                          setState(() {
                            errorMessage = validation;
                          });
                          return;
                        }

                        if (isEditing) {
                          final success = await _productService.updateProduct(
                            product['id'],
                            name,
                            price,
                            description,
                            urlImage,
                          );

                          if (success) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Producto actualizado correctamente',
                                ),
                              ),
                            );
                            _loadProducts();
                          } else {
                            setState(() {
                              errorMessage = 'Error al actualizar el producto';
                            });
                          }
                        } else {
                          final result = await _productService.createProduct(
                            name,
                            price,
                            description,
                            urlImage,
                          );

                          if (result.startsWith('Error')) {
                            setState(() {
                              errorMessage = result;
                            });
                          } else {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Producto creado correctamente'),
                              ),
                            );
                            _loadProducts();
                          }
                        }
                      } catch (e) {
                        setState(() {
                          errorMessage = 'Error: $e';
                        });
                      }
                    },
                    child: Text(isEditing ? 'Actualizar' : 'Añadir'),
                  ),
                ],
              );
            },
          ),
    );
  }
}
