import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/models/stock_item_model.dart';
import '../../../core/models/shortage_report_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/utils/responsive.dart';
import '../../auth/providers/auth_provider.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StockItem> _filterItems(List<StockItem> items, String query) {
    if (query.isEmpty && _selectedCategory == 'All') {
      return items;
    }

    return items.where((item) {
      final matchesSearch = query.isEmpty ||
          item.nom.toLowerCase().contains(query.toLowerCase()) ||
          item.categorie.toLowerCase().contains(query.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' ||
          item.categorie == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _showShortageReportDialog(StockItem item) {
    final commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Shortage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product: ${item.nom}'),
            const SizedBox(height: 8),
            Text(
                'Current Stock: ${item.quantite.toStringAsFixed(item.quantite.truncateToDouble() == item.quantite ? 0 : 1)} ${item.unite}'),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Comment (optional)',
                hintText: 'Ex: We are running low on milk',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();
              final user = authProvider.currentUser;
              if (user == null) return;

              final report = ShortageReport(
                id: '',
                stockItemId: item.id,
                stockItemName: item.nom,
                category: item.categorie,
                currentQuantity: item.quantite,
                unit: item.unite,
                userId: user.uid,
                userEmail: user.email,
                userName: null, // Username not available in current UserModel
                comment: commentController.text.trim().isEmpty
                    ? null
                    : commentController.text.trim(),
                timestamp: DateTime.now(),
              );

              try {
                await FirestoreService().reportShortage(report);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Shortage reported successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final route = ModalRoute.of(context)?.settings.name ?? '/user/stock';
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      drawer: AppDrawer(currentRoute: route),
      appBar: CustomAppBar(
        title: 'CoffeeStock',
        currentRoute: route,
      ),
      body: Column(
        children: [
          // Search and filter bar
          Padding(
            padding: Responsive.responsivePadding(context),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search for a product...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                // Category filter
                StreamBuilder<List<StockItem>>(
                  stream: FirestoreService().getStockItems(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final allCategories = snapshot.data!
                          .map((item) => item.categorie)
                          .toSet()
                          .toList();
                      if (_categories.length == 1 && allCategories.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() {
                            _categories = ['All', ...allCategories];
                          });
                        });
                      }
                    }
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((category) {
                          final isSelected = _selectedCategory == category;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = category;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Stock grid
          Expanded(
            child: StreamBuilder<List<StockItem>>(
              stream: FirestoreService().getStockItems(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget();
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erreur: ${snapshot.error}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  );
                }

                final allItems = snapshot.data ?? [];
                final filteredItems =
                    _filterItems(allItems, _searchController.text);

                if (filteredItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = Responsive.responsiveColumnCount(context, mobile: 2, tablet: 3, desktop: 4);
                    return GridView.builder(
                      padding: Responsive.responsivePadding(context),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: Responsive.responsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20),
                        mainAxisSpacing: Responsive.responsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20),
                        childAspectRatio: 0.85,
                      ),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        return _StockCard(
                          item: filteredItems[index],
                          onReportShortage: () =>
                              _showShortageReportDialog(filteredItems[index]),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  final StockItem item;
  final VoidCallback onReportShortage;

  const _StockCard({
    required this.item,
    required this.onReportShortage,
  });

  String _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'café':
      case 'cafe':
      case 'grains':
        return '☕';
      case 'lait':
        return '🥛';
      case 'jus':
        return '🧃';
      case 'sucre':
        return '🍬';
      case 'accessoire':
      case 'accessoires':
        return '🥤';
      default:
        return '📦';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLowStock = item.isLowStock;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isLowStock
            ? const BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isLowStock
              ? Colors.red.withValues(alpha: 0.05)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon/Image with low stock indicator
            Stack(
              children: [
                Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: item.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              item.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    _getCategoryIcon(item.categorie),
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Text(
                              _getCategoryIcon(item.categorie),
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                  ),
                ),
                if (isLowStock)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Product name
            Text(
              item.nom,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isLowStock ? Colors.red : theme.colorScheme.primary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Category
            Text(
              item.categorie,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const Spacer(),

            // Quantity with warning if low stock
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isLowStock
                    ? Colors.red.withValues(alpha: 0.1)
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.quantite.toStringAsFixed(
                        item.quantite.truncateToDouble() == item.quantite
                            ? 0
                            : 1),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color:
                          isLowStock ? Colors.red : theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.unite,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          isLowStock ? Colors.red : theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Report shortage button if low stock
            if (isLowStock)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onReportShortage,
                  icon: const Icon(Icons.warning, size: 16),
                  label: const Text('Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            const SizedBox(height: 8),

            // Last update
            Text(
              'Last updated: ${DateFormat('dd/MM/yyyy').format(item.misAJourLe)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
