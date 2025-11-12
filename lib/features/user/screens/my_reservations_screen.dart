import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/custom_app_bar.dart';

// Human-readable mapping for Open-Meteo weather codes.
const Map<int, String> _weatherCodeDescriptions = {
  0: 'Clear sky',
  1: 'Mainly clear',
  2: 'Partly cloudy',
  3: 'Overcast',
  45: 'Fog',
  48: 'Depositing rime fog',
  51: 'Light drizzle',
  53: 'Moderate drizzle',
  55: 'Dense drizzle',
  56: 'Light freezing drizzle',
  57: 'Dense freezing drizzle',
  61: 'Slight rain',
  63: 'Moderate rain',
  65: 'Heavy rain',
  66: 'Light freezing rain',
  67: 'Heavy freezing rain',
  71: 'Slight snow fall',
  73: 'Moderate snow fall',
  75: 'Heavy snow fall',
  77: 'Snow grains',
  80: 'Slight rain showers',
  81: 'Moderate rain showers',
  82: 'Violent rain showers',
  85: 'Slight snow showers',
  86: 'Heavy snow showers',
  95: 'Thunderstorm',
  96: 'Thunderstorm with slight hail',
  99: 'Thunderstorm with heavy hail',
};

class MyReservationsScreen extends StatelessWidget {
  const MyReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scaffoldContext = context; // Use this for dialogs & snackbars

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('You must be logged in.')),
      );
    }

    final query = FirebaseFirestore.instance
        .collection('reservations')
        .where('userId', isEqualTo: uid);

    final route = ModalRoute.of(context)?.settings.name ?? '/user/reservations';

    return Scaffold(
      appBar: CustomAppBar(
        title: 'My Reservations',
        currentRoute: route,
      ),
      drawer: AppDrawer(currentRoute: route),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Failed to load reservations: ${snapshot.error}\n'
                  'If you recently updated rules or indexes, please publish them.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No reservations yet. Make one from the menu!'),
            );
          }

          final docs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final ta = a.data()['reservationDateTime'];
              final tb = b.data()['reservationDateTime'];
              final da = ta is Timestamp ? ta.toDate() : DateTime.tryParse('$ta') ?? DateTime(2100);
              final db = tb is Timestamp ? tb.toDate() : DateTime.tryParse('$tb') ?? DateTime(2100);
              return da.compareTo(db);
            });

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final data = docs[i].data();
              final ts = data['reservationDateTime'];
              final dt = ts is Timestamp ? ts.toDate() : DateTime.tryParse('$ts');
              final guests = (data['guests'] as num?)?.toInt() ?? 1;
              final name = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
              final note = data['specialRequests'] as String?;
              final reservationId = docs[i].id;

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
                      if (note != null && note.isNotEmpty) Text('Note: $note'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'View QR code',
                        icon: const Icon(Icons.qr_code_2, color: Colors.brown),
                        onPressed: () async {
                          try {
                            final payload = {
                              'n': name,
                              'g': guests,
                              't': dt?.toUtc().toIso8601String(),
                            };
                            final dataStr = jsonEncode(payload);

                            debugPrint('Opening QR dialog for reservation $reservationId');
                            if (!scaffoldContext.mounted) return;

                            await showDialog(
                              context: scaffoldContext,
                              barrierDismissible: true,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('Reservation QR'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 240,
                                        height: 240,
                                        child: Center(
                                          child: QrImageView(
                                            data: dataStr,
                                            version: QrVersions.auto,
                                            size: 220,
                                            backgroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Show this QR at the host stand. It includes only your name, guest count, and time.',
                                        style: Theme.of(context).textTheme.bodySmall,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                );
                              },
                            );
                          } catch (e, st) {
                            debugPrint('Failed to open QR dialog: $e\n$st');
                            if (!scaffoldContext.mounted) return;
                            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                              const SnackBar(content: Text('Could not open QR code. Please try again.')),
                            );
                          }
                        },
                      ),
                      IconButton(
                        tooltip: 'Check weather',
                        icon: const Icon(Icons.wb_sunny_outlined, color: Colors.orangeAccent),
                        onPressed: dt == null
                            ? null
                            : () async {
                                final whenUtc = dt.toUtc();
                                const latitude = 36.86012;
                                const longitude = 10.19337;
                                final hour = whenUtc.hour;
                                try {
                                  if (!scaffoldContext.mounted) return;
                                  showDialog(
                                    context: scaffoldContext,
                                    barrierDismissible: false,
                                    builder: (_) => const Dialog(
                                      child: Padding(
                                        padding: EdgeInsets.all(24.0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircularProgressIndicator(),
                                            SizedBox(width: 16),
                                            Text('Fetching weather...'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );

                                  final date = whenUtc.toIso8601String().substring(0, 10);
                                  final url = Uri.parse(
                                    'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&hourly=temperature_2m,precipitation,weathercode&timezone=UTC&start_date=$date&end_date=$date',
                                  );
                                  final resp = await http.get(url);
                                  if (!scaffoldContext.mounted) return;
                                  Navigator.of(scaffoldContext).pop(); // close progress
                                  if (resp.statusCode != 200) {
                                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                      SnackBar(content: Text('Weather API error: ${resp.statusCode}')),
                                    );
                                    return;
                                  }
                                  final json = jsonDecode(resp.body) as Map<String, dynamic>;
                                  final hourly = (json['hourly'] as Map<String, dynamic>?);
                                  List temps = hourly?['temperature_2m'] as List? ?? [];
                                  List precs = hourly?['precipitation'] as List? ?? [];
                                  List codes = hourly?['weathercode'] as List? ?? [];
                                  double temp = temps.length > hour ? (temps[hour] as num).toDouble() : double.nan;
                                  double precip = precs.length > hour ? (precs[hour] as num).toDouble() : double.nan;
                                  int code = codes.length > hour ? (codes[hour] as num).toInt() : -1;
                                  final description = _weatherCodeDescriptions[code] ?? 'Unknown';

                                  String recommendation;
                                  if (precip > 0.2 || code >= 50) {
                                    recommendation = 'Better inside (rain expected).';
                                  } else if (temp < 12) {
                                    recommendation = 'Inside recommended (cool temperature).';
                                  } else if (temp > 30) {
                                    recommendation = 'Inside (too hot outside).';
                                  } else {
                                    recommendation = 'Outside is pleasant.';
                                  }

                                  showDialog(
                                    context: scaffoldContext,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Weather Recommendation'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Date/Time (UTC): ${whenUtc.toIso8601String()}'),
                                          if (!temp.isNaN) Text('Temperature: ${temp.toStringAsFixed(1)}°C'),
                                          if (!precip.isNaN) Text('Precipitation: ${precip.toStringAsFixed(2)} mm'),
                                          Text('Condition: $description (code $code)'),
                                          const SizedBox(height: 12),
                                          Text(
                                            recommendation,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(scaffoldContext).pop(),
                                          child: const Text('Close'),
                                        ),
                                      ],
                                    ),
                                  );
                                } catch (e, st) {
                                  debugPrint('Weather fetch failed: $e\n$st');
                                  if (!scaffoldContext.mounted) return;
                                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                    const SnackBar(content: Text('Failed to fetch weather.')),
                                  );
                                }
                              },
                      ),
                      IconButton(
                        tooltip: 'Open Map',
                        icon: const Icon(Icons.location_on, color: Colors.green),
                        onPressed: () async {
                          final uri = Uri.parse(
                              'https://www.google.com/maps/place/coin+bouslimi/data=!4m2!3m1!1s0x12e2cbcf17bd60e3:0xc5658f2104dec980?sa=X&ved=1t:242&ictx=111');
                          try {
                            final launched =
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                            if (!launched) {
                              if (!scaffoldContext.mounted) return;
                              ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                const SnackBar(content: Text('Could not launch maps.')),
                              );
                            }
                          } catch (e) {
                            debugPrint('Map launch failed: $e');
                            if (!scaffoldContext.mounted) return;
                            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                              const SnackBar(content: Text('Failed to open map.')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
