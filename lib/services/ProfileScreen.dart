import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? imagenBase64;
  File? imagenSeleccionada;
  String? nombre;
  String? telefono;
  bool isUploading = false;

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    obtenerDatosPerfil();
  }

  Future<void> obtenerDatosPerfil() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();

    final data = doc.data();
    if (data != null) {
      setState(() {
        imagenBase64 = data['imgProfile'];
        nombre = data['nombre'];
        telefono = data['telefono'];
      });
    }
  }

  Future<void> seleccionarImagen(ImageSource source) async {
    final picked = await picker.pickImage(source: source, imageQuality: 50);
    if (picked == null) return;

    setState(() {
      imagenSeleccionada = File(picked.path);
    });
  }

  // Función para comprimir la imagen
  Future<String> _compressImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    
    // Decodificar la imagen
    img.Image? image = img.decodeImage(bytes);
    if (image == null) throw Exception('No se pudo procesar la imagen');

    // Redimensionar si es muy grande (máximo 300x300)
    if (image.width > 300 || image.height > 300) {
      image = img.copyResize(image, width: 300, height: 300);
    }

    // Comprimir como JPEG con calidad del 70%
    final compressedBytes = img.encodeJpg(image, quality: 70);
    
    // Convertir a Base64
    final base64Image = base64Encode(compressedBytes);
    
    // Verificar tamaño (no debe exceder ~700KB en Base64)
    if (base64Image.length > 700000) {
      throw Exception('La imagen es demasiado grande. Selecciona una imagen más pequeña.');
    }
    
    return base64Image;
  }

  Future<void> subirImagen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || imagenSeleccionada == null) return;

    setState(() {
      isUploading = true;
    });

    try {
      // Comprimir la imagen
      final base64Image = await _compressImage(imagenSeleccionada!);

      final docRef = FirebaseFirestore.instance.collection('usuarios').doc(user.uid);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        await docRef.update({
          'imgProfile': base64Image,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.set({
          'userId': user.uid,
          'email': user.email ?? '',
          'nombre': user.displayName ?? '',
          'telefono': '',
          'imgProfile': base64Image,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      setState(() {
        imagenBase64 = base64Image;
        imagenSeleccionada = null;
        isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Imagen de perfil actualizada exitosamente'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        isUploading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    ImageProvider<Object>? imageWidget;

    if (imagenSeleccionada != null) {
      imageWidget = FileImage(imagenSeleccionada!);
    } else if (imagenBase64 != null) {
      try {
        final bytes = base64Decode(imagenBase64!);
        imageWidget = MemoryImage(bytes);
      } catch (e) {
        imageWidget = null;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 70,
                  backgroundImage: imageWidget,
                  child: imageWidget == null
                      ? const Icon(Icons.person, size: 70)
                      : null,
                ),
                if (isUploading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (isUploading)
              const Text(
                'Comprimiendo y guardando imagen...',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.blue,
                ),
              ),
            const SizedBox(height: 10),
            if (nombre != null)
              Text('Nombre: $nombre', style: const TextStyle(fontSize: 16)),
            if (user?.email != null)
              Text('Email: ${user!.email}', style: const TextStyle(fontSize: 16)),
            if (telefono != null)
              Text('Teléfono: $telefono', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: isUploading ? null : () => seleccionarImagen(ImageSource.gallery),
              icon: const Icon(Icons.image),
              label: const Text("Desde galería"),
            ),
            ElevatedButton.icon(
              onPressed: isUploading ? null : () => seleccionarImagen(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text("Desde cámara"),
            ),
            if (imagenSeleccionada != null)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: isUploading ? null : subirImagen,
                icon: isUploading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(isUploading ? "Guardando..." : "Guardar imagen"),
              ),
          ],
        ),
      ),
    );
  }
}