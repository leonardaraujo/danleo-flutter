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

  final LatLng _storeLocation = LatLng(-12.072084149539371, -75.20713025949189);
  Set<Polyline> _polylines = {};

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
    final routePoints = await _getRouteCoordinates(userLatLng, _storeLocation);

    setState(() {
      _currentPosition = userLatLng;
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
              : GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition!,
                  zoom: 14,
                ),
                myLocationEnabled: true,
                onMapCreated: (controller) => _mapController = controller,
                markers: {
                  Marker(
                    markerId: const MarkerId("user"),
                    position: _currentPosition!,
                    infoWindow: const InfoWindow(title: "Tú estás aquí"),
                  ),
                  Marker(
                    markerId: const MarkerId("store"),
                    position: _storeLocation,
                    infoWindow: const InfoWindow(
                      title: "Tienda - Jr. Cajamarca 351",
                    ),
                  ),
                },
                polylines: _polylines,
              ),
    );
  }
}
