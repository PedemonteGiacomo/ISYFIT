import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isyfit/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app loads login screen', (tester) async {
    await tester.pumpWidget(const IsyFitApp());
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('IsyFit'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
