import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/complaint_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/utils/responsive.dart';

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  ComplaintStatus? _statusFilter;
  ComplaintPriority? _priorityFilter;

  Color _getStatusColor(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return Colors.orange;
      case ComplaintStatus.inProgress:
        return Colors.blue;
      case ComplaintStatus.resolved:
        return Colors.green;
      case ComplaintStatus.closed:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(ComplaintPriority priority) {
    switch (priority) {
      case ComplaintPriority.low:
        return Colors.green;
      case ComplaintPriority.medium:
        return Colors.orange;
      case ComplaintPriority.high:
        return Colors.red;
    }
  }

  Future<void> _updateStatus(ComplaintModel complaint, ComplaintStatus newStatus) async {
    try {
      await FirestoreService().updateComplaintStatus(complaint.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Complaint status updated to ${newStatus.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showStatusDialog(ComplaintModel complaint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ComplaintStatus.values.map((status) {
            return ListTile(
              title: Text(status.name),
              leading: Radio<ComplaintStatus>(
                value: status,
                groupValue: complaint.status,
                onChanged: (value) {
                  if (value != null) {
                    Navigator.pop(context);
                    _updateStatus(complaint, value);
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final route = ModalRoute.of(context)?.settings.name ?? '/admin/complaints';
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      drawer: AppDrawer(currentRoute: route),
      appBar: CustomAppBar(
        title: 'Complaints Management',
        currentRoute: route,
      ),
      body: Responsive.responsiveContainer(
        context,
        child: Column(
          children: [
            // Filters
            Padding(
              padding: Responsive.responsivePadding(context),
              child: Column(
                children: [
                  // Status filter
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Status Filter:',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<ComplaintStatus?>(
                          value: _statusFilter,
                          decoration: const InputDecoration(
                            labelText: 'All Statuses',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem<ComplaintStatus?>(
                              value: null,
                              child: Text('All Statuses'),
                            ),
                            ...ComplaintStatus.values.map((status) {
                              return DropdownMenuItem<ComplaintStatus>(
                                value: status,
                                child: Text(status.name),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _statusFilter = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.responsiveSpacing(context)),
                  // Priority filter
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Priority Filter:',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<ComplaintPriority?>(
                          value: _priorityFilter,
                          decoration: const InputDecoration(
                            labelText: 'All Priorities',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem<ComplaintPriority?>(
                              value: null,
                              child: Text('All Priorities'),
                            ),
                            ...ComplaintPriority.values.map((priority) {
                              return DropdownMenuItem<ComplaintPriority>(
                                value: priority,
                                child: Text(priority.name),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _priorityFilter = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Complaints list
            Expanded(
              child: StreamBuilder<List<ComplaintModel>>(
                stream: FirestoreService().getAllComplaints(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingWidget();
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: Responsive.responsiveIconSize(context, mobile: 64, tablet: 80, desktop: 96),
                            color: theme.colorScheme.error,
                          ),
                          SizedBox(height: Responsive.responsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
                          Padding(
                            padding: Responsive.responsiveHorizontalPadding(context),
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error,
                                fontSize: Responsive.responsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final allComplaints = snapshot.data ?? [];
                  final filteredComplaints = allComplaints.where((complaint) {
                    if (_statusFilter != null && complaint.status != _statusFilter) {
                      return false;
                    }
                    if (_priorityFilter != null && complaint.priority != _priorityFilter) {
                      return false;
                    }
                    return true;
                  }).toList();

                  if (filteredComplaints.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.feedback_outlined,
                            size: Responsive.responsiveIconSize(context, mobile: 80, tablet: 100, desktop: 120),
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                          SizedBox(height: Responsive.responsiveSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
                          Text(
                            allComplaints.isEmpty ? 'No complaints' : 'No complaints match filters',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                        return ListView.builder(
                          padding: Responsive.responsivePadding(context),
                          itemCount: filteredComplaints.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: Responsive.responsiveSpacing(context)),
                              child: _ComplaintCard(
                                complaint: filteredComplaints[index],
                                onStatusUpdate: () => _showStatusDialog(filteredComplaints[index]),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/user/complaint-detail',
                                    arguments: filteredComplaints[index],
                                  );
                                },
                                getStatusColor: _getStatusColor,
                                getPriorityColor: _getPriorityColor,
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
                          childAspectRatio: 1.1,
                        ),
                        itemCount: filteredComplaints.length,
                        itemBuilder: (context, index) {
                          return _ComplaintCard(
                            complaint: filteredComplaints[index],
                            onStatusUpdate: () => _showStatusDialog(filteredComplaints[index]),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/user/complaint-detail',
                                arguments: filteredComplaints[index],
                              );
                            },
                            getStatusColor: _getStatusColor,
                            getPriorityColor: _getPriorityColor,
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
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final VoidCallback onStatusUpdate;
  final VoidCallback onTap;
  final Color Function(ComplaintStatus) getStatusColor;
  final Color Function(ComplaintPriority) getPriorityColor;

  const _ComplaintCard({
    required this.complaint,
    required this.onStatusUpdate,
    required this.onTap,
    required this.getStatusColor,
    required this.getPriorityColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final statusColor = getStatusColor(complaint.status);
    final priorityColor = getPriorityColor(complaint.priority);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: statusColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: Responsive.responsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      complaint.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'update_status',
                        child: Row(
                          children: [
                            Icon(Icons.update, size: 20),
                            SizedBox(width: 8),
                            Text('Update Status'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'update_status') {
                        onStatusUpdate();
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: Responsive.responsiveSpacing(context, mobile: 8)),
              Text(
                complaint.description,
                style: theme.textTheme.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: Responsive.responsiveSpacing(context, mobile: 12)),
              Wrap(
                spacing: Responsive.responsiveSpacing(context, mobile: 8),
                runSpacing: Responsive.responsiveSpacing(context, mobile: 8),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      complaint.statusLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      complaint.priorityLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: priorityColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.responsiveSpacing(context, mobile: 12)),
              Text(
                'Created: ${dateFormat.format(complaint.createdAt)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              if (complaint.resolvedAt != null)
                Padding(
                  padding: EdgeInsets.only(top: Responsive.responsiveSpacing(context, mobile: 4)),
                  child: Text(
                    'Resolved: ${dateFormat.format(complaint.resolvedAt!)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.green,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

