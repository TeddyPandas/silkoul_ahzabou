# 📋 Prochaines Étapes de Développement

## ✅ Ce qui a été fait

### Backend & Architecture
- [x] Configuration Supabase
- [x] Schéma de base de données complet
- [x] Politiques RLS (sécurité)
- [x] Fonction RPC `register_and_subscribe` (atomicité)
- [x] Modèles de données (Profile, Campaign, Task, UserTask, etc.)
- [x] Services (Auth, Campaign, Task)
- [x] Providers (State Management)
- [x] Configuration thème (couleurs vert/blanc/mauve)
- [x] Écran de splash

## 🚀 Prochaines Étapes Prioritaires

### 1. Écrans d'Authentification (2-3 jours)

#### a. Écran de Login (`lib/screens/auth/login_screen.dart`)
```dart
Fonctionnalités :
- Formulaire email + mot de passe
- Bouton "Se connecter avec Google"
- Lien vers l'inscription
- Lien "Mot de passe oublié"
- Validation des champs
- Gestion des erreurs
```

#### b. Écran d'Inscription (`lib/screens/auth/signup_screen.dart`)
```dart
Fonctionnalités :
- Formulaire : nom, email, mot de passe, confirmation
- Validation (email valide, mot de passe fort)
- Création automatique du profil
- Redirection après inscription
```

#### c. Écran de Profil (`lib/screens/profile/profile_screen.dart`)
```dart
Fonctionnalités :
- Affichage des informations utilisateur
- Photo de profil (upload)
- Niveau et points
- Statistiques personnelles
- Modification du profil
- Sélection de la Silsila
- Bouton de déconnexion
```

### 2. Écrans de Campagnes (3-4 jours)

#### a. Écran d'Accueil / Dashboard (`lib/screens/home/home_screen.dart`)
```dart
Structure :
- Barre de navigation en bas (Home, Campaigns, Community, Profile)
- Carte utilisateur (nom, niveau, points)
- Section "Mes Campagnes" (cartes horizontales)
- Section "Daily Tracking" avec barre de progression
- Section "Features" (boutons vers autres fonctionnalités)
```

#### b. Liste des Campagnes (`lib/screens/campaigns/campaigns_list_screen.dart`)
```dart
Fonctionnalités :
- Onglets : "Publiques" / "Mes Campagnes" / "Créées par moi"
- Recherche par nom
- Filtres (catégorie, statut)
- Cartes de campagne avec :
  * Nom de la campagne
  * Créateur
  * Dates de début/fin
  * Progression globale
  * Bouton "S'abonner" ou "Voir détails"
```

#### c. Détails de Campagne (`lib/screens/campaigns/campaign_details_screen.dart`)
```dart
Fonctionnalités :
- Informations complètes de la campagne
- Liste des tâches avec progression
- Bouton "S'abonner" (si pas encore abonné)
- Participants (nombre)
- Statistiques de la campagne
```

#### d. Création de Campagne (`lib/screens/campaigns/create_campaign_screen.dart`)
```dart
Fonctionnalités :
- Formulaire multi-étapes :
  * Étape 1 : Info de base (nom, description, dates)
  * Étape 2 : Catégorie, visibilité
  * Étape 3 : Ajout de tâches (nom + quantité)
- Validation des champs
- Prévisualisation
- Bouton "Créer"
```

### 3. Dialogue de Souscription (1 jour)

#### Widget de Souscription (`lib/widgets/subscribe_dialog.dart`)
```dart
Fonctionnalités critiques :
- Afficher TOUTES les tâches de la campagne sélectionnée
- Pour chaque tâche :
  * Nom
  * Nombre restant disponible
  * Champ de saisie pour la quantité souhaitée
  * Checkbox de sélection
- Validation :
  * Au moins une tâche sélectionnée
  * Quantités valides (> 0 et <= restant)
- Bouton "Confirmer"
- Appel de la fonction RPC avec transaction atomique
```

### 4. Écran de Suivi des Tâches (2 jours)

#### a. Mes Tâches (`lib/screens/tasks/my_tasks_screen.dart`)
```dart
Fonctionnalités :
- Liste de toutes les tâches de l'utilisateur
- Groupées par campagne
- Pour chaque tâche :
  * Nom de la tâche
  * Progression (barre + chiffres)
  * Bouton "+" pour incrémenter
  * Checkbox "Marquer comme terminé"
- Statistiques globales en haut
```

#### b. Widget Tâche (`lib/widgets/task_card.dart`)
```dart
Composants :
- Icône ou image
- Nom de la tâche
- Barre de progression circulaire ou linéaire
- Texte : "X / Y complétés"
- Boutons d'action
```

### 5. Notifications (1-2 jours)

#### Service de Notifications (`lib/services/notification_service.dart`)
```dart
Fonctionnalités :
- Initialisation flutter_local_notifications
- Planification de rappels :
  * Début de campagne
  * Échéance proche (3 jours avant)
  * Rappel quotidien
- Notifications in-app
- Badges de nombre de tâches en attente
```

### 6. Widgets Réutilisables

#### Créer les widgets suivants :
- `lib/widgets/campaign_card.dart` - Carte de campagne
- `lib/widgets/task_list_item.dart` - Item de liste de tâche
- `lib/widgets/progress_bar.dart` - Barre de progression personnalisée
- `lib/widgets/loading_indicator.dart` - Indicateur de chargement
- `lib/widgets/error_message.dart` - Message d'erreur
- `lib/widgets/empty_state.dart` - État vide (pas de données)

## 🎨 Guidelines de Design

### Couleurs à utiliser
```dart
// Couleurs principales
AppColors.primary      // Vert principal
AppColors.secondary    // Mauve
AppColors.white        // Blanc
AppColors.gold         // Or (pour badges, niveaux)

// Gradients
AppColors.primaryGradient    // Pour les boutons importants
AppColors.secondaryGradient  // Pour les cartes
```

### Composants UI
- **Cards** : BorderRadius 16px, elevation 2
- **Boutons** : BorderRadius 12px, padding 16px
- **Espacement** : Multiples de 8px (8, 16, 24, 32)
- **Icônes** : Size 24px (standard), 32px (grandes)
- **Typographie** : Police Cairo (arabe/français)

### Animations
- Transitions : 300ms
- Micro-interactions sur les boutons
- Loading skeletons pour le chargement
- Pull-to-refresh sur les listes

## 📱 Ordre de Développement Recommandé

### Semaine 1
1. ✅ Setup initial (déjà fait)
2. Écrans d'authentification (Login, Signup)
3. Écran de profil basique

### Semaine 2
4. Écran d'accueil / Dashboard
5. Liste des campagnes publiques
6. Détails de campagne

### Semaine 3
7. Dialogue de souscription (CRITIQUE)
8. Création de campagne
9. Mes tâches avec progression

### Semaine 4
10. Notifications
11. Tests et corrections de bugs
12. Polish UI/UX

## 🧪 Tests à Implémenter

### Tests Unitaires
```dart
test/services/
  - auth_service_test.dart
  - campaign_service_test.dart
  - task_service_test.dart

test/providers/
  - auth_provider_test.dart
  - campaign_provider_test.dart
  - user_provider_test.dart
```

### Tests d'Intégration
```dart
integration_test/
  - authentication_flow_test.dart
  - campaign_creation_flow_test.dart
  - subscription_flow_test.dart
```

## 🔍 Points d'Attention Critiques

### 1. Dialogue de Souscription
⚠️ **TRÈS IMPORTANT** : Le dialogue de souscription doit :
- Afficher les tâches de la campagne sélectionnée UNIQUEMENT
- Mettre à jour le `remaining_number` atomiquement
- Gérer les race conditions (plusieurs utilisateurs)
- Valider côté client ET serveur

### 2. Progression des Tâches
- Permettre la mise à jour incrémentielle
- Permettre de marquer comme terminé (système d'honneur)
- Synchroniser avec le backend en temps réel

### 3. Gestion d'État
- Rafraîchir les données après chaque action
- Gérer le loading state correctement
- Afficher les erreurs de manière user-friendly

## 📚 Ressources Utiles

### Documentation
- [Flutter Documentation](https://docs.flutter.dev/)
- [Supabase Flutter Guide](https://supabase.com/docs/reference/dart/introduction)
- [Provider Package](https://pub.dev/packages/provider)

### Design Inspiration
- [Dribbble - Islamic Apps](https://dribbble.com/tags/islamic_app)
- [Material Design](https://m3.material.io/)
- Interface fournie par l'utilisateur (voir image)

### Packages Utiles
```yaml
# Ajout possible selon les besoins
- shimmer: ^3.0.0           # Loading skeletons
- flutter_staggered_grid_view: ^0.7.0  # Grilles avancées
- pull_to_refresh: ^2.0.0    # Pull to refresh
- lottie: ^3.0.0            # Animations Lottie
```

## 💡 Conseils de Développement

1. **Commencer simple** : Implémenter la version basique d'abord
2. **Tester fréquemment** : Tester après chaque fonctionnalité
3. **Commits réguliers** : Faire des commits atomiques
4. **Documentation** : Documenter le code complexe
5. **Responsive** : Penser à différentes tailles d'écran
6. **Accessibilité** : Labels pour les screen readers

## 🎯 Objectif Final

Une application Flutter complète, stable et agréable à utiliser qui permet aux disciples Tijani de pratiquer le Zikr collectivement de manière moderne et efficace.

---

**Bon développement ! 🚀**
