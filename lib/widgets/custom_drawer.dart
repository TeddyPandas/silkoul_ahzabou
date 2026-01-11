import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../screens/tasks/my_tasks_screen.dart';
import '../screens/silsila/silsila_screen.dart';
import '../screens/badges/badges_screen.dart';
import '../screens/wazifa/wazifa_map_screen.dart';
import '../screens/calculators/abjad_calculator_screen.dart';
import '../screens/profile/profile_tab.dart';
import '../modules/teachings/screens/teachings_home_screen.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.checklist_rounded,
                    title: 'My tasks',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MyTasksScreen())),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.link_rounded,
                    title: 'The Silsila',
                    subtitle: 'Coming soon',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SilsilaScreen())),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.emoji_events_rounded,
                    title: 'The Badges',
                    subtitle: 'Coming soon',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const BadgesScreen())),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.location_on_rounded,
                    title: 'The Wazifa Finder',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const WazifaMapScreen())),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.play_lesson_rounded,
                    title: 'Enseignements',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TeachingsHomeScreen())),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.calculate_rounded,
                    title: 'Abjad Calculator',
                    subtitle: 'Coming soon',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AbjadCalculatorScreen())),
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    context,
                    icon: Icons.person_rounded,
                    title: 'Mon Profil',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ProfileTab())),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        bottom: 24,
        left: 24,
        right: 24,
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.tealPrimary.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.tealPrimary.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.mosque_rounded,
              color: AppColors.tealPrimary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ahzab',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Votre compagnon spirituel',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context); // Close drawer first
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey[700], size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.tealPrimary,
                            fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[300]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(color: Colors.grey[100], thickness: 1),
    );
  }
}
