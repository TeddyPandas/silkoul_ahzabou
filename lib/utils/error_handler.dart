import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorHandler {
  /// Nettoie les messages d'erreur pour l'affichage utilisateur.
  ///
  /// En mode DEBUG : Retourne l'erreur complète pour faciliter le débogage.
  /// En mode RELEASE : Retourne un message convivial et générique.
  static String sanitize(dynamic error) {
    // 1. Log the full error internally
    log('❌ Error caught: $error');

    // 2. Specialized handling for PostgrestException (Supabase DB errors)
    if (error is PostgrestException) {
      log('📊 Database Error: ${error.message} (Code: ${error.code})');
      
      // Hide raw DB details even in debug if they contain sensitive schema info
      // But for better dev UX, we show more in debug
      if (!kDebugMode) {
        // Common Postgres error codes
        switch (error.code) {
          case '23503': // foreign_key_violation
            return "Cette opération ne peut pas être effectuée car l'élément est lié à d'autres données.";
          case '23505': // unique_violation
            return "Cet élément existe déjà.";
          case '42P01': // undefined_table (Security risk to show)
            return "Une erreur interne est survenue (Ressource indisponible).";
          case 'PGRST301': // Row level security violation
            return "Vous n'avez pas la permission d'effectuer cette action.";
          default:
            return "Une erreur de base de données est survenue. Veuillez réessayer.";
        }
      }
    }

    // 3. AuthException (Supabase)
    if (error is AuthException) {
      String msg = error.message;
      if (msg.contains("Invalid login credentials")) return "Email ou mot de passe incorrect.";
      if (msg.contains("Email not confirmed")) return "Veuillez confirmer votre email.";
      if (msg.contains("User already registered")) return "Cet email est déjà utilisé.";
      return msg; // Auth messages are usually safe
    }

    // 4. Fallback for generic strings/exceptions
    String message = error.toString();

    // En mode RELEASE, on filtre les termes techniques
    if (!kDebugMode) {
      if (message.contains("PostgresException") || 
          message.contains("SocketException") || 
          message.contains("XMLHttpRequest") ||
          message.contains("HandshakeException")) {
        return "Problème de connexion au serveur. Veuillez vérifier votre internet.";
      }
      
      // Generic fallback for release
      return "Une erreur inattendue est survenue. L'équipe technique a été notifiée.";
    }

    // mode DEBUG : Retourne l'erreur complète
    if (message.startsWith("Exception: ")) {
      message = message.substring(11);
    }
    return message;
  }

  /// Log message safely (only in debug mode)
  static void log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }
}
