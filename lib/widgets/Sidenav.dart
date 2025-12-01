import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:zoeguard_web/pages/dashboard_page.dart';
import 'package:zoeguard_web/pages/inbox_page.dart';
import 'package:zoeguard_web/pages/login_page.dart';
import 'package:zoeguard_web/pages/map_page.dart';
import 'package:zoeguard_web/pages/postcrime_page.dart';
import 'package:zoeguard_web/pages/settings_page.dart';

class SideNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const SideNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  // ----------------------- LOGOUT BUTTON -----------------------
  Widget _buildLogoutItem(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              Icon(Icons.logout_rounded, color: Colors.redAccent, size: 28),
              const SizedBox(height: 6),
              const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------- MAIN BUILD -----------------------
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.only(top: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(0),
        gradient: LinearGradient(
          colors: [
const Color(0xFF1A2980).withOpacity(0.85), const Color.fromARGB(255, 18, 80, 79).withOpacity(0.35),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 25,
            offset: const Offset(8, 0),
          )
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  _buildNavItem(context, Icons.dashboard_rounded, 'Dashboard', 0, '/dashboard'),
                  _buildNavItem(context, Icons.map_rounded, 'Map', 1, '/map'),
                  _buildNavItem(context, Icons.add_circle_outline_rounded, 'Post', 2, '/post'),
                  _buildNavItem(context, Icons.inbox_rounded, 'Inbox', 3, '/inbox'),
                  _buildNavItem(context, Icons.settings_rounded, 'Settings', 4, '/settings'),
                ],
              ),

              _buildLogoutItem(context),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------- EACH ITEM -----------------------
  Widget _buildNavItem(
      BuildContext context, IconData icon, String label, int index, String route) {
    
    final bool isSelected = currentIndex == index;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: GestureDetector(
          onTap: () {
            onTabSelected(index);
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => _getPage(route),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          },
          child: AnimatedScale(
            duration: const Duration(milliseconds: 250),
            scale: isSelected ? 1.12 : 1.0,
            curve: Curves.easeOutBack,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      icon,
                      size: 30,
                      color: isSelected ? Colors.white : Colors.white70,
                      shadows: isSelected
                          ? [
                              Shadow(
                                blurRadius: 15,
                                color: Colors.blueAccent.shade100,
                              )
                            ]
                          : [],
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: isSelected ? 12 : 11,
                    ),
                    child: Text(label),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------- PAGE ROUTER -----------------------
  Widget _getPage(String route) {
    switch (route) {
      case '/dashboard': return const DashboardPage();
      case '/map': return const MapPage();
      case '/post': return const PostCrimePage();
      case '/inbox': return const InboxPage();
      case '/settings': return const SettingsPage();
      case '/login': return const LoginPage();
      default: return const DashboardPage();
    }
  }
}
