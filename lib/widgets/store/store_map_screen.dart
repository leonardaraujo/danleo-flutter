import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class StoreMapScreen extends StatefulWidget {
  const StoreMapScreen({super.key});

  @override
  State<StoreMapScreen> createState() => _StoreMapScreenState();
}

class _StoreMapScreenState extends State<StoreMapScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  String? _errorMessage;
  StoreLocation? _selectedStore;
  Set<Polyline> _polylines = {};
  bool _isLoadingRoute = false;
  String? _routeDistance;
  String? _routeDuration;

  // Colores de la empresa
  static const Color primaryGreen = Color(0xFF00443F);
  static const Color primaryOrange = Color(0xFFFF7B00);
  static const Color secondaryCream = Color(0xFFF6E4D6);
  static const Color secondaryRed = Color(0xFFB10000);

  // Lista de locales disponibles
  final List<StoreLocation> _storeLocations = [
    StoreLocation(
      name: "Tienda Principal",
      address: "Jr. Cajamarca 351, Huancayo",
      location: LatLng(-12.072084149539371, -75.20713025949189),
      phone: "+51 964 123 456",
      hours: "Lun - Sáb: 8:00 AM - 8:00 PM\nDom: 9:00 AM - 6:00 PM",
    ),
    StoreLocation(
      name: "Tienda Secundaria",
      address: "Jr. Ica 269, Huancayo",
      location: LatLng(-12.068189, -75.203603),
      phone: "+51 964 123 457",
      hours: "Lun - Vie: 9:00 AM - 7:00 PM\nSáb: 9:00 AM - 6:00 PM",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeLocationAndRoute();
  }

  Future<void> _initializeLocationAndRoute() async {
    final position = await _determinePosition();
    if (position == null) {
      setState(() {
        _errorMessage = 'No se pudo obtener tu ubicación. Revisa permisos y GPS.';
      });
      return;
    }

    final userLatLng = LatLng(position.latitude, position.longitude);

    // Encuentra el local más cercano
    final nearestStore = await _findNearestStore(userLatLng);

    if (nearestStore == null) {
      setState(() {
        _errorMessage = 'No se pudo encontrar un local cercano.';
      });
      return;
    }

    setState(() {
      _currentPosition = userLatLng;
      _selectedStore = nearestStore;
    });

    // Obtener la ruta al local más cercano
    await _getRouteToStore(nearestStore);
  }

  Future<StoreLocation?> _findNearestStore(LatLng userLocation) async {
    if (_storeLocations.isEmpty) return null;

    final distances = await Future.wait(
      _storeLocations.map(
        (store) => _calculateDistance(userLocation, store.location),
      ),
    );

    int nearestIndex = 0;
    double minDistance = distances[0];
    for (int i = 1; i < distances.length; i++) {
      if (distances[i] < minDistance) {
        minDistance = distances[i];
        nearestIndex = i;
      }
    }

    return _storeLocations[nearestIndex];
  }

  Future<double> _calculateDistance(LatLng start, LatLng end) async {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  Future<Position?> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Error al obtener ubicación: $e');
      return null;
    }
  }

  Future<void> _getRouteToStore(StoreLocation store) async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoadingRoute = true;
      _routeDistance = null;
      _routeDuration = null;
    });

    const apiKey = 'AIzaSyDVMshygm08Alc3wsRZUdSvpOGkuWHIvt8';
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${_currentPosition!.latitude},${_currentPosition!.longitude}&destination=${store.location.latitude},${store.location.longitude}&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final points = route['overview_polyline']['points'];
          final leg = route['legs'][0];
          
          setState(() {
            _polylines = {
              Polyline(
                polylineId: const PolylineId("ruta_real"),
                visible: true,
                points: _decodePolyline(points),
                width: 4,
                color: primaryOrange,
                patterns: [],
              ),
            };
            _routeDistance = leg['distance']['text'];
            _routeDuration = leg['duration']['text'];
            _isLoadingRoute = false;
          });
        }
      } else {
        setState(() {
          _isLoadingRoute = false;
        });
        debugPrint('Error API: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoadingRoute = false;
      });
      debugPrint('Error en la petición de ruta: $e');
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryCream,
      body: Column(
        children: [
          // Header personalizado
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
                        Icons.location_on,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ubícanos',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Encuentra nuestras tiendas más cercanas',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Contenido principal
          Expanded(
            child: _errorMessage != null
                ? _buildErrorState()
                : _currentPosition == null
                    ? _buildLoadingState()
                    : _buildMapContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
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
                Icons.location_off,
                size: 60,
                color: secondaryRed,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Error de Ubicación',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 16,
                color: primaryGreen.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
                _initializeLocationAndRoute();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Intentar de nuevo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
            'Obteniendo tu ubicación...',
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

  Widget _buildMapContent() {
    return Column(
      children: [
        // Información de la tienda seleccionada
        if (_selectedStore != null) _buildStoreInfoCard(),

        // Mapa
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition!,
                  zoom: 14,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onMapCreated: (controller) => _mapController = controller,
                markers: {
                  ..._storeLocations.map(
                    (store) => Marker(
                      markerId: MarkerId("store_${store.name}"),
                      position: store.location,
                      infoWindow: InfoWindow(
                        title: store.name,
                        snippet: store.address,
                      ),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        store == _selectedStore
                            ? BitmapDescriptor.hueOrange
                            : BitmapDescriptor.hueGreen,
                      ),
                      onTap: () {
                        setState(() {
                          _selectedStore = store;
                        });
                        _getRouteToStore(store);
                      },
                    ),
                  ),
                },
                polylines: _polylines,
              ),
            ),
          ),
        ),

        // Botones de acción
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_mapController != null && _currentPosition != null) {
                      _mapController!.animateCamera(
                        CameraUpdate.newLatLng(_currentPosition!),
                      );
                    }
                  },
                  icon: const Icon(Icons.my_location, size: 20),
                  label: const Text('Mi Ubicación'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _selectedStore != null
                      ? () => _showStoreOptions(_selectedStore!)
                      : null,
                  icon: const Icon(Icons.directions, size: 20),
                  label: const Text('Cómo llegar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStoreInfoCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.store,
                  color: primaryOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedStore!.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                    Text(
                      _selectedStore!.address,
                      style: TextStyle(
                        fontSize: 14,
                        color: primaryGreen.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoadingRoute)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primaryOrange,
                  ),
                )
              else if (_routeDistance != null && _routeDuration != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _routeDistance!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                      Text(
                        _routeDuration!,
                        style: TextStyle(
                          fontSize: 10,
                          color: primaryGreen.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showStoreOptions(StoreLocation store) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
                margin: const EdgeInsets.only(bottom: 20),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.store,
                      color: primaryOrange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                        Text(
                          store.address,
                          style: TextStyle(
                            fontSize: 14,
                            color: primaryGreen.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildInfoRow(Icons.phone, "Teléfono", store.phone),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.access_time, "Horarios", store.hours),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Aquí podrías abrir la app de mapas externa
                    // launch("google.navigation:q=${store.location.latitude},${store.location.longitude}");
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Abrir en Maps'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: primaryOrange,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: primaryGreen.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Clase mejorada para representar un local
class StoreLocation {
  final String name;
  final String address;
  final LatLng location;
  final String phone;
  final String hours;

  StoreLocation({
    required this.name,
    required this.address,
    required this.location,
    required this.phone,
    required this.hours,
  });
}