import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/stock_item_model.dart';
import '../models/stock_history_model.dart';
import '../models/shortage_report_model.dart';
import '../models/user_model.dart';
import '../models/order_forecast_model.dart';
import '../models/menu_item_model.dart';
import '../models/order_model.dart' as orders;
import '../models/feedback_model.dart' as fb;
import '../models/complaint_model.dart';
import '../models/complaint_message_model.dart';
import '../errors/app_exception.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Optional: allow injection for testing
  FirestoreService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<String> _requireSignedInUid() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AppException('auth-required', 'You must be logged in.');
    }
    return user.uid;
  }

  Future<bool> _isCurrentUserAdmin() async {
    final uid = await _requireSignedInUid();
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final role = (doc.data() ?? const {})['role'] as String?;
      return role == 'admin';
    } catch (e) {
      throw const AppException('firestore', "Unable to verify user role.");
    }
  }

  // Get all stock items (real-time stream)
  Stream<List<StockItem>> getStockItems() {
    // Only allow if user is signed-in
    if (_auth.currentUser == null) {
      return Stream.error(
          const AppException('auth-required', 'You must be logged in.'));
    }
    return _firestore
        .collection('stock')
        .orderBy('misAJourLe', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => StockItem.fromFirestore(doc)).toList());
  }

  // Get single stock item
  Future<StockItem?> getStockItem(String id) async {
    try {
      await _requireSignedInUid();
      final doc = await _firestore.collection('stock').doc(id).get();
      if (doc.exists) {
        return StockItem.fromFirestore(doc);
      }
      return null;
    } on AppException {
      rethrow;
    } on FirebaseException catch (e) {
      throw AppException(
          'firestore', 'Error retrieving: ${e.message ?? e.code}');
    } catch (e) {
      throw const AppException('unknown', 'Error retrieving');
    }
  }

  // Add stock item
  Future<String> addStockItem(StockItem item) async {
    try {
      if (!await _isCurrentUserAdmin()) {
        throw const AppException(
            'permission-denied', 'Action reserved for administrators.');
      }
      final user = _auth.currentUser;
      if (user == null) {
        throw const AppException('auth-required', 'You must be logged in.');
      }

      final docRef =
          await _firestore.collection('stock').add(item.toFirestore());
      final itemId = docRef.id;

      // Verify write by reading back
      final verify = await docRef.get();
      if (!verify.exists) {
        throw const AppException('firestore', "L'élément n'a pas été créé.");
      }

      // Record history
      final history = StockHistory(
        id: '',
        type: HistoryType.input,
        stockItemId: itemId,
        stockItemName: item.nom,
        category: item.categorie,
        quantityChange: item.quantite,
        unit: item.unite,
        userId: user.uid,
        userEmail: user.email,
        timestamp: DateTime.now(),
      );
      await _recordHistory(history);

      return itemId;
    } on AppException {
      rethrow;
    } on FirebaseException catch (e) {
      throw AppException('firestore', "Error adding: ${e.message ?? e.code}");
    } catch (e) {
      throw const AppException('unknown', "Error adding");
    }
  }

  // Update stock item
  Future<void> updateStockItem(StockItem item) async {
    try {
      if (!await _isCurrentUserAdmin()) {
        throw const AppException(
            'permission-denied', 'Action reserved for administrators.');
      }
      final user = _auth.currentUser;
      if (user == null) {
        throw const AppException('auth-required', 'You must be logged in.');
      }

      // Get previous item to track changes
      final docRef = _firestore.collection('stock').doc(item.id);
      final previousDoc = await docRef.get();
      StockItem? previousItem;
      if (previousDoc.exists) {
        previousItem = StockItem.fromFirestore(previousDoc);
      }

      await docRef.update(item.toFirestore());

      // Verify by fetching
      final verify = await docRef.get();
      if (!verify.exists) {
        throw const AppException('firestore', "Item not found after update.");
      }

      // Record history
      if (previousItem != null) {
        final quantityChange = item.quantite - previousItem.quantite;
        HistoryType historyType;
        if (quantityChange > 0) {
          historyType = HistoryType.input;
        } else if (quantityChange < 0) {
          historyType = HistoryType.output;
        } else {
          historyType = HistoryType.update;
        }

        final history = StockHistory(
          id: '',
          type: historyType,
          stockItemId: item.id,
          stockItemName: item.nom,
          category: item.categorie,
          quantityChange: quantityChange.abs(),
          previousQuantity: previousItem.quantite,
          newQuantity: item.quantite,
          unit: item.unite,
          userId: user.uid,
          userEmail: user.email,
          timestamp: DateTime.now(),
        );
        await _recordHistory(history);
      }
    } on AppException {
      rethrow;
    } on FirebaseException catch (e) {
      throw AppException('firestore', 'Error updating: ${e.message ?? e.code}');
    } catch (e) {
      throw const AppException('unknown', 'Error updating');
    }
  }

  // Delete stock item
  Future<void> deleteStockItem(String id) async {
    try {
      if (!await _isCurrentUserAdmin()) {
        throw const AppException(
            'permission-denied', 'Action reserved for administrators.');
      }
      final user = _auth.currentUser;
      if (user == null) {
        throw const AppException('auth-required', 'You must be logged in.');
      }

      // Get item data before deletion for history
      final docRef = _firestore.collection('stock').doc(id);
      final itemDoc = await docRef.get();
      StockItem? deletedItem;
      if (itemDoc.exists) {
        deletedItem = StockItem.fromFirestore(itemDoc);
      }

      await docRef.delete();

      // Verify by checking existence
      final verify = await docRef.get();
      if (verify.exists) {
        throw const AppException('firestore', "Deletion was not confirmed.");
      }

      // Record history
      if (deletedItem != null) {
        final history = StockHistory(
          id: '',
          type: HistoryType.output,
          stockItemId: id,
          stockItemName: deletedItem.nom,
          category: deletedItem.categorie,
          quantityChange: deletedItem.quantite,
          unit: deletedItem.unite,
          userId: user.uid,
          userEmail: user.email,
          timestamp: DateTime.now(),
        );
        await _recordHistory(history);
      }
    } on AppException {
      rethrow;
    } on FirebaseException catch (e) {
      throw AppException('firestore', 'Error deleting: ${e.message ?? e.code}');
    } catch (e) {
      throw const AppException('unknown', 'Error deleting');
    }
  }

  // Record history entry
  Future<void> _recordHistory(StockHistory history) async {
    try {
      await _firestore.collection('history').add(history.toFirestore());
    } catch (e) {
      debugPrint('Failed to record history: $e');
    }
  }

  // Get history entries
  Stream<List<StockHistory>> getHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? productId,
    String? userId,
  }) {
    if (_auth.currentUser == null) {
      return Stream.error(
          const AppException('auth-required', 'You must be logged in.'));
    }

    Query query = _firestore.collection('history');

    if (startDate != null) {
      query = query.where('timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('timestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }
    if (productId != null) {
      query = query.where('stockItemId', isEqualTo: productId);
    }
    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    return query
        .orderBy('timestamp', descending: true)
        .limit(500)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StockHistory.fromFirestore(doc))
            .toList());
  }

  // Report shortage (for users)
  Future<void> reportShortage(ShortageReport report) async {
    try {
      await _requireSignedInUid();
      await _firestore.collection('shortageReports').add(report.toFirestore());
    } on FirebaseException catch (e) {
      throw AppException(
          'firestore', 'Error reporting: ${e.message ?? e.code}');
    }
  }

  // Get shortage reports (admin only)
  Stream<List<ShortageReport>> getShortageReports(
      {bool unresolvedOnly = false}) {
    if (_auth.currentUser == null) {
      return Stream.error(
          const AppException('auth-required', 'You must be logged in.'));
    }
    if (unresolvedOnly) {
      // Avoid composite index requirement by removing orderBy and sorting in memory.
      return _firestore
          .collection('shortageReports')
          .where('resolved', isEqualTo: false)
          .snapshots()
          .map((snapshot) {
        final list = snapshot.docs
            .map((doc) => ShortageReport.fromFirestore(doc))
            .toList();
        list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return list;
      });
    }
    return _firestore
        .collection('shortageReports')
        .orderBy('timestamp', descending: true)
        .limit(500)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShortageReport.fromFirestore(doc))
            .toList());
  }

  // Mark shortage report as resolved (admin only)
  Future<void> resolveShortageReport(String reportId) async {
    try {
      if (!await _isCurrentUserAdmin()) {
        throw const AppException(
            'permission-denied', 'Action reserved for administrators.');
      }
      await _firestore
          .collection('shortageReports')
          .doc(reportId)
          .update({'resolved': true});
    } on FirebaseException catch (e) {
      throw AppException(
          'firestore', 'Error resolving: ${e.message ?? e.code}');
    }
  }

  // Get stock analytics (admin only)
  Future<Map<String, dynamic>> getStockAnalytics() async {
    try {
      if (!await _isCurrentUserAdmin()) {
        throw const AppException(
            'permission-denied', 'Action reserved for administrators.');
      }

      final items = await _firestore.collection('stock').get();
      final history = await _firestore
          .collection('history')
          .where('timestamp',
              isGreaterThan: Timestamp.fromDate(
                DateTime.now().subtract(const Duration(days: 30)),
              ))
          .get();

      final itemsList =
          items.docs.map((doc) => StockItem.fromFirestore(doc)).toList();
      final historyList =
          history.docs.map((doc) => StockHistory.fromFirestore(doc)).toList();

      // Calculate total stock value (estimated - sum of quantities)
      double totalValue = 0;
      for (var item in itemsList) {
        totalValue += item.quantite;
      }

      // Most used products (by output/consumption)
      final productUsage = <String, double>{};
      for (var h in historyList) {
        if (h.type == HistoryType.output) {
          productUsage[h.stockItemName] =
              (productUsage[h.stockItemName] ?? 0) + h.quantityChange;
        }
      }
      final mostUsed = productUsage.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Daily consumption (last 30 days)
      final dailyConsumption = <String, double>{};
      for (var h in historyList) {
        if (h.type == HistoryType.output) {
          final dateKey = DateFormat('yyyy-MM-dd').format(h.timestamp);
          dailyConsumption[dateKey] =
              (dailyConsumption[dateKey] ?? 0) + h.quantityChange;
        }
      }

      return {
        'totalValue': totalValue,
        'mostUsedProducts': mostUsed
            .take(5)
            .map((e) => {'name': e.key, 'quantity': e.value})
            .toList(),
        'dailyConsumption': dailyConsumption,
        'totalProducts': itemsList.length,
        'lowStockCount': itemsList.where((item) => item.isLowStock).length,
      };
    } on FirebaseException catch (e) {
      throw AppException(
          'firestore', 'Error analyzing: ${e.message ?? e.code}');
    }
  }

  // Get all users (admin only)
  Stream<List<UserModel>> getAllUsers() {
    if (_auth.currentUser == null) {
      return Stream.error(
          const AppException('auth-required', 'You must be logged in.'));
    }
    return _firestore.collection('users').snapshots().map((snapshot) {
      final users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc.data(), doc.id))
          .toList();
      // Sort by createdAt descending (newest first), with nulls last
      users.sort((a, b) {
        if (a.createdAt.isAfter(b.createdAt)) return -1;
        if (a.createdAt.isBefore(b.createdAt)) return 1;
        return 0;
      });
      return users;
    });
  }

  // Update user role (admin only)
  Future<void> updateUserRole(String userId, String role) async {
    try {
      debugPrint(
          '[FirestoreService] updateUserRole called: userId=$userId, role=$role');

      // Validate role
      if (role != 'admin' && role != 'employee' && role != 'client') {
        debugPrint('[FirestoreService] Invalid role: $role');
        throw const AppException('invalid-role',
            'Invalid role specified. Must be admin, employee, or client.');
      }

      // Check admin permission
      final isAdmin = await _isCurrentUserAdmin();
      debugPrint('[FirestoreService] Current user is admin: $isAdmin');

      if (!isAdmin) {
        throw const AppException(
            'permission-denied', 'Action reserved for administrators.');
      }

      // Update the role
      debugPrint('[FirestoreService] Updating user role in Firestore...');
      await _firestore.collection('users').doc(userId).update({'role': role});
      debugPrint('[FirestoreService] Role updated successfully');

      // Verify the update
      final verifyDoc = await _firestore.collection('users').doc(userId).get();
      if (verifyDoc.exists) {
        final updatedRole = verifyDoc.data()?['role'] as String?;
        debugPrint(
            '[FirestoreService] Verified role in database: $updatedRole');
        if (updatedRole != role) {
          debugPrint(
              '[FirestoreService] WARNING: Role mismatch! Expected: $role, Got: $updatedRole');
        }
      }
    } on FirebaseException catch (e) {
      debugPrint(
          '[FirestoreService] FirebaseException: ${e.code} - ${e.message}');
      throw AppException('firestore', 'Update error: ${e.message ?? e.code}');
    } on AppException {
      rethrow;
    } catch (e) {
      debugPrint('[FirestoreService] Unexpected error: $e');
      throw AppException('firestore', 'Unexpected error updating role: $e');
    }
  }

  // Delete user (admin only)
  Future<void> deleteUser(String userId) async {
    try {
      if (!await _isCurrentUserAdmin()) {
        throw const AppException(
            'permission-denied', 'Action reserved for administrators.');
      }
      await _firestore.collection('users').doc(userId).delete();
    } on FirebaseException catch (e) {
      throw AppException('firestore', 'Delete error: ${e.message ?? e.code}');
    }
  }

  // Order Forecasts (admin only)
  Future<void> createOrderForecast(OrderForecast forecast) async {
    try {
      if (!await _isCurrentUserAdmin()) {
        throw const AppException(
            'permission-denied', 'Action reserved for administrators.');
      }
      await _firestore.collection('orderForecasts').add(forecast.toFirestore());
    } on FirebaseException catch (e) {
      throw AppException('firestore', 'Error creating: ${e.message ?? e.code}');
    }
  }

  Stream<List<OrderForecast>> getOrderForecasts({bool upcomingOnly = false}) {
    if (_auth.currentUser == null) {
      return Stream.error(
          const AppException('auth-required', 'You must be logged in.'));
    }

    Query query = _firestore.collection('orderForecasts');

    if (upcomingOnly) {
      query = query.where('scheduledDate',
          isGreaterThan: Timestamp.fromDate(DateTime.now()));
    }

    return query.orderBy('scheduledDate', descending: false).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => OrderForecast.fromFirestore(doc))
            .toList());
  }

  Future<void> updateOrderForecast(OrderForecast forecast) async {
    try {
      if (!await _isCurrentUserAdmin()) {
        throw const AppException(
            'permission-denied', 'Action reserved for administrators.');
      }
      await _firestore
          .collection('orderForecasts')
          .doc(forecast.id)
          .update(forecast.toFirestore());
    } on FirebaseException catch (e) {
      throw AppException('firestore', 'Update error: ${e.message ?? e.code}');
    }
  }

  Future<void> deleteOrderForecast(String id) async {
    try {
      if (!await _isCurrentUserAdmin()) {
        throw const AppException(
            'permission-denied', 'Action reserved for administrators.');
      }
      await _firestore.collection('orderForecasts').doc(id).delete();
    } on FirebaseException catch (e) {
      throw AppException('firestore', 'Delete error: ${e.message ?? e.code}');
    }
  }

  Future<void> completeOrderForecast(String id) async {
    try {
      if (!await _isCurrentUserAdmin()) {
        throw const AppException(
            'permission-denied', 'Action reserved for administrators.');
      }
      await _firestore
          .collection('orderForecasts')
          .doc(id)
          .update({'completed': true});
    } on FirebaseException catch (e) {
      throw AppException(
          'firestore', 'Error completing: ${e.message ?? e.code}');
    }
  }

  // ======================= MENU ITEMS =======================
  Stream<List<MenuItemModel>> getMenuItems(
      {String? category, bool? onlyAvailable}) {
    if (_auth.currentUser == null) {
      return Stream.error(
          const AppException('auth-required', 'You must be logged in.'));
    }
    Query query = _firestore.collection('menuItems');
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    if (onlyAvailable == true) {
      query = query.where('available', isEqualTo: true);
    }
    // Note: When using where() with orderBy(), Firestore requires a composite index
    // If index doesn't exist, we'll sort in memory instead
    return query.snapshots().map((s) {
      final items = s.docs.map((d) => MenuItemModel.fromFirestore(d)).toList();
      // Sort by name in memory
      items.sort((a, b) => a.name.compareTo(b.name));
      return items;
    });
  }

  Future<String> addMenuItem(MenuItemModel item) async {
    try {
      if (!await _isCurrentUserAdmin()) {
        throw const AppException(
            'permission-denied', 'Action reserved for administrators.');
      }
      final ref =
          await _firestore.collection('menuItems').add(item.toFirestore());
      return ref.id;
    } on FirebaseException catch (e) {
      throw AppException('firestore', 'Error creating: ${e.message ?? e.code}');
    }
  }

  Future<void> updateMenuItem(MenuItemModel item) async {
    try {
      if (!await _isCurrentUserAdmin()) {
        throw const AppException(
            'permission-denied', 'Action reserved for administrators.');
      }
      await _firestore
          .collection('menuItems')
          .doc(item.id)
          .update(item.toFirestore());
    } on FirebaseException catch (e) {
      throw AppException('firestore', 'Update error: ${e.message ?? e.code}');
    }
  }

  Future<void> deleteMenuItem(String id) async {
    try {
      if (!await _isCurrentUserAdmin()) {
        throw const AppException(
            'permission-denied', 'Action reserved for administrators.');
      }
      await _firestore.collection('menuItems').doc(id).delete();
    } on FirebaseException catch (e) {
      throw AppException('firestore', 'Delete error: ${e.message ?? e.code}');
    }
  }

  // ========================= ORDERS =========================
  Future<String> createOrder(orders.OrderModel order) async {
    try {
      final uid = await _requireSignedInUid();
      final ref = await _firestore.collection('orders').add(order
          .copyWith(
            clientId: uid,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          )
          .toFirestore());
      return ref.id;
    } on FirebaseException catch (e) {
      throw AppException(
          'firestore', 'Error creating order: ${e.message ?? e.code}');
    }
  }

  Stream<List<orders.OrderModel>> getMyOrders() {
    if (_auth.currentUser == null) {
      return Stream.error(
          const AppException('auth-required', 'You must be logged in.'));
    }
    return _firestore
        .collection('orders')
        .where('clientId', isEqualTo: _auth.currentUser!.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => orders.OrderModel.fromFirestore(d)).toList());
  }

  Stream<List<orders.OrderModel>> getAllOrdersForEmployees(
      {List<String>? statuses}) {
    if (_auth.currentUser == null) {
      return Stream.error(
          const AppException('auth-required', 'You must be logged in.'));
    }
    Query query = _firestore.collection('orders');
    if (statuses != null && statuses.isNotEmpty) {
      query = query.where('status', whereIn: statuses);
    }
    return query
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => orders.OrderModel.fromFirestore(d)).toList());
  }

  Future<void> updateOrderStatus(String id, orders.OrderStatus status) async {
    try {
      await _firestore.collection('orders').doc(id).update({
        'status': status.name[0].toUpperCase() + status.name.substring(1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      if (status == orders.OrderStatus.completed) {
        final orderDoc = await _firestore.collection('orders').doc(id).get();
        if (orderDoc.exists) {
          final order = orders.OrderModel.fromFirestore(orderDoc);
          final Map<String, _Consumption> toConsume = {};
          for (final orderItem in order.items) {
            final menuSnap = await _firestore
                .collection('menuItems')
                .doc(orderItem.menuItemId)
                .get();
            if (!menuSnap.exists) continue;
            final menu = MenuItemModel.fromFirestore(menuSnap);
            for (final ing in menu.recipe) {
              final key = '${ing.ingredientId}::${ing.unit}';
              final qty = ing.qtyNeeded * orderItem.quantity;
              final prev = toConsume[key];
              toConsume[key] = _Consumption(
                ingredientId: ing.ingredientId,
                unit: ing.unit,
                quantity: (prev?.quantity ?? 0) + qty,
                productName: menu.name,
              );
            }
          }
          final user = _auth.currentUser;
          for (final c in toConsume.values) {
            final stockRef = _firestore.collection('stock').doc(c.ingredientId);
            final stockDoc = await stockRef.get();
            if (!stockDoc.exists) continue;
            final current = StockItem.fromFirestore(stockDoc);
            final newQty = (current.quantite - c.quantity);
            await stockRef.update({
              'quantite': newQty,
              'misAJourLe': Timestamp.fromDate(DateTime.now()),
            });
            await _recordHistory(StockHistory(
              id: '',
              type: HistoryType.output,
              stockItemId: current.id,
              stockItemName: current.nom,
              category: current.categorie,
              quantityChange: c.quantity,
              previousQuantity: current.quantite,
              newQuantity: newQty,
              unit: current.unite,
              userId: user?.uid ?? '',
              userEmail: user?.email,
              timestamp: DateTime.now(),
            ));
          }
        }
      }
    } on FirebaseException catch (e) {
      throw AppException(
          'firestore', 'Error updating status: ${e.message ?? e.code}');
    }
  }

  // ======================== FEEDBACK ========================
  Future<void> submitFeedback(fb.FeedbackModel feedback) async {
    try {
      await _requireSignedInUid();
      await _firestore.collection('feedbacks').add(feedback.toFirestore());
      // After submit, recompute average rating for product (simple client-side aggregate)
      if (feedback.menuItemId != null && feedback.menuItemId!.isNotEmpty) {
        final snap = await _firestore
            .collection('feedbacks')
            .where('menuItemId', isEqualTo: feedback.menuItemId)
            .get();
        if (snap.docs.isNotEmpty) {
          double total = 0;
          for (final d in snap.docs) {
            final data = d.data();
            total += (data['rating'] ?? 0).toDouble();
          }
          final avg = total / snap.docs.length;
          await _firestore
              .collection('menuItems')
              .doc(feedback.menuItemId)
              .update({'rating': avg});
        }
      }
    } on FirebaseException catch (e) {
      throw AppException(
          'firestore', 'Error submitting feedback: ${e.message ?? e.code}');
    }
  }

  Stream<List<fb.FeedbackModel>> getFeedbacks({String? menuItemId}) {
    if (_auth.currentUser == null) {
      return Stream.error(
          const AppException('auth-required', 'You must be logged in.'));
    }
    Query query = _firestore.collection('feedbacks');
    if (menuItemId != null) {
      query = query.where('menuItemId', isEqualTo: menuItemId);
    }
    return query
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => fb.FeedbackModel.fromFirestore(d)).toList());
  }

  // Complaints
  // Create a new complaint
  Future<String> createComplaint(ComplaintModel complaint) async {
    try {
      await _requireSignedInUid(); // Ensure user is signed in
      final docRef = _firestore.collection('complaints').doc();
      final data = complaint.toFirestore();
      data['id'] = docRef.id;
      await docRef.set(data);
      return docRef.id;
    } on FirebaseException catch (e) {
      throw AppException(
          'firestore', 'Error creating complaint: ${e.message ?? e.code}');
    }
  }

  // Get complaints for current user (client)
  Stream<List<ComplaintModel>> getUserComplaints() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.error(
          const AppException('auth-required', 'You must be logged in.'));
    }
    return _firestore
        .collection('complaints')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ComplaintModel.fromFirestore(doc))
            .toList());
  }

  // Get all complaints (admin only)
  Stream<List<ComplaintModel>> getAllComplaints() {
    return _firestore
        .collection('complaints')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ComplaintModel.fromFirestore(doc))
            .toList());
  }

  // Update complaint status (admin only)
  Future<void> updateComplaintStatus(String complaintId, ComplaintStatus status,
      {String? assignedTo}) async {
    try {
      if (!await _isCurrentUserAdmin()) {
        throw const AppException(
            'permission-denied', 'Action reserved for administrators.');
      }
      final updateData = <String, dynamic>{
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (status == ComplaintStatus.resolved ||
          status == ComplaintStatus.closed) {
        updateData['resolvedAt'] = FieldValue.serverTimestamp();
      }
      if (assignedTo != null) {
        updateData['assignedTo'] = assignedTo;
      }
      await _firestore
          .collection('complaints')
          .doc(complaintId)
          .update(updateData);
    } on FirebaseException catch (e) {
      throw AppException(
          'firestore', 'Error updating complaint: ${e.message ?? e.code}');
    }
  }

  // Update complaint rating (client only, after resolution)
  Future<void> updateComplaintRating(String complaintId, int rating,
      {String? comment}) async {
    try {
      final uid = await _requireSignedInUid();
      final complaintDoc =
          await _firestore.collection('complaints').doc(complaintId).get();
      if (!complaintDoc.exists) {
        throw const AppException('not-found', 'Complaint not found.');
      }
      final data = complaintDoc.data()!;
      if (data['userId'] != uid) {
        throw const AppException(
            'permission-denied', 'You can only rate your own complaints.');
      }
      final updateData = <String, dynamic>{
        'rating': rating,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (comment != null && comment.isNotEmpty) {
        updateData['ratingComment'] = comment;
      }
      await _firestore
          .collection('complaints')
          .doc(complaintId)
          .update(updateData);
    } on FirebaseException catch (e) {
      throw AppException(
          'firestore', 'Error updating rating: ${e.message ?? e.code}');
    }
  }

  // Complaint Messages
  // Create a new message for a complaint
  Future<String> createComplaintMessage(ComplaintMessageModel message) async {
    try {
      await _requireSignedInUid(); // Ensure user is signed in
      final docRef = _firestore.collection('messages').doc();
      final data = message.toFirestore();
      data['id'] = docRef.id;
      await docRef.set(data);
      return docRef.id;
    } on FirebaseException catch (e) {
      throw AppException(
          'firestore', 'Error creating message: ${e.message ?? e.code}');
    }
  }

  // Get messages for a specific complaint
  Stream<List<ComplaintMessageModel>> getComplaintMessages(String complaintId) {
    // Query without orderBy to avoid index requirement, then sort in memory
    return _firestore
        .collection('messages')
        .where('complaintID', isEqualTo: complaintId)
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs
          .map((doc) => ComplaintMessageModel.fromFirestore(doc))
          .toList();
      // Sort by createdAt in ascending order (oldest first)
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return messages;
    });
  }

  // Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'isRead': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw AppException(
          'firestore', 'Error marking message as read: ${e.message ?? e.code}');
    }
  }


// Delete complaint (user can delete their own, admin can delete any)
Future<void> deleteComplaint(String complaintId) async {
  try {
    final uid = await _requireSignedInUid();
    
    // Get the complaint first to check ownership
    final complaintDoc = await _firestore.collection('complaints').doc(complaintId).get();
    if (!complaintDoc.exists) {
      throw const AppException('not-found', 'Complaint not found.');
    }
    
    final complaintData = complaintDoc.data()!;
    final complaintUserId = complaintData['userId'] as String?;
    
    // Check if user owns the complaint or is admin
    final isAdmin = await _isCurrentUserAdmin();
    if (complaintUserId != uid && !isAdmin) {
      throw const AppException(
          'permission-denied', 'You can only delete your own complaints.');
    }

    // Delete associated messages first
    final messagesSnapshot = await _firestore
        .collection('messages')
        .where('complaintID', isEqualTo: complaintId)
        .get();

    // Use batch to delete all messages and the complaint
    final batch = _firestore.batch();
    
    // Delete all messages
    for (final messageDoc in messagesSnapshot.docs) {
      batch.delete(messageDoc.reference);
    }
    
    // Delete the complaint
    batch.delete(_firestore.collection('complaints').doc(complaintId));
    
    await batch.commit();

    // Verify deletion
    final verifyDoc = await _firestore.collection('complaints').doc(complaintId).get();
    if (verifyDoc.exists) {
      throw const AppException('firestore', 'Complaint deletion was not confirmed.');
    }

  } on AppException {
    rethrow;
  } on FirebaseException catch (e) {
    throw AppException('firestore', 'Error deleting complaint: ${e.message ?? e.code}');
  } catch (e) {
    throw const AppException('unknown', 'Error deleting complaint');
  }
}
  // Mark all messages for a complaint as read
  Future<void> markComplaintMessagesAsRead(String complaintId) async {
    try {
      final uid = await _requireSignedInUid();
      final messages = await _firestore
          .collection('messages')
          .where('complaintID', isEqualTo: complaintId)
          .where('isRead', isEqualTo: false)
          .where('SenderId',
              isNotEqualTo: uid) // Only mark messages not sent by current user
          .get();

      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw AppException('firestore',
          'Error marking messages as read: ${e.message ?? e.code}');
    }
  }

  // Get unread message count for a complaint
  Future<int> getUnreadMessageCount(String complaintId) async {
    try {
      final uid = await _requireSignedInUid();
      final snapshot = await _firestore
          .collection('messages')
          .where('complaintID', isEqualTo: complaintId)
          .where('isRead', isEqualTo: false)
          .where('SenderId', isNotEqualTo: uid)
          .get();
      return snapshot.docs.length;
    } on FirebaseException catch (e) {
      throw AppException(
          'firestore', 'Error getting unread count: ${e.message ?? e.code}');
    }
  }
}

class _Consumption {
  final String ingredientId;
  final String unit;
  final double quantity;
  final String productName;
  _Consumption(
      {required this.ingredientId,
      required this.unit,
      required this.quantity,
      required this.productName});
}
