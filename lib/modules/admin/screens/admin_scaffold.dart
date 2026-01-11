import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../utils/app_theme.dart';
import '../widgets/admin_sidebar.dart';

class AdminScaffold extends StatelessWidget {
  final Widget body;
  final String currentRoute;
  final String title;
  final List<Widget>? actions;

  const AdminScaffold({
    super.key,
    required this.body,
    required this.currentRoute,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Protection basique : Redirection si non admin
    if (!authProvider.isLoading && authProvider.isAuthenticated && !authProvider.isAdmin) {
       // Wait for build to complete before redirecting
       WidgetsBinding.instance.addPostFrameCallback((_) {
         Navigator.of(context).pushReplacementNamed('/');
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Accès non autorisé aux administrateurs uniquement.")),
         );
       });
       return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Only show sidebar on desktop (simplified for now)
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Very dark background
      body: Row(
        children: [
          if (isDesktop)
            AdminSidebar(
              currentRoute: currentRoute,
              onNavigate: (route) {
                Navigator.of(context).pushReplacementNamed(route);
              },
            ),
          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
                  ),
                  child: Row(
                    children: [
                       if (!isDesktop) ...[
                         IconButton(
                           icon: const Icon(Icons.menu, color: Colors.white),
                           onPressed: () {
                             // Open drawer
                           },
                         ),
                         const SizedBox(width: 16),
                       ],
                      Text(
                        title.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const Spacer(),
                      if (actions != null) ...actions!,
                    ],
                  ),
                ),
                
                // Main Content
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: !isDesktop 
        ? Drawer(
            child: AdminSidebar(
              currentRoute: currentRoute,
              onNavigate: (route) {
                Navigator.pop(context); // Close drawer
                Navigator.of(context).pushReplacementNamed(route);
              },
            ),
          )
        : null,
    );
  }
}
