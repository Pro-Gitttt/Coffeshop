import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/models/stock_item_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/app_drawer.dart';

class AddStockScreen extends StatefulWidget {
  const AddStockScreen({super.key});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _quantiteController = TextEditingController();
  final _thresholdController = TextEditingController();
  String _categorie = 'coffee';
  String _unite = 'g';
  File? _selectedImage;
  bool _isLoading = false;

  final List<String> _categories = [
    'coffee',
    'milk',
    'juice',
    'sugar',
    'accessory',
  ];

  final List<String> _unites = ['g', 'L', 'pcs', 'kg', 'ml'];

  @override
  void dispose() {
    _nomController.dispose();
    _quantiteController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final storageService = StorageService();
      final image = await storageService.pickImage();
      if (image != null) {
        setState(() => _selectedImage = image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final firestoreService = FirestoreService();
        final storageService = StorageService();

        String? imageUrl;
        String tempId = DateTime.now().millisecondsSinceEpoch.toString();

        // Upload image if selected
        if (_selectedImage != null) {
          imageUrl = await storageService.uploadImage(_selectedImage!, tempId);
        }

        // Create stock item
        final item = StockItem(
          id: '',
          nom: _nomController.text.trim(),
          categorie: _categorie,
          quantite: double.parse(_quantiteController.text),
          unite: _unite,
          imageUrl: imageUrl,
          misAJourLe: DateTime.now(),
          shortageThreshold: _thresholdController.text.trim().isEmpty
              ? null
              : double.tryParse(_thresholdController.text.trim()),
        );

        await firestoreService.addStockItem(item);

        if (mounted) {
          // Reset loading state
          setState(() => _isLoading = false);
          // Navigate back with success result
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final route = ModalRoute.of(context)?.settings.name ?? '/admin/add-stock';
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      drawer: AppDrawer(currentRoute: route),
      appBar: CustomAppBar(
        title: 'Add Product',
        currentRoute: route,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image picker (optionnel)
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.4),
                        width: 1),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate,
                                size: 48, color: theme.colorScheme.primary),
                            const SizedBox(height: 8),
                            Text('Tap to add an image (optional)',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7))),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Nom field
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                    labelText: 'Product Name', prefixIcon: Icon(Icons.label)),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Catégorie dropdown
              DropdownButtonFormField<String>(
                initialValue: _categorie,
                decoration: const InputDecoration(
                    labelText: 'Category', prefixIcon: Icon(Icons.category)),
                items: _categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _categorie = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Quantité field
              TextFormField(
                controller: _quantiteController,
                decoration: const InputDecoration(
                    labelText: 'Quantity', prefixIcon: Icon(Icons.numbers)),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a quantity';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Invalid quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Unité dropdown
              DropdownButtonFormField<String>(
                initialValue: _unite,
                decoration: const InputDecoration(
                    labelText: 'Unit', prefixIcon: Icon(Icons.straighten)),
                items: _unites.map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text(unit),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _unite = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Shortage threshold field
              TextFormField(
                controller: _thresholdController,
                decoration: const InputDecoration(
                  labelText: 'Alert Threshold (optional)',
                  prefixIcon: Icon(Icons.warning),
                  hintText: 'Minimum quantity before alert',
                  helperText: 'Leave empty to disable alert',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'Invalid value';
                    }
                    final threshold = double.parse(value);
                    if (threshold < 0) {
                      return 'Threshold must be positive';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text('Add Product',
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
