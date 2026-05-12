import 'package:flutter_test/flutter_test.dart';
import 'package:studyapp/main.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const StudyApp());
    expect(find.text('Yaza'), findsOneWidget);
  });
}
