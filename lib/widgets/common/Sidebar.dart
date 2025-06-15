import 'package:flutter/material.dart';
import 'splash_image.dart'; // Importa el widget SplashImage

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(
                0xFF00443F,
              ), // Cambia el color de fondo al especificado
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: const SplashImage(
                    width: 90,
                    height: 90,
                    fit: BoxFit.contain, // Usa el logo como imagen
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Danleo',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 5),
                Text(
                  'Versión 1.0',
                  style: TextStyle(
                    color: Colors.white.withAlpha((0.8 * 255).toInt()),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.shopping_bag,
            title: 'Productos',
            index: 0,
          ),
          const Divider(),
          _buildMenuItem(
            context: context,
            icon: Icons.location_on,
            title: 'Ubícanos',
            index: 1,
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.history,
            title: 'Historial de Compras',
            index: 2,
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.person,
            title: 'Perfil',
            index: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).primaryColor : Colors.black,
        ),
      ),
      selected: isSelected,
      onTap: () {
        onItemSelected(index);
        Navigator.pop(context); // Cierra el drawer
      },
    );
  }
}
