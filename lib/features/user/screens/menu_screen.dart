import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/menu_item_model.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/utils/responsive.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/cart_provider.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final service = FirestoreService();
    final route = ModalRoute.of(context)?.settings.name ?? '/user/menu';
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Menu',
        currentRoute: route,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => Navigator.pushNamed(context, '/user/cart'),
          ),
        ],
      ),
      drawer: AppDrawer(currentRoute: route),
      body: StreamBuilder<List<MenuItemModel>>(
        stream: service.getMenuItems(onlyAvailable: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading menu: ${snapshot.error}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          
          final allItems = snapshot.data ?? const [];
          final items = allItems
              .where((e) => _query.isEmpty || e.name.toLowerCase().contains(_query.toLowerCase()) || e.description.toLowerCase().contains(_query.toLowerCase()))
              .toList();
          
          if (items.isEmpty) {
            if (_query.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No products found matching "$_query"',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No products available',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return Column(
            children: [
              Padding(
                padding: Responsive.responsiveHorizontalPadding(context).copyWith(top: 8),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search for a product...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = Responsive.isMobile(context);
                    if (isMobile) {
                      return ListView.separated(
                        padding: Responsive.responsivePadding(context),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => SizedBox(height: Responsive.responsiveSpacing(context)),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Card(
                            child: ListTile(
                              leading: item.images.isNotEmpty
                                  ? Image.network(item.images.first, width: 56, height: 56, fit: BoxFit.cover)
                                  : const Icon(Icons.local_cafe),
                              title: Text(item.name),
                              subtitle: Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('${item.price.toStringAsFixed(2)} TND'),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star, size: 14, color: Colors.amber),
                                      Text(item.rating.toStringAsFixed(1)),
                                    ],
                                  ),
                                ],
                              ),
                              onTap: () => Navigator.pushNamed(context, '/user/product', arguments: item),
                            ),
                          );
                        },
                      );
                    }
                    // Grid layout for tablet/desktop
                    final crossAxisCount = Responsive.responsiveColumnCount(context, mobile: 1, tablet: 2, desktop: 3);
                    return GridView.builder(
                      padding: Responsive.responsivePadding(context),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: Responsive.responsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20),
                        mainAxisSpacing: Responsive.responsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20),
                        childAspectRatio: 0.75,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Card(
                          child: InkWell(
                            onTap: () => Navigator.pushNamed(context, '/user/product', arguments: item),
                            borderRadius: BorderRadius.circular(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                    child: item.images.isNotEmpty
                                        ? Image.network(item.images.first, fit: BoxFit.cover)
                                        : Container(
                                            color: Theme.of(context).colorScheme.surfaceVariant,
                                            child: const Icon(Icons.local_cafe, size: 48),
                                          ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.description,
                                        style: Theme.of(context).textTheme.bodySmall,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${item.price.toStringAsFixed(2)} TND',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: Theme.of(context).colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.star, size: 16, color: Colors.amber),
                                              const SizedBox(width: 4),
                                              Text(item.rating.toStringAsFixed(1)),
                                            ],
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
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<CartProvider>(
        builder: (_, cart, __) => FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, '/user/cart'),
          label: Text('Cart (${cart.items.length})'),
          icon: const Icon(Icons.shopping_cart_checkout),
        ),
      ),
    );
  }
}


