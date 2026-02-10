import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../models/profile.dart';
import '../../../../providers/auth_provider.dart';
import 'admin_scaffold.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  List<Profile> _users = [];
  List<Profile> _filteredUsers = []; // For search
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      // Use RPC to get secure data (including emails)
      final response = await _client.rpc('get_admin_users');
      
      final users = (response as List).map((json) => Profile.fromRpc(json)).toList();
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red));
      }
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users.where((user) {
          final name = user.displayName.toLowerCase();
          final email = user.email.toLowerCase();
          final search = query.toLowerCase();
          return name.contains(search) || email.contains(search);
        }).toList();
      }
    });
  }

  Future<void> _updateUserRole(Profile user, String newRole) async {
    try {
      // Optimistic update
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
         setState(() {
           final updatedUser = user.copyWith(role: newRole);
           _users[index] = updatedUser;
           // Re-filter if needed, simple approach:
           _filterUsers(_searchQuery); 
         });
      }

      await _client.from('profiles').update({'role': newRole}).eq('id', user.id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Rôle de ${user.displayName} mis à jour en $newRole")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur maj rôle: $e")));
      _fetchUsers(); // Revert on error
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isSuperAdmin = authProvider.isSuperAdmin;

    return AdminScaffold(
      currentRoute: '/admin/users',
      title: 'Gestion des Utilisateurs',
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filterUsers,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Rechercher un utilisateur...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filteredUsers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final isMe = user.id == authProvider.user?.id;
                      
                      return Card(
                        color: const Color(0xFF1E1E1E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withOpacity(0.1))),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                            child: user.avatarUrl == null ? Text(user.displayName[0].toUpperCase()) : null,
                          ),
                          title: Text(
                            "${user.displayName} ${isMe ? '(Moi)' : ''}", 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                          ),
                          subtitle: Text(user.email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          trailing: isSuperAdmin 
                            ? DropdownButton<String>(
                                value: user.role,
                                dropdownColor: const Color(0xFF2C2C2C),
                                style: const TextStyle(color: Colors.white),
                                underline: Container(),
                                onChanged: isMe ? null : (newRole) { // Cannot demote self
                                  if (newRole != null) _updateUserRole(user, newRole);
                                },
                                items: const [
                                  DropdownMenuItem(value: 'USER', child: Text("Utilisateur")),
                                  DropdownMenuItem(value: 'ADMIN', child: Text("Admin")),
                                  DropdownMenuItem(value: 'SUPER_ADMIN', child: Text("Super Admin")),
                                ],
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getRoleColor(user.role).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _getRoleColor(user.role).withOpacity(0.5))
                                ),
                                child: Text(user.role, style: TextStyle(color: _getRoleColor(user.role), fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'SUPER_ADMIN': return Colors.purpleAccent;
      case 'ADMIN': return Colors.orangeAccent;
      case 'USER': return Colors.teal;
      default: return Colors.grey;
    }
  }
}
