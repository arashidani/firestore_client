import 'package:cloud_firestore/cloud_firestore.dart';
import '../../firestore_client.dart';

/// [FirestoreClient]はFirebaseFirestoreを簡易的に扱うためのラッパークラスです。
/// CRUD操作、クエリ、トランザクション、バッチ処理などをサポートします。
///
/// [FirestoreClient] is a wrapper class to handle FirebaseFirestore easily.
/// It supports CRUD operations, queries, transactions, and batch operations, etc.
class FirestoreClient {
  final FirebaseFirestore _firestore;

  /// コンストラクタ
  /// [firestore]を指定しなければ[FirebaseFirestore.instance]が使用されます。
  ///
  /// Constructor
  /// If [firestore] is not provided, [FirebaseFirestore.instance] will be used by default.
  FirestoreClient({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ===========================================================================
  // =                                 CREATE                                  =
  // ===========================================================================
  /// 新規ドキュメントを作成します。
  /// [collectionPath]を指定し、[data]をFirestoreに保存します。
  /// [docId]を指定しない場合は、自動生成されます。
  /// 作成時にcreatedAtとupdatedAtを自動的に付与します。
  ///
  /// Creates a new document in the specified [collectionPath] with the given [docId] and [data].
  /// If [docId] is not specified, an auto-generated ID will be used.
  /// Automatically adds 'createdAt' and 'updatedAt' timestamps.
  Future<void> create<T>({
    required String collectionPath,
    String? docId,
    required T data,
    required Map<String, dynamic> Function(T) toJson,
  }) async {
    try {
      final now = FieldValue.serverTimestamp();
      final dataWithTimestamps = {
        ...toJson(data),
        'createdAt': now,
        'updatedAt': now,
      };
      final collectionRef = _firestore.collection(collectionPath);
      if (docId != null) {
        await collectionRef.doc(docId).set(dataWithTimestamps);
      } else {
        await collectionRef.add(dataWithTimestamps);
      }
    } catch (e, stackTrace) {
      throw FirestoreException(
        message: 'Failed to create document',
        stackTrace: stackTrace,
      );
    }
  }

  /// サブコレクションにドキュメントを作成します。
  /// [parentCollectionPath] (例: "users"), [parentDocId] (例: "user123") を指定し、
  /// その配下の[subCollectionName] (例: "posts") に対してドキュメントを作成します。
  ///
  /// Creates a new document under a subCollection.
  /// Example usage: parentCollectionPath="users", parentDocId="user123", subCollectionName="posts".
  Future<void> createInSubCollection<T>({
    required String parentCollectionPath,
    required String parentDocId,
    required String subCollectionName,
    required String docId,
    required T data,
    required Map<String, dynamic> Function(T) toJson,
  }) {
    final path = '$parentCollectionPath/$parentDocId/$subCollectionName';
    return create(
      collectionPath: path,
      docId: docId,
      data: data,
      toJson: toJson,
    );
  }

  // ===========================================================================
  // =                                  READ                                   =
  // ===========================================================================
  /// ドキュメントを読み込みます。[docId]が存在しない場合はnullを返します。
  ///
  /// Reads a document from [collectionPath]. Returns null if the [docId] doesn't exist.
  Future<T?> read<T>({
    required String collectionPath,
    required String docId,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final snapshot =
          await _firestore.collection(collectionPath).doc(docId).get();
      if (!snapshot.exists) return null;
      return fromFirestore(snapshot, fromJson);
    } catch (e, stackTrace) {
      throw FirestoreException(
        message: 'Failed to read document',
        stackTrace: stackTrace,
      );
    }
  }

  /// サブコレクション内の単一ドキュメントを読み込みます。存在しない場合はnullを返します。
  ///
  /// Reads a document inside a subCollection. Returns null if it doesn't exist.
  Future<T?> readInSubCollection<T>({
    required String parentCollectionPath,
    required String parentDocId,
    required String subCollectionName,
    required String docId,
    required T Function(Map<String, dynamic>) fromJson,
  }) {
    final path = '$parentCollectionPath/$parentDocId/$subCollectionName';
    return read(collectionPath: path, docId: docId, fromJson: fromJson);
  }

  // ===========================================================================
  // =                                 UPDATE                                 =
  // ===========================================================================
  /// 指定したドキュメントを更新します。ドキュメントが存在しない場合は新規作成します。
  /// updatedAtのみ更新し、createdAtは更新しません。
  ///
  /// Updates the specified document with [data]. If the document doesn't exist, it will create a new one.
  /// Only 'updatedAt' is set or updated; 'createdAt' remains unchanged if it already exists.
  Future<void> update<T>({
    required String collectionPath,
    required String docId,
    required Map<String, dynamic> Function(T) toJson,
    required T data,
  }) async {
    try {
      final docRef = _firestore.collection(collectionPath).doc(docId);
      final snapshot = await docRef.get();
      final dataWithUpdatedTimestamp = {
        ...toJson(data),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (snapshot.exists) {
        await docRef.update(dataWithUpdatedTimestamp);
      } else {
        await docRef.set(dataWithUpdatedTimestamp, SetOptions(merge: true));
      }
    } catch (e, stackTrace) {
      throw FirestoreException(
        message: 'Failed to update document',
        stackTrace: stackTrace,
      );
    }
  }

  /// サブコレクション内のドキュメントを更新します。存在しない場合は新規作成します。
  ///
  /// Updates a document inside a subCollection. If it doesn't exist, a new one will be created.
  Future<void> updateInSubCollection<T>({
    required String parentCollectionPath,
    required String parentDocId,
    required String subCollectionName,
    required String docId,
    required Map<String, dynamic> Function(T) toJson,
    required T data,
  }) {
    final path = '$parentCollectionPath/$parentDocId/$subCollectionName';
    return update(
      collectionPath: path,
      docId: docId,
      toJson: toJson,
      data: data,
    );
  }

  // ===========================================================================
  // =                                 DELETE                                 =
  // ===========================================================================
  /// ドキュメントを削除します。
  ///
  /// Deletes a document from the specified [collectionPath].
  Future<void> delete({
    required String collectionPath,
    required String docId,
  }) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).delete();
    } catch (e, stackTrace) {
      throw FirestoreException(
        message: 'Failed to delete document',
        stackTrace: stackTrace,
      );
    }
  }

  /// サブコレクション内のドキュメントを削除します。
  ///
  /// Deletes a document inside a subCollection.
  Future<void> deleteInSubCollection({
    required String parentCollectionPath,
    required String parentDocId,
    required String subCollectionName,
    required String docId,
  }) {
    final path = '$parentCollectionPath/$parentDocId/$subCollectionName';
    return delete(collectionPath: path, docId: docId);
  }

  // ===========================================================================
  // =                                 WATCH                                  =
  // ===========================================================================
  /// ドキュメントの変更を監視し、ストリームとして返します。
  /// ドキュメントが存在しない場合はnullを流します。
  ///
  /// Watches for changes on a document and returns a stream.
  /// If the document doesn't exist, it emits null.
  Stream<T?> watch<T>({
    required String collectionPath,
    required String docId,
    required T Function(Map<String, dynamic>) fromJson,
  }) {
    return _firestore
        .collection(collectionPath)
        .doc(docId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return fromFirestore(snapshot, fromJson);
    }).handleError((error, stackTrace) {
      throw FirestoreException(
        message: 'Failed to watch document',
        stackTrace: stackTrace,
      );
    });
  }

  /// サブコレクション内のドキュメント変更を監視し、ストリームとして返します。
  ///
  /// Watches for changes on a document in a subCollection and returns a stream.
  Stream<T?> watchInSubCollection<T>({
    required String parentCollectionPath,
    required String parentDocId,
    required String subCollectionName,
    required T Function(Map<String, dynamic>) fromJson,
  }) {
    final path = '$parentCollectionPath/$parentDocId/$subCollectionName';
    return watch(collectionPath: path, docId: parentDocId, fromJson: fromJson);
  }

  // ===========================================================================
  // =                                  QUERY                                 =
  // ===========================================================================
  /// クエリを実行し、該当するドキュメントを[T]のリストとして返します。
  /// [QueryCondition]に基づいてフィルタします。
  ///
  /// Executes a query on the specified [collectionPath] and returns a list of [T].
  /// Filters are applied based on the provided [QueryCondition] list.
  Future<List<T>> query<T>({
    required String collectionPath,
    required List<QueryCondition> conditions,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _firestore.collection(collectionPath) as Query<Map<String, dynamic>>;

      for (var condition in conditions) {
        query = applyCondition(query, condition);
      }

      final snapshots = await query.get();
      return snapshots.docs.map((doc) {
        return fromFirestore(
          doc as DocumentSnapshot<Map<String, dynamic>>,
          fromJson,
        );
      }).toList();
    } catch (e, stackTrace) {
      throw FirestoreException(
        message: 'Failed to query documents',
        stackTrace: stackTrace,
      );
    }
  }

  /// コレクショングループクエリを実行し、特定のコレクション名に一致する全サブコレクションを横断して検索します。
  ///
  /// Performs a collection group query across all subCollections matching [collectionGroupName].
  Future<List<T>> collectionGroupQuery<T>({
    required String collectionGroupName,
    required List<QueryCondition> conditions,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collectionGroup(
        collectionGroupName,
      );

      for (var condition in conditions) {
        query = applyCondition(query, condition);
      }

      final snapshots = await query.get();
      return snapshots.docs.map((doc) {
        return fromJson({...doc.data(), 'id': doc.id});
      }).toList();
    } catch (e, stackTrace) {
      throw FirestoreException(
        message: 'Failed to collectionGroup query documents',
        stackTrace: stackTrace,
      );
    }
  }

  // ===========================================================================
  // =                                BATCH WRITE                             =
  // ===========================================================================
  /// 複数の書き込み操作を一括でコミットするためのメソッドです。
  ///
  /// Allows executing multiple write operations in a single batch commit.
  Future<void> batchWrite(List<WriteBatch Function(WriteBatch)> actions) async {
    try {
      final batch = _firestore.batch();
      for (final action in actions) {
        action(batch);
      }
      await batch.commit();
    } catch (e, stackTrace) {
      throw FirestoreException(
        message: 'Failed to execute batch write',
        stackTrace: stackTrace,
      );
    }
  }

  // ===========================================================================
  // =                               TRANSACTION                              =
  // ===========================================================================
  /// トランザクションを実行します。
  ///
  /// Executes a Firestore transaction using [transactionHandler].
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction) transactionHandler,
  ) async {
    try {
      return _firestore.runTransaction(transactionHandler);
    } catch (e, stackTrace) {
      throw FirestoreException(
        message: 'Failed to run transaction',
        stackTrace: stackTrace,
      );
    }
  }

  // ===========================================================================
  // =                                 COUNT                                  =
  // ===========================================================================
  /// クエリの該当ドキュメント数を返します(2023年以降に追加されたFirestore Aggregation Query)。
  /// 利用可能な環境で動作します。
  ///
  /// Returns the count of documents that match the given [conditions].
  /// Requires Firestore Aggregation Query support (available since 2023).
  Future<int?> count({
    required String collectionPath,
    required List<QueryCondition> conditions,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _firestore.collection(collectionPath) as Query<Map<String, dynamic>>;
      for (var condition in conditions) {
        query = applyCondition(query, condition);
      }
      final snapshot = await query.count().get();
      return snapshot.count;
    } catch (e, stackTrace) {
      throw FirestoreException(
        message: 'Failed to count documents',
        stackTrace: stackTrace,
      );
    }
  }

  // ===========================================================================
  // =                           HELPER  METHODS                              =
  // ===========================================================================
  /// Firestoreから取得した[DocumentSnapshot]を[T]のオブジェクトに変換します。
  ///
  /// Converts the [DocumentSnapshot] from Firestore into an object of type [T].
  T fromFirestore<T>(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw FirestoreException(message: 'Document data is null');
    }
    return fromJson({...data, 'id': snapshot.id});
  }

  /// [QueryCondition]に基づいてクエリにフィルタを適用します。
  ///
  /// Applies filters to the query based on the [QueryCondition].
  Query<Map<String, dynamic>> applyCondition(
    Query<Map<String, dynamic>> query,
    QueryCondition condition,
  ) {
    var ref = query;
    if (condition.isEqualTo != null) {
      ref = ref.where(condition.field, isEqualTo: condition.isEqualTo);
    }
    if (condition.isNotEqualTo != null) {
      ref = ref.where(condition.field, isNotEqualTo: condition.isNotEqualTo);
    }
    if (condition.isLessThan != null) {
      ref = ref.where(condition.field, isLessThan: condition.isLessThan);
    }
    if (condition.isLessThanOrEqualTo != null) {
      ref = ref.where(
        condition.field,
        isLessThanOrEqualTo: condition.isLessThanOrEqualTo,
      );
    }
    if (condition.isGreaterThan != null) {
      ref = ref.where(condition.field, isGreaterThan: condition.isGreaterThan);
    }
    if (condition.isGreaterThanOrEqualTo != null) {
      ref = ref.where(
        condition.field,
        isGreaterThanOrEqualTo: condition.isGreaterThanOrEqualTo,
      );
    }
    if (condition.arrayContains != null) {
      ref = ref.where(condition.field, arrayContains: condition.arrayContains);
    }
    if (condition.arrayContainsAny != null) {
      ref = ref.where(
        condition.field,
        arrayContainsAny: condition.arrayContainsAny,
      );
    }
    if (condition.whereIn != null) {
      ref = ref.where(condition.field, whereIn: condition.whereIn);
    }
    if (condition.whereNotIn != null) {
      ref = ref.where(condition.field, whereNotIn: condition.whereNotIn);
    }
    if (condition.isNull != null) {
      ref = ref.where(condition.field, isNull: condition.isNull);
    }
    return ref;
  }
}
