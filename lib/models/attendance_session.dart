import 'package:cloud_firestore/cloud_firestore.dart';

/// Sesi absen yang dibuat guru. Siswa absen dengan memindai QR sesi ini.
class AttendanceSession {
  static const qrPrefix = 'attendance_app:session:';

  final String id;
  final String className;
  final String subject;
  final String teacherUid;
  final String teacherName;
  final DateTime? createdAt;
  final DateTime expiresAt;

  /// Scan setelah waktu ini tercatat Late. Null untuk sesi lama sebelum fitur ini ada.
  final DateTime? lateAt;
  final bool active;

  const AttendanceSession({
    required this.id,
    required this.className,
    required this.subject,
    required this.teacherUid,
    required this.teacherName,
    required this.createdAt,
    required this.expiresAt,
    this.lateAt,
    required this.active,
  });

  factory AttendanceSession.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AttendanceSession(
      id: doc.id,
      className: data['class_name']?.toString() ?? '-',
      subject: data['subject']?.toString() ?? '-',
      teacherUid: data['teacher_uid']?.toString() ?? '',
      teacherName: data['teacher_name']?.toString() ?? '-',
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      expiresAt: (data['expires_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lateAt: (data['late_at'] as Timestamp?)?.toDate(),
      active: data['active'] as bool? ?? false,
    );
  }

  String get qrData => '$qrPrefix$id';

  /// Id sesi dari isi QR, atau null bila QR bukan milik aplikasi ini.
  static String? idFromQr(String? raw) {
    if (raw == null || !raw.startsWith(qrPrefix)) return null;
    final id = raw.substring(qrPrefix.length);
    return id.isEmpty ? null : id;
  }

  bool get isOpen => active && DateTime.now().isBefore(expiresAt);

  /// Status presensi untuk siswa yang memindai QR pada waktu [scannedAt].
  String statusAt(DateTime scannedAt) {
    final limit = lateAt;
    return limit != null && scannedAt.isAfter(limit) ? 'Late' : 'Attend';
  }

  /// Pilihan batas terlambat (menit): selalu lebih pendek dari masa berlaku QR,
  /// supaya status Late masih mungkin terjadi.
  static List<int> lateAfterOptions(int validMinutes) =>
      [2, 5, 10, 15].where((m) => m < validMinutes).toList();

  Duration get remaining {
    final left = expiresAt.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }
}
