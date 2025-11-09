import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/order_model.dart' as orders;
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/utils/responsive.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/cart_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _loading = false;
  String _orderType = 'Takeaway';

  Future<void> _checkout() async {
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) return;
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      final service = FirestoreService();
      final order = orders.OrderModel(
        id: '',
        clientId: auth.currentUser!.uid,
        items: cart.items,
        totalPrice: cart.totalPrice,
        status: orders.OrderStatus.pending,
        orderType: _orderType,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final id = await service.createOrder(order);
      cart.clear();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/user/order-status',
          arguments: id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final route = ModalRoute.of(context)?.settings.name ?? '/user/cart';
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Cart',
        currentRoute: route,
      ),
      drawer: AppDrawer(currentRoute: route),
      body: Responsive.responsiveContainer(
        context,
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: Responsive.responsivePadding(context),
                itemBuilder: (_, i) {
                  final it = cart.items[i];
                  return ListTile(
                    title: Text(it.name),
                    subtitle: Text('x${it.quantity}'),
                    trailing: Text(
                        '${(it.price * it.quantity).toStringAsFixed(2)} TND'),
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: cart.items.length,
              ),
            ),
            Padding(
              padding: Responsive.responsivePadding(context),
              child: Column(
                children: [
                  Row(children: [
                    const Text('Order Type: '),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _orderType,
                      items: const [
                        DropdownMenuItem(
                            value: 'Dine-in', child: Text('Dine-in')),
                        DropdownMenuItem(
                            value: 'Takeaway', child: Text('Takeaway')),
                      ],
                      onChanged: (v) =>
                          setState(() => _orderType = v ?? 'Takeaway'),
                    )
                  ]),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Total:'),
                      const Spacer(),
                      Text('${cart.totalPrice.toStringAsFixed(2)} TND',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          _loading || cart.items.isEmpty ? null : _checkout,
                      icon: const Icon(Icons.payment),
                      label: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Place Order'),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
