import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:attendance_app/theme/app_tokens.dart';
import 'package:attendance_app/ui/widgets/feedback.dart';

class AbsentScreen extends StatefulWidget {
  const AbsentScreen({super.key});

  @override
  State<AbsentScreen> createState() => _AbsentScreenState();
}

class _AbsentScreenState extends State<AbsentScreen> {
  static const List<String> categories = ["Sick", "Permission", "Others"];

  final nameController = TextEditingController();
  final fromController = TextEditingController();
  final untilController = TextEditingController();
  String? selectedCategory;

  final CollectionReference dataCollection =
      FirebaseFirestore.instance.collection('attendance');

  @override
  void dispose() {
    nameController.dispose();
    fromController.dispose();
    untilController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        controller.text = DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }
  }

  Future<void> submitPermission(String nama, String keterangan, String from, String until) async {
    await dataCollection.add({
      'name': nama.trim(),
      'address': '-',
      'description': keterangan,
      'datetime': '$from - $until',
      'type': 'permission',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> onSubmitPressed() async {
    final nama = nameController.text;
    final from = fromController.text;
    final until = untilController.text;

    if (nama.trim().isEmpty || selectedCategory == null || from.isEmpty || until.isEmpty) {
      _showSnackBar("Lengkapi semua data izin terlebih dahulu.", Icons.warning_amber_rounded);
      return;
    }

    final format = DateFormat('dd/MM/yyyy');
    if (format.parse(until).isBefore(format.parse(from))) {
      _showSnackBar("Tanggal selesai tidak boleh sebelum tanggal mulai.", Icons.event_busy_rounded);
      return;
    }

    _showLoaderDialog();
    try {
      await submitPermission(nama, selectedCategory!, from, until);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showSnackBar("Pengajuan izin berhasil dikirim.", Icons.check_circle_outline_rounded);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showSnackBar("Gagal mengirim pengajuan izin: $e", Icons.error_outline_rounded);
    }
  }

  void _showLoaderDialog() => showLoaderDialog(context);

  void _showSnackBar(String message, IconData icon) {
    if (!mounted) return;
    showAppSnackBar(context, message, icon);
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Permission / Leave")),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s5,
            vertical: AppSpacing.s4,
          ),
          children: [
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              style: textTheme.bodyLarge,
              decoration: _decoration("Full Name", Icons.person_outline_rounded),
            ),
            const SizedBox(height: AppSpacing.s4),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              style: textTheme.bodyLarge,
              dropdownColor: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.field),
              icon: const Icon(Icons.arrow_drop_down_rounded),
              decoration: _decoration("Description", Icons.description_rounded),
              items: categories
                  .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                  .toList(),
              onChanged: (value) => setState(() => selectedCategory = value),
            ),
            const SizedBox(height: AppSpacing.s4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: fromController,
                    readOnly: true,
                    style: textTheme.bodyLarge,
                    onTap: () => _pickDate(fromController),
                    decoration: _decoration("From", Icons.calendar_today_rounded),
                  ),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: TextField(
                    controller: untilController,
                    readOnly: true,
                    style: textTheme.bodyLarge,
                    onTap: () => _pickDate(untilController),
                    decoration: _decoration("Until", Icons.event_rounded),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s8),
            SizedBox(
              height: AppSizes.buttonHeight,
              child: FilledButton.icon(
                onPressed: onSubmitPressed,
                icon: const Icon(Icons.send_rounded),
                label: const Text("Submit Permission"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
