import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/app_constants.dart';
import '../../../../config/app_theme.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/notification_service.dart';
import 'admin_scaffold.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _maintenanceMode = false;
  bool _isTestingNotification = false;

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Paramètres',
      currentRoute: '/admin/settings',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('INFORMATIONS GÉNÉRALES'),
            const SizedBox(height: 16),
            _buildInfoCard(),
            const SizedBox(height: 32),
            _buildSectionHeader('LIMITES SYSTÈME (LECTURE SEULE)'),
            const SizedBox(height: 16),
            _buildLimitsCard(),
            const SizedBox(height: 32),
            _buildSectionHeader('OUTILS & ADMINISTRATION'),
            const SizedBox(height: 16),
            _buildToolsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: Colors.grey[400],
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildListTile(
            icon: Icons.info_outline,
            title: 'Nom de l\'application',
            subtitle: AppConstants.appName,
          ),
          _buildDivider(),
          _buildListTile(
            icon: Icons.verified_outlined,
            title: 'Version',
            subtitle: AppConstants.appVersion,
          ),
          _buildDivider(),
          _buildListTile(
            icon: Icons.build_circle_outlined,
            title: 'Build Number',
            subtitle: '100 (Production)',
          ),
        ],
      ),
    );
  }

  Widget _buildLimitsCard() {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildListTile(
            icon: Icons.task_alt,
            title: 'Max Tâches / Campagne',
            subtitle: '${AppConstants.maxTasksPerCampaign}',
          ),
          _buildDivider(),
          _buildListTile(
            icon: Icons.timer_outlined,
            title: 'Durée Max Campagne',
            subtitle: '${AppConstants.maxCampaignDurationDays} jours',
          ),
          _buildDivider(),
          _buildListTile(
            icon: Icons.description_outlined,
            title: 'Longueur Max Description',
            subtitle: '${AppConstants.maxDescriptionLength} caractères',
          ),
        ],
      ),
    );
  }

  Widget _buildToolsCard() {
    final authProvider = Provider.of<AuthProvider>(context);

    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Notification Test
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined,
                color: AppColors.tealPrimary),
            title: Text(
              'Tester Notification',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            subtitle: Text(
              'Envoyer une notification de test sur cet appareil',
              style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
            ),
            trailing: _isTestingNotification
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : OutlinedButton(
                    onPressed: () async {
                      setState(() => _isTestingNotification = true);
                      await NotificationService().showInstantNotification();
                      setState(() => _isTestingNotification = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Notification envoyée !')),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.tealPrimary,
                      side: const BorderSide(color: AppColors.tealPrimary),
                    ),
                    child: const Text('Tester'),
                  ),
          ),
          _buildDivider(),

          // Maintenance Mode
          SwitchListTile(
            secondary: const Icon(Icons.construction, color: Colors.orange),
            title: Text(
              'Mode Maintenance',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            subtitle: Text(
              'Empêcher l\'accès aux utilisateurs (Simulation)',
              style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
            ),
            value: _maintenanceMode,
            activeColor: Colors.orange,
            onChanged: (value) {
              setState(() => _maintenanceMode = value);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Mode maintenance mis à jour (Simulation)')),
              );
            },
          ),
          _buildDivider(),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: Text(
              'Déconnexion',
              style: GoogleFonts.poppins(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () async {
              // Confirm dialog
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1E1E1E),
                  title: const Text('Déconnexion',
                      style: TextStyle(color: Colors.white)),
                  content: const Text(
                      'Êtes-vous sûr de vouloir vous déconnecter ?',
                      style: TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent),
                      child: const Text('Déconnecter'),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await authProvider.signOut();
                if (context.mounted) {
                   Navigator.of(context).pushReplacementNamed('/login');
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.tealPrimary),
      title: Text(
        title,
        style: GoogleFonts.poppins(color: Colors.white),
      ),
      trailing: Text(
        subtitle,
        style:
            GoogleFonts.poppins(color: Colors.grey[400], fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.white.withValues(alpha: 0.05),
      indent: 16,
      endIndent: 16,
    );
  }
}
