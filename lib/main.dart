import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'widgets/product/productList.dart';
import 'widgets/common/Sidebar.dart';
import 'utils/AutoUpload.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión de Productos',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    print('Seleccionado índice: $index'); // Añadido para depuración
  }

  @override
  Widget build(BuildContext context) {
    // Lista de widgets que representan las diferentes pantallas
    final List<Widget> screens = [
      const ProductList(),
      const AutoUpload(), // Asegúrate de que este es el componente correcto
      const Center(child: Text('Configuración')),
      const Center(child: Text('Ayuda')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitleByIndex(_selectedIndex)),
      ),
      drawer: Sidebar(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
    );
  }

  String _getTitleByIndex(int index) {
    switch (index) {
      case 0:
        return 'Gestión de Productos';
      case 1:
        return 'Carga Automática';
      case 2:
        return 'Configuración';
      case 3:
        return 'Ayuda';
      default:
        return 'Danleo';
    }
  }
}