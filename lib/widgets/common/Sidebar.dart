import 'package:flutter/material.dart';

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
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.inventory, size: 30, color: Colors.blue),
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