import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:attendance_app/models/attendance_session.dart';
import 'package:attendance_app/services/user_service.dart';
import 'package:attendance_app/theme/app_theme.dart';
import 'package:attendance_app/ui/home_screen.dart';
import 'package:attendance_app/ui/teacher/session_status.dart';

void main() {
  testWidgets('Student home shows menu', (WidgetTester tester) async {
    const user = AppUser(uid: 'u1', name: 'Siswa', role: UserRole.student);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light(), home: const HomeScreen(user: user)));

    expect(find.text('Attendance Record'), findsOneWidget);
    expect(find.text('Permission / Leave'), findsOneWidget);
    expect(find.text('Attendance History'), findsOneWidget);
  });

  test('Session id is read only from app QR codes', () {
    expect(AttendanceSession.idFromQr('attendance_app:session:abc123'), 'abc123');
    expect(AttendanceSession.idFromQr('attendance_app:session:'), isNull);
    expect(AttendanceSession.idFromQr('https://example.com'), isNull);
    expect(AttendanceSession.idFromQr(null), isNull);
  });

  test('Sessions are grouped by day label', () {
    final now = DateTime(2026, 11, 6, 9);
    expect(sessionDayLabel(DateTime(2026, 11, 6, 7), now), 'Today');
    expect(sessionDayLabel(DateTime(2026, 11, 5, 23), now), 'Yesterday');
    expect(sessionDayLabel(DateTime(2026, 11, 1), now), '1 November 2026');
  });
}
