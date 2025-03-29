import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_client/firestore_client.dart';

/// FirestoreClient は FirebaseFirestore を簡易的に扱うためのラッパークラスです。
/// CRUD 操作、クエリ、トランザクション、バッチ処理などをサポートします。
/// - create / read / update / delete
/// - query / collectionGroupQuery
/// - watch
/// - batchWrite / runTransaction
/// - count (Firestore Aggregation Query)
///
/// 内部的には [FirebaseFirestore] インスタンスを利用しますが、
/// コンストラクタで外部から注入もできるため、テスト時にモックに差し替えることも可能です。
class FirestoreClient {
  final FirebaseFirestore _firestore;

  /// [firestore] を指定しなければ [FirebaseFirestore.instance] が使用されます。
  FirestoreClient({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ===========================================================================
  // =                                 CREATE                                  =
  // ===========================================================================
  /// 新規ドキュメントを作成します。
  /// - [collectionPath] : コレクションのパス
  /// - [docId] : ドキュメントID (null の場合は自動生成)
  /// - [data] : 保存するオブジェクト
  /// - [toJson] : data を Map`<` String, dynamic> に変換する関数
  ///
  /// 作成日時(createdAt)と更新日時(updatedAt)を自動で設定します。
  ///
  /// 戻り値として [DocumentReference] を返すため、作成したドキュメントを後続で扱う場合に便利です。
  Future<DocumentReference> create<T>({
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
        return collectionRef.doc(docId);
      } else {
        return await collectionRef.add(dataWithTimestamps);
      }
    } on FirebaseException catch (e) {
      throw FirestoreException.fromFirebaseException(e)..stackTrace?.toString();
    } catch (e, stackTrace) {
      throw FirestoreException(
        message: 'Failed to create document',
        stackTrace: stackTrace,
      );
    }
  }

  /// サブコレクションにドキュメントを作成します。
  /// 例: parentCollectionPath="users", parentDocId="user123", subCollectionName="posts"
  ///
  /// 戻り値として [DocumentReference] を返します。
  Future<DocumentReference> createInSubCollection<T>({
    required String parentCollectionPath,
    required String parentDocId,
    required String subCollectionName,
    String? docId,
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
  /// ドキュメントを読み込み、存在しない場合は null を返します。
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
    } on FirebaseException catch (e) {
      throw FirestoreException.fromFirebaseException(e)..stackTrace?.toString();
    } catch (e, stackTrace) {
      throw FirestoreException(
        message: 'Failed to read document',
        stackTrace: stackTrace,
      );
    }
  }

  /// サブコレクション内の単一ドキュメントを読み込みます。存在しない場合は null を返します。
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
  /// ドキュメントを更新します。存在しない場合は新規作成されます。
  /// - updatedAt のみ更新し、既にある createdAt は変更しません。
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
        // ドキュメントが存在しない場合は作成 (createdAt も付与)
        dataWithUpdatedTimestamp['createdAt'] = FieldValue.serverTimestamp();
        await docRef.set(dataWithUpdatedTimestamp, SetOptions(merge: true));
      }
    } on FirebaseException catch (e) {
      throw FirestoreException.fromFirebaseException(e)..stackTrace?.toString();
    } catch (e, stackTrace) {
      throw FirestoreException(
        message: 'Failed to update document',
        stackTrace: stackTrace,
      );
    }
  }

  /// サブコレクション内のドキュメントを更新します。存在しない場合は新規作成されます。
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
  /// 指定したドキュメントを削除します。
  Future<void> delete({
    required String collectionPath,
    required String docId,
  }) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).delete();
    } on FirebaseException catch (e) {
      throw FirestoreException.fromFirebaseException(e)..stackTrace?.toString();
    } catch (e, stackTrace) {
      throw FirestoreException(
        message: 'Failed to delete document',
        stackTrace: stackTrace,
      );
    }
  }

  /// サブコレクション内のドキュメントを削除します。
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
  // =                                FETCH ALL                                =
  // ===========================================================================
  /// 指定したドキュメントIDのリストに基づいて、複数のドキュメントを一度に取得します。
  /// - [collectionPath]: コレクションのパス
  /// - [docIds]: 取得するドキュメントIDのリスト
  /// - [fromJson]: JSONからオブジェクトへの変換関数
  ///
  /// 戻り値は `Map<String, T?>` 形式で、キーはドキュメントID、値はデータオブジェクト（存在しない場合はnull）
  Future<Map<String, T?>> fetchAll<T>({
    required String collectionPath,
    required List<String> docIds,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final result = <String, T?>{};

      // ドキュメントIDが空の場合は空のマップを返す
      if (docIds.isEmpty) return result;

      // バッチで取得する（並列処理）
      final futures = docIds.map((docId) => read<T>(
            collectionPath: collectionPath,
            docId: docId,
            fromJson: fromJson,
          ).then((value) => MapEntry(docId, value)));

      final entries = await Future.wait(futures);
      return Map.fromEntries(entries);
    } on FirebaseException catch (e) {
      throw FirestoreException.fromFirebaseException(e)..stackTrace?.toString();
    } catch (e, stackTrace) {
      throw FirestoreException(
        message: 'Failed to fetch multiple documents',
        stackTrace: stackTrace,
      );
    }
  }

  /// サブコレクション内の複数のドキュメントを一度に取得します。
  Future<Map<String, T?>> fetchAllInSubCollection<T>({
    required String parentCollectionPath,
    required String parentDocId,
    required String subCollectionName,
    required List<String> docIds,
    required T Function(Map<String, dynamic>) fromJson,
  }) {
    final path = '$parentCollectionPath/$parentDocId/$subCollectionName';
    return fetchAll(
      collectionPath: path,
      docIds: docIds,
      fromJson: fromJson,
    );
  }

  // ===========================================================================
  // =                                WATCH ALL                                =
  // ===========================================================================
  /// 複数のドキュメントの変更を監視し、それぞれの変更をストリームとして返します。
  /// - [collectionPath]: コレクションのパス
  /// - [docIds]: 監視するドキュメントIDのリスト
  /// - [fromJson]: JSONからオブジェクトへの変換関数
  ///
  /// 戻り値は `Stream<Map<String, T?>>` で、キーはドキュメントID、値は最新のデータ（存在しない場合はnull）
  Stream<Map<String, T?>> watchAll<T>({
    required String collectionPath,
    required List<String> docIds,
    required T Function(Map<String, dynamic>) fromJson,
  }) {
    try {
      // ドキュメントIDが空の場合は空のマップを流すストリームを返す
      if (docIds.isEmpty) {
        return Stream.value(<String, T?>{});
      }

      // 各ドキュメントの監視ストリームを作成
      final streams = docIds.map((docId) {
        return watch<T>(
          collectionPath: collectionPath,
          docId: docId,
          fromJson: fromJson,
        ).map((data) => MapEntry(docId, data));
      }).toList();

      // 複数のストリームをまとめて、Map<String, T?>として出力する
      return StreamZip<MapEntry<String, T?>>(streams).map((entries) {
        return Map.fromEntries(entries);
      });
    } catch (e, stackTrace) {
      throw FirestoreException(
        message: 'Failed to watch multiple documents',
        stackTrace: stackTrace,
      );
    }
  }

  /// サブコレクション内の複数のドキュメントの変更を監視します。
  Stream<Map<String, T?>> watchAllInSubCollection<T>({
    required String parentCollectionPath,
    required String parentDocId,
    required String subCollectionName,
    required List<String> docIds,
    required T Function(Map<String, dynamic>) fromJson,
  }) {
    final path = '$parentCollectionPath/$parentDocId/$subCollectionName';
    return watchAll(
      collectionPath: path,
      docIds: docIds,
      fromJson: fromJson,
    );
  }

  // ===========================================================================
  // =                                 WATCH                                  =
  // ===========================================================================
  /// ドキュメントの変更を監視し、ストリームとして返します。
  /// - 存在しない場合は null を流す
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
      // ここで例外を投げ直すとストリームが終了する場合があるので注意
      throw FirestoreException(
        message: 'Failed to watch document',
        stackTrace: stackTrace,
      );
    });
  }

  /// サブコレクション内のドキュメント変更を監視し、ストリームとして返します。
  Stream<T?> watchInSubCollection<T>({
    required String parentCollectionPath,
    required String parentDocId,
    required String subCollectionName,
    required String docId,
    required T Function(Map<String, dynamic>) fromJson,
  }) {
    final path = '$parentCollectionPath/$parentDocId/$subCollectionName';
    return watch(collectionPath: path, docId: docId, fromJson: fromJson);
  }

  // ===========================================================================
  // =                                  QUERY                                 =
  // ===========================================================================
  /// クエリを実行し、該当するドキュメントを [T] のリストとして返します。
  /// [conditions] に基づく where 句をチェーン的に適用します。
  Future<List<T>> query<T>({
    required String collectionPath,
    required List<QueryCondition> conditions,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      Query<Map<String, dynamic>> ref = _firestore
          .collection(collectionPath)
          .withConverter<Map<String, dynamic>>(
            fromFirestore: (snap, _) => snap.data() ?? {},
            toFirestore: (model, _) => model,
          );

      for (final condition in conditions) {
        ref = applyCondition(ref, condition);
      }

      final snapshots = await ref.get();
      return snapshots.docs.map((doc) {
        // doc.data() は Map<String, dynamic>
        // id を付けて fromJson に渡す
        final data = doc.data();
        return fromJson({...data, 'id': doc.id});
      }).toList();
    } on FirebaseException catch (e) {
      throw FirestoreException.fromFirebaseException(e)..stackTrace?.toString();
    } catch (e, stackTrace) {
      throw FirestoreException(
        message: 'Failed to query documents',
        stackTrace: stackTrace,
      );
    }
  }

  /// コレクショングループクエリを実行し、特定のコレクション名に一致する
  /// 全サブコレクションをまたいで検索します。
  Future<List<T>> collectionGroupQuery<T>({
    required String collectionGroupName,
    required List<QueryCondition> conditions,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      Query<Map<String, dynamic>> ref = _firestore
          .collectionGroup(collectionGroupName)
          .withConverter<Map<String, dynamic>>(
            fromFirestore: (snap, _) => snap.data() ?? {},
            toFirestore: (model, _) => model,
          );

      for (final condition in conditions) {
        ref = applyCondition(ref, condition);
      }

      final snapshots = await ref.get();
      return snapshots.docs.map((doc) {
        final data = doc.data();
        return fromJson({...data, 'id': doc.id});
      }).toList();
    } on FirebaseException catch (e) {
      throw FirestoreException.fromFirebaseException(e)..stackTrace?.toString();
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
  /// 複数の書き込み操作を一括でコミットします。
  /// [actions] には WriteBatch を引数に取り、バッチ操作を組み立てる関数を複数渡すことができます。
  Future<void> batchWrite(List<WriteBatch Function(WriteBatch)> actions) async {
    try {
      final batch = _firestore.batch();
      for (final action in actions) {
        action(batch);
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw FirestoreException.fromFirebaseException(e)..stackTrace?.toString();
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
  /// [transactionHandler] 内で get や set などの処理を行い、その結果を返してください。
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction) transactionHandler,
  ) async {
    try {
      return await _firestore.runTransaction(transactionHandler);
    } on FirebaseException catch (e) {
      throw FirestoreException.fromFirebaseException(e)..stackTrace?.toString();
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
  /// Aggregation Query を使って、条件に合致するドキュメント数を取得します。
  /// 2023年以降に追加された機能のため、Firestore SDK バージョンによっては利用不可の場合があります。
  Future<int?> count({
    required String collectionPath,
    required List<QueryCondition> conditions,
  }) async {
    try {
      Query<Map<String, dynamic>> ref = _firestore
          .collection(collectionPath)
          .withConverter<Map<String, dynamic>>(
            fromFirestore: (snap, _) => snap.data() ?? {},
            toFirestore: (model, _) => model,
          );

      for (final condition in conditions) {
        ref = applyCondition(ref, condition);
      }

      final aggregate = await ref.count().get();
      return aggregate.count;
    } on FirebaseException catch (e) {
      throw FirestoreException.fromFirebaseException(e)..stackTrace?.toString();
    } catch (e, stackTrace) {
      throw FirestoreException(
        message: 'Failed to count documents',
        stackTrace: stackTrace,
      );
    }
  }

  // ===========================================================================
  // =                             WATCH QUERY                                =
  // ===========================================================================
  /// コレクションに対してクエリを実行し、その結果を List`<` T> としてストリームで返す。
  /// [orderBy] など、ソートの指定が必要な場合は引数で受け取るようにする。
  Stream<List<T>> watchQuery<T>({
    required String collectionPath,
    required List<QueryCondition> conditions,
    required T Function(Map<String, dynamic>) fromJson,
    List<String>? orderBy,
  }) {
    try {
      // まずは Query<Map<String,dynamic>> を構築
      Query<Map<String, dynamic>> ref = _firestore
          .collection(collectionPath)
          .withConverter<Map<String, dynamic>>(
            fromFirestore: (snap, _) => snap.data() ?? {},
            toFirestore: (model, _) => model,
          );

      // 条件を適用
      for (final condition in conditions) {
        ref = applyCondition(ref, condition);
      }

      // 並び順を指定（必要なら任意のロジックで拡張可能）
      if (orderBy != null) {
        for (final field in orderBy) {
          ref = ref.orderBy(field);
        }
      }

      // snapshots() を購読して List<T> に変換
      return ref.snapshots().map((querySnapshot) {
        return querySnapshot.docs.map((doc) {
          final data = doc.data();
          return fromJson({...data, 'id': doc.id});
        }).toList();
      }).handleError((error, stackTrace) {
        throw FirestoreException(
          message: 'Failed to watch query snapshots',
          stackTrace: stackTrace,
        );
      });
    } catch (e, stackTrace) {
      // ここは同期的に throw される可能性があるので、直接 FirestoreException に包んで投げる
      throw FirestoreException(
        message: 'Failed to build query stream',
        stackTrace: stackTrace,
      );
    }
  }

  // ===========================================================================
  // =                           HELPER  METHODS                              =
  // ===========================================================================
  /// Firestore から取得した [DocumentSnapshot] を [T] オブジェクトに変換します。
  /// fromJson 関数でデシリアライズし、その際に doc.id も data に混ぜます。
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

  /// [QueryCondition] を元にクエリオブジェクトへフィルタを適用します。
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
