import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/models/order_forecast_model.dart';
import '../../../core/models/stock_item_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../auth/providers/auth_provider.dart';

class OrderForecastsScreen extends StatefulWidget {
  const OrderForecastsScreen({super.key});

  @override
  State<OrderForecastsScreen> createState() => _OrderForecastsScreenState();
}

class _OrderForecastsScreenState extends State<OrderForecastsScreen> {
  bool _showUpcomingOnly = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final route =
        ModalRoute.of(context)?.settings.name ?? '/admin/order-forecasts';
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      drawer: AppDrawer(currentRoute: route),
      appBar: CustomAppBar(
        title: 'Order Forecasts',
        currentRoute: route,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Use Column layout on smaller screens
                if (constraints.maxWidth < 600) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Show upcoming only',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          Switch(
                            value: _showUpcomingOnly,
                            onChanged: (value) {
                              setState(() {
                                _showUpcomingOnly = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showAddForecastDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('New Forecast'),
                      ),
                    ],
                  );
                }
                // Use Row layout on larger screens
                return Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Show upcoming only',
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Switch(
                      value: _showUpcomingOnly,
                      onChanged: (value) {
                        setState(() {
                          _showUpcomingOnly = value;
                        });
                      },
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _showAddForecastDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('New Forecast'),
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<OrderForecast>>(
              stream: FirestoreService()
                  .getOrderForecasts(upcomingOnly: _showUpcomingOnly),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget();
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  );
                }

                final forecasts = snapshot.data ?? [];

                if (forecasts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 80,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No order forecasts',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add a forecast to plan orders',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: forecasts.length,
                  itemBuilder: (context, index) {
                    return _ForecastListItem(
                      forecast: forecasts[index],
                      onComplete: () =>
                          _completeForecast(context, forecasts[index].id),
                      onDelete: () =>
                          _deleteForecast(context, forecasts[index].id),
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

  Future<void> _showAddForecastDialog(BuildContext context) async {
    // Capture context before async operations
    final outerContext = context;
    final stockItems = await FirestoreService().getStockItems().first;
    if (!mounted) return;
    if (stockItems.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(outerContext).showSnackBar(
        const SnackBar(
          content: Text('No products available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    StockItem? selectedItem;
    final quantityController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    if (!mounted) return;
    await showDialog(
      context: outerContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('New Order Forecast'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<StockItem>(
                  decoration: const InputDecoration(labelText: 'Product'),
                  items: stockItems.map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text('${item.nom} (${item.categorie})'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedItem = value),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: quantityController,
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    suffixText: selectedItem?.unite ?? '',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                      'Scheduled Date: ${DateFormat('dd/MM/yyyy').format(selectedDate)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: dialogContext,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedItem == null || quantityController.text.isEmpty) {
                  return;
                }
                final quantity = double.tryParse(quantityController.text);
                if (quantity == null || quantity <= 0) {
                  return;
                }

                final user = dialogContext.read<AuthProvider>().currentUser;
                if (user == null) return;

                final forecast = OrderForecast(
                  id: '',
                  stockItemId: selectedItem!.id,
                  stockItemName: selectedItem!.nom,
                  category: selectedItem!.categorie,
                  quantity: quantity,
                  unit: selectedItem!.unite,
                  scheduledDate: selectedDate,
                  notes: notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim(),
                  createdBy: user.uid,
                  createdAt: DateTime.now(),
                );

                try {
                  await FirestoreService().createOrderForecast(forecast);
                  if (!mounted) return;
                  Navigator.pop(dialogContext);
                  if (!mounted) return;
                  ScaffoldMessenger.of(outerContext).showSnackBar(
                    const SnackBar(
                      content: Text('Forecast created successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(outerContext).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeForecast(BuildContext context, String id) async {
    try {
      await FirestoreService().completeOrderForecast(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Forecast marked as completed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteForecast(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Forecast'),
        content: const Text('Are you sure you want to delete this forecast?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirestoreService().deleteOrderForecast(id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Forecast deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
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
}

class _ForecastListItem extends StatelessWidget {
  final OrderForecast forecast;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const _ForecastListItem({
    required this.forecast,
    required this.onComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isPast = forecast.scheduledDate.isBefore(DateTime.now());
    final isCompleted = forecast.completed;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isCompleted ? 0 : 1,
      color: isCompleted
          ? theme.colorScheme.surface
          : isPast
              ? Colors.orange.withValues(alpha: 0.05)
              : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCompleted
              ? Colors.green.withValues(alpha: 0.3)
              : isPast
                  ? Colors.orange.withValues(alpha: 0.5)
                  : Colors.blue.withValues(alpha: 0.3),
          width: isCompleted || isPast ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: isCompleted
              ? Colors.green
              : isPast
                  ? Colors.orange
                  : Colors.blue,
          child: Icon(
            isCompleted ? Icons.check : Icons.calendar_today,
            color: Colors.white,
          ),
        ),
        title: Text(
          forecast.stockItemName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Category: ${forecast.category}'),
            const SizedBox(height: 4),
            Text(
              'Quantity: ${forecast.quantity.toStringAsFixed(forecast.quantity.truncateToDouble() == forecast.quantity ? 0 : 1)} ${forecast.unit}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
                Text(
                  'Date: ${dateFormat.format(forecast.scheduledDate)}',
                  style: theme.textTheme.bodySmall,
                ),
                if (isPast && !isCompleted) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'OVERDUE',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            if (forecast.notes != null && forecast.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Notes: ${forecast.notes}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
        trailing: !isCompleted
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: onComplete,
                    tooltip: 'Mark as completed',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                  ),
                ],
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Completed',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
      ),
    );
  }
}
