import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
      _showSnackBar("Data berhasil diperbarui.", Icons.check_circle_outline);
    } catch (e) {
      _showSnackBar("Gagal memperbarui data: $e", Icons.error_outline);
    }
  }

  Future<void> _deleteData(String docId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
        title: const Text("Hapus Data?"),
        content: Text("Data presensi \"$name\" akan dihapus permanen dan tidak bisa dikembalikan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await dataCollection.doc(docId).delete();
      _showSnackBar("Data berhasil dihapus.", Icons.delete_outline);
    } catch (e) {
      _showSnackBar("Gagal menghapus data: $e", Icons.error_outline);
    }
  }

  void _showSnackBar(String message, IconData icon) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String description) {
    switch (description) {
      case 'Attend':
        return Colors.green;
      case 'Late':
        return Colors.orange;
      case 'Leave':
        return Colors.red;
      default:
        return Colors.blue; // Sick / Permission / Others
    }
  }

  Widget _buildAttendanceCard(
    String docId,
    String name,
    String address,
    String description,
    String datetime,
  ) {
    final statusColor = _statusColor(description);

    return Card(
      key: ValueKey(docId),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: _getAvatarColor(name),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          description,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.black45),
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
                              leading: Icon(Icons.edit_outlined),
                              title: Text("Edit"),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete_outline, color: Colors.red),
                              title: Text("Delete", style: TextStyle(color: Colors.red)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.black45),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          datetime,
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.black45),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          address,
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: StreamBuilder<QuerySnapshot>(
            stream: dataCollection.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text("Gagal memuat riwayat: ${snapshot.error}"));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Belum ada riwayat presensi"));
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
