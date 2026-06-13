import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/room_state.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('App smoke test - splash screen renders', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => RoomState(),
        child: const MyApp(),
      ),
    );

    // Verify that Splash Screen title "Cravit" renders
    expect(find.text('Cravit'), findsOneWidget);
    expect(find.text('Swipe. Match. Feast.'), findsOneWidget);

    // Pump frames for 3 seconds to let the splash timer fire and avoid pending timer error.
    await tester.pump(const Duration(seconds: 3));
  });
}
