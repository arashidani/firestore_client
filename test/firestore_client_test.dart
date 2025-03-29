import 'package:firestore_client/example/models/user.dart';
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

  test('create() should throw FirestoreException on toJson error', () async {
    expect(
      () => firestoreClient.create(
        collectionPath: 'users',
        data: 'invalidData',
        toJson: (_) => throw Exception('serialization error'),
      ),
      throwsA(isA<FirestoreException>()),
    );
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

      final snapshot = await fakeFirestore
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

  test('read() should return null if document does not exist', () async {
    final user = await firestoreClient.read(
      collectionPath: 'users',
      docId: 'non_existing_user',
      fromJson: (json) => json,
    );

    expect(user, isNull);
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

  test('update() should throw FirestoreException on serialization error',
      () async {
    expect(
      () => firestoreClient.update(
        collectionPath: 'users',
        docId: 'any',
        data: 'invalidData',
        toJson: (_) => throw Exception('Serialization failed'),
      ),
      throwsA(isA<FirestoreException>()),
    );
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

  // test/firestore_client_test.dart に追加

// fetchAll() のテスト
  test('fetchAll() should fetch multiple documents', () async {
    await fakeFirestore.collection('users').doc('user1').set({'name': 'Alice'});
    await fakeFirestore.collection('users').doc('user2').set({'name': 'Bob'});
    await fakeFirestore
        .collection('users')
        .doc('user3')
        .set({'name': 'Charlie'});

    final result = await firestoreClient.fetchAll<Map<String, dynamic>>(
      collectionPath: 'users',
      docIds: ['user1', 'user2', 'non_existent'],
      fromJson: (json) => json,
    );

    expect(result.length, 3);
    expect(result['user1']?['name'], 'Alice');
    expect(result['user2']?['name'], 'Bob');
    expect(result['non_existent'], isNull);
  });

  test('fetchAll() should return empty map for empty docIds', () async {
    final result = await firestoreClient.fetchAll<Map<String, dynamic>>(
      collectionPath: 'users',
      docIds: [],
      fromJson: (json) => json,
    );

    expect(result, isEmpty);
  });

  test('fetchAll() should throw FirestoreException on fromJson error',
      () async {
    await fakeFirestore.collection('users').doc('user1').set({'name': 'Alice'});

    expect(
      () => firestoreClient.fetchAll<Map<String, dynamic>>(
        collectionPath: 'users',
        docIds: ['user1'],
        fromJson: (_) => throw Exception('fromJson error'),
      ),
      throwsA(isA<FirestoreException>()),
    );
  });

  test('watchAll() should return a stream with empty map for empty docIds',
      () async {
    final stream = firestoreClient.watchAll<Map<String, dynamic>>(
      collectionPath: 'users',
      docIds: [],
      fromJson: (json) => json,
    );

    final result = await stream.first;
    expect(result, isEmpty);
  });

// サブコレクション関連のテスト
  test('fetchAllInSubCollection() should fetch documents in a subCollection',
      () async {
    await fakeFirestore
        .collection('users/user123/posts')
        .doc('post1')
        .set({'title': 'Post 1'});
    await fakeFirestore
        .collection('users/user123/posts')
        .doc('post2')
        .set({'title': 'Post 2'});

    final result =
        await firestoreClient.fetchAllInSubCollection<Map<String, dynamic>>(
      parentCollectionPath: 'users',
      parentDocId: 'user123',
      subCollectionName: 'posts',
      docIds: ['post1', 'post2'],
      fromJson: (json) => json,
    );

    expect(result.length, 2);
    expect(result['post1']?['title'], 'Post 1');
    expect(result['post2']?['title'], 'Post 2');
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

  test('batchWrite() should throw FirestoreException on error inside batch',
      () async {
    final brokenClient = FirestoreClient(firestore: fakeFirestore);

    expect(
      () => brokenClient.batchWrite([
        (_) => throw Exception('batch error'),
      ]),
      throwsA(isA<FirestoreException>()),
    );
  });

  test('runTransaction() should throw FirestoreException on failure', () async {
    expect(
      () => firestoreClient.runTransaction((tx) async {
        throw Exception('transaction failed');
      }),
      throwsA(isA<FirestoreException>()),
    );
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

  test('watchQuery() should stream filtered user list', () async {
    final docRef = fakeFirestore.collection('users').doc('user_1');
    await docRef.set({'name': 'Alice', 'age': 20});

    final stream = firestoreClient.watchQuery<Map<String, dynamic>>(
      collectionPath: 'users',
      conditions: [QueryCondition('age', isGreaterThan: 18)],
      orderBy: ['age'],
      fromJson: (json) => json,
    );

    expectLater(
      stream,
      emitsInOrder([
        [containsPair('name', 'Alice')], // 初回 emit
        [containsPair('name', 'Alice'), containsPair('name', 'Bob')], // 追加後
      ]),
    );

    // 追加入力
    await fakeFirestore.collection('users').doc('user_2').set({
      'name': 'Bob',
      'age': 22,
    });
  });

  test('watchQuery() should emit FirestoreException on fromJson error',
      () async {
    await fakeFirestore.collection('users').add({'name': 'Test'});

    final stream = firestoreClient.watchQuery<Map<String, dynamic>>(
      collectionPath: 'users',
      conditions: [],
      fromJson: (json) => throw Exception('fromJson failed'), // わざと例外を投げる
    );

    expectLater(
      stream,
      emitsError(isA<FirestoreException>()),
    );
  });

  test('collectionGroupQuery() should return documents across subCollections',
      () async {
    await fakeFirestore.collection('users/user1/posts').doc('post1').set({
      'title': 'Hello World',
    });
    await fakeFirestore.collection('users/user2/posts').doc('post2').set({
      'title': 'Goodbye World',
    });

    final posts =
        await firestoreClient.collectionGroupQuery<Map<String, dynamic>>(
      collectionGroupName: 'posts',
      conditions: [],
      fromJson: (json) => json,
    );

    expect(posts.length, 2);
    expect(posts[0]['title'], isNotNull);
    expect(posts[1]['title'], isNotNull);
  });
}
