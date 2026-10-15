import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:attendance_app/theme/app_tokens.dart';
import 'package:attendance_app/ui/widgets/feedback.dart';
import 'package:attendance_app/ui/widgets/status_badge.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  final CollectionReference dataCollection =
      FirebaseFirestore.instance.collection('attendance');

  Color _getAvatarColor(String name) {
    if (name.trim().isEmpty) return Colors.blueGrey;
    final int hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    return Colors.primaries[hash % Colors.primaries.length];
  }

  Future<void> _editData(
    String docId,
    String name,
    String address,
    String description,
    String datetime,
  ) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _EditAttendanceDialog(
        name: name,
        address: address,
        description: description,
        datetime: datetime,
      ),
    );
    if (result == null) return;

    try {
      await dataCollection.doc(docId).update(result);
      _showSnackBar("Data berhasil diperbarui.", Icons.check_circle_outline_rounded);
    } catch (e) {
      _showSnackBar("Gagal memperbarui data: $e", Icons.error_outline_rounded);
    }
  }

  Future<void> _deleteData(String docId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_rounded, color: AppColors.danger, size: 40),
        title: const Text("Hapus Data?"),
        content: Text("Data presensi \"$name\" akan dihapus permanen dan tidak bisa dikembalikan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.pressed)
                    ? AppColors.dangerPressed
                    : AppColors.danger,
              ),
              foregroundColor: const WidgetStatePropertyAll(AppColors.onDanger),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await dataCollection.doc(docId).delete();
      _showSnackBar("Data berhasil dihapus.", Icons.delete_outline_rounded);
    } catch (e) {
      _showSnackBar("Gagal menghapus data: $e", Icons.error_outline_rounded);
    }
  }

  void _showSnackBar(String message, IconData icon) {
    if (!mounted) return;
    showAppSnackBar(context, message, icon);
  }

  // Inisial putih bila kontras dengan warna avatar minimal 3:1 (teks besar), selain itu gelap.
  Color _avatarTextColor(Color background) {
    final lum = background.computeLuminance();
    final contrastWithWhite = 1.05 / (lum + 0.05);
    return contrastWithWhite >= 3 ? AppColors.onPrimary : AppColors.textPrimary;
  }

  Widget _buildMetaRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.s2),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceCard(
    String docId,
    String name,
    String address,
    String description,
    String datetime,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final avatarColor = _getAvatarColor(name);

    return Card(
      key: ValueKey(docId),
      margin: const EdgeInsets.only(bottom: AppSpacing.s3),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: AppSizes.avatar / 2,
              backgroundColor: avatarColor,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: textTheme.titleLarge!.copyWith(color: _avatarTextColor(avatarColor)),
              ),
            ),
            const SizedBox(width: AppSpacing.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(name, style: textTheme.titleSmall)),
                      const SizedBox(width: AppSpacing.s2),
                      StatusBadge(description: description),
                      PopupMenuButton<String>(
                        tooltip: "Opsi",
                        icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editData(docId, name, address, description, datetime);
                          } else if (value == 'delete') {
                            _deleteData(docId, name);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit_rounded, color: AppColors.textSecondary),
                              title: Text("Edit"),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete_rounded, color: AppColors.danger),
                              title: Text("Delete", style: TextStyle(color: AppColors.danger)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _buildMetaRow(Icons.schedule_rounded, datetime),
                  const SizedBox(height: AppSpacing.s2),
                  _buildMetaRow(Icons.location_on_rounded, address),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateView({required Widget icon, String? message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            if (message != null) ...[
              const SizedBox(height: AppSpacing.s3),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Attendance History")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.s5, AppSpacing.s4, AppSpacing.s5, 0),
          child: StreamBuilder<QuerySnapshot>(
            stream: dataCollection.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildStateView(icon: const CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _buildStateView(
                  icon: const Icon(Icons.error_rounded, size: 48, color: AppColors.danger),
                  message: "Gagal memuat riwayat: ${snapshot.error}",
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildStateView(
                  icon: const Icon(Icons.history_rounded, size: 48, color: AppColors.textSecondary),
                  message: "Belum ada riwayat presensi",
                );
              }

              // Urutkan data berdasarkan created_at secara aman di memori
              final docs = List<QueryDocumentSnapshot>.from(snapshot.data!.docs);
              docs.sort((a, b) {
                final dataA = a.data() as Map<String, dynamic>? ?? {};
                final dataB = b.data() as Map<String, dynamic>? ?? {};
                final timeA = dataA['created_at'] as Timestamp?;
                final timeB = dataB['created_at'] as Timestamp?;
                if (timeA != null && timeB != null) {
                  return timeB.compareTo(timeA);
                }
                // created_at masih null = baru ditulis, belum dikonfirmasi server -> paling atas
                if (timeA == null && timeB != null) return -1;
                if (timeA != null && timeB == null) return 1;
                return 0;
              });

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>? ?? {};
                  final docId = docs[index].id;
                  final name = data['name']?.toString() ?? 'Unknown';
                  final address = data['address']?.toString() ?? '-';
                  final description = data['description']?.toString() ?? '-';
                  final datetime = data['datetime']?.toString() ?? '-';

                  return _buildAttendanceCard(docId, name, address, description, datetime);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// Dialog punya State sendiri supaya controller di-dispose setelah animasi tutup selesai.
class _EditAttendanceDialog extends StatefulWidget {
  final String name;
  final String address;
  final String description;
  final String datetime;

  const _EditAttendanceDialog({
    required this.name,
    required this.address,
    required this.description,
    required this.datetime,
  });

  @override
  State<_EditAttendanceDialog> createState() => _EditAttendanceDialogState();
}

class _EditAttendanceDialogState extends State<_EditAttendanceDialog> {
  late final nameController = TextEditingController(text: widget.name);
  late final addressController = TextEditingController(text: widget.address);
  late final descriptionController = TextEditingController(text: widget.description);
  late final datetimeController = TextEditingController(text: widget.datetime);

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    descriptionController.dispose();
    datetimeController.dispose();
    super.dispose();
  }

  Widget _field(TextEditingController controller, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit Data"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(nameController, "Name"),
            _field(addressController, "Address", maxLines: 2),
            _field(descriptionController, "Description"),
            _field(datetimeController, "Date / Time"),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Batal"),
        ),
        FilledButton(
          onPressed: () {
            if (nameController.text.trim().isEmpty) return;
            Navigator.pop(context, {
              'name': nameController.text.trim(),
              'address': addressController.text.trim(),
              'description': descriptionController.text.trim(),
              'datetime': datetimeController.text.trim(),
            });
          },
          child: const Text("Simpan"),
        ),
      ],
    );
  }
}
