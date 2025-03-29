import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore で発生した例外を扱うためのカスタム例外クラス。
/// [FirestoreException] is a custom exception class to handle Firestore errors.
class FirestoreException implements Exception {
  /// エラーメッセージ
  final String message;

  /// Firebase 側のエラーコード
  final String? code;

  /// スタックトレース
  final StackTrace? stackTrace;

  FirestoreException({
    required this.message,
    this.code,
    this.stackTrace,
  });

  /// [FirebaseException] を [FirestoreException] に変換するファクトリコンストラクタ。
  factory FirestoreException.fromFirebaseException(
    FirebaseException exception,
  ) {
    return FirestoreException(
      message: exception.message ?? 'Firebase Firestore error occurred.',
      code: exception.code,
      stackTrace: exception.stackTrace,
    );
  }

  @override
  String toString() {
    return 'FirestoreException{message: $message, code: $code, stackTrace: $stackTrace}';
  }
}
