import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firestore_client/firestore_client.dart';

import 'models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firestore Client Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const UserPage(),
    );
  }
}

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final client = FirestoreClient();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: StreamBuilder<List<User>>(
        stream: client.watchQuery(
          collectionPath: 'users',
          conditions: [
            QueryCondition('age', isGreaterThan: 18),
          ],
          orderBy: ['age'],
          fromJson: (json) => User.fromJson(json),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No users found'));
          }
          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                title: Text(user.name),
                subtitle: Text('Age: \${user.age}'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDummyUser,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addDummyUser() async {
    final user = User(
        id: '',
        name: 'User \${DateTime.now().second}',
        createdAt: DateTime.now());
    await client.create(
      collectionPath: 'users',
      data: user,
      toJson: (u) => u.toJson(),
    );
  }
}
