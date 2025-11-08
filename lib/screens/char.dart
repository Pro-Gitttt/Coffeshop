import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminStatisticsScreen extends StatelessWidget {
  const AdminStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Statistics"), backgroundColor: Colors.brown),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Users Statistics", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 10,
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 5, color: Colors.brown)]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 8, color: Colors.brown)]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 3, color: Colors.brown)]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Orders History", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // You can add another chart here for orders
            const Text("More charts coming..."),
          ],
        ),
      ),
    );
  }
}
