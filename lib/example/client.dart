import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_client/firestore_client.dart';

/// FirestoreClientのインスタンスを作成する関数
FirestoreClient createFirestoreClient() {
  return FirestoreClient(firestore: FirebaseFirestore.instance);
}

/// FakeFirestoreを使用する場合（test）
FirestoreClient createFakeFirestoreClient() {
  final fakeFirestore = FakeFirebaseFirestore();
  return FirestoreClient(firestore: fakeFirestore);
}
