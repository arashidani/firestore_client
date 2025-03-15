import 'package:firestore_client/example/lib/models/user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_client/firestore_client.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreClient firestoreClient;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    firestoreClient = FirestoreClient(firestore: fakeFirestore);
  });

  test('create() should add a document', () async {
    await firestoreClient.create(
      collectionPath: 'users',
      docId: 'test_user',
      data: {'name': 'Test User'},
      toJson: (data) => data,
    );

    final snapshot =
        await fakeFirestore.collection('users').doc('test_user').get();
    expect(snapshot.exists, true);
    expect(snapshot.data()?['name'], 'Test User');
  });

  test('create() should add a User document', () async {
    final user = User(
      id: 'user_123',
      name: 'John Doe',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await firestoreClient.create(
      collectionPath: 'users',
      docId: user.id,
      data: user,
      toJson: (user) => user.toJson(),
    );

    final snapshot =
        await fakeFirestore.collection('users').doc('user_123').get();
    expect(snapshot.exists, true);
    expect(snapshot.data()?['name'], 'John Doe');
    expect(snapshot.data()?['id'], 'user_123');
  });

  test(
    'createInSubCollection() should add a document in a subCollection',
    () async {
      await firestoreClient.createInSubCollection(
        parentCollectionPath: 'users',
        parentDocId: 'user123',
        subCollectionName: 'posts',
        docId: 'post_1',
        data: {'title': 'First Post'},
        toJson: (data) => data,
      );

      final snapshot =
          await fakeFirestore
              .collection('users/user123/posts')
              .doc('post_1')
              .get();
      expect(snapshot.exists, true);
      expect(snapshot.data()?['title'], 'First Post');
    },
  );

  test('read() should return a document', () async {
    await fakeFirestore.collection('users').doc('test_user').set({
      'name': 'Alice',
    });

    final user = await firestoreClient.read(
      collectionPath: 'users',
      docId: 'test_user',
      fromJson: (json) => json,
    );

    expect(user?['name'], 'Alice');
  });

  test('read() should return a User document', () async {
    final userJson = {
      'id': 'user_123',
      'name': 'John Doe',
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    };

    await fakeFirestore.collection('users').doc('user_123').set(userJson);

    final user = await firestoreClient.read(
      collectionPath: 'users',
      docId: 'user_123',
      fromJson: (json) => User.fromJson(json),
    );

    expect(user, isNotNull);
    expect(user?.name, 'John Doe');
  });

  test('update() should modify a document or create if not exist', () async {
    await firestoreClient.update(
      collectionPath: 'users',
      docId: 'test_user',
      data: {'name': 'Updated Name'},
      toJson: (data) => data,
    );

    final snapshot =
        await fakeFirestore.collection('users').doc('test_user').get();
    expect(snapshot.exists, true);
    expect(snapshot.data()?['name'], 'Updated Name');
  });

  test('update() should modify a User document', () async {
    final user = User(
      id: 'user_123',
      name: 'Updated Name',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await firestoreClient.update(
      collectionPath: 'users',
      docId: user.id,
      data: user,
      toJson: (user) => user.toJson(),
    );

    final snapshot =
        await fakeFirestore.collection('users').doc('user_123').get();
    expect(snapshot.exists, true);
    expect(snapshot.data()?['name'], 'Updated Name');
  });

  test('delete() should remove a document', () async {
    await fakeFirestore.collection('users').doc('test_user').set({
      'name': 'Alice',
    });
    await firestoreClient.delete(collectionPath: 'users', docId: 'test_user');

    final snapshot =
        await fakeFirestore.collection('users').doc('test_user').get();
    expect(snapshot.exists, false);
  });

  test('watch() should stream document changes', () async {
    final docRef = fakeFirestore.collection('users').doc('watch_user');
    await docRef.set({'name': 'Initial Name'});

    final stream = firestoreClient.watch(
      collectionPath: 'users',
      docId: 'watch_user',
      fromJson: (json) => json,
    );

    expectLater(
      stream,
      emitsInOrder([
        {'name': 'Initial Name', 'id': 'watch_user'},
        {'name': 'Updated Name', 'id': 'watch_user'},
      ]),
    );

    await docRef.update({'name': 'Updated Name'});
  });

  test('watch() should stream User document changes', () async {
    final docRef = fakeFirestore.collection('users').doc('user_123');
    await docRef.set({'name': 'Initial Name'});

    final stream = firestoreClient.watch(
      collectionPath: 'users',
      docId: 'user_123',
      fromJson: (json) => User.fromJson(json),
    );

    expectLater(
      stream,
      emitsInOrder([
        isA<User>().having((u) => u.name, 'name', 'Initial Name'),
        isA<User>().having((u) => u.name, 'name', 'Updated Name'),
      ]),
    );

    await docRef.update({'name': 'Updated Name'});
  });

  test('query() should return filtered users', () async {
    await fakeFirestore.collection('users').doc('user_1').set({
      'name': 'Alice',
    });
    await fakeFirestore.collection('users').doc('user_2').set({'name': 'Bob'});

    final result = await firestoreClient.query<User>(
      collectionPath: 'users',
      conditions: [QueryCondition('name', isEqualTo: 'Alice')],
      fromJson: (json) => User.fromJson(json),
    );

    expect(result.length, 1);
    expect(result.first.name, 'Alice');
  });

  test('batchWrite() should execute multiple operations', () async {
    await firestoreClient.batchWrite([
      (batch) {
        batch.set(fakeFirestore.collection('users').doc('user1'), {
          'name': 'User1',
        });
        return batch;
      },
      (batch) {
        batch.set(fakeFirestore.collection('users').doc('user2'), {
          'name': 'User2',
        });
        return batch;
      },
    ]);

    final snapshot1 =
        await fakeFirestore.collection('users').doc('user1').get();
    final snapshot2 =
        await fakeFirestore.collection('users').doc('user2').get();
    expect(snapshot1.exists, true);
    expect(snapshot2.exists, true);
  });

  test('runTransaction() should execute a transaction', () async {
    await fakeFirestore.collection('users').doc('user1').set({'counter': 0});

    await firestoreClient.runTransaction((transaction) async {
      final docRef = fakeFirestore.collection('users').doc('user1');
      final snapshot = await transaction.get(docRef);
      final currentCounter = snapshot.data()?['counter'] ?? 0;
      transaction.update(docRef, {'counter': currentCounter + 1});
    });

    final snapshot = await fakeFirestore.collection('users').doc('user1').get();
    expect(snapshot.data()?['counter'], 1);
  });

  test('count() should return the number of documents', () async {
    await fakeFirestore.collection('users').doc('user1').set({'name': 'Alice'});
    await fakeFirestore.collection('users').doc('user2').set({'name': 'Bob'});

    final count = await firestoreClient.count(
      collectionPath: 'users',
      conditions: [],
    );

    expect(count, 2);
  });
}
