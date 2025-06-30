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

  @override
  void initState() {
    super.initState();

    SensorsPlatform.instance.accelerometerEventStream().listen((e) {
      setState(() {
        acelerometro =
            'Acelerómetro:\nX: ${e.x.toStringAsFixed(2)}\nY: ${e.y.toStringAsFixed(2)}\nZ: ${e.z.toStringAsFixed(2)}';
      });
    });
    SensorsPlatform.instance.gyroscopeEventStream().listen((e) {
      setState(() {
        giroscopio =
            'Giroscopio:\nX: ${e.x.toStringAsFixed(2)}\nY: ${e.y.toStringAsFixed(2)}\nZ: ${e.z.toStringAsFixed(2)}';
      });
    });
    SensorsPlatform.instance.magnetometerEventStream().listen((e) {
      setState(() {
        magnetometro =
            'Magnetómetro:\nX: ${e.x.toStringAsFixed(2)}\nY: ${e.y.toStringAsFixed(2)}\nZ: ${e.z.toStringAsFixed(2)}';
      });
    });
    SensorsPlatform.instance.userAccelerometerEventStream().listen((e) {
      setState(() {
        userAccel =
            'User Accel:\nX: ${e.x.toStringAsFixed(2)}\nY: ${e.y.toStringAsFixed(2)}\nZ: ${e.z.toStringAsFixed(2)}';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sensores del Móvil')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(acelerometro, style: const TextStyle(fontSize: 16)),
            const Divider(),
            Text(giroscopio, style: const TextStyle(fontSize: 16)),
            const Divider(),
            Text(magnetometro, style: const TextStyle(fontSize: 16)),
            const Divider(),
            Text(userAccel, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}