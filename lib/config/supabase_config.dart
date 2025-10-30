class SupabaseConfig {
  // À remplacer par vos vraies clés Supabase
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
  
  // Configuration des tables
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
