import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../utils/app_theme.dart';

class AdminSidebar extends StatelessWidget {
  final String currentRoute;
  final Function(String route) onNavigate;

  const AdminSidebar({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: const Color(0xFF1E1E1E), // Dark sidebar
      child: Column(
        children: [
          // Header
          Container(
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield, color: AppColors.tealPrimary, size: 28),
                const SizedBox(width: 8),
                Text(
                  "ADMIN",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildMenuItem(
                  "Tableau de bord",
                  Icons.dashboard_rounded,
                  '/admin',
                ),
                _buildSectionHeader("CONTENU"),
                _buildMenuItem(
                  "Auteurs",
                  Icons.person_outline_rounded,
                  '/admin/authors',
                ),
                _buildMenuItem(
                  "Podcasts (Séries)",
                  Icons.podcasts_rounded,
                  '/admin/shows',
                ),
                _buildMenuItem(
                  "Enseignements",
                  Icons.mic_none_rounded,
                  '/admin/teachings',
                ),
                _buildMenuItem("Podcasts", Icons.mic, "/admin/podcasts"),
                _buildMenuItem("Vidéos", Icons.video_library, "/admin/videos"),
                _buildMenuItem("Import YouTube", Icons.cloud_download, "/admin/media/import"),
                _buildSectionHeader("COMMUNAUTÉ"),
                _buildMenuItem(
                  "Wazifa Finder",
                  Icons.location_on_outlined,
                  '/admin/wazifa',
                ),
                 _buildMenuItem(
                  "Utilisateurs",
                  Icons.people_outline,
                  '/admin/users',
                ),
                 _buildSectionHeader("SYSTÈME"),
                _buildMenuItem(
                  "Paramètres",
                  Icons.settings_outlined,
                  '/admin/settings',
                ),
              ],
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              "v1.0.0",
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 24, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.grey[600],
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon, String route) {
    final bool isSelected = currentRoute == route;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.tealPrimary.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: () => onNavigate(route),
        leading: Icon(
          icon,
          color: isSelected ? AppColors.tealPrimary : Colors.grey[400],
          size: 22,
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        dense: true,
        horizontalTitleGap: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
