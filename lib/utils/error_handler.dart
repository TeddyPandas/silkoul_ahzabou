import 'package:flutter/foundation.dart';

class ErrorHandler {
  /// Nettoie les messages d'erreur pour l'affichage utilisateur.
  ///
  /// En mode DEBUG : Retourne l'erreur complète pour faciliter le débogage.
  /// En mode RELEASE : Retourne un message convivial et générique.
  static String sanitize(dynamic error) {
    // 1. En mode DEBUG, on affiche tout (sauf si on veut tester le comportement prod)
    if (kDebugMode) {
      return error.toString();
    }

    // 2. En mode RELEASE, on filtre
    String message = error.toString();

    // Enlever le préfixe "Exception: "
    if (message.startsWith("Exception: ")) {
      message = message.substring(11);
    }

    // Traductions courantes (AuthException Supabase)
    if (message.contains("Invalid login credentials")) {
      return "Email ou mot de passe incorrect.";
    }
    if (message.contains("Email not confirmed")) {
      return "Veuillez confirmer votre email avant de vous connecter.";
    }
    if (message.contains("User already registered")) {
      return "Cet email est déjà utilisé.";
    }
    if (message.contains("Password should be at least")) {
      return "Le mot de passe est trop court.";
    }
    if (message.contains("Network request failed") || message.contains("SocketException")) {
      return "Erreur de connexion internet.";
    }

    // --- Patterns spécifiques Campagnes ---
    if (message.contains('déjà abonné') || message.contains('already subscribed')) {
      return 'Vous êtes déjà abonné à cette campagne.';
    }
    if (message.contains('Code d\'accès requis') || message.contains('Access code required')) {
      return 'Un code d\'accès est requis pour accéder à cette campagne.';
    }
    if (message.contains('Code d\'accès invalide') || message.contains('Invalid access code') || message.contains('access code')) {
      return 'Le code d\'accès est invalide.';
    }
    if (message.contains('Quantité') || message.contains('quantity')) {
      return 'La quantité demandée n\'est plus disponible.';
    }
    if (message.contains('non authentifié') || message.contains('not authenticated')) {
      return 'Vous devez être connecté pour effectuer cette action.';
    }
    if (message.contains('404')) {
      return 'Ressource introuvable.';
    }
    
    // Message par défaut pour les autres erreurs en prod
    return "Une erreur inattendue est survenue. Veuillez réessayer.";
  }

  /// Log message safely (only in debug mode)
  static void log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }
}
