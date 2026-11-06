import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:attendance_app/services/user_service.dart';
import 'package:attendance_app/theme/app_tokens.dart';
import 'package:attendance_app/ui/widgets/feedback.dart';
import 'package:attendance_app/ui/widgets/status_badge.dart';

class AbsentScreen extends StatefulWidget {
  const AbsentScreen({super.key});

  @override
  State<AbsentScreen> createState() => _AbsentScreenState();
}

class _AbsentScreenState extends State<AbsentScreen> {
  static const List<String> categories = ["Sick", "Permission", "Others"];

  final nameController = TextEditingController(
    text: UserService.current.value?.name ?? '',
  );
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
      'uid': UserService.current.value?.uid,
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

  // Lama izin dalam hari, null bila tanggal belum lengkap atau tidak valid.
  int? get _dayCount {
    if (fromController.text.isEmpty || untilController.text.isEmpty) return null;
    final format = DateFormat('dd/MM/yyyy');
    final days = format.parse(untilController.text).difference(format.parse(fromController.text)).inDays;
    return days < 0 ? null : days + 1;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dayCount = _dayCount;

    return Scaffold(
      appBar: AppBar(title: const Text("Permission / Leave")),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s5,
            vertical: AppSpacing.s4,
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.s4),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_note_rounded, color: AppColors.onPrimaryContainer),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: Text(
                      "Tidak bisa hadir? Ajukan izin di sini, lalu pantau di Attendance History.",
                      style: textTheme.bodyMedium!.copyWith(color: AppColors.onPrimaryContainer),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s6),
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              style: textTheme.bodyLarge,
              decoration: _decoration("Full Name", Icons.person_outline_rounded),
            ),
            const SizedBox(height: AppSpacing.s6),
            Text("Description", style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.s3),
            Row(
              children: [
                for (var i = 0; i < categories.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: _CategoryTile(
                      label: categories[i],
                      selected: selectedCategory == categories[i],
                      onTap: () => setState(() => selectedCategory = categories[i]),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.s6),
            Row(
              children: [
                Expanded(child: Text("Date", style: textTheme.titleSmall)),
                if (dayCount != null)
                  Text(
                    dayCount == 1 ? "1 day" : "$dayCount days",
                    style: textTheme.labelMedium!.copyWith(color: AppColors.primary),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s3),
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

/// Pilihan jenis izin: ikon dan label status, garis tebal saat dipilih.
class _CategoryTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = statusStyleOf(label);
    final radius = BorderRadius.circular(AppRadius.card);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? style.container : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: style.base, shape: BoxShape.circle),
                  child: Icon(style.icon, size: 20, color: style.onBase),
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: selected ? style.onContainer : AppColors.textPrimary,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
