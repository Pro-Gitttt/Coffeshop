import 'package:flutter/material.dart';
import '../../../core/models/menu_item_model.dart';
import '../../../core/services/firestore_service.dart';

class EditMenuItemScreen extends StatefulWidget {
  const EditMenuItemScreen({super.key});

  @override
  State<EditMenuItemScreen> createState() => _EditMenuItemScreenState();
}

class _EditMenuItemScreenState extends State<EditMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _category = TextEditingController();
  bool _available = true;
  String? _id;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    _category.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)!.settings.arguments;
    if (arg is MenuItemModel) {
      _id = arg.id;
      _name.text = arg.name;
      _desc.text = arg.description;
      _price.text = arg.price.toStringAsFixed(2);
      _category.text = arg.category;
      _available = arg.available;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final service = FirestoreService();
    final item = MenuItemModel(
      id: _id ?? '',
      name: _name.text.trim(),
      description: _desc.text.trim(),
      price: double.parse(_price.text),
      images: const [],
      category: _category.text.trim(),
      available: _available,
      rating: 0,
      recipe: const [],
    );
    if (_id == null || _id!.isEmpty) {
      final id = await service.addMenuItem(item);
      _id = id;
    } else {
      await service.updateMenuItem(item);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_id == null ? 'Add' : 'Edit')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (TND)'),
                validator: (v) => (double.tryParse(v ?? '') == null) ? 'Invalid number' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _category,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _available,
                onChanged: (v) => setState(() => _available = v),
                title: const Text('Available'),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}


