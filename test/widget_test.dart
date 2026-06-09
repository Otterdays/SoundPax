import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:soundpax/main.dart';
import 'package:soundpax/models/app_state.dart';
import 'package:soundpax/src/rust/frb_generated.dart';

void main() {
  setUpAll(() async => await RustLib.init());

  testWidgets('shows SoundPax transport bar', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const SoundPaxApp(),
      ),
    );
    await tester.pump();

    expect(find.text('SoundPax'), findsOneWidget);
  });
}
