import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserData {
  final String userId;
  final String email;
  String nombre;
  String telefono;
  String? imgProfile; // Base64 de la imagen (se implementará después)
  
  UserData({
    required this.userId,
    required this.email,
    required this.nombre,
    this.telefono = '',
    this.imgProfile,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'nombre': nombre,
      'telefono': telefono,
      'imgProfile': imgProfile,
      'lastUpdated': FieldValue.serverTimestamp(),
      'hasPurchaseHistory': true, // Indicador explícito de que existe la subcolección
    };
  }
  
  factory UserData.fromMap(Map<String, dynamic> map) {
    return UserData(
      userId: map['userId'] ?? '',
      email: map['email'] ?? '',
      nombre: map['nombre'] ?? '',
      telefono: map['telefono'] ?? '',
      imgProfile: map['imgProfile'],
    );
  }
  
  factory UserData.fromFirebaseUser(User user, {String telefono = ''}) {
    return UserData(
      userId: user.uid,
      email: user.email ?? '',
      nombre: user.displayName ?? '',
      telefono: telefono,
    );
  }
}

class UserService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  UserData? _currentUserData;
  
  // Getter para datos de usuario actual
  UserData? get currentUserData => _currentUserData;
  
  // Crear o actualizar usuario después del registro o login
  Future<void> saveUserOnRegistration(User user, String nombre, String telefono) async {
    try {
      // Crear nuevo documento de usuario
      final userData = UserData(
        userId: user.uid,
        email: user.email ?? '',
        nombre: nombre,
        telefono: telefono,
      );
      
      // Guardar datos principales del usuario
      await _db.collection('usuarios').doc(user.uid).set(userData.toMap());
      
      // Crear explícitamente la subcolección purchaseHistory con un documento inicial vacío
      // Esto garantiza que la subcolección exista aunque esté vacía
      await _db.collection('usuarios').doc(user.uid)
          .collection('purchaseHistory')
          .doc('placeholder')
          .set({
            'createdAt': FieldValue.serverTimestamp(),
            'isPlaceholder': true,
            'note': 'Este es un documento para inicializar la subcolección'
          });
      
      _currentUserData = userData;
      notifyListeners();
    } catch (e) {
      print('Error al guardar usuario: $e');
      throw Exception('No se pudo guardar la información del usuario');
    }
  }

  // Actualizar información después del login
  Future<void> saveUserOnLogin(User user) async {
    try {
      // Verificar si el usuario ya existe en la base de datos
      DocumentSnapshot userDoc = await _db.collection('usuarios').doc(user.uid).get();
      
      if (userDoc.exists) {
        // Si existe, actualizar el último acceso
        await _db.collection('usuarios').doc(user.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
        
        // Cargar datos del usuario
        await getUserData(user.uid);
        
        // Verificar si existe la subcolección purchaseHistory
        final purchaseHistoryCheck = await _db.collection('usuarios')
            .doc(user.uid)
            .collection('purchaseHistory')
            .limit(1)
            .get();
            
        // Si no existe ningún documento en la subcolección, crear uno de placeholder
        if (purchaseHistoryCheck.docs.isEmpty) {
          await _db.collection('usuarios')
              .doc(user.uid)
              .collection('purchaseHistory')
              .doc('placeholder')
              .set({
                'createdAt': FieldValue.serverTimestamp(),
                'isPlaceholder': true,
                'note': 'Este es un documento para inicializar la subcolección'
              });
        }
      } else {
        // Si no existe (caso improbable pero posible si se borraron los datos)
        final userData = UserData.fromFirebaseUser(user);
        await _db.collection('usuarios').doc(user.uid).set(userData.toMap());
        
        // Crear subcolección
        await _db.collection('usuarios')
            .doc(user.uid)
            .collection('purchaseHistory')
            .doc('placeholder')
            .set({
              'createdAt': FieldValue.serverTimestamp(),
              'isPlaceholder': true,
              'note': 'Este es un documento para inicializar la subcolección'
            });
            
        _currentUserData = userData;
      }
      
      notifyListeners();
    } catch (e) {
      print('Error al actualizar datos de login: $e');
    }
  }

  // Obtener datos del usuario
  Future<UserData?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _db.collection('usuarios').doc(userId).get();
      
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        _currentUserData = UserData.fromMap(data);
        notifyListeners();
        return _currentUserData;
      }
      
      return null;
    } catch (e) {
      print('Error al obtener datos del usuario: $e');
      return null;
    }
  }
  
  // Método para acceder a la subcolección de historial de compras
  CollectionReference getPurchaseHistoryRef(String userId) {
    return _db.collection('usuarios').doc(userId).collection('purchaseHistory');
  }
  
  // Verificar si existe la subcolección purchaseHistory
  Future<bool> hasPurchaseHistory(String userId) async {
    try {
      final snapshot = await _db.collection('usuarios')
          .doc(userId)
          .collection('purchaseHistory')
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error al verificar historial de compras: $e');
      return false;
    }
  }
}