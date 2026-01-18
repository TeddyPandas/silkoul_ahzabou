import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../utils/app_theme.dart';
import 'admin_scaffold.dart';

class AdminMediaImportScreen extends StatefulWidget {
  const AdminMediaImportScreen({super.key});

  @override
  State<AdminMediaImportScreen> createState() => _AdminMediaImportScreenState();
}

class _AdminMediaImportScreenState extends State<AdminMediaImportScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String _logs = "";

  Future<void> _syncMedia() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _logs = "⏳ Démarrage de la synchronisation...\n";
    });

    try {
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:3000/api';
      final url = Uri.parse('$baseUrl/media/sync');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'channelQuery': query}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['data'];
        final count = result['count'];
        final channel = result['channel'];
        
        setState(() {
          _logs += "✅ SUCCÈS !\n";
          _logs += "Chaîne : $channel\n";
          _logs += "Vidéos importées/mises à jour : $count\n";
          if (result['errors'] != null && (result['errors'] as List).isNotEmpty) {
             _logs += "⚠️ Erreurs sur ${(result['errors'] as List).length} vidéos.\n";
          }
        });
      } else {
        setState(() {
          _logs += "❌ ERREUR HTTP ${response.statusCode}\n";
          _logs += "${response.body}\n";
        });
      }
    } catch (e) {
      setState(() {
        _logs += "❌ ERREUR CONNECTION : $e\n";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentRoute: '/admin/media/import',
      title: 'Import YouTube',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Importer une Chaîne YouTube",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Collez le lien (ex: youtube.com/@chaine) ou le nom pour importer ses 50 dernières vidéos.",
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Lien ou Nom de la chaîne",
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.tealPrimary)),
                      prefixIcon: Icon(Icons.link, color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _syncMedia,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tealPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                    ),
                    icon: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.cloud_sync, color: Colors.white),
                    label: Text(
                      _isLoading ? "Synchronisation..." : "Lancer l'Importation",
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Journal d'exécution",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _logs.isEmpty ? "En attente..." : _logs,
                        style: const TextStyle(
                          color: Colors.greenAccent, 
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
