import 'package:coffee_shop_app/screens/profilescreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedCategory = "All";
  List<String> _categories = ["All"];
  bool isGuest = false;

  // User profile data
  String userName = "";
  String userEmail = "";
  String userPhoto = "";

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchUserProfile();

    // Listen to search bar changes
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<void> _fetchCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .orderBy('order')
          .get();
      setState(() {
        _categories = ["All", ...snapshot.docs.map((d) => d['name'] as String)];
      });
    } catch (e) {
      debugPrint("Error fetching categories: $e");
    }
  }

  Future<void> _fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      setState(() {
        userName = doc['name'] ?? '';
        userEmail = doc['email'] ?? '';
        userPhoto = doc['photoURL'] ?? '';
      });
    }
  }

  void _handleRestrictedAction(String label) {
    if (isGuest) {
      _showLoginPrompt();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Navigating to $label...")),
      );
    }
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Restricted Feature 🔒"),
        content: const Text(
          "You are browsing as a guest.\nPlease register or login to use this feature.",
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(c);
              _authService.signInWithFacebook(context);
            },
            icon: const Icon(Icons.facebook, color: Colors.blue),
            label: const Text("Continue with Facebook"),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(c);
              _authService.signInWithGoogle(context);
            },
            icon: const Icon(Icons.g_mobiledata, color: Colors.red),
            label: const Text("Continue with Google"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              Navigator.pushReplacementNamed(context, '/register');
            },
            child: const Text(
              "Register with Email",
              style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () => _showItemDetails(data),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.3,
              child: (data['imageUrl'] ?? "").isNotEmpty
                  ? Image.network(
                      data['imageUrl'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: Colors.brown[100]),
                    )
                  : Container(
                      color: Colors.brown[100],
                      child: const Icon(Icons.local_cafe,
                          size: 48, color: Colors.brown),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'] ?? 'Unnamed',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown)),
                  const SizedBox(height: 6),
                  Text("${data['price']} TND",
                      style: const TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showItemDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (c) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if ((data['imageUrl'] ?? "").isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  data['imageUrl'],
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.brown[100]),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    data['name'] ?? 'Unnamed',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown),
                  ),
                  const SizedBox(height: 8),
                  Text("${data['price']} TND",
                      style: const TextStyle(fontSize: 18, color: Colors.green)),
                  const SizedBox(height: 12),
                  Text(data['description'] ?? '', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                        onPressed: () => Navigator.pop(c),
                        child: const Text("Close"),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(c);
                          if (isGuest) {
                            _showLoginPrompt();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text("${data['name']} added to cart")));
                          }
                        },
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text("Add to Cart"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuStream = FirebaseFirestore.instance
        .collection('menu')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        backgroundColor: Colors.brown[700],
        title: const Text("☕ Coffee Shop"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search for coffee...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                // Categories
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = cat == _selectedCategory;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                isSelected ? Colors.brown : Colors.brown[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(cat,
                              style: const TextStyle(color: Colors.white)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.brown[50],
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(userName.isEmpty ? "Loading..." : userName),
              accountEmail: Text(userEmail.isEmpty ? "" : userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundImage: userPhoto.isNotEmpty
                    ? NetworkImage(userPhoto)
                    : const AssetImage('assets/cafe.png') as ImageProvider,
              ),
              decoration: const BoxDecoration(color: Colors.brown),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.brown),
              title: const Text("Profile"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProfileScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.brown),
              title: const Text("Favorites"),
              onTap: () => _handleRestrictedAction("Favorites"),
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.brown),
              title: const Text("History"),
              onTap: () => _handleRestrictedAction("History"),
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.brown),
              title: const Text("Logout"),
              onTap: () async => await _authService.logout(context),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: menuStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(
                child: Text("☕ No menu items available.",
                    style: TextStyle(color: Colors.grey)));
          }

          // Filter items by search query and category
          final docs = snap.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final category = (data['category'] ?? '').toString();
            final matchesSearch = name.contains(_searchQuery);
            final matchesCategory =
                _selectedCategory == "All" || category == _selectedCategory;
            return matchesSearch && matchesCategory;
          }).toList();

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: docs.length,
            itemBuilder: (context, idx) {
              final data = docs[idx].data() as Map<String, dynamic>;
              return _buildMenuCard(data);
            },
          );
        },
      ),
    );
  }
}
