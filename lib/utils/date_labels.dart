import 'package:intl/intl.dart';

/// Judul kelompok per hari: Today, Yesterday, atau tanggal lengkap.
String dayLabel(DateTime day, DateTime now) {
  final d = DateTime(day.year, day.month, day.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(d).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return DateFormat('d MMMM yyyy').format(day);
}
