import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/cloudinary_service.dart';
import 'admin_menu_screen.dart'; // ✅ Add Menu Screen
import 'char.dart'; // ✅ Statistics Screen

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final AuthService _authService = AuthService();
  Widget _currentScreen = const DashboardHome();

  void _setScreen(Widget screen) {
    setState(() => _currentScreen = screen);
    Navigator.pop(context); // close drawer
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) await _authService.logout(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.brown,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout)
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.brown),
              child: Text("Admin Menu",
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () => _setScreen(const DashboardHome()),
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text("Add Menu"),
              onTap: () => _setScreen(const AdminMenuScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text("All Menus"),
              onTap: () => _setScreen(const AllMenusWidget()),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text("Statistics"),
              onTap: () => _setScreen(const AdminStatisticsScreen()),
            ),
          ],
        ),
      ),
      body: SafeArea(child: _currentScreen),
    );
  }
}

/// Dashboard Home
class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            color: Colors.brown[700],
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.admin_panel_settings,
                      size: 50, color: Colors.white),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Welcome Back, Admin!",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Manage menus, users, and orders easily.",
                          style:
                              TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Quick Action Buttons
          const Text("Quick Actions",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildActionCard(
                  context, "Add Menu", Icons.add_box, Colors.brown, () {
                context
                    .findAncestorStateOfType<_AdminScreenState>()
                    ?._setScreen(const AdminMenuScreen());
              }),
              _buildActionCard(
                  context, "View All Menus", Icons.list_alt, Colors.teal, () {
                context
                    .findAncestorStateOfType<_AdminScreenState>()
                    ?._setScreen(const AllMenusWidget());
              }),
              _buildActionCard(context, "Statistics", Icons.bar_chart,
                  Colors.purple, () {
                context
                    .findAncestorStateOfType<_AdminScreenState>()
                    ?._setScreen(const AdminStatisticsScreen());
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 100,
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// All Menus Widget
class AllMenusWidget extends StatelessWidget {
  const AllMenusWidget({super.key});

  Future<void> _deleteMenu(String id, BuildContext context) async {
    await FirebaseFirestore.instance.collection('menu').doc(id).delete();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Menu deleted")));
  }

  @override
  Widget build(BuildContext context) {
    final menuCol = FirebaseFirestore.instance.collection('menu');

    return StreamBuilder<QuerySnapshot>(
      stream: menuCol.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text("No menu items available."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Unnamed';
            final price = data['price'] ?? 0;
            final category = data['category'] ?? 'Unknown';
            final imageUrl =
                data['imageUrl'] ?? 'https://via.placeholder.com/150';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading:
                    Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                title: Text(name),
                subtitle: Text("$price TND\nCategory: $category"),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () {
                        context
                            .findAncestorStateOfType<_AdminScreenState>()
                            ?._setScreen(const AdminMenuScreen());
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteMenu(docs[index].id, context),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
