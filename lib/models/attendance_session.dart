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
  final bool active;

  const AttendanceSession({
    required this.id,
    required this.className,
    required this.subject,
    required this.teacherUid,
    required this.teacherName,
    required this.createdAt,
    required this.expiresAt,
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

  Duration get remaining {
    final left = expiresAt.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }
}
