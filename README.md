# Firestore Client
Firestore Client is a Flutter package that provides a simple and efficient wrapper around Firebase Firestore. It simplifies Firestore CRUD operations, queries, transactions, batch writes, and real-time document listening.
Firestore Client は、Firebase Firestore を簡単に操作できる Flutter パッケージです。CRUD 操作、クエリ、トランザクション、バッチ書き込み、リアルタイムのドキュメント監視を簡単に実装できます。

## Features
- 📌 **CRUD operations**: Create, Read, Update, and Delete Firestore documents easily.
- 🔍 **Queries**: Perform filtered Firestore queries with flexible conditions.
- 🔄 **Real-time updates**: Listen to document changes in real-time.
- 📡 **Real-time queries**: Listen to query results as they update in real-time.
- 🧺 **Batch writes**: Execute multiple write operations in a single transaction.
- 🔁 **Firestore transactions**: Perform Firestore transactions safely and efficiently.
- 📂 **SubCollection support**: Easily handle nested Firestore collections.

## 特徴
- 📌 CRUD 操作: Firestore のドキュメントを簡単に作成・取得・更新・削除できます。
- 🔍 クエリ: 柔軟な条件を指定して Firestore のデータを検索できます。
- 🔄 リアルタイム更新: Firestore の変更をリアルタイムで監視できます。
- 📡 リアルタイムクエリ: クエリ結果の変更をリアルタイムに取得できます。
- 🧺 バッチ書き込み: 複数の Firestore 書き込み操作を一括で実行できます。
- 🔁 トランザクション: Firestore のトランザクションを安全かつ効率的に実行できます。
- 📂 サブコレクション対応: Firestore のネストされたコレクションを簡単に管理できます。

## Getting Started
### Installation
Add the package to your `pubspec.yaml` file:
```yaml
dependencies:
  firestore_client: latest_version
```
Then run:
```sh
flutter pub get
```

### Setup
Before using Firestore Client, make sure Firebase is initialized in your project:
```dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
```

## Usage
### Initialize FirestoreClient
```dart
import 'package:firestore_client/firestore_client.dart';

final firestoreClient = FirestoreClient();
```

### Creating a Document
```dart
await firestoreClient.create(
  collectionPath: 'users',
  docId: 'user_123', // optional: if not provided, a new ID will be generated
  data: user,
  toJson: (user) => user.toJson(),
);
```

### Reading a Document
```dart
final user = await firestoreClient.read(
  collectionPath: 'users',
  docId: 'user_123',
  fromJson: (json) => User.fromJson(json),
);
```

### Updating a Document
```dart
await firestoreClient.update(
  collectionPath: 'users',
  docId: 'user_123',
  data: updatedUser,
  toJson: (user) => user.toJson(),
);
```

### Deleting a Document
```dart
await firestoreClient.delete(
  collectionPath: 'users',
  docId: 'user_123',
);
```

### Querying Documents
```dart
final users = await firestoreClient.query<User>(
  collectionPath: 'users',
  conditions: [QueryCondition('age', isGreaterThan: 18)],
  fromJson: (json) => User.fromJson(json),
);
```

### Watching a Document in Real-time
```dart
final userStream = firestoreClient.watch<User>(
  collectionPath: 'users',
  docId: 'user_123',
  fromJson: (json) => User.fromJson(json),
);

userStream.listen((user) {
  print('User updated: \${user?.name}');
});
```

### Watching a Query in Real-time
```dart
final reportsStream = firestoreClient.watchQuery<DailyReport>(
  collectionPath: 'users/uid123/dailyReports',
  conditions: [
    QueryCondition('date', isGreaterThanOrEqualTo: start),
    QueryCondition('date', isLessThan: end),
  ],
  orderBy: ['date'],
  fromJson: (json) => DailyReport.fromJson(json),
);

reportsStream.listen((reports) {
  print('Got \${reports.length} reports');
});
```

## Additional Information
- Example applications can be found in the `/example` folder.
- Contributions are welcome! Feel free to submit PRs or issues on GitHub.
- For more details, refer to the official Firebase Firestore documentation.

Happy coding! 🚀
