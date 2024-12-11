import 'package:flutter/material.dart';

class ShuttleManagementPage extends StatefulWidget {
  const ShuttleManagementPage({super.key});

  @override
  _ShuttleManagementPageState createState() => _ShuttleManagementPageState();
}

class _ShuttleManagementPageState extends State<ShuttleManagementPage> {
  final List<Map<String, String>> shuttles = [
    {'name': 'Shuttle 1', 'route': 'NSBM -> Colombo', 'capacity': '40'},
    {'name': 'Shuttle 2', 'route': 'NSBM -> Kandy', 'capacity': '30'},
    {'name': 'Shuttle 3', 'route': 'NSBM -> Galle', 'capacity': '35'},
  ];

  void _addShuttle() {
    setState(() {
      shuttles.add({
        'name': 'Shuttle ${shuttles.length + 1}',
        'route': 'New Route',
        'capacity': '40',
      });
    });
  }

  void _editShuttle(int index) {
    // You can add functionality to edit shuttle details
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit ${shuttles[index]['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: shuttles[index]['route'],
                decoration: const InputDecoration(labelText: 'Route'),
                onChanged: (value) {
                  setState(() {
                    shuttles[index]['route'] = value;
                  });
                },
              ),
              TextFormField(
                initialValue: shuttles[index]['capacity'],
                decoration: const InputDecoration(labelText: 'Capacity'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    shuttles[index]['capacity'] = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteShuttle(int index) {
    setState(() {
      shuttles.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Shuttle Management'),
      ),
      body: ListView.builder(
        itemCount: shuttles.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 5,
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(shuttles[index]['name']!),
              subtitle: Text(
                  'Route: ${shuttles[index]['route']} - Capacity: ${shuttles[index]['capacity']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      _editShuttle(index);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      _deleteShuttle(index);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: _addShuttle,
        child: const Icon(Icons.add),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ShuttleManagementPage(),
  ));
}
