import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cloudinary_service.dart';
import 'admin_categories_screen.dart'; // ✅ Import de l’écran des catégories

class AdminMenuScreen extends StatefulWidget {
  const AdminMenuScreen({super.key});

  @override
  State<AdminMenuScreen> createState() => _AdminMenuScreenState();
}

class _AdminMenuScreenState extends State<AdminMenuScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String? _selectedCategory;
  bool _isLoading = false;

  /// 🖼️ Pick image from gallery
  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  /// ☕ Upload menu item
  Future<void> _uploadMenuItem() async {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _selectedCategory == null ||
        _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please fill all fields and pick an image")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ Upload image to Cloudinary
      final imageUrl = await CloudinaryService.uploadImage(_selectedImage!);

      if (imageUrl == null) throw Exception("Image upload failed");

      // ✅ Save to Firestore
      await FirebaseFirestore.instance.collection('menu').add({
        'name': _nameController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'imageUrl': imageUrl,
        'category': _selectedCategory,
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("✅ Item added successfully!")));
      _resetForm();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _nameController.clear();
    _priceController.clear();
    _selectedCategory = null;
    _selectedImage = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final categoriesCol = FirebaseFirestore.instance.collection('categories');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.brown[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Manage Categories',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminCategoriesScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Add Menu Item",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown),
            ),
            const SizedBox(height: 16),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Item Name")),
            const SizedBox(height: 10),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Price (TND)"),
            ),
            const SizedBox(height: 10),

            /// ✅ Dropdown dynamique de catégorie
            StreamBuilder<QuerySnapshot>(
              stream: categoriesCol.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final docs = snapshot.data!.docs;
                final items = docs.map((d) => (d.data() as Map)['name'] as String).toList();
                return DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  hint: const Text("Select Category"),
                  items: items.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val),
                );
              },
            ),
            const SizedBox(height: 12),

            /// 🖼️ Sélection d’image
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.brown, width: 1.5),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: _selectedImage == null
                    ? const Center(child: Text("Tap to select image"))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            /// ✅ Bouton d’ajout
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _uploadMenuItem,
              icon: _isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add),
              label: Text(_isLoading ? "Uploading..." : "Add Item"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[700],
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
