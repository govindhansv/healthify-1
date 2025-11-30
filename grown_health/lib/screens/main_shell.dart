import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home/home_screen.dart';
import 'nutrition/nutrition_screen.dart';
import 'mind/mind_screen.dart';
import 'help/help_screen.dart';
import 'workout/workouts_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(), // index 0: Home
    WorkoutsScreen(), // index 1: Body (Workouts page)
    NutritionScreen(), // index 2: Nutrition
    HelpScreen(), // index 3: Help
    MindScreen(), // index 4: Mind
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: _pages),
      ),
      bottomNavigationBar: _SharedBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

class _SharedBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _SharedBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFAA3D50),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _BottomNavItem(
                label: 'Home',
                index: 0,
                currentIndex: currentIndex,
                onTap: onTap,
                icon: Icons.home_rounded,
              ),
            ),
            Expanded(
              child: _BottomNavItem(
                label: 'Body',
                index: 1,
                currentIndex: currentIndex,
                onTap: onTap,
                icon: Icons.person_outline_rounded,
              ),
            ),
            Expanded(
              child: _BottomNavItem(
                label: 'Nutrition',
                index: 2,
                currentIndex: currentIndex,
                onTap: onTap,
                icon: Icons.rice_bowl_outlined,
              ),
            ),
            Expanded(
              child: _BottomNavItem(
                label: 'Help',
                index: 3,
                currentIndex: currentIndex,
                onTap: onTap,
                icon: Icons.account_circle_outlined,
              ),
            ),
            Expanded(
              child: _BottomNavItem(
                label: 'Mind',
                index: 4,
                currentIndex: currentIndex,
                onTap: onTap,
                icon: Icons.emoji_emotions_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final IconData icon;

  const _BottomNavItem({
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = index == currentIndex;

    if (isSelected) {
      // White pill for selected tab
      return GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: const Color(0xFFAA3D50)),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFAA3D50),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Unselected state: simple icon + label
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          Icon(icon, size: 20, color: const Color(0xFFF6C5CF)),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              textStyle: const TextStyle(
                fontSize: 11,
                color: Color(0xFFF6C5CF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
