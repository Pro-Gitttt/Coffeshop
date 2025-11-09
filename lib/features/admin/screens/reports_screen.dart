import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/stock_item_model.dart';
import '../../../core/models/stock_history_model.dart';
import '../../../core/models/shortage_report_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/theme/app_colors.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final route = ModalRoute.of(context)?.settings.name ?? '/admin/reports';

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F6F4),
      drawer: AppDrawer(currentRoute: route),
      appBar: CustomAppBar(
        title: 'Reports',
        currentRoute: route,
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: isDark
                  ? AppColors.premiumGold
                  : AppColors.darkBrown,
              labelColor: isDark
                  ? AppColors.premiumGold
                  : AppColors.darkBrown,
              unselectedLabelColor: isDark
                  ? AppColors.caramelBeige.withOpacity(0.6)
                  : AppColors.darkBrown.withOpacity(0.5),
              tabs: const [
                Tab(text: 'Stock Items', icon: Icon(Icons.inventory_2_rounded)),
                Tab(text: 'History', icon: Icon(Icons.history_rounded)),
                Tab(text: 'Shortage Reports', icon: Icon(Icons.warning_amber_rounded)),
                Tab(text: 'Users', icon: Icon(Icons.people_rounded)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStockItemsTab(isDark),
                _buildHistoryTab(isDark),
                _buildShortageReportsTab(isDark),
                _buildUsersTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockItemsTab(bool isDark) {
    return StreamBuilder<List<StockItem>>(
      stream: FirestoreService().getStockItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString(), isDark);
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return _buildEmptyState('No stock items found', isDark);
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          color: isDark ? AppColors.premiumGold : AppColors.darkBrown,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _StockItemCard(item: item, isDark: isDark, dateFormat: _dateFormat);
            },
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab(bool isDark) {
    return StreamBuilder<List<StockHistory>>(
      stream: FirestoreService().getHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString(), isDark);
        }

        final historyItems = snapshot.data ?? [];

        if (historyItems.isEmpty) {
          return _buildEmptyState('No history found', isDark);
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          color: isDark ? AppColors.premiumGold : AppColors.darkBrown,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: historyItems.length,
            itemBuilder: (context, index) {
              final history = historyItems[index];
              return _HistoryCard(history: history, isDark: isDark, dateFormat: _dateFormat);
            },
          ),
        );
      },
    );
  }

  Widget _buildShortageReportsTab(bool isDark) {
    return StreamBuilder<List<ShortageReport>>(
      stream: FirestoreService().getShortageReports(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString(), isDark);
        }

        final reports = snapshot.data ?? [];

        if (reports.isEmpty) {
          return _buildEmptyState('No shortage reports found', isDark);
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          color: isDark ? AppColors.premiumGold : AppColors.darkBrown,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return _ShortageReportCard(report: report, isDark: isDark, dateFormat: _dateFormat);
            },
          ),
        );
      },
    );
  }

  Widget _buildUsersTab(bool isDark) {
    return StreamBuilder<List<UserModel>>(
      stream: FirestoreService().getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString(), isDark);
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return _buildEmptyState('No users found', isDark);
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          color: isDark ? AppColors.premiumGold : AppColors.darkBrown,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _UserCard(user: user, isDark: isDark, dateFormat: _dateFormat);
            },
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.errorRed,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.lightText : AppColors.darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? AppColors.caramelBeige.withOpacity(0.6)
                    : AppColors.darkBrown.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 64,
              color: isDark
                  ? AppColors.premiumGold.withOpacity(0.3)
                  : AppColors.darkBrown.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? AppColors.caramelBeige.withOpacity(0.6)
                    : AppColors.darkBrown.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockItemCard extends StatelessWidget {
  final StockItem item;
  final bool isDark;
  final DateFormat dateFormat;

  const _StockItemCard({
    required this.item,
    required this.isDark,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    final isLowStock = item.isLowStock;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.nom,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.lightText : AppColors.darkText,
                  ),
                ),
              ),
              if (isLowStock)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warningOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.warningOrange.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    'Low Stock',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warningOrange,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.category_rounded,
                size: 16,
                color: isDark
                    ? AppColors.caramelBeige.withOpacity(0.6)
                    : AppColors.darkBrown.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Text(
                item.categorie,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.caramelBeige.withOpacity(0.7)
                      : AppColors.darkBrown.withOpacity(0.7),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.inventory_2_rounded,
                size: 16,
                color: isLowStock
                    ? AppColors.warningOrange
                    : (isDark ? AppColors.premiumGold : AppColors.darkBrown),
              ),
              const SizedBox(width: 8),
              Text(
                '${item.quantite.toStringAsFixed(item.quantite.truncateToDouble() == item.quantite ? 0 : 1)} ${item.unite}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isLowStock
                      ? AppColors.warningOrange
                      : (isDark ? AppColors.premiumGold : AppColors.darkBrown),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: isDark
                    ? AppColors.caramelBeige.withOpacity(0.5)
                    : AppColors.darkBrown.withOpacity(0.5),
              ),
              const SizedBox(width: 8),
              Text(
                'Last Updated: ${dateFormat.format(item.misAJourLe)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.caramelBeige.withOpacity(0.6)
                      : AppColors.darkBrown.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final StockHistory history;
  final bool isDark;
  final DateFormat dateFormat;

  const _HistoryCard({
    required this.history,
    required this.isDark,
    required this.dateFormat,
  });

  Color _getTypeColor(HistoryType type) {
    switch (type) {
      case HistoryType.input:
        return AppColors.successGreen;
      case HistoryType.output:
        return AppColors.errorRed;
      case HistoryType.update:
        return AppColors.warningOrange;
    }
  }

  IconData _getTypeIcon(HistoryType type) {
    switch (type) {
      case HistoryType.input:
        return Icons.add_circle_rounded;
      case HistoryType.output:
        return Icons.remove_circle_rounded;
      case HistoryType.update:
        return Icons.edit_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(history.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: typeColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTypeIcon(history.type),
                  color: typeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        history.typeLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      history.stockItemName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.lightText : AppColors.darkText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.inventory_2_rounded,
                size: 16,
                color: isDark
                    ? AppColors.caramelBeige.withOpacity(0.6)
                    : AppColors.darkBrown.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Text(
                history.displayQuantity,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: typeColor,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.category_rounded,
                size: 16,
                color: isDark
                    ? AppColors.caramelBeige.withOpacity(0.6)
                    : AppColors.darkBrown.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Text(
                history.category,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.caramelBeige.withOpacity(0.7)
                      : AppColors.darkBrown.withOpacity(0.7),
                ),
              ),
            ],
          ),
          if (history.userEmail != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.person_rounded,
                  size: 14,
                  color: isDark
                      ? AppColors.caramelBeige.withOpacity(0.5)
                      : AppColors.darkBrown.withOpacity(0.5),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    history.userEmail!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.caramelBeige.withOpacity(0.6)
                          : AppColors.darkBrown.withOpacity(0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Divider(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: isDark
                    ? AppColors.caramelBeige.withOpacity(0.5)
                    : AppColors.darkBrown.withOpacity(0.5),
              ),
              const SizedBox(width: 8),
              Text(
                dateFormat.format(history.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.caramelBeige.withOpacity(0.6)
                      : AppColors.darkBrown.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShortageReportCard extends StatelessWidget {
  final ShortageReport report;
  final bool isDark;
  final DateFormat dateFormat;

  const _ShortageReportCard({
    required this.report,
    required this.isDark,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: report.resolved
              ? AppColors.successGreen.withOpacity(0.3)
              : AppColors.warningOrange.withOpacity(0.5),
          width: report.resolved ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (report.resolved
                          ? AppColors.successGreen
                          : AppColors.warningOrange)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  report.resolved
                      ? Icons.check_circle_rounded
                      : Icons.warning_amber_rounded,
                  color: report.resolved
                      ? AppColors.successGreen
                      : AppColors.warningOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (report.resolved
                                ? AppColors.successGreen
                                : AppColors.warningOrange)
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        report.resolved ? 'Resolved' : 'Active',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: report.resolved
                              ? AppColors.successGreen
                              : AppColors.warningOrange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.stockItemName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.lightText : AppColors.darkText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.category_rounded,
                size: 16,
                color: isDark
                    ? AppColors.caramelBeige.withOpacity(0.6)
                    : AppColors.darkBrown.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Text(
                report.category,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.caramelBeige.withOpacity(0.7)
                      : AppColors.darkBrown.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.inventory_2_rounded,
                size: 16,
                color: AppColors.warningOrange,
              ),
              const SizedBox(width: 8),
              Text(
                '${report.currentQuantity.toStringAsFixed(report.currentQuantity.truncateToDouble() == report.currentQuantity ? 0 : 1)} ${report.unit}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warningOrange,
                ),
              ),
            ],
          ),
          if (report.comment != null && report.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : AppColors.caramelBeige.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.comment_rounded,
                    size: 16,
                    color: isDark
                        ? AppColors.caramelBeige.withOpacity(0.6)
                        : AppColors.darkBrown.withOpacity(0.6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      report.comment!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.caramelBeige.withOpacity(0.7)
                            : AppColors.darkBrown.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (report.userEmail != null || report.userName != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.person_rounded,
                  size: 14,
                  color: isDark
                      ? AppColors.caramelBeige.withOpacity(0.5)
                      : AppColors.darkBrown.withOpacity(0.5),
                ),
                const SizedBox(width: 8),
                Text(
                  report.userName ?? report.userEmail ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.caramelBeige.withOpacity(0.6)
                        : AppColors.darkBrown.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Divider(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: isDark
                    ? AppColors.caramelBeige.withOpacity(0.5)
                    : AppColors.darkBrown.withOpacity(0.5),
              ),
              const SizedBox(width: 8),
              Text(
                dateFormat.format(report.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.caramelBeige.withOpacity(0.6)
                      : AppColors.darkBrown.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final bool isDark;
  final DateFormat dateFormat;

  const _UserCard({
    required this.user,
    required this.isDark,
    required this.dateFormat,
  });

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppColors.errorRed;
      case 'employee':
        return AppColors.infoBlue;
      default:
        return AppColors.successGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor(user.role);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: roleColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user.role.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: roleColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.displayName ?? user.email,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.lightText : AppColors.darkText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.email_rounded,
                size: 16,
                color: isDark
                    ? AppColors.caramelBeige.withOpacity(0.6)
                    : AppColors.darkBrown.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.caramelBeige.withOpacity(0.7)
                        : AppColors.darkBrown.withOpacity(0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: isDark
                    ? AppColors.caramelBeige.withOpacity(0.5)
                    : AppColors.darkBrown.withOpacity(0.5),
              ),
              const SizedBox(width: 8),
              Text(
                'Created: ${dateFormat.format(user.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.caramelBeige.withOpacity(0.6)
                      : AppColors.darkBrown.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

