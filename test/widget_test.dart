import 'package:flutter_test/flutter_test.dart';

import 'package:attendance_app/main.dart';

void main() {
  testWidgets('Home screen shows menu', (WidgetTester tester) async {
    await tester.pumpWidget(const AttendanceApp());

    expect(find.text('Attendance Record'), findsOneWidget);
    expect(find.text('Permission / Leave'), findsOneWidget);
    expect(find.text('Attendance History'), findsOneWidget);
  });
}
