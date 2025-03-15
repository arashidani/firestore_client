import 'package:flutter/material.dart';
import 'package:firestore_client/firestore_client.dart';

import 'client.dart';
import 'lib/models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firestoreClient = createFirestoreClient(); // FirestoreClientを作成

  runApp(MyApp(firestoreClient: firestoreClient));
}

class MyApp extends StatelessWidget {
  final FirestoreClient firestoreClient;

  const MyApp({super.key, required this.firestoreClient});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firestore Client Example',
      home: UserScreen(firestoreClient: firestoreClient),
    );
  }
}

class UserScreen extends StatefulWidget {
  final FirestoreClient firestoreClient;

  const UserScreen({super.key, required this.firestoreClient});

  @override
  UserScreenState createState() => UserScreenState();
}

class UserScreenState extends State<UserScreen> {
  late FirestoreClient firestoreClient;
  List<User> users = [];

  @override
  void initState() {
    super.initState();
    firestoreClient = widget.firestoreClient;
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final usersList = await firestoreClient.query<User>(
      collectionPath: 'users',
      conditions: [],
      fromJson: (json) => User.fromJson(json),
    );

    setState(() {
      users = usersList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User List')),
      body: users.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  title: Text(user.name),
                  subtitle: Text('Created: ${user.createdAt}'),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadUsers,
        child: Icon(Icons.refresh),
      ),
    );
  }
}
