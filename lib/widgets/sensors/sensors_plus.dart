import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class TodosLosSensoresScreen extends StatefulWidget {
  const TodosLosSensoresScreen({super.key});

  @override
  State<TodosLosSensoresScreen> createState() => _TodosLosSensoresScreenState();
}

class _TodosLosSensoresScreenState extends State<TodosLosSensoresScreen> {
  String acelerometro = '';
  String giroscopio = '';
  String magnetometro = '';
  String userAccel = '';

  static const Color primaryGreen = Color(0xFF00443F);
  static const Color primaryOrange = Color(0xFFFF7B00);
  static const Color secondaryCream = Color(0xFFF6E4D6);
  static const Color secondaryRed = Color(0xFFB10000);

  @override
  void initState() {
    super.initState();

    SensorsPlatform.instance.accelerometerEventStream().listen((event) {
      setState(() {
        acelerometro =
            'Acelerómetro:\nX: ${event.x.toStringAsFixed(2)}\nY: ${event.y.toStringAsFixed(2)}\nZ: ${event.z.toStringAsFixed(2)}';
      });
    });

    SensorsPlatform.instance.gyroscopeEventStream().listen((event) {
      setState(() {
        giroscopio =
            'Giroscopio:\nX: ${event.x.toStringAsFixed(2)}\nY: ${event.y.toStringAsFixed(2)}\nZ: ${event.z.toStringAsFixed(2)}';
      });
    });

    SensorsPlatform.instance.magnetometerEventStream().listen((event) {
      setState(() {
        magnetometro =
            'Magnetómetro:\nX: ${event.x.toStringAsFixed(2)}\nY: ${event.y.toStringAsFixed(2)}\nZ: ${event.z.toStringAsFixed(2)}';
      });
    });

    SensorsPlatform.instance.userAccelerometerEventStream().listen((event) {
      setState(() {
        userAccel =
            'User Accel:\nX: ${event.x.toStringAsFixed(2)}\nY: ${event.y.toStringAsFixed(2)}\nZ: ${event.z.toStringAsFixed(2)}';
      });
    });
  }

  Widget _buildSensorCard(
    String title,
    String data,
    Color bgColor,
    Color textColor,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data,
              style: TextStyle(
                fontSize: 16,
                color: textColor.withOpacity(0.9),
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensores del Móvil'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
      ),
      backgroundColor: secondaryCream,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildSensorCard(
              "Acelerómetro",
              acelerometro,
              primaryOrange,
              Colors.white,
            ),
            const SizedBox(height: 12),
            _buildSensorCard(
              "Giroscopio",
              giroscopio,
              secondaryRed,
              Colors.white,
            ),
            const SizedBox(height: 12),
            _buildSensorCard(
              "Magnetómetro",
              magnetometro,
              primaryGreen,
              Colors.white,
            ),
            const SizedBox(height: 12),
            _buildSensorCard(
              "User Acceleration",
              userAccel,
              Colors.white,
              Colors.black87,
            ),
          ],
        ),
      ),
    );
  }
}
