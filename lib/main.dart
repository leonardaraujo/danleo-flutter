import 'dart:async';
import 'dart:io';

import 'package:danleo/firebase_options.dart'; // Asegúrate de que este archivo exista
import 'package:danleo/widgets/sensors/sensors_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para PlatformDispatcher.onError

// Importa tus widgets y servicios
import 'widgets/admin/admin_dashboard.dart';
import 'widgets/common/splash_screen.dart';
import 'widgets/auth/login_screen.dart';
import 'services/AuthService.dart';
import 'widgets/store/purchase_history_screen.dart';
import 'widgets/store/store_map_screen.dart';
import 'widgets/product/productList.dart';
import 'widgets/common/Sidebar.dart';
import 'services/bottom_nav.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Manejo global de errores
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kReleaseMode) exit(1); // Salir si es modo release
  };

  // Maneja errores fuera del ciclo de vida de Flutter (como excepciones en callbacks)
  PlatformDispatcher.instance.onError = (error, stack) {
    print("Error no capturado: $error\n$stack");
    return true; // Evita que la app falle
  };

  // Inicializa Firebase para ambas plataformas
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
      // ✅ AQUÍ ESTÁ EL CAMBIO PRINCIPAL:
      // Si es WEB → AdminDashboard directo
      // Si es ANDROID/iOS → App normal con splash, login, etc.
      home: kIsWeb
          ? const AdminDashboard()
          : SplashScreen(
              nextScreen: const AuthWrapper(),
              minimumDuration: const Duration(seconds: 3),
            ),
      debugShowCheckedModeBanner: false,
    );
  }
}

// === AuthWrapper (Solo para Android/iOS) ===
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
          final user = snapshot.data!;
          if (user.email == 'fabricio99cv@gmail.com') {
            return const AdminDashboard();
          }
          return const MainScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

// === MainScreen (Solo para Android/iOS) ===
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final _authService = AuthService();
  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _startInactivityTimer();
    } else if (state == AppLifecycleState.resumed) {
      _cancelInactivityTimer();
    }
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 5), () async {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      }
    });
  }

  void _cancelInactivityTimer() {
    _inactivityTimer?.cancel();
  }

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
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthWrapper()),
            (route) => false,
          );
        }
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
      const TodosLosSensoresScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
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
}