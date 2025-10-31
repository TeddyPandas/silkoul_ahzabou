import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // Utiliser dotenv pour charger les variables d'environnement
  static final String supabaseUrl = dotenv.env['SUPABASE_URL']!;
  static final String supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']!;

  // Le reste de la configuration reste inchangé
  static const String profilesTable = 'profiles';
  static const String campaignsTable = 'campaigns';
  static const String tasksTable = 'tasks';
  static const String userCampaignsTable = 'user_campaigns';
  static const String userTasksTable = 'user_tasks';
  static const String silsilasTable = 'silsilas';
  
  // Configuration auth
  static const String redirectUrl = 'io.supabase.silkoul://login-callback/';
  
  // Configuration storage
  static const String avatarsBucket = 'avatars';
  static const String campaignImagesBucket = 'campaign_images';
}
