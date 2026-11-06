import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:attendance_app/models/attendance_record.dart';
import 'package:attendance_app/models/attendance_session.dart';
import 'package:attendance_app/services/user_service.dart';
import 'package:attendance_app/theme/app_theme.dart';
import 'package:attendance_app/ui/home_screen.dart';
import 'package:attendance_app/utils/date_labels.dart';

void main() {
  testWidgets('Student home shows menu', (WidgetTester tester) async {
    const user = AppUser(uid: 'u1', name: 'Siswa', role: UserRole.student);
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light(), home: HomeScreen(user: user, recordsStream: Stream.value(const []))));

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

  test('Status follows the late limit set by the teacher', () {
    final late = DateTime(2026, 11, 6, 9, 5);
    final session = AttendanceSession(
      id: 's1',
      className: 'XI RPL',
      subject: 'Mobile',
      teacherUid: 't1',
      teacherName: 'Guru',
      createdAt: DateTime(2026, 11, 6, 9),
      expiresAt: DateTime(2026, 11, 6, 9, 10),
      active: true,
      lateAt: late,
    );

    expect(session.statusAt(DateTime(2026, 11, 6, 9, 4, 59)), 'Attend');
    expect(session.statusAt(late), 'Attend');
    expect(session.statusAt(DateTime(2026, 11, 6, 9, 5, 1)), 'Late');
  });

  test('Late limit options stay shorter than QR validity', () {
    expect(AttendanceSession.lateAfterOptions(5), [2]);
    expect(AttendanceSession.lateAfterOptions(10), [2, 5]);
    expect(AttendanceSession.lateAfterOptions(30), [2, 5, 10, 15]);
  });

  test('Sessions are grouped by day label', () {
    final now = DateTime(2026, 11, 6, 9);
    expect(dayLabel(DateTime(2026, 11, 6, 7), now), 'Today');
    expect(dayLabel(DateTime(2026, 11, 5, 23), now), 'Yesterday');
    expect(dayLabel(DateTime(2026, 11, 1), now), '1 November 2026');
  });

  test('Student summary counts this month and finds today', () {
    final now = DateTime(2026, 11, 6, 9);
    AttendanceRecord record(String status, DateTime at, {String type = 'attendance'}) =>
        AttendanceRecord(
          id: '$status$at',
          name: 'Siswa',
          description: status,
          datetime: '-',
          address: '-',
          type: type,
          createdAt: at,
        );

    final summary = StudentSummary.from([
      record('Attend', DateTime(2026, 11, 6, 7)),
      record('Late', DateTime(2026, 11, 6, 8, 45)),
      record('Attend', DateTime(2026, 11, 2, 7)),
      record('Sick', DateTime(2026, 11, 3), type: 'permission'),
      record('Attend', DateTime(2026, 10, 30, 7)),
    ], now);

    expect(summary.monthAttend, 2);
    expect(summary.monthLate, 1);
    expect(summary.monthPermission, 1);
    expect(summary.latestToday?.description, 'Late');
  });
}
