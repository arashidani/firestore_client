# Dart Package Coding Guidelines & Style Guide

# Introduction
- レビュー言語: レビューは専門用語を除いて**必ず**日本語で回答すること。
- レビューのルール: **必ず**日本語でレビューを記述すること。

## 1. 一般的なガイドライン
- **Dart スタイルガイドに従う**: [公式 Dart スタイルガイド](https://dart.dev/guides/language/effective-dart/style)を遵守する。
- **リントを有効にする**: `analysis_options.yaml` に `lints` パッケージを設定する。
- **ドキュメントを記述する**: 公開クラス、メソッド、フィールドには DartDoc (`///`) を使用する。
- **セマンティックバージョニングを守る**: `major.minor.patch` の形式を遵守する。
- **Dart パッケージとして適切な形にする**: `pubspec.yaml` の `name` や `description` などを適切に設定し、適切なディレクトリ構造を維持する。

## 2. 命名規則
- **ファイル名**: `snake_case.dart` (例: `my_class.dart`)
- **クラス名**: `PascalCase` (例: `MyClass`)
- **メソッド・変数名**: `camelCase` (例: `fetchData`)
- **定数名**: `ALL_CAPS_WITH_UNDERSCORES` (例: `MAX_TIMEOUT`)
- **列挙型**: 名前と値ともに `PascalCase` (例: `enum LogLevel { debug, error }`)

## 3. コードフォーマット
- **Dart フォーマッターを使用する**: `dart format .` を実行して整形する。
- **行の長さ**: **80～100 文字以内**を推奨。
- **インデント**: スペース 2 つを使用する。

```dart
if (condition) {
  doSomething();
} else {
  doSomethingElse();
}
```

## 4. Null 安全性 & 型安全性
- `var` の使用は **型が明確な場合のみ** にする。
- **可能な限り null を避ける**: `late` やデフォルト値を活用する。
- **Nullable 型 (`?`) を慎重に扱う**: `?.` や `??` を適切に活用し、明示的な null チェックを行う。

```dart
String? nullableString;
if (nullableString != null) {
  print(nullableString.length); // 安全にアクセス可能
}
```

## 5. エラーハンドリング
- `try-catch` を適切に使用し、エラーの影響範囲を限定する。
- **汎用的な `Exception` のキャッチを避ける**: 具体的な例外クラスを使う。

```dart
try {
  fetchData();
} on TimeoutException catch (e) {
  print('タイムアウト: ${e.message}');
} catch (e) {
  print('予期しないエラー: $e');
}
```

## 6. ロギング & デバッグ
- **デバッグ用途以外で `print()` を使用しない**
- **本番環境では `logger` パッケージを使用する**

```dart
import 'package:logger/logger.dart';

final logger = Logger();
logger.d('デバッグメッセージ');
logger.e('エラーメッセージ');
```

## 7. 非同期処理
- **`async/await` を優先する** (`Future.then()` より可読性が高いため)
- **非同期処理のエラーを適切に処理する**

```dart
Future<void> fetchData() async {
  try {
    final data = await api.getData();
    print(data);
  } catch (e) {
    print('エラー: $e');
  }
}
```

## 8. ハードコーディングの禁止
- **設定値やメッセージは適切な定数やリソースファイルで管理する**
- **API の URL やキーをコード内に直接書かない** (環境変数や `.env` ファイルを利用する)
- **文字列のハードコーディングを避ける** (i18n に対応させる)

**NG例:**
```dart
final apiUrl = 'https://example.com/api';
```

**OK例:**
```dart
const String apiUrl = String.fromEnvironment('API_URL', defaultValue: 'https://example.com/api');
```

## 9. パッケージ公開前のチェックリスト
- ✅ `dart analyze` を実行し、すべての警告を修正する。
- ✅ `dart test` でテストを実行し、すべてのテストが成功することを確認する。
- ✅ `pubspec.yaml` に適切なメタデータ (`description`, `homepage` など) を記述する。
- ✅ `CHANGELOG.md` に最新の変更履歴を記載する。
- ✅ `dart doc` でドキュメントを生成し、内容を確認する。


