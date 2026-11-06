import 'package:cloud_firestore/cloud_firestore.dart';

/// Satu baris koleksi `attendance`: presensi (type attendance) atau izin (type permission).
class AttendanceRecord {
  final String id;
  final String name;
  final String description;
  final String datetime;
  final String address;
  final String type;
  final String? className;
  final DateTime? createdAt;

  const AttendanceRecord({
    required this.id,
    required this.name,
    required this.description,
    required this.datetime,
    required this.address,
    required this.type,
    this.className,
    this.createdAt,
  });

  factory AttendanceRecord.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AttendanceRecord(
      id: doc.id,
      name: data['name']?.toString() ?? 'Unknown',
      description: data['description']?.toString() ?? '-',
      datetime: data['datetime']?.toString() ?? '-',
      address: data['address']?.toString() ?? '-',
      type: data['type']?.toString() ?? 'attendance',
      className: data['class_name']?.toString(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  bool get isPermission => type == 'permission';
}

/// Ringkasan untuk Home siswa, dihitung dari riwayat milik siswa itu sendiri.
class StudentSummary {
  final AttendanceRecord? latestToday;
  final int monthAttend;
  final int monthLate;
  final int monthPermission;

  const StudentSummary({
    required this.latestToday,
    required this.monthAttend,
    required this.monthLate,
    required this.monthPermission,
  });

  factory StudentSummary.from(List<AttendanceRecord> records, DateTime now) {
    AttendanceRecord? latestToday;
    var attend = 0, late = 0, permission = 0;

    for (final r in records) {
      // createdAt null = baru dikirim, belum dikonfirmasi server.
      final at = r.createdAt ?? now;
      if (at.year != now.year || at.month != now.month) continue;

      if (r.isPermission) {
        permission++;
      } else if (r.description == 'Attend') {
        attend++;
      } else if (r.description == 'Late') {
        late++;
      }

      if (!r.isPermission && at.day == now.day) {
        final current = latestToday;
        if (current == null || at.isAfter(current.createdAt ?? now)) latestToday = r;
      }
    }

    return StudentSummary(
      latestToday: latestToday,
      monthAttend: attend,
      monthLate: late,
      monthPermission: permission,
    );
  }
}
