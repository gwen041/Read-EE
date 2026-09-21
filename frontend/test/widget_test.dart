import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('READ-EE login screen test', (WidgetTester tester) async {
    await tester.pumpWidget(const ReadEEApp());

    expect(find.text('Teacher Login'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
  });
}