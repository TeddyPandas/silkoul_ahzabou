# ⚡ Guide de Démarrage Rapide

## 🎯 En 5 Minutes

### Étape 1 : Prérequis (2 min)

Assurez-vous d'avoir :
- ✅ Flutter SDK installé ([flutter.dev](https://flutter.dev))
- ✅ Un éditeur (VS Code ou Android Studio)
- ✅ Un compte Supabase ([supabase.com](https://supabase.com))

```bash
# Vérifier Flutter
flutter doctor
```

### Étape 2 : Configuration Supabase (2 min)

1. **Créer un projet Supabase**
   - Allez sur [supabase.com](https://supabase.com)
   - Créez un nouveau projet
   - Notez votre URL et Anon Key

2. **Exécuter les migrations**
   - Ouvrez l'**SQL Editor** dans Supabase
   - Copiez et exécutez `supabase/migrations/001_initial_schema.sql`
   - Copiez et exécutez `supabase/migrations/002_rls_policies.sql`

3. **Activer l'authentification**
   - Allez dans **Authentication** > **Providers**
   - Activez **Email**
   - (Optionnel) Configurez **Google OAuth**

### Étape 3 : Configuration du Projet (1 min)

```bash
# 1. Installer les dépendances
flutter pub get

# 2. Créer le fichier .env
cp .env.example .env

# 3. Éditer .env avec vos clés Supabase
# SUPABASE_URL=votre_url_ici
# SUPABASE_ANON_KEY=votre_key_ici
```

**OU** éditez directement `lib/config/supabase_config.dart` :

```dart
static const String supabaseUrl = 'https://votre-projet.supabase.co';
static const String supabaseAnonKey = 'votre-anon-key-ici';
```

### Étape 4 : Lancer l'Application

```bash
# Android/iOS
flutter run

# Web (pour tester rapidement)
flutter run -d chrome
```

## 🎉 Ça Marche !

Vous devriez voir :
1. ✅ Écran de splash avec logo
2. ✅ Écran de connexion
3. ✅ Possibilité de créer un compte

## 🧪 Test Rapide

### Créer un Utilisateur de Test

1. Cliquez sur "S'inscrire"
2. Remplissez les champs :
   - Nom : Omar Hassan
   - Email : test@example.com
   - Mot de passe : test1234
3. Créez le compte
4. Vous serez redirigé vers le dashboard !

## 📱 Fonctionnalités Actuelles

### ✅ Ce Qui Fonctionne Déjà

1. **Authentification**
   - Inscription par email
   - Connexion par email
   - Connexion Google (si configuré)
   - Déconnexion

2. **Dashboard**
   - Profil utilisateur (nom, niveau, points)
   - Liste des campagnes (vide au début)
   - Statistiques quotidiennes
   - Navigation en bas d'écran

3. **Backend**
   - Base de données fonctionnelle
   - API sécurisée
   - Politiques RLS actives

### 🚧 En Cours de Développement

1. **Campagnes**
   - Création de campagnes
   - Liste complète
   - Dialogue d'abonnement

2. **Tâches**
   - Suivi des tâches
   - Mise à jour de progression
   - Marquage comme terminé

## 🔥 Prochaines Étapes de Développement

### 1. Créer l'Écran de Liste des Campagnes

Fichier à créer : `lib/screens/campaigns/campaigns_list_screen.dart`

### 2. Créer le Dialogue d'Abonnement (PRIORITAIRE)

Fichier à créer : `lib/widgets/subscribe_dialog.dart`

C'est le **cœur** de l'application ! Ce dialogue permet aux utilisateurs de s'abonner aux campagnes.

### 3. Créer l'Écran de Suivi des Tâches

Fichier à créer : `lib/screens/tasks/my_tasks_screen.dart`

## 🐛 Problèmes Courants

### ❌ Erreur "Supabase URL not configured"

**Solution** : Vérifiez que vous avez bien configuré vos clés dans `lib/config/supabase_config.dart`

### ❌ Erreur "RLS policy violation"

**Solution** : Vérifiez que vous avez exécuté le fichier `002_rls_policies.sql`

### ❌ L'application ne se lance pas

```bash
# Nettoyer et reconstruire
flutter clean
flutter pub get
flutter run
```

## 📚 Documentation Complète

- **README.md** - Installation détaillée
- **PROJECT_SUMMARY.md** - Résumé du projet
- **NEXT_STEPS.md** - Feuille de route
- **PROJECT_STRUCTURE.md** - Structure du code

## 🎨 Personnalisation

### Changer les Couleurs

Éditez `lib/config/app_theme.dart` :

```dart
static const Color primary = Color(0xFF2D7A6E); // Votre vert
static const Color secondary = Color(0xFF9B7EBD); // Votre mauve
```

### Changer le Nom de l'Application

Éditez :
- `pubspec.yaml` → `name: votre_app`
- `lib/config/app_constants.dart` → `appName`

## 🤝 Besoin d'Aide ?

1. Consultez la documentation complète dans **README.md**
2. Lisez **NEXT_STEPS.md** pour la feuille de route
3. Vérifiez **PROJECT_SUMMARY.md** pour comprendre l'architecture

## 🎯 Ce Qu'il Faut Faire Maintenant

### Option 1 : Développement UI
Commencez par créer les écrans manquants (voir **NEXT_STEPS.md**)

### Option 2 : Test & Exploration
Explorez le code existant et testez l'authentification

### Option 3 : Lecture
Lisez la documentation pour bien comprendre l'architecture

---

**Bon développement ! 🚀**

*N'oubliez pas : Le fichier le plus important à créer ensuite est le dialogue d'abonnement (`subscribe_dialog.dart`) car c'est le cœur de l'application !*
