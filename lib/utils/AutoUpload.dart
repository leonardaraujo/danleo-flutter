import 'package:flutter/material.dart';
import '../services/ProductService.dart';
import 'data.dart';

class AutoUpload extends StatefulWidget {
  const AutoUpload({Key? key}) : super(key: key);

  @override
  State<AutoUpload> createState() => _AutoUploadState();
}

class _AutoUploadState extends State<AutoUpload> {
  final ProductService _productService = ProductService();
  bool _isLoading = false;
  String _statusMessage = '';
  bool _isSuccess = false;
  int _totalUploaded = 0;
  int _totalFailed = 0;
  List<String> _errorMessages = [];
  int _startIndex = 16; // Comenzar desde el elemento 16
  
  // Acceder a la lista de productos correctamente
  List<Map<String, dynamic>> get products => productos;

  Future<void> _uploadProducts() async {
    // Reset estado
    setState(() {
      _isLoading = true;
      _statusMessage = 'Subiendo productos...';
      _isSuccess = false;
      _totalUploaded = 0;
      _totalFailed = 0;
      _errorMessages = [];
    });

    try {
      // Comenzar desde el índice 16
      for (int i = _startIndex; i < products.length; i++) {
        var product = products[i];
        
        // Verificar si el producto tiene todos los campos necesarios
        if (product["name"] == null || 
            product["precio"] == null || 
            product["descripcion"] == null || 
            product["urlImage"] == null) {
          
          String errorMsg = "Error en producto #$i: Faltan campos requeridos";
          _errorMessages.add(errorMsg);
          setState(() {
            _totalFailed++;
          });
          continue;
        }
        
        try {
          // Convertir el precio a double independientemente de si es int o double
          final double precio = product["precio"] is int 
              ? (product["precio"] as int).toDouble() 
              : (product["precio"] as double);
              
          String result = await _productService.createProduct(
            product["name"],
            precio,  // Ahora siempre es double
            product["descripcion"],
            product["urlImage"],
          );

          if (!result.startsWith('Error')) {
            setState(() {
              _totalUploaded++;
            });
          } else {
            String errorMsg = "Error en producto #$i: $result";
            _errorMessages.add(errorMsg);
            setState(() {
              _totalFailed++;
            });
          }
        } catch (e) {
          String errorMsg = "Error en producto #$i: $e";
          _errorMessages.add(errorMsg);
          setState(() {
            _totalFailed++;
          });
        }
      }

      setState(() {
        _isLoading = false;
        _isSuccess = _totalFailed == 0;
        _statusMessage = _isSuccess 
            ? '¡Carga completada! $_totalUploaded productos subidos correctamente.'
            : 'Carga parcial: $_totalUploaded subidos, $_totalFailed fallidos.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _statusMessage = 'Error durante la carga: $e';
        _errorMessages.add(e.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_upload,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Carga Automática de Datos',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Iniciando desde el elemento $_startIndex de ${products.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Datos a cargar: ${products.length - _startIndex} productos',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Al hacer clic en el botón, se subirán automáticamente\nlos productos restantes a la base de datos.',
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                if (_isLoading)
                  Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        _statusMessage,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                else if (_statusMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isSuccess ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isSuccess ? Colors.green[300]! : Colors.red[300]!,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _isSuccess ? Icons.check_circle : Icons.error,
                          color: _isSuccess ? Colors.green : Colors.red,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _statusMessage,
                          style: TextStyle(
                            fontSize: 16,
                            color: _isSuccess ? Colors.green[800] : Colors.red[800],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                // Mostrar los errores si hay alguno
                if (_errorMessages.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detalles de errores:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: _errorMessages.length > 3 ? 150 : null,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _errorMessages.map((error) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    error,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                )).toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _uploadProducts,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  icon: const Icon(Icons.upload),
                  label: Text(
                    _isLoading ? 'Subiendo...' : 'Subir Productos',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}