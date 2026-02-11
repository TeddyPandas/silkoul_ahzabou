import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:silkoul_ahzabou/screens/silsila/silsila_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_theme.dart';
import '../screens/tasks/my_tasks_screen.dart';
import '../screens/badges/badges_screen.dart';
import '../screens/wazifa/wazifa_map_screen.dart';

import '../screens/profile/profile_tab.dart';
import '../modules/teachings/screens/teachings_home_screen.dart';
import '../services/notification_service.dart';

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
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SilsilaScreen())),
                  ),
                  /* _buildMenuItem(
                    context,
                    icon: Icons.emoji_events_rounded,
                    title: 'The Badges',
                    subtitle: 'Coming soon',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const BadgesScreen())),
                  ), */
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

                  _buildDivider(),
                  _buildMenuItem(
                    context,
                    icon: Icons.person_rounded,
                    title: 'Mon Profil',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ProfileTab())),
                  ),
                  _buildDivider(),
                  // Social Media Icons Section
                  const Padding(
                    padding: EdgeInsets.only(left: 12, bottom: 8),
                    child: Text(
                      'Nous contacter',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSocialIconFA(
                          context,
                          FontAwesomeIcons.instagram,
                          'https://www.instagram.com/markazseyidtijani?igsh=MTY2cnQyYzJtaG8zNg==',
                          const Color(0xFFE4405F), // Instagram pink
                        ),
                        _buildSocialIconFA(
                          context,
                          FontAwesomeIcons.xTwitter,
                          'https://x.com/markaztijani',
                          Colors.black, // X black
                        ),
                        _buildSocialIconFA(
                          context,
                          FontAwesomeIcons.whatsapp,
                          'https://Wa.me/221781098017',
                          const Color(0xFF25D366), // WhatsApp green
                        ),
                        _buildSocialIcon(
                          context,
                          'assets/icons/website.png',
                          Icons.language_rounded,
                          'https://www.markaztijani.com',
                        ),
                      ],
                    ),
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
        color: AppColors.tealPrimary.withValues(alpha: 0.05),
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
                  color: AppColors.tealPrimary.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/app_logo_512.png',
              height: 48,
              width: 48,
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
                        style: const TextStyle(
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

  Widget _buildSocialIcon(
    BuildContext context,
    String assetPath,
    IconData fallbackIcon,
    String url,
  ) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.tealPrimary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          fallbackIcon,
          color: AppColors.tealPrimary,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildSocialIconFA(
    BuildContext context,
    IconData icon,
    String url,
    Color iconColor,
  ) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: FaIcon(
          icon,
          color: iconColor,
          size: 24,
        ),
      ),
    );
  }
}
