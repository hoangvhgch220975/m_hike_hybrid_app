import 'package:flutter/material.dart';
import '../feed/feed_view.dart';
import '../plan/plan_view.dart';
import '../remarkable/remarkable_view.dart';
import '../settings/settings_view.dart';

// This is a StatefulWidget because it needs to manage the state of the current tab
class MainNavbar extends StatefulWidget {
  const MainNavbar({super.key});

  @override
  State<MainNavbar> createState() => _MainNavbarState();
}

class _MainNavbarState extends State<MainNavbar> {
  int _currentIndex = 0; // State: Index of the current tab

  // List of screens corresponding to the tabs
  final List<Widget> _screens = [
    const FeedView(), // Feed = isComplete == true
    const PlanView(), // Plan = isComplete == false
    const RemarkableView(), // Remarkable = isRemarkable == true
    const SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // Display the screen corresponding to the current index with animation
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: _screens[_currentIndex],
      ),

      // Feature 3: Modern BottomNavigationBar with Light Theme
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(icon: Icons.terrain_rounded, label: 'Feed', index: 0),
                _buildNavItem(icon: Icons.map_rounded, label: 'Plan', index: 1),
                _buildNavItem(icon: Icons.star_rounded, label: 'Remarkable', index: 2),
                _buildNavItem(icon: Icons.settings_rounded, label: 'Settings', index: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Custom nav item with smooth animation
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    Color? color,
  }) {
    final isSelected = _currentIndex == index;
    final theme = Theme.of(context);
    final selColor = color ?? theme.colorScheme.primary;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? selColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Icon(
                icon,
                size: isSelected ? 28 : 24,
                color: isSelected ? selColor : (theme.iconTheme.color ?? const Color(0xFF9CA3AF)).withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSelected ? 12 : 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? selColor : (theme.textTheme.bodyMedium?.color ?? const Color(0xFF9CA3AF)).withOpacity(0.9),
                fontFamily: 'PlusJakartaSans',
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
