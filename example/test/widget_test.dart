import 'package:flutter_in_store_app_version_checker_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Check MyApp', (tester) async {
    await tester.pumpWidget(const App());
    expect(find.byWidget(const App()), findsOneWidget);
  });
}
