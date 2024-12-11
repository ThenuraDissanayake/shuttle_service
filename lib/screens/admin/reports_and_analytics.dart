import 'package:flutter/material.dart';

class ReportsAnalyticsPage extends StatelessWidget {
  const ReportsAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Reports and Analytics'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Shuttle Usage', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            _buildReportCard('Active Shuttles', '10'),
            _buildReportCard('Total Reservations', '350'),
            const SizedBox(height: 20),
            const Text('User Feedback', style: TextStyle(fontSize: 20)),
            _buildReportCard('Positive Feedback', '85%'),
            _buildReportCard('Negative Feedback', '15%'),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, String value) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 18)),
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
