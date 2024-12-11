import 'package:flutter/material.dart';

class SystemConfigPage extends StatelessWidget {
  const SystemConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('System Configuration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildConfigSwitch('Enable Notifications'),
            const Divider(),
            _buildConfigSwitch('Allow Emergency Requests'),
            const Divider(),
            _buildConfigDropdown(
              title: 'Default Notification Type',
              options: ['Email', 'SMS', 'Push'],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigSwitch(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18)),
        Switch(value: true, onChanged: (bool value) {}),
      ],
    );
  }

  Widget _buildConfigDropdown(
      {required String title, required List<String> options}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18)),
        DropdownButton<String>(
          items: options.map((String value) {
            return DropdownMenuItem(value: value, child: Text(value));
          }).toList(),
          onChanged: (String? value) {},
        ),
      ],
    );
  }
}
