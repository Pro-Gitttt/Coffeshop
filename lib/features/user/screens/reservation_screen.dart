import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../../core/services/reservation_service.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/utils/responsive.dart';
import 'package:firebase_core/firebase_core.dart';

class ReservationScreen extends StatefulWidget {
  final DateTime? initialDateTime;
  final String? initialNotes;

  const ReservationScreen({super.key, this.initialDateTime, this.initialNotes});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ReservationService();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _guestsCtrl = TextEditingController(text: '2');
  final _specialCtrl = TextEditingController();

  String? _phoneFull;
  DateTime? _date;
  TimeOfDay? _time;
  bool _submitting = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _guestsCtrl.dispose();
    _specialCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time.')),
      );
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in.')),
      );
      return;
    }

    final dt = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );

    setState(() => _submitting = true);
    try {
      final data = {
        'userId': user.uid,
        'email': user.email ?? '',
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'phone': _phoneFull ?? '',
        'reservationDateTime': dt,
        'guests': int.tryParse(_guestsCtrl.text.trim()) ?? 1,
        'specialRequests': _specialCtrl.text.trim().isEmpty ? null : _specialCtrl.text.trim(),
      };
      await _service.createReservation(data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Reservation submitted! You can view it under My Reservations.')),
      );
      // Navigate to My Reservations for a stable destination, falling back to menu if route missing
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/user/my-reservations',
        (route) => route.settings.name == '/user/menu' || route.isFirst,
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final msg = e.code == 'permission-denied'
          ? 'Permission denied. Please ensure Firestore rules allow reservations for signed-in users.'
          : 'Failed to submit reservation: ${e.message ?? e.code}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit reservation: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    if (_date == null && widget.initialDateTime != null) {
      final dt = widget.initialDateTime!.toLocal();
      _date = DateTime(dt.year, dt.month, dt.day);
      _time = TimeOfDay(hour: dt.hour, minute: dt.minute);
    }
    if (_specialCtrl.text.isEmpty && widget.initialNotes != null) {
      _specialCtrl.text = widget.initialNotes!;
    }
    final route = ModalRoute.of(context)?.settings.name ?? '/user/reservation';
    void _goBack() {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacementNamed('/user/menu');
      }
    }
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Reservation',
        currentRoute: route,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
            onPressed: _goBack,
          ),
        ],
      ),
      drawer: AppDrawer(currentRoute: route),
      body: SingleChildScrollView(
        padding: Responsive.responsivePadding(context),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Coffee Shop Reservation Form',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameCtrl,
                      decoration: const InputDecoration(labelText: 'First name *', hintText: 'Type a placeholder'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameCtrl,
                      decoration: const InputDecoration(labelText: 'Last name *', hintText: 'Type a placeholder'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              IntlPhoneField(
                decoration: const InputDecoration(
                  labelText: 'Phone number *',
                  hintText: '(000) 000-0000',
                ),
                initialCountryCode: 'TN',
                showCountryFlag: false,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (phone) {
                  _phoneFull = phone.completeNumber;
                },
                validator: (phone) => (phone == null || phone.number.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: email,
                enabled: false,
                decoration: const InputDecoration(labelText: 'Email (from your account)'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Date *'),
                        child: Text(
                          _date == null
                              ? 'MM-DD-YYYY'
                              : '${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}-${_date!.year}',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Time *'),
                        child: Text(
                          _time == null
                              ? 'HH : MM'
                              : '${_time!.hour.toString().padLeft(2, '0')} : ${_time!.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _guestsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Number of Guests *'),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Enter a positive number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _specialCtrl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Special Requests / Notes'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _submitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.event_available),
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.brown[700], padding: const EdgeInsets.all(14)),
                  label: Text(_submitting ? 'Submitting...' : 'Reserve Table'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
