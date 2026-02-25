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
import '../modules/quizzes/screens/quiz_list_screen.dart';
import '../services/notification_service.dart';
import '../modules/calendar/screens/calendar_screen.dart';
import '../l10n/generated/app_localizations.dart';
import '../providers/locale_provider.dart';
import 'package:provider/provider.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary, // Teal
              AppColors.primaryDark, // Darker Teal/Green
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.calendar_month_rounded,
                      title: AppLocalizations.of(context)!.courseCalendar,
                      onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const CalendarScreen())),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.checklist_rounded,
                      title: AppLocalizations.of(context)!.myTasks,
                      onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const MyTasksScreen())),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.link_rounded,
                      title: AppLocalizations.of(context)!.theSilsila,
                      onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const SilsilaScreen())),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.location_on_rounded,
                      title: AppLocalizations.of(context)!.findWazifa,
                      onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const WazifaMapScreen())),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.play_lesson_rounded,
                      title: AppLocalizations.of(context)!.teachings,
                      onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const TeachingsHomeScreen())),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.quiz_rounded,
                      title: AppLocalizations.of(context)!.quizzes,
                      onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const QuizListScreen())),
                    ),

                    _buildMenuItem(
                      context,
                      icon: Icons.person_rounded,
                      title: AppLocalizations.of(context)!.profile,
                      onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const ProfileTab())),
                    ),
                  ],
                ),
              ),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.gold.withOpacity(0.3), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3), // Gold border width
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 2),
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/images/app_logo_512.png',
                height: 48,
                width: 48,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ahzab',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Playfair Display', // Elegant serif font if available, or fallback
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Votre compagnon spirituel',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
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
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            children: [
              Icon(icon, color: AppColors.gold, size: 24),
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
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.3), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.gold.withOpacity(0.3), width: 1),
        ),
      ),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.language,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          Consumer<LocaleProvider>(
            builder: (context, localeProvider, child) {
              return InkWell(
                onTap: () => localeProvider.toggleLocale(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        localeProvider.currentFlag,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        localeProvider.currentLanguageName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.sync, color: Colors.white70, size: 14),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Nous contacter',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialIconFA(
                context,
                FontAwesomeIcons.instagram,
                'https://www.instagram.com/markazseyidtijani?igsh=MTY2cnQyYzJtaG8zNg==',
                Colors.white,
              ),
              _buildSocialIconFA(
                context,
                FontAwesomeIcons.xTwitter,
                'https://x.com/markaztijani',
                Colors.white,
              ),
              _buildSocialIconFA(
                context,
                FontAwesomeIcons.whatsapp,
                'https://Wa.me/221781098017',
                Colors.white,
              ),
              _buildSocialIcon(
                context,
                'assets/icons/website.png',
                Icons.language_rounded,
                'https://www.markaztijani.com',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Version 1.0.0',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
        ],
      ),
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(
          fallbackIcon,
          color: Colors.white,
          size: 20,
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: FaIcon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
    );
  }
}
