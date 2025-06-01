import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Usuario actual
  User? get currentUser => _auth.currentUser;
  
  // Stream del estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Verificar si el usuario está autenticado
  bool get isAuthenticated => _auth.currentUser != null;

  // Registrar usuario con email y contraseña
  Future<UserCredential?> registerWithEmailPassword(
    String email, 
    String password, 
    String name,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Actualizar el nombre del usuario
      await result.user?.updateDisplayName(name);
      
      notifyListeners();
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Iniciar sesión con email y contraseña
  Future<UserCredential?> signInWithEmailPassword(
    String email, 
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      throw 'Error al cerrar sesión: $e';
    }
  }

  // Enviar email de restablecimiento de contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Manejar excepciones de autenticación
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este email';
      case 'user-not-found':
        return 'No se encontró un usuario con este email';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'invalid-email':
        return 'Email inválido';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}