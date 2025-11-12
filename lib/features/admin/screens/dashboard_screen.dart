import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../../../core/models/stock_item_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/export_service.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/theme/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _gridView = true;
  bool _isExporting = false;
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _exportStock(BuildContext context, bool isCSV) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final items = await FirestoreService().getStockItems().first;
      if (items.isEmpty) {
        if (context.mounted) {
          _showSnackBar(context, 'No data to export', AppColors.warningOrange,
              Icons.warning_amber_rounded);
        }
        return;
      }

      final exportService = ExportService();
      File file = isCSV
          ? await exportService.exportStockToCSV(items)
          : await exportService.exportStockToPDF(items);

      if (context.mounted) {
        _showSnackBar(
          context,
          'Export successful: ${file.path.split('/').last}',
          AppColors.successGreen,
          Icons.check_circle_rounded,
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () => OpenFile.open(file.path),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Export error: ${e.toString()}',
            AppColors.errorRed, Icons.error_outline_rounded);
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showSnackBar(
      BuildContext context, String message, Color color, IconData icon,
      {SnackBarAction? action}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
                child: Text(message,
                    style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        action: action,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final route = ModalRoute.of(context)?.settings.name ?? '/admin/dashboard';

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F6F4),
      drawer: AppDrawer(currentRoute: route),
      appBar: CustomAppBar(
        title: 'Dashboard',
        currentRoute: route,
        actions: [
          _buildViewToggle(isDark),
          const SizedBox(width: 12),
          _buildExportButton(context, isDark),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        color: isDark ? AppColors.premiumGold : AppColors.darkBrown,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildSearchSection(context, isDark)),
            _buildAnalyticsSection(context, isDark),
            SliverToBoxAdapter(
                child: _buildQuickActionsSection(context, isDark)),
            _buildStockItemsSection(context, isDark),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(context, isDark),
    );
  }

  Widget _buildViewToggle(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _ToggleButton(
              icon: Icons.grid_view_rounded,
              isSelected: _gridView,
              isDark: isDark,
              onTap: () => setState(() => _gridView = true),
            ),
            _ToggleButton(
              icon: Icons.view_list_rounded,
              isSelected: !_gridView,
              isDark: isDark,
              onTap: () => setState(() => _gridView = false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.premiumGold.withOpacity(0.15),
                  AppColors.premiumGold.withOpacity(0.05)
                ]
              : [
                  AppColors.darkBrown.withOpacity(0.1),
                  AppColors.darkBrown.withOpacity(0.05)
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.premiumGold.withOpacity(0.3)
              : AppColors.darkBrown.withOpacity(0.2),
        ),
      ),
      child: PopupMenuButton(
        icon: _isExporting
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? AppColors.premiumGold : AppColors.darkBrown,
                  ),
                ),
              )
            : Icon(Icons.download_rounded,
                color: isDark ? AppColors.premiumGold : AppColors.darkBrown),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        offset: const Offset(0, 50),
        elevation: 8,
        itemBuilder: (context) => [
          _buildExportMenuItem('CSV', Icons.table_chart_rounded,
              AppColors.successGreen, 'Spreadsheet format', 'export_csv'),
          _buildExportMenuItem('PDF', Icons.picture_as_pdf_rounded,
              AppColors.errorRed, 'Document format', 'export_pdf'),
        ],
        onSelected: (value) async {
          await _exportStock(context, value == 'export_csv');
        },
      ),
    );
  }

  PopupMenuItem _buildExportMenuItem(
      String title, IconData icon, Color color, String subtitle, String value) {
    return PopupMenuItem(
      value: value,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export $title',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.caramelBeige.withOpacity(0.7)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : AppColors.caramelBeige.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : AppColors.darkBrown.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: (_) => setState(() {}),
          style: TextStyle(
            color: isDark ? AppColors.lightText : AppColors.darkText,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Search for a product, category...',
            hintStyle: TextStyle(
              color: isDark
                  ? AppColors.caramelBeige.withOpacity(0.5)
                  : AppColors.darkBrown.withOpacity(0.4),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(16),
              child: Icon(
                Icons.search_rounded,
                color: isDark ? AppColors.premiumGold : AppColors.darkBrown,
                size: 24,
              ),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark
                          ? AppColors.caramelBeige.withOpacity(0.6)
                          : AppColors.darkBrown.withOpacity(0.5),
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsSection(BuildContext context, bool isDark) {
    return StreamBuilder<List<StockItem>>(
      stream: FirestoreService().getStockItems(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final items = snapshot.data!;
        final analytics = _calculateAnalytics(items);

        return SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _animationController,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              icon: Icons.inventory_2_rounded,
                              label: 'Products',
                              value: analytics.totalProducts.toString(),
                              color: isDark
                                  ? AppColors.premiumGold
                                  : AppColors.darkBrown,
                              trend: analytics.totalProducts > 0
                                  ? 'positive'
                                  : 'neutral',
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _MetricCard(
                              icon: Icons.category_rounded,
                              label: 'Categories',
                              value: analytics.categoriesCount.toString(),
                              color: AppColors.infoBlue,
                              trend: 'positive',
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              icon: Icons.analytics_rounded,
                              label: 'Total Quantity',
                              value: analytics.totalValue.toStringAsFixed(0),
                              color: AppColors.successGreen,
                              trend: 'positive',
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _MetricCard(
                              icon: Icons.warning_amber_rounded,
                              label: 'Alerts',
                              value: analytics.lowStockCount.toString(),
                              color: analytics.lowStockCount > 0
                                  ? AppColors.warningOrange
                                  : AppColors.successGreen,
                              trend: analytics.lowStockCount > 0
                                  ? 'negative'
                                  : 'neutral',
                              isDark: isDark,
                              onTap: analytics.lowStockCount > 0
                                  ? () => Navigator.pushNamed(
                                      context, '/admin/shortage-reports')
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionsSection(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.lightText : AppColors.darkText,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.history_rounded,
                  label: 'History',
                  color: AppColors.royalPurple,
                  isDark: isDark,
                  onTap: () => Navigator.pushNamed(context, '/admin/history'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _QuickAction(
                  icon: Icons.people_rounded,
                  label: 'Users',
                  color: AppColors.infoBlue,
                  isDark: isDark,
                  onTap: () => Navigator.pushNamed(context, '/admin/users'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _QuickAction(
                  icon: Icons.assessment_rounded,
                  label: 'Reports',
                  color: AppColors.accentTeal,
                  isDark: isDark,
                  onTap: () => Navigator.pushNamed(context, '/admin/reports'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockItemsSection(BuildContext context, bool isDark) {
    return StreamBuilder<List<StockItem>>(
      stream: FirestoreService().getStockItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: LoadingWidget(),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: _buildErrorState(context, snapshot.error.toString(), isDark),
          );
        }

        final items = snapshot.data ?? [];
        final filteredItems = _filterItems(items, _searchController.text);

        if (filteredItems.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildEmptyState(
                context, _searchController.text.isNotEmpty, isDark),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          sliver: _gridView
              ? _buildGridView(filteredItems, isDark)
              : _buildListView(filteredItems, isDark),
        );
      },
    );
  }

  Widget _buildFloatingActionButton(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.premiumGold.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/admin/add-stock');
          if (!context.mounted) return;
          if (result == true) {
            _showSnackBar(context, 'Product added successfully!',
                AppColors.successGreen, Icons.check_circle_rounded);
          }
        },
        backgroundColor: AppColors.premiumGold,
        foregroundColor: AppColors.darkBrown,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text(
          'New Product',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }

  AnalyticsData _calculateAnalytics(List<StockItem> items) {
    return AnalyticsData(
      totalProducts: items.length,
      lowStockCount: items.where((item) => item.isLowStock).length,
      categoriesCount: items.map((item) => item.categorie).toSet().length,
      totalValue: items.fold(0.0, (sum, item) => sum + item.quantite),
    );
  }

  List<StockItem> _filterItems(List<StockItem> items, String query) {
    if (query.isEmpty) return items;
    final lowerQuery = query.toLowerCase();
    return items.where((item) {
      return item.nom.toLowerCase().contains(lowerQuery) ||
          item.categorie.toLowerCase().contains(lowerQuery) ||
          item.unite.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  Widget _buildErrorState(BuildContext context, String error, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(40),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.errorRed.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.errorRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.errorRed),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading Error',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.errorRed,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.caramelBeige.withOpacity(0.6)
                      : AppColors.darkBrown.withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isSearch, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(40),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  (isDark ? AppColors.premiumGold : AppColors.darkBrown)
                      .withOpacity(0.2),
                  (isDark ? AppColors.premiumGold : AppColors.darkBrown)
                      .withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSearch ? Icons.search_off_rounded : Icons.inventory_2_outlined,
              size: 48,
              color: isDark ? AppColors.premiumGold : AppColors.darkBrown,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isSearch ? 'No Results' : 'Empty Inventory',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.lightText : AppColors.darkText,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearch
                ? 'Try other search terms'
                : 'Start by adding your first product',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.caramelBeige.withOpacity(0.6)
                      : AppColors.darkBrown.withOpacity(0.6),
                ),
          ),
          if (!isSearch) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/admin/add-stock'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add a Product'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGridView(List<StockItem> items, bool isDark) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        int crossAxisCount = width >= 1200
            ? 4
            : width >= 900
                ? 3
                : width >= 600
                    ? 2
                    : 1;

        return SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _ProductCard(
              item: items[index],
              isDark: isDark,
              onEdit: () => _navigateToEdit(context, items[index]),
              onDelete: () => _showDeleteDialog(context, items[index]),
              onStockIn: () => _showStockDialog(context, items[index], true),
              onStockOut: () => _showStockDialog(context, items[index], false),
            ),
            childCount: items.length,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.85,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
        );
      },
    );
  }

  Widget _buildListView(List<StockItem> items, bool isDark) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _ProductListCard(
            item: items[index],
            isDark: isDark,
            onEdit: () => _navigateToEdit(context, items[index]),
            onDelete: () => _showDeleteDialog(context, items[index]),
            onStockIn: () => _showStockDialog(context, items[index], true),
            onStockOut: () => _showStockDialog(context, items[index], false),
          ),
        ),
        childCount: items.length,
      ),
    );
  }

  void _navigateToEdit(BuildContext context, StockItem item) {
    Navigator.pushNamed(context, '/admin/edit-stock', arguments: item);
  }

  void _showStockDialog(BuildContext context, StockItem item, bool isAdd) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    (isAdd ? AppColors.successGreen : AppColors.warningOrange)
                        .withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isAdd ? Icons.add_circle_rounded : Icons.remove_circle_rounded,
                color: isAdd ? AppColors.successGreen : AppColors.warningOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isAdd ? 'Add Stock' : 'Remove Stock',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : AppColors.caramelBeige.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nom,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_rounded,
                        size: 16,
                        color: AppColors.caramelBeige.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Current stock: ${item.quantite.toStringAsFixed(item.quantite.truncateToDouble() == item.quantite ? 0 : 1)} ${item.unite}',
                        style: TextStyle(
                          color: AppColors.caramelBeige.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Quantity',
                hintText: 'Enter quantity',
                suffixText: item.unite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.05),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isAdd ? AppColors.successGreen : AppColors.warningOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              final quantity = double.tryParse(controller.text.trim());
              if (quantity == null || quantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Invalid quantity'),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              try {
                final newQuantity =
                    isAdd ? item.quantite + quantity : item.quantite - quantity;

                if (newQuantity < 0) {
                  throw Exception('Insufficient stock');
                }

                await FirestoreService().updateStockItem(item.copyWith(
                    quantite: newQuantity, misAJourLe: DateTime.now()));

                if (context.mounted) {
                  _showSnackBar(
                    context,
                    'Stock ${isAdd ? 'added' : 'removed'} successfully',
                    AppColors.successGreen,
                    Icons.check_circle_rounded,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  _showSnackBar(context, 'Error: ${e.toString()}',
                      AppColors.errorRed, Icons.error_outline_rounded);
                }
              }
            },
            child: Text(isAdd ? 'Add' : 'Remove'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, StockItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.delete_rounded, color: AppColors.errorRed),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delete',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${item.nom}"?',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 16, color: AppColors.errorRed),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action is irreversible',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.errorRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirestoreService().deleteStockItem(item.id);
                if (context.mounted) {
                  _showSnackBar(context, '${item.nom} deleted',
                      AppColors.successGreen, Icons.check_circle_rounded);
                }
              } catch (e) {
                if (context.mounted) {
                  _showSnackBar(context, 'Error: ${e.toString()}',
                      AppColors.errorRed, Icons.error_outline_rounded);
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Data Classes
class AnalyticsData {
  final int totalProducts;
  final int lowStockCount;
  final int categoriesCount;
  final double totalValue;

  AnalyticsData({
    required this.totalProducts,
    required this.lowStockCount,
    required this.categoriesCount,
    required this.totalValue,
  });
}

// Toggle Button Widget
class _ToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: isDark
                      ? [
                          AppColors.premiumGold,
                          AppColors.premiumGold.withOpacity(0.8)
                        ]
                      : [
                          AppColors.darkBrown,
                          AppColors.darkBrown.withOpacity(0.8)
                        ],
                )
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected
              ? (isDark ? AppColors.darkBrown : Colors.white)
              : (isDark
                  ? AppColors.caramelBeige.withOpacity(0.6)
                  : AppColors.darkBrown.withOpacity(0.5)),
        ),
      ),
    );
  }
}

// Metric Card Widget
class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String trend;
  final bool isDark;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.trend,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : color.withOpacity(0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : color.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                if (trend != 'neutral')
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: (trend == 'positive'
                              ? AppColors.successGreen
                              : AppColors.errorRed)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      trend == 'positive'
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 16,
                      color: trend == 'positive'
                          ? AppColors.successGreen
                          : AppColors.errorRed,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.caramelBeige.withOpacity(0.7)
                    : AppColors.darkBrown.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Quick Action Widget
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : color.withOpacity(0.15),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.lightText : AppColors.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Product Card Widget
class _ProductCard extends StatelessWidget {
  final StockItem item;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onStockIn;
  final VoidCallback onStockOut;

  const _ProductCard({
    required this.item,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
    required this.onStockIn,
    required this.onStockOut,
  });

  @override
  Widget build(BuildContext context) {
    final isLowStock = item.isLowStock;
    final threshold = item.shortageThreshold;
    final fillRatio = threshold != null && threshold > 0
        ? (item.quantite / threshold).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLowStock
              ? AppColors.warningOrange.withOpacity(0.5)
              : (isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05)),
          width: isLowStock ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isLowStock
                ? AppColors.warningOrange.withOpacity(0.15)
                : (isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.04)),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    (isDark ? AppColors.premiumGold : AppColors.darkBrown)
                        .withOpacity(0.15),
                    (isDark ? AppColors.premiumGold : AppColors.darkBrown)
                        .withOpacity(0.05),
                  ],
                ),
              ),
              child: item.imageUrl != null
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
          ),
          // Content Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.nom,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.lightText
                                : AppColors.darkText,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isLowStock)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.warningOrange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          (isDark ? AppColors.premiumGold : AppColors.darkBrown)
                              .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.categorie,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.premiumGold
                            : AppColors.darkBrown,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${item.quantite.toStringAsFixed(item.quantite.truncateToDouble() == item.quantite ? 0 : 1)} ${item.unite}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isLowStock
                          ? AppColors.warningOrange
                          : (isDark
                              ? AppColors.premiumGold
                              : AppColors.darkBrown),
                    ),
                  ),
                  if (threshold != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fillRatio,
                        minHeight: 6,
                        backgroundColor:
                            AppColors.caramelBeige.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isLowStock
                              ? AppColors.warningOrange
                              : AppColors.successGreen,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.add_rounded,
                          color: AppColors.successGreen,
                          onTap: onStockIn,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.remove_rounded,
                          color: AppColors.warningOrange,
                          onTap: onStockOut,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.edit_rounded,
                          color: isDark
                              ? AppColors.premiumGold
                              : AppColors.darkBrown,
                          onTap: onEdit,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.delete_rounded,
                          color: AppColors.errorRed,
                          onTap: onDelete,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.inventory_2_rounded,
        size: 48,
        color: (isDark ? AppColors.premiumGold : AppColors.darkBrown)
            .withOpacity(0.3),
      ),
    );
  }
}

// Product List Card Widget
class _ProductListCard extends StatelessWidget {
  final StockItem item;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onStockIn;
  final VoidCallback onStockOut;

  const _ProductListCard({
    required this.item,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
    required this.onStockIn,
    required this.onStockOut,
  });

  @override
  Widget build(BuildContext context) {
    final isLowStock = item.isLowStock;
    final threshold = item.shortageThreshold;
    final fillRatio = threshold != null && threshold > 0
        ? (item.quantite / threshold).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLowStock
              ? AppColors.warningOrange.withOpacity(0.5)
              : (isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.05)),
          width: isLowStock ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isLowStock
                ? AppColors.warningOrange.withOpacity(0.15)
                : (isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.04)),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (isDark ? AppColors.premiumGold : AppColors.darkBrown)
                      .withOpacity(0.15),
                  (isDark ? AppColors.premiumGold : AppColors.darkBrown)
                      .withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: item.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.inventory_2_rounded,
                        size: 32,
                        color: (isDark
                                ? AppColors.premiumGold
                                : AppColors.darkBrown)
                            .withOpacity(0.3),
                      ),
                    ),
                  )
                : Icon(
                    Icons.inventory_2_rounded,
                    size: 32,
                    color:
                        (isDark ? AppColors.premiumGold : AppColors.darkBrown)
                            .withOpacity(0.3),
                  ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.nom,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? AppColors.lightText : AppColors.darkText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLowStock)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warningOrange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.warningOrange.withOpacity(0.5)),
                        ),
                        child: Text(
                          'Low Stock',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warningOrange,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? AppColors.premiumGold
                                : AppColors.darkBrown)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.categorie,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.premiumGold
                              : AppColors.darkBrown,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.quantite.toStringAsFixed(item.quantite.truncateToDouble() == item.quantite ? 0 : 1)} ${item.unite}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isLowStock
                            ? AppColors.warningOrange
                            : (isDark
                                ? AppColors.premiumGold
                                : AppColors.darkBrown),
                      ),
                    ),
                  ],
                ),
                if (threshold != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fillRatio,
                      minHeight: 6,
                      backgroundColor: AppColors.caramelBeige.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isLowStock
                            ? AppColors.warningOrange
                            : AppColors.successGreen,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Actions
          Column(
            children: [
              Row(
                children: [
                  _ActionBtn(
                    icon: Icons.add_rounded,
                    color: AppColors.successGreen,
                    onTap: onStockIn,
                    small: true,
                  ),
                  const SizedBox(width: 8),
                  _ActionBtn(
                    icon: Icons.remove_rounded,
                    color: AppColors.warningOrange,
                    onTap: onStockOut,
                    small: true,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _ActionBtn(
                    icon: Icons.edit_rounded,
                    color: isDark ? AppColors.premiumGold : AppColors.darkBrown,
                    onTap: onEdit,
                    small: true,
                  ),
                  const SizedBox(width: 8),
                  _ActionBtn(
                    icon: Icons.delete_rounded,
                    color: AppColors.errorRed,
                    onTap: onDelete,
                    small: true,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Action Button Widget
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool small;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(small ? 10 : 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: small ? 18 : 20),
      ),
    );
  }
}
