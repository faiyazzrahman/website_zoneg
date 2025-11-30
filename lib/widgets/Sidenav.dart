import 'dart:ui';
import 'package:flutter/material.dart';

class SideNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const SideNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A2980).withOpacity(0.85),
            const Color(0xFF26D0CE).withOpacity(0.35),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(context, Icons.dashboard_rounded, 'Dashboard', 0, '/dashboard'),
              _buildNavItem(context, Icons.map_rounded, 'Map', 1, '/map'),
              _buildNavItem(context, Icons.add_circle_outline_rounded, 'Post', 2, '/post'),
              _buildNavItem(context, Icons.inbox_rounded, 'Inbox', 3, '/inbox'),
              _buildNavItem(context, Icons.settings_rounded, 'Settings', 4, '/settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, IconData icon, String label, int index, String route) {
    final bool isSelected = currentIndex == index;

    return InkWell(
      onTap: () {
        onTabSelected(index);
        Navigator.pushReplacementNamed(context, route);
      },
      child: Container(
        color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white70,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
