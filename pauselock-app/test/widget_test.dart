import 'package:flutter_test/flutter_test.dart';
import 'package:pauselock_app/main.dart';
import 'package:pauselock_app/src/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.initialize();
  });

  testWidgets('App basic rendering test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PauselockApp());
    await tester.pumpAndSettle();

    // Verify that PAUSELOCK text is rendered somewhere (appbar, sidebar, etc)
    expect(find.text('PAUSELOCK'), findsWidgets);
    
    // Verify Nav elements exist in the UI (either sidebar or cards)
    expect(find.text('Heroes'), findsWidgets);
    expect(find.text('Builds'), findsWidgets);
    expect(find.text('Leaderboard'), findsWidgets);
  });
}
