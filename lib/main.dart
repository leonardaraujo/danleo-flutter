import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/product/productList.dart';
import 'widgets/common/Sidebar.dart';
import 'widgets/store/store_map_screen.dart';
import 'widgets/auth/login_screen.dart';
import 'services/AuthService.dart';

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
      title: 'Danleo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Mientras se verifica el estado de autenticación
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Si hay un usuario autenticado, mostrar la app principal
        if (snapshot.hasData && snapshot.data != null) {
          return const MainScreen();
        }
        
        // Si no hay usuario autenticado, mostrar el login
        return const LoginScreen();
      },
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
  final _authService = AuthService();

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      try {
        await _authService.signOut();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cerrar sesión: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const ProductList(),
      const StoreMapScreen(),
      const Center(child: Text('Ayuda')),
      const Center(child: Text('Configuración')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitleByIndex(_selectedIndex)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      drawer: Sidebar(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      body: IndexedStack(index: _selectedIndex, children: screens),
    );
  }

  String _getTitleByIndex(int index) {
    switch (index) {
      case 0:
        return 'Productos';
      case 1:
        return 'Ubícanos';
      case 2:
        return 'Ayuda';
      case 3:
        return 'Configuración'; 
      default:
        return 'Danleo';
    }
  }
}