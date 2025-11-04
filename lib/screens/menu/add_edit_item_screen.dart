import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/menu_item.dart';
import '../../services/menu_service.dart';
import '../../services/storage_service.dart';

class AddEditItemScreen extends StatefulWidget {
  final MenuItem? existingItem;
  const AddEditItemScreen({super.key, this.existingItem});

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _menuService = MenuService();
  final _storageService = StorageService();
  final picker = ImagePicker();

  String name = "";
  String desc = "";
  double price = 0.0;
  File? imageFile;
  bool available = true;

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      final i = widget.existingItem!;
      name = i.name;
      desc = i.description;
      price = i.price;
      available = i.available;
    }
  }

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => imageFile = File(picked.path));
    }
  }

  Future<void> saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    String imageUrl = widget.existingItem?.imageUrl ?? '';
    if (imageFile != null) {
      imageUrl = await _storageService.uploadImage(imageFile!, 'menu');
    }

    final data = MenuItem(
      id: widget.existingItem?.id ?? '',
      name: name,
      description: desc,
      price: price,
      imageUrl: imageUrl,
      available: available,
      categoryId: 'coffee', // you can make it dynamic later
    );

    if (widget.existingItem == null) {
      await _menuService.addItem(data);
    } else {
      await _menuService.updateItem(data.id, data.toMap());
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingItem == null ? "Add Item" : "Edit Item"),
        backgroundColor: Colors.brown,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: pickImage,
                child: imageFile != null
                    ? Image.file(imageFile!, height: 150, fit: BoxFit.cover)
                    : widget.existingItem != null
                        ? Image.network(widget.existingItem!.imageUrl, height: 150)
                        : Container(
                            height: 150,
                            color: Colors.grey[300],
                            child: const Icon(Icons.add_a_photo),
                          ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(labelText: "Name"),
                onSaved: (v) => name = v!,
                validator: (v) => v!.isEmpty ? "Enter name" : null,
              ),
              TextFormField(
                initialValue: desc,
                decoration: const InputDecoration(labelText: "Description"),
                onSaved: (v) => desc = v!,
                validator: (v) => v!.isEmpty ? "Enter description" : null,
              ),
              TextFormField(
                initialValue: price.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Price"),
                onSaved: (v) => price = double.parse(v!),
                validator: (v) => v!.isEmpty ? "Enter price" : null,
              ),
              SwitchListTile(
                title: const Text("Available"),
                value: available,
                onChanged: (v) => setState(() => available = v),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: saveItem,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                child: Text(widget.existingItem == null ? "Add Item" : "Update Item"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
