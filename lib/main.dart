import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'widgets/product/productList.dart';
import 'widgets/common/Sidebar.dart';
import 'widgets/store/store_map_screen.dart';
import 'widgets/store/purchase_history_screen.dart';
import 'widgets/auth/login_screen.dart';
import 'widgets/common/splash_screen.dart'; // Importamos el splash screen
import 'services/bottom_nav.dart';
import 'services/AuthService.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      // Usar el componente SplashScreen y pasarle el AppInitializer
      home: SplashScreen(
        nextScreen: const AppInitializer(),
        minimumDuration: const Duration(seconds: 3),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Esta clase se encarga de inicializar Firebase
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  // Inicialización en el initState
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Inicializar Firebase 
      await Firebase.initializeApp();
      
      // Navegar a AuthWrapper cuando Firebase está listo
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      }
    } catch (e) {
      print('Error inicializando Firebase: $e');
      // En caso de error, mostrar mensaje y reintentar
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) _initializeApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pantalla simple de carga mientras se inicializa Firebase
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const MainScreen();
        }

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
      const PurchaseHistoryScreen(),
      const BottomNavPerfilOnly(),
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
        return 'Historial de Compras';
      case 3:
        return 'Perfil';
      default:
        return 'Danleo';
    }
  }
}