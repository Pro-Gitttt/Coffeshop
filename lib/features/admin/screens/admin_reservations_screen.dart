import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/reservation_service.dart';
import '../../../core/widgets/app_drawer.dart';

class AdminReservationsScreen extends StatefulWidget {
  const AdminReservationsScreen({super.key});

  @override
  State<AdminReservationsScreen> createState() => _AdminReservationsScreenState();
}

class _AdminReservationsScreenState extends State<AdminReservationsScreen> {
  final _service = ReservationService();
  final _searchCtrl = TextEditingController();
  bool _showPast = false;
  bool _ascending = true; // sort direction
  String _sortField = 'date'; // 'date' or 'name'
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _paginationMode = false;
  static const int _pageSize = 20;
  bool _isLoadingPage = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDoc;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _pagedDocs = [];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _resetAndLoad() {
    if (_paginationMode) {
      _pagedDocs.clear();
      _lastDoc = null;
      _hasMore = true;
      _loadNextPage();
    }
    setState(() {});
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingPage || !_hasMore) return;
    setState(() => _isLoadingPage = true);
    try {
      Query<Map<String, dynamic>> q = FirebaseFirestore.instance.collection('reservations');
      if (_sortField == 'date') {
        if (_fromDate != null) {
          q = q.where('reservationDateTime', isGreaterThanOrEqualTo: _fromDate);
        }
        if (_toDate != null) {
          final end = DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);
          q = q.where('reservationDateTime', isLessThanOrEqualTo: end);
        }
        q = q.orderBy('reservationDateTime', descending: !_ascending);
      } else {
        q = q.orderBy('lastName', descending: !_ascending).orderBy('firstName', descending: !_ascending);
      }
      if (_lastDoc != null) {
        q = q.startAfterDocument(_lastDoc!);
      }
      q = q.limit(_pageSize);

      final snap = await q.get();
      if (snap.docs.isNotEmpty) {
        _lastDoc = snap.docs.last;
        _pagedDocs.addAll(snap.docs);
        if (snap.docs.length < _pageSize) _hasMore = false;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint('Pagination load failed: $e');
    } finally {
      if (mounted) setState(() => _isLoadingPage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Reservations'),
        backgroundColor: Colors.brown,
        actions: [
          IconButton(
            tooltip: _showPast ? 'Hide past' : 'Show past',
            icon: Icon(_showPast ? Icons.history_toggle_off : Icons.history),
            onPressed: () => setState(() => _showPast = !_showPast),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/admin/reservations'),
      body: Column(
        children: [
          _buildControls(),
          const Divider(height: 1),
          Expanded(child: _paginationMode ? _buildPagedList() : _buildStreamedList()),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search by name or email',
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        _resetAndLoad();
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortField,
                  items: const [
                    DropdownMenuItem(value: 'date', child: Text('Sort by Date/Time')),
                    DropdownMenuItem(value: 'name', child: Text('Sort by Name')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    _sortField = v;
                    _resetAndLoad();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: _ascending ? 'Ascending' : 'Descending',
                icon: Icon(_ascending ? Icons.arrow_upward : Icons.arrow_downward),
                onPressed: () {
                  _ascending = !_ascending;
                  _resetAndLoad();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _fromDate ?? now,
                      firstDate: DateTime(now.year - 1),
                      lastDate: DateTime(now.year + 2),
                    );
                    if (picked != null) {
                      _fromDate = DateTime(picked.year, picked.month, picked.day);
                      _resetAndLoad();
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'From'),
                    child: Text(_fromDate == null
                        ? 'Any'
                        : '${_fromDate!.year}-${_fromDate!.month.toString().padLeft(2, '0')}-${_fromDate!.day.toString().padLeft(2, '0')}'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _toDate ?? now,
                      firstDate: DateTime(now.year - 1),
                      lastDate: DateTime(now.year + 2),
                    );
                    if (picked != null) {
                      _toDate = DateTime(picked.year, picked.month, picked.day);
                      _resetAndLoad();
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'To'),
                    child: Text(_toDate == null
                        ? 'Any'
                        : '${_toDate!.year}-${_toDate!.month.toString().padLeft(2, '0')}-${_toDate!.day.toString().padLeft(2, '0')}'),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Clear dates',
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _fromDate = null;
                  _toDate = null;
                  _resetAndLoad();
                },
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Pagination mode (server-side)'),
            value: _paginationMode,
            onChanged: (v) {
              _paginationMode = v;
              _resetAndLoad();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStreamedList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.streamAllReservations(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final q = snapshot.data?.docs ?? [];
        final lower = _searchCtrl.text.toLowerCase();
        final now = DateTime.now();
        final docs = q.where((d) {
          final data = d.data();
          final ts = data['reservationDateTime'];
          DateTime? dt;
          if (ts is Timestamp) dt = ts.toDate();
          else if (ts is DateTime) dt = ts;
          else if (ts is String) dt = DateTime.tryParse(ts);
          if (!_showPast && dt != null && dt.isBefore(now)) return false;
          if (_fromDate != null && dt != null && dt.isBefore(_fromDate!)) return false;
          if (_toDate != null && dt != null && dt.isAfter(DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59))) return false;
          if (lower.isNotEmpty) {
            final name = ('${data['firstName'] ?? ''} ${data['lastName'] ?? ''}').toLowerCase();
            final email = (data['email'] as String? ?? '').toLowerCase();
            if (!name.contains(lower) && !email.contains(lower)) return false;
          }
          return true;
        }).toList();

        docs.sort((a, b) {
          final da = a.data();
          final db = b.data();
          int cmp;
          if (_sortField == 'name') {
            final an = '${da['lastName'] ?? ''} ${da['firstName'] ?? ''}'.toLowerCase();
            final bn = '${db['lastName'] ?? ''} ${db['firstName'] ?? ''}'.toLowerCase();
            cmp = an.compareTo(bn);
          } else {
            final ta = da['reservationDateTime'];
            final tb = db['reservationDateTime'];
            final aDt = ta is Timestamp ? ta.toDate() : DateTime.tryParse('$ta') ?? DateTime(2100);
            final bDt = tb is Timestamp ? tb.toDate() : DateTime.tryParse('$tb') ?? DateTime(2100);
            cmp = aDt.compareTo(bDt);
          }
          return _ascending ? cmp : -cmp;
        });

        if (docs.isEmpty) {
          return Center(child: Text(_showPast ? 'No past reservations.' : 'No upcoming reservations.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data();
            final ts = data['reservationDateTime'];
            DateTime? dt;
            if (ts is Timestamp) dt = ts.toDate();
            else if (ts is DateTime) dt = ts;
            else if (ts is String) dt = DateTime.tryParse(ts);
            final name = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
            final guests = (data['guests'] as num?)?.toInt() ?? 1;
            final email = data['email'] as String? ?? '';
            final special = data['specialRequests'] as String?;

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.event, color: Colors.brown),
                title: Text(
                  dt != null
                      ? '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}  '
                        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
                      : 'Unknown date',
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name: $name'),
                    Text('Guests: $guests'),
                    if (email.isNotEmpty) Text('Email: $email'),
                    if (special != null && special.isNotEmpty) Text('Note: $special'),
                  ],
                ),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit, color: Colors.blueGrey),
                      onPressed: () => _openEditDialog(doc.id, data),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                      onPressed: () => _confirmDelete(doc.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPagedList() {
    if (_pagedDocs.isEmpty && !_isLoadingPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadNextPage());
    }
    final lower = _searchCtrl.text.toLowerCase();
    final now = DateTime.now();
    final filtered = _pagedDocs.where((d) {
      final data = d.data();
      final ts = data['reservationDateTime'];
      DateTime? dt;
      if (ts is Timestamp) dt = ts.toDate();
      else if (ts is DateTime) dt = ts;
      else if (ts is String) dt = DateTime.tryParse(ts);
      if (!_showPast && dt != null && dt.isBefore(now)) return false;
      if (_fromDate != null && dt != null && dt.isBefore(_fromDate!)) return false;
      if (_toDate != null && dt != null && dt.isAfter(DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59))) return false;
      if (lower.isNotEmpty) {
        final name = ('${data['firstName'] ?? ''} ${data['lastName'] ?? ''}').toLowerCase();
        final email = (data['email'] as String? ?? '').toLowerCase();
        if (!name.contains(lower) && !email.contains(lower)) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        final da = a.data();
        final db = b.data();
        int cmp;
        if (_sortField == 'name') {
          final an = '${da['lastName'] ?? ''} ${da['firstName'] ?? ''}'.toLowerCase();
          final bn = '${db['lastName'] ?? ''} ${db['firstName'] ?? ''}'.toLowerCase();
          cmp = an.compareTo(bn);
        } else {
          final ta = da['reservationDateTime'];
          final tb = db['reservationDateTime'];
          final aDt = ta is Timestamp ? ta.toDate() : DateTime.tryParse('$ta') ?? DateTime(2100);
          final bDt = tb is Timestamp ? tb.toDate() : DateTime.tryParse('$tb') ?? DateTime(2100);
          cmp = aDt.compareTo(bDt);
        }
        return _ascending ? cmp : -cmp;
      });

    if (filtered.isEmpty && _isLoadingPage) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final doc = filtered[i];
              final data = doc.data();
              final ts = data['reservationDateTime'];
              DateTime? dt;
              if (ts is Timestamp) dt = ts.toDate();
              else if (ts is DateTime) dt = ts;
              else if (ts is String) dt = DateTime.tryParse(ts);
              final name = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
              final guests = (data['guests'] as num?)?.toInt() ?? 1;
              final email = data['email'] as String? ?? '';
              final special = data['specialRequests'] as String?;

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.event, color: Colors.brown),
                  title: Text(
                    dt != null
                        ? '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}  '
                          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
                        : 'Unknown date',
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Name: $name'),
                      Text('Guests: $guests'),
                      if (email.isNotEmpty) Text('Email: $email'),
                      if (special != null && special.isNotEmpty) Text('Note: $special'),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit, color: Colors.blueGrey),
                        onPressed: () => _openEditDialog(doc.id, data),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                        onPressed: () => _confirmDelete(doc.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_isLoadingPage) const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()),
        if (!_isLoadingPage && _hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ElevatedButton(
              onPressed: _loadNextPage,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
              child: const Text('Load more'),
            ),
          ),
        if (!_hasMore)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('No more results.', style: TextStyle(color: Colors.grey)),
          ),
      ],
    );
  }

  Future<void> _openEditDialog(String id, Map<String, dynamic> data) async {
    DateTime? dt;
    final ts = data['reservationDateTime'];
    if (ts is Timestamp) dt = ts.toDate();
    else if (ts is DateTime) dt = ts;
    else if (ts is String) dt = DateTime.tryParse(ts);

    final guestsCtrl = TextEditingController(text: (data['guests'] as num?)?.toString() ?? '1');
    final specialCtrl = TextEditingController(text: data['specialRequests'] as String? ?? '');
    DateTime working = dt ?? DateTime.now().add(const Duration(hours: 1));
    TimeOfDay workingTime = TimeOfDay.fromDateTime(working);
    bool submitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          Future<void> pickDate() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: working,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              setStateDialog(() {
                working = DateTime(picked.year, picked.month, picked.day, workingTime.hour, workingTime.minute);
              });
            }
          }

          Future<void> pickTime() async {
            final picked = await showTimePicker(
              context: context,
              initialTime: workingTime,
            );
            if (picked != null) {
              setStateDialog(() {
                workingTime = picked;
                working = DateTime(working.year, working.month, working.day, picked.hour, picked.minute);
              });
            }
          }

          Future<void> submit() async {
            if (submitting) return;
            setStateDialog(() => submitting = true);
            try {
              final guests = int.tryParse(guestsCtrl.text.trim()) ?? 1;
              final update = {
                'reservationDateTime': working,
                'guests': guests,
                'specialRequests': specialCtrl.text.trim().isEmpty ? null : specialCtrl.text.trim(),
              };
              await _service.updateReservation(id, update);
              if (!mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reservation updated.')));
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
            } finally {
              if (mounted) setStateDialog(() => submitting = false);
            }
          }

          return AlertDialog(
            title: const Text('Edit Reservation'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: pickDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Date'),
                            child: Text('${working.month.toString().padLeft(2, '0')}-${working.day.toString().padLeft(2, '0')}-${working.year}'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: pickTime,
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Time'),
                            child: Text('${workingTime.hour.toString().padLeft(2, '0')}:${workingTime.minute.toString().padLeft(2, '0')}'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: guestsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Guests'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: specialCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Special Requests / Notes'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: submitting ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: submitting ? null : submit,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                child: submitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Reservation'),
        content: const Text('Are you sure you want to delete this reservation? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.deleteReservation(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reservation deleted.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }
}
