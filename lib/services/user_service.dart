import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserRole { student, teacher }

class AppUser {
  /// Id perangkat. Dipakai sebagai `uid` di Firestore (pemilik sesi, cek absen ganda).
  final String uid;
  final String name;
  final UserRole role;

  const AppUser({required this.uid, required this.name, required this.role});

  String get roleLabel => role == UserRole.teacher ? 'Teacher' : 'Student';
}

/// Profil lokal di HP, pengganti login sementara (tanpa Firebase Auth).
class UserService {
  UserService._();

  static const _keyDeviceId = 'device_id';
  static const _keyName = 'profile_name';
  static const _keyRole = 'profile_role';

  /// Profil yang sedang aktif; null = belum masuk.
  static final current = ValueNotifier<AppUser?>(null);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyName);
    final role = prefs.getString(_keyRole);
    if (name == null || role == null) return;
    current.value = AppUser(
      uid: await _deviceId(prefs),
      name: name,
      role: role == 'teacher' ? UserRole.teacher : UserRole.student,
    );
  }

  static Future<void> signIn({required String name, required UserRole role}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyRole, role == UserRole.teacher ? 'teacher' : 'student');
    current.value = AppUser(uid: await _deviceId(prefs), name: name, role: role);
  }

  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyName);
    await prefs.remove(_keyRole);
    current.value = null;
  }

  // Id tetap per perangkat, tidak ikut terhapus saat logout,
  // supaya satu HP hanya bisa absen sekali per sesi.
  static Future<String> _deviceId(SharedPreferences prefs) async {
    final existing = prefs.getString(_keyDeviceId);
    if (existing != null) return existing;
    final random = Random.secure();
    final id = List.generate(16, (_) => random.nextInt(16).toRadixString(16)).join();
    await prefs.setString(_keyDeviceId, id);
    return id;
  }
}
