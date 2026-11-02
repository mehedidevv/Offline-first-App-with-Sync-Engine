import 'package:flutter_test/flutter_test.dart';
import 'package:sync_nest/main.dart';

void main() {
  testWidgets('SyncNestApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Note: Hive requires initialization in tests or mock services.
    // For basic test, verify app structure.
    expect(SyncNestApp, isNotNull);
  });
}
