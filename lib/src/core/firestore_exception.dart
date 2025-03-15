import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestoreで発生した例外を扱うためのカスタム例外クラスです。
/// [FirestoreException] is a custom exception class to handle Firestore errors.
class FirestoreException implements Exception {
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  FirestoreException({required this.message, this.code, this.stackTrace});

  /// [FirebaseException]から[FirestoreException]を生成します。
  ///
  /// Creates a [FirestoreException] from a [FirebaseException].
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
