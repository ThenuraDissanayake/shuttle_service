import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shuttle_service/screens/userScreens/shuttledetails.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  Future<List<Map<String, dynamic>>> _fetchFavoriteShuttles() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final favoritesSnapshot = await FirebaseFirestore.instance
        .collection('user_favorites')
        .doc(user.uid)
        .collection('shuttles')
        .get();

    List<Future<Map<String, dynamic>>> shuttleFutures =
        favoritesSnapshot.docs.map((doc) async {
      final shuttleDetails = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(doc.id)
          .get();

      return {
        'id': doc.id,
        'details': shuttleDetails.data(),
        'favoriteTimestamp': doc.data()['timestamp']
      };
    }).toList();

    return await Future.wait(shuttleFutures);
  }

  Future<void> _removeFavorite(String shuttleId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('user_favorites')
        .doc(user.uid)
        .collection('shuttles')
        .doc(shuttleId)
        .delete();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Shuttles'),
        // backgroundColor: Colors.green,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchFavoriteShuttles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No favorite shuttles yet',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final shuttle = snapshot.data![index];
              final driverName =
                  shuttle['details']?['driver_name'] ?? 'Unknown Driver';
              final shuttleType = shuttle['details']?['shuttle']
                      ?['shuttle_type'] ??
                  'Unknown Type';
              final route =
                  shuttle['details']?['shuttle']?['route'] ?? 'Unknown Route';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    driverName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Type: $shuttleType'),
                      Text('Route: $route'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_red_eye,
                            color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ShuttleDetailsPage(shuttleId: shuttle['id']),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeFavorite(shuttle['id']),
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
