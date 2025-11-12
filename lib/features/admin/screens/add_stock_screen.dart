import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _uploadingImage = false;

  final List<String> _categories = [
    'coffee',
    'milk',
    'juice',
    'sugar',
    'accessory'
  ];
  final List<String> _unites = ['g', 'L', 'pcs', 'kg', 'ml'];
  final ImagePicker _imagePicker = ImagePicker();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  @override
  void dispose() {
    _nomController.dispose();
    _quantiteController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );

      if (pickedFile != null && mounted) {
        setState(() => _selectedImage = File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadImageIfSelected() async {
    if (_selectedImage == null) return null;

    setState(() => _uploadingImage = true);

    try {
      debugPrint('Starting image upload...');
      final imageUrl = await _storageService.uploadImage(
        _selectedImage!,
        'stock_${DateTime.now().millisecondsSinceEpoch}',
      );
      debugPrint('Image upload successful: $imageUrl');
      return imageUrl;
    } catch (e) {
      debugPrint('Image upload failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => _uploadingImage = false);
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('Starting form submission...');

      // Upload image first (if selected)
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImageIfSelected();
        // Continue even if image upload fails
      }

      // Create stock item
      final stockItem = StockItem(
        id: '',
        nom: _nomController.text.trim(),
        categorie: _categorie,
        quantite: double.parse(_quantiteController.text.trim()),
        unite: _unite,
        imageUrl: imageUrl,
        misAJourLe: DateTime.now(),
        shortageThreshold: _thresholdController.text.trim().isEmpty
            ? null
            : double.tryParse(_thresholdController.text.trim()),
      );

      debugPrint('Adding product to Firestore: ${stockItem.nom}');
      await _firestoreService.addStockItem(stockItem);
      debugPrint('Product added successfully!');

      if (mounted) {
        // Clear the loading overlay before navigating
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Let the snackbar paint, then navigate away safely.
        await Future.delayed(const Duration(milliseconds: 50));
        if (!mounted) return;

        // If there's no route to pop (drawer uses pushReplacement),
        // replace with a known admin route to avoid a blank page on web.
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        } else {
          Navigator.pushReplacementNamed(context, '/admin/dashboard');
        }
      }
    } catch (e) {
      debugPrint('Error in form submission: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding product: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      // No-op: _isLoading may already be set to false on success before navigation.
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _removeImage() {
    if (mounted) {
      setState(() => _selectedImage = null);
    }
  }

  bool get _isFormDisabled => _isLoading || _uploadingImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final route = ModalRoute.of(context)?.settings.name ?? '/admin/add-stock';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      drawer: AppDrawer(currentRoute: route),
      appBar: CustomAppBar(title: 'Add Product', currentRoute: route),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // IMAGE PICKER
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _isFormDisabled ? null : _pickImage,
                          child: Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _selectedImage != null
                                ? Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                            color: theme
                                                .colorScheme.errorContainer,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.broken_image,
                                                  size: 48,
                                                  color:
                                                      theme.colorScheme.error,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Invalid Image',
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    color:
                                                        theme.colorScheme.error,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (_uploadingImage)
                                        Container(
                                          color: Colors.black.withOpacity(0.5),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          ),
                                        ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: CircleAvatar(
                                          backgroundColor: Colors.black54,
                                          radius: 16,
                                          child: IconButton(
                                            icon: const Icon(Icons.close,
                                                size: 16),
                                            color: Colors.white,
                                            onPressed: _isFormDisabled
                                                ? null
                                                : _removeImage,
                                            padding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate,
                                        size: 48,
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.7),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap to add an image',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '(Optional)',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // NAME
                  TextFormField(
                    controller: _nomController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name *',
                      prefixIcon: Icon(Icons.label),
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_isFormDisabled,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a product name';
                      }
                      if (value.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // CATEGORY
                  DropdownButtonFormField<String>(
                    value: _categorie,
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    items: _categories
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child:
                                  Text(cat[0].toUpperCase() + cat.substring(1)),
                            ))
                        .toList(),
                    onChanged: _isFormDisabled
                        ? null
                        : (value) {
                            if (value != null)
                              setState(() => _categorie = value);
                          },
                  ),
                  const SizedBox(height: 16),

                  // QUANTITY
                  TextFormField(
                    controller: _quantiteController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity *',
                      prefixIcon: Icon(Icons.numbers),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    enabled: !_isFormDisabled,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter quantity';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // UNIT
                  DropdownButtonFormField<String>(
                    value: _unite,
                    decoration: const InputDecoration(
                      labelText: 'Unit *',
                      prefixIcon: Icon(Icons.straighten),
                      border: OutlineInputBorder(),
                    ),
                    items: _unites
                        .map((unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            ))
                        .toList(),
                    onChanged: _isFormDisabled
                        ? null
                        : (value) {
                            if (value != null) setState(() => _unite = value);
                          },
                  ),
                  const SizedBox(height: 16),

                  // THRESHOLD (Optional)
                  TextFormField(
                    controller: _thresholdController,
                    decoration: const InputDecoration(
                      labelText: 'Low Stock Alert (Optional)',
                      prefixIcon: Icon(Icons.warning),
                      hintText: 'Leave empty for no alerts',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    enabled: !_isFormDisabled,
                  ),
                  const SizedBox(height: 32),

                  // SUBMIT BUTTON
                  ElevatedButton(
                    onPressed: _isFormDisabled ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: theme.colorScheme.primary,
                      disabledBackgroundColor:
                          theme.colorScheme.primary.withOpacity(0.5),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'ADD PRODUCT',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),

          // LOADING OVERLAY
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Adding Product...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
