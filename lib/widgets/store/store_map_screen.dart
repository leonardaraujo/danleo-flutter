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
  String? _selectedStoreName;
  Set<Polyline> _polylines = {};

  // Lista de locales disponibles
  final List<StoreLocation> _storeLocations = [
    StoreLocation(
      name: "Tienda Principal - Jr. Cajamarca 351",
      location: LatLng(-12.072084149539371, -75.20713025949189),
    ),
    StoreLocation(
      name: "Tienda Secundaria - Jr. Ica 269",
      location: LatLng(-12.068189, -75.203603), // Coordenadas de ejemplo
    ),
    // Puedes agregar más locales aquí
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
        _errorMessage =
            'No se pudo obtener tu ubicación. Revisa permisos y GPS.';
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

    // Obtener la ruta al local más cercano
    final routePoints = await _getRouteCoordinates(
      userLatLng,
      nearestStore.location,
    );

    setState(() {
      _currentPosition = userLatLng;
      _selectedStoreName = nearestStore.name;
      _polylines = {
        Polyline(
          polylineId: const PolylineId("ruta_real"),
          visible: true,
          points: routePoints,
          width: 5,
          color: Colors.blue,
        ),
      };
    });
  }

  // Encuentra el local más cercano al usuario
  Future<StoreLocation?> _findNearestStore(LatLng userLocation) async {
    if (_storeLocations.isEmpty) return null;

    // Calcula distancias a todos los locales
    final distances = await Future.wait(
      _storeLocations.map(
        (store) => _calculateDistance(userLocation, store.location),
      ),
    );

    // Encuentra el índice del local más cercano
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

  // Calcula la distancia entre dos puntos en metros
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
      print('Error al obtener ubicación: $e');
      return null;
    }
  }

  Future<List<LatLng>> _getRouteCoordinates(
    LatLng origin,
    LatLng destination,
  ) async {
    const apiKey = 'AIzaSyDVMshygm08Alc3wsRZUdSvpOGkuWHIvt8';
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final points = data['routes'][0]['overview_polyline']['points'];
        return _decodePolyline(points);
      } else {
        print('Error API: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error en la petición de ruta: $e');
      return [];
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
      appBar: AppBar(title: const Text("Ubícanos")),
      body:
          _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _currentPosition == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  if (_selectedStoreName != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Ruta a: $_selectedStoreName",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Expanded(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _currentPosition!,
                        zoom: 14,
                      ),
                      myLocationEnabled: true,
                      onMapCreated: (controller) => _mapController = controller,
                      markers: {
                        // Marcadores para todos los locales
                        ..._storeLocations.map(
                          (store) => Marker(
                            markerId: MarkerId("store_${store.name}"),
                            position: store.location,
                            infoWindow: InfoWindow(title: store.name),
                            icon:
                                store.name == _selectedStoreName
                                    ? BitmapDescriptor.defaultMarkerWithHue(
                                      BitmapDescriptor.hueOrange,
                                    )
                                    : BitmapDescriptor.defaultMarkerWithHue(
                                      BitmapDescriptor.hueOrange,
                                    ),
                          ),
                        ),
                      },
                      polylines: _polylines,
                    ),
                  ),
                ],
              ),
    );
  }
}

// Clase para representar un local
class StoreLocation {
  final String name;
  final LatLng location;

  StoreLocation({required this.name, required this.location});
}
