import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        imagenBase64 = data['fotoPerfilBase64'];
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

  Future<void> subirImagen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || imagenSeleccionada == null) return;

    final bytes = await imagenSeleccionada!.readAsBytes();
    final base64Image = base64Encode(bytes);

    final docRef = FirebaseFirestore.instance.collection('usuarios').doc(user.uid);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      await docRef.update({
        'fotoPerfilBase64': base64Image,
        'correo': user.email ?? '',
      });
    } else {
      await docRef.set({
        'fotoPerfilBase64': base64Image,
        'correo': user.email ?? '',
      });
    }

    if (!mounted) return;
    setState(() {
      imagenBase64 = base64Image;
      imagenSeleccionada = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Imagen de perfil actualizada')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            CircleAvatar(
              radius: 70,
              backgroundImage: imageWidget,
              child: imageWidget == null
                  ? const Icon(Icons.person, size: 70)
                  : null,
            ),
            const SizedBox(height: 10),
            if (nombre != null)
              Text('Nombre: $nombre', style: const TextStyle(fontSize: 16)),
            if (telefono != null)
              Text('Teléfono: $telefono', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => seleccionarImagen(ImageSource.gallery),
              icon: const Icon(Icons.image),
              label: const Text("Desde galería"),
            ),
            ElevatedButton.icon(
              onPressed: () => seleccionarImagen(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text("Desde cámara"),
            ),
            if (imagenSeleccionada != null)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: subirImagen,
                icon: const Icon(Icons.check),
                label: const Text("Guardar imagen"),
              ),
          ],
        ),
      ),
    );
  }
}
