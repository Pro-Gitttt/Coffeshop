import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/utils/safe_fonts.dart';
import '../../../core/models/stock_item_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/app_drawer.dart';

class EditStockScreen extends StatefulWidget {
  const EditStockScreen({super.key});

  @override
  State<EditStockScreen> createState() => _EditStockScreenState();
}

class _EditStockScreenState extends State<EditStockScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _quantiteController;
  late TextEditingController _thresholdController;
  late String _categorie;
  late String _unite;
  File? _selectedImage;
  String? _existingImageUrl;
  bool _isLoading = false;
  late StockItem _originalItem;
  bool _initialized = false;
  bool _removeImage = false;

  final List<String> _categories = [
    'café',
    'lait',
    'jus',
    'sucre',
    'accessoire',
  ];

  final List<String> _unites = ['g', 'L', 'pcs', 'kg', 'ml'];

  @override
  void initState() {
    super.initState();
    // Initialize with default values
    _nomController = TextEditingController();
    _quantiteController = TextEditingController();
    _thresholdController = TextEditingController();
    _categorie = 'café';
    _unite = 'g';
    _originalItem = StockItem(
      id: '',
      nom: '',
      categorie: '',
      quantite: 0,
      unite: '',
      misAJourLe: DateTime.now(),
    );

    // Get item from arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is StockItem) {
        _originalItem = args;
        _nomController.text = args.nom;
        _quantiteController.text = args.quantite.toString();
        _thresholdController.text = args.shortageThreshold?.toString() ?? '';
        _categorie = args.categorie;
        _unite = args.unite;
        _existingImageUrl = args.imageUrl;
        _initialized = true;
        setState(() {});
      }
    });
  }

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
        setState(() {
          _selectedImage = image;
          _existingImageUrl = null; // Clear existing when new image selected
          _removeImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
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

        String? imageUrl = _existingImageUrl;

        // Upload new image if selected (upload first, then delete old)
        if (_selectedImage != null) {
          final String newImageUrl = await storageService.uploadImage(
              _selectedImage!, _originalItem.id);
          if (_existingImageUrl != null) {
            await storageService.deleteImage(_existingImageUrl!);
          }
          imageUrl = newImageUrl;
          _removeImage = false;
        }

        // Update stock item
        final updatedItem = _originalItem.copyWith(
          nom: _nomController.text.trim(),
          categorie: _categorie,
          quantite: double.parse(_quantiteController.text),
          unite: _unite,
          imageUrl: imageUrl,
          clearImage: _removeImage,
          misAJourLe: DateTime.now(),
          shortageThreshold: _thresholdController.text.trim().isEmpty
              ? null
              : double.tryParse(_thresholdController.text.trim()),
        );

        await firestoreService.updateStockItem(updatedItem);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Produit modifié avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      final theme = Theme.of(context);
      final route = ModalRoute.of(context)?.settings.name ?? '/admin/edit-stock';
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        drawer: AppDrawer(currentRoute: route),
        appBar: CustomAppBar(
          title: 'Modifier le produit',
          currentRoute: route,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final route = ModalRoute.of(context)?.settings.name ?? '/admin/edit-stock';
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      drawer: AppDrawer(currentRoute: route),
      appBar: CustomAppBar(
        title: 'Modifier le produit',
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
                      : _existingImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _existingImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildImagePlaceholder();
                                },
                              ),
                            )
                          : _buildImagePlaceholder(),
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedImage != null || _existingImageUrl != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _selectedImage = null;
                              _existingImageUrl = null;
                              _removeImage = true;
                            });
                          },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text("Supprimer l'image"),
                  ),
                ),
              const SizedBox(height: 24),

              // Nom field
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                    labelText: 'Nom du produit', prefixIcon: Icon(Icons.label)),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
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
                  labelText: 'Seuil d\'alerte (optionnel)',
                  prefixIcon: Icon(Icons.warning),
                  hintText: 'Quantité minimum avant alerte',
                  helperText: 'Laissez vide pour désactiver l\'alerte',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'Valeur invalide';
                    }
                    final threshold = double.parse(value);
                    if (threshold < 0) {
                      return 'Le seuil doit être positif';
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
                    : Text('Enregistrer les modifications',
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

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          'Appuyez pour ajouter/modifier une image (optionnel)',
          style: SafeFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
