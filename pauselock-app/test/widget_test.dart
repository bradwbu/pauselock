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

    // Verify that we are on the Home Page and PAUSELOCK text is rendered
    expect(find.text('PAUSELOCK'), findsOneWidget);
    
    // Verify that the search input is rendered
    expect(find.text('Search player...'), findsOneWidget);

    // Verify Nav Cards exist
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Builds'), findsOneWidget);
    expect(find.text('Heroes'), findsOneWidget);
    expect(find.text('Leaderboard'), findsOneWidget);
  });
}
