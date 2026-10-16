import 'package:flutter/material.dart';
import 'package:attendance_app/services/user_service.dart';
import 'package:attendance_app/ui/profile/profile_screen.dart';
import 'package:attendance_app/ui/teacher/teacher_home_screen.dart';

/// Kerangka layar guru: bottom navigation Sessions dan Profile.
class TeacherShell extends StatefulWidget {
  final AppUser user;

  const TeacherShell({super.key, required this.user});

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  int currentIndex = 0;

  static const _titles = ["Sessions", "Profile"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[currentIndex])),
      body: SafeArea(
        child: IndexedStack(
          index: currentIndex,
          children: [
            TeacherHomeView(user: widget.user),
            ProfileView(user: widget.user),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => setState(() => currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note_rounded),
            label: "Sessions",
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
