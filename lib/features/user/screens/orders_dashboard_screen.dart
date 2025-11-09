import 'package:flutter/material.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/order_model.dart' as orders;
import '../../../core/widgets/app_drawer.dart';
import '../../../core/utils/responsive.dart';

class OrdersDashboardScreen extends StatelessWidget {
  const OrdersDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      drawer: const AppDrawer(currentRoute: '/employee/orders'),
      body: Responsive.responsiveContainer(
        context,
        child: StreamBuilder<List<orders.OrderModel>>(
          stream: service.getAllOrdersForEmployees(statuses: const ['Pending', 'Preparing', 'Ready']),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final ordersList = snapshot.data ?? const [];
            if (ordersList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: Responsive.responsiveIconSize(context, mobile: 80, tablet: 100, desktop: 120),
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    SizedBox(height: Responsive.responsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
                    Text(
                      'No orders',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: Responsive.responsiveFontSize(context, mobile: 18, tablet: 20, desktop: 24),
                      ),
                    ),
                  ],
                ),
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = Responsive.isMobile(context);
                if (isMobile) {
                  return ListView.separated(
                    padding: Responsive.responsivePadding(context),
                    itemCount: ordersList.length,
                    separatorBuilder: (_, __) => SizedBox(height: Responsive.responsiveSpacing(context)),
                    itemBuilder: (_, i) {
                      final order = ordersList[i];
                      return Card(
                        child: ListTile(
                          title: Text('Order ${order.id.substring(0, 6)} • ${order.orderType}'),
                          subtitle: Text('${order.items.length} items • ${order.totalPrice.toStringAsFixed(2)} TND'),
                          trailing: DropdownButton<orders.OrderStatus>(
                            value: order.status,
                            onChanged: (s) {
                              if (s != null) {
                                service.updateOrderStatus(order.id, s);
                              }
                            },
                            items: const [
                              DropdownMenuItem(value: orders.OrderStatus.pending, child: Text('Pending')),
                              DropdownMenuItem(value: orders.OrderStatus.preparing, child: Text('Preparing')),
                              DropdownMenuItem(value: orders.OrderStatus.ready, child: Text('Ready')),
                              DropdownMenuItem(value: orders.OrderStatus.completed, child: Text('Completed')),
                              DropdownMenuItem(value: orders.OrderStatus.cancelled, child: Text('Cancelled')),
                            ],
                          ),
                          onTap: () => Navigator.pushNamed(context, '/user/order-status', arguments: order.id),
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
                    childAspectRatio: 1.5,
                  ),
                  itemCount: ordersList.length,
                  itemBuilder: (context, index) {
                    final order = ordersList[index];
                    return Card(
                      child: InkWell(
                        onTap: () => Navigator.pushNamed(context, '/user/order-status', arguments: order.id),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: Responsive.responsivePadding(context),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order ${order.id.substring(0, 6)}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: Responsive.responsiveSpacing(context, mobile: 4)),
                                  Text(
                                    order.orderType,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  SizedBox(height: Responsive.responsiveSpacing(context, mobile: 8)),
                                  Text(
                                    '${order.items.length} items',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Text(
                                    '${order.totalPrice.toStringAsFixed(2)} TND',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              DropdownButton<orders.OrderStatus>(
                                value: order.status,
                                isExpanded: true,
                                onChanged: (s) {
                                  if (s != null) {
                                    service.updateOrderStatus(order.id, s);
                                  }
                                },
                                items: const [
                                  DropdownMenuItem(value: orders.OrderStatus.pending, child: Text('Pending')),
                                  DropdownMenuItem(value: orders.OrderStatus.preparing, child: Text('Preparing')),
                                  DropdownMenuItem(value: orders.OrderStatus.ready, child: Text('Ready')),
                                  DropdownMenuItem(value: orders.OrderStatus.completed, child: Text('Completed')),
                                  DropdownMenuItem(value: orders.OrderStatus.cancelled, child: Text('Cancelled')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}


