import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/menu_item_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/models/feedback_model.dart' as fb;
import '../../../core/utils/responsive.dart';
import '../providers/cart_provider.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final item = ModalRoute.of(context)!.settings.arguments as MenuItemModel;
    final cart = context.watch<CartProvider>();
    final service = FirestoreService();
    final ratingController = TextEditingController();
    final commentController = TextEditingController();
    String size = 'Medium';
    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: Responsive.responsiveContainer(
        context,
        child: SingleChildScrollView(
          padding: Responsive.responsivePadding(context),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.images.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(item.images.first, height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
            SizedBox(height: Responsive.responsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
            Text(
              item.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: Responsive.responsiveSpacing(context, mobile: 12)),
            Row(children: [
              const Icon(Icons.star, color: Colors.amber),
              SizedBox(width: Responsive.responsiveSpacing(context, mobile: 6)),
              Text(
                item.rating.toStringAsFixed(1),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ]),
            SizedBox(height: Responsive.responsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
            StreamBuilder<List<fb.FeedbackModel>>(
              stream: service.getFeedbacks(menuItemId: item.id),
              builder: (context, snapshot) {
                final list = snapshot.data ?? const [];
                if (list.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reviews',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: Responsive.responsiveSpacing(context)),
                    ...list.map((f) => Padding(
                      padding: EdgeInsets.only(bottom: Responsive.responsiveSpacing(context)),
                      child: Card(
                        child: ListTile(
                          leading: const Icon(Icons.person),
                          title: Row(
                            children: [
                              ...List.generate(5, (i) => Icon(
                                i < f.rating ? Icons.star : Icons.star_border,
                                size: Responsive.responsiveIconSize(context, mobile: 16, tablet: 18, desktop: 20),
                                color: Colors.amber,
                              )),
                            ],
                          ),
                          subtitle: f.comment == null ? null : Text(f.comment!),
                        ),
                      ),
                    )).toList(),
                  ],
                );
              },
            ),
            SizedBox(height: Responsive.responsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
            if (FirebaseAuth.instance.currentUser != null)
              Card(
                child: Padding(
                  padding: Responsive.responsivePadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Leave a Review',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: Responsive.responsiveSpacing(context)),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (Responsive.isMobile(context)) {
                            return Column(
                              children: [
                                TextField(
                                  controller: ratingController,
                                  decoration: const InputDecoration(labelText: 'Rating (1-5)'),
                                  keyboardType: TextInputType.number,
                                ),
                                SizedBox(height: Responsive.responsiveSpacing(context)),
                                TextField(
                                  controller: commentController,
                                  decoration: const InputDecoration(labelText: 'Comment (optional)'),
                                  maxLines: 3,
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: ratingController,
                                  decoration: const InputDecoration(labelText: 'Rating (1-5)'),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              SizedBox(width: Responsive.responsiveSpacing(context)),
                              Expanded(
                                child: TextField(
                                  controller: commentController,
                                  decoration: const InputDecoration(labelText: 'Comment (optional)'),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: Responsive.responsiveSpacing(context)),
                      ElevatedButton(
                        onPressed: () async {
                          final rating = int.tryParse(ratingController.text);
                          if (rating == null || rating < 1 || rating > 5) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid rating (1-5)')),
                            );
                            return;
                          }
                          try {
                            await service.submitFeedback(fb.FeedbackModel(
                              id: '',
                              userId: FirebaseAuth.instance.currentUser!.uid,
                              menuItemId: item.id,
                              rating: rating,
                              comment: commentController.text.trim().isEmpty ? null : commentController.text.trim(),
                              createdAt: DateTime.now(),
                            ));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Review submitted')),
                              );
                              ratingController.clear();
                              commentController.clear();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                        child: const Text('Submit Review'),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: Responsive.responsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
            Row(
              children: [
                const Text('Size:'),
                SizedBox(width: Responsive.responsiveSpacing(context)),
                StatefulBuilder(
                  builder: (context, setLocal) => DropdownButton<String>(
                    value: size,
                    items: const [
                      DropdownMenuItem(value: 'Small', child: Text('Small')),
                      DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'Large', child: Text('Large')),
                    ],
                    onChanged: (v) => setLocal(() => size = v ?? 'Medium'),
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.responsiveSpacing(context)),
            Row(
              children: [
                Text(
                  '${item.price.toStringAsFixed(2)} TND',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    cart.add(item, options: {'size': size});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Added to cart')),
                    );
                  },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Add'),
                ),
              ],
            ),
            SizedBox(height: Responsive.responsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
          ],
        ),
        ),
      ),
    );
  }
}


