# 🕌 Silkoul Ahzabou Tidiani




Application mobile Flutter pour les disciples de la Tariqa Tijaniyya permettant la pratique collective du Zikr à travers des campagnes partagées.

## 📱 Aperçu du Projet

Silkoul Ahzabou est une application qui permet aux utilisateurs de :
- ✨ Créer des campagnes de Zikr avec des objectifs quantifiés
- 🤝 S'abonner aux campagnes et choisir leur engagement personnel
- 📊 Suivre leur progression et marquer les tâches comme terminées
- 🎯 Gagner des points et monter de niveau
- 🌟 Participer à une communauté spirituelle collective

## 🎨 Design

Interface utilisateur avec palette **Vert, Blanc & Mauve** créant une ambiance de tranquillité et de richesse spirituelle.

## 🛠️ Stack Technique

- **Frontend**: Flutter (iOS/Android)
- **Backend**: Supabase (PostgreSQL + Auth)
- **State Management**: Provider
- **Base de données**: PostgreSQL via Supabase
- **Authentification**: Supabase Auth (Email, Google, Téléphone)

## 📋 Prérequis

Avant de commencer, assurez-vous d'avoir installé :

- **Flutter SDK** >= 3.0.0
  - [Installation Flutter](https://docs.flutter.dev/get-started/install)
- **Android Studio** ou **Xcode** (selon votre plateforme)
- **Git**
- Un compte **Supabase** (gratuit)
  - [Créer un compte Supabase](https://supabase.com)

## 🚀 Installation

### 1. Cloner le projet

```bash
git clone <votre-repo>
cd silkoul_ahzabou
```

### 2. Installer les dépendances Flutter

```bash
flutter pub get
```

### 3. Configuration Supabase

#### a. Créer un projet Supabase

1. Allez sur [supabase.com](https://supabase.com)
2. Créez un nouveau projet
3. Notez votre **URL du projet** et **Anon Key**

#### b. Exécuter les migrations SQL

1. Dans votre projet Supabase, allez dans **SQL Editor**
2. Exécutez le fichier `supabase/migrations/001_initial_schema.sql`
3. Exécutez le fichier `supabase/migrations/002_rls_policies.sql`

#### c. Configurer l'authentification

Dans votre projet Supabase :
1. Allez dans **Authentication** > **Providers**
2. Activez **Email** et **Google** (optionnel: Phone)
3. Pour Google OAuth :
   - Suivez [ce guide](https://supabase.com/docs/guides/auth/social-login/auth-google)
   - Configurez les redirect URLs

### 4. Configuration de l'application

Créez un fichier `.env` à la racine du projet :

```bash
cp .env.example .env
```

Éditez `.env` avec vos clés Supabase :

```env
SUPABASE_URL=https://votre-projet.supabase.co
SUPABASE_ANON_KEY=votre-anon-key-ici
```

### 5. Mettre à jour la configuration

Éditez `lib/config/supabase_config.dart` :

```dart
static const String supabaseUrl = 'https://votre-projet.supabase.co';
static const String supabaseAnonKey = 'votre-anon-key-ici';
```

## ▶️ Lancer l'application

### Mode développement

```bash
# Android
flutter run

# iOS (sur macOS)
flutter run -d ios

# Web (pour tester)
flutter run -d chrome
```

### Build de production

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 📁 Structure du Projet

```
silkoul_ahzabou/
├── lib/
│   ├── config/              # Configuration (thème, constantes, supabase)
│   ├── models/              # Modèles de données
│   ├── providers/           # State management (Provider)
│   ├── services/            # Services API et logique métier
│   ├── screens/             # Écrans de l'application
│   ├── widgets/             # Widgets réutilisables
│   └── main.dart           # Point d'entrée
├── supabase/
│   └── migrations/         # Scripts SQL pour la base de données
├── assets/                 # Images, icônes, fonts
└── pubspec.yaml           # Dépendances Flutter
```

## 🔑 Fonctionnalités Principales (MVP)

### ✅ Phase 1 (Implémentée)

- [x] Authentification (Email, Google)
- [x] Gestion des profils utilisateur
- [x] Création de campagnes avec tâches
- [x] Découverte des campagnes publiques
- [x] Abonnement atomique aux campagnes
- [x] Suivi des tâches personnelles
- [x] Système de progression et complétion
- [x] Système de points et niveaux

### 🔜 Phase 2 (À venir)

- [ ] Écrans d'interface utilisateur complets
- [ ] Recherche et filtres de campagnes
- [ ] Notifications et rappels
- [ ] Dashboard avec statistiques
- [ ] Géolocalisation (Wazifa Places)
- [ ] Gestion des événements
- [ ] Mode hors ligne

### 🌟 Phase 3 (Future)

- [ ] Fonctionnalités sociales
- [ ] Classements
- [ ] Partage sur réseaux sociaux
- [ ] Support multilingue

## 📊 Modèle de Données

### Tables Principales

1. **profiles** - Profils utilisateurs
2. **campaigns** - Campagnes de Zikr
3. **tasks** - Tâches dans les campagnes
4. **user_campaigns** - Souscriptions utilisateurs
5. **user_tasks** - Engagement et progression
6. **silsilas** - Généalogie spirituelle

Voir `supabase/migrations/` pour les schémas complets.

## 🔒 Sécurité

- **Row Level Security (RLS)** activé sur toutes les tables
- Opérations sensibles via fonctions RPC sécurisées
- Atomicité garantie pour les abonnements
- Validation des données côté serveur

## 🧪 Tests

```bash
# Tests unitaires
flutter test

# Tests d'intégration
flutter test integration_test/
```

## 📱 Compatibilité

- **iOS**: 12.0+
- **Android**: API 21+ (Android 5.0)
- **Web**: Navigateurs modernes

## 🎯 Flux d'Utilisation Principal

1. **Créer une campagne**
   - Nom, dates, description
   - Ajouter des tâches avec quantités

2. **Découvrir des campagnes**
   - Parcourir les campagnes publiques
   - Filtrer par catégorie

3. **S'abonner**
   - Voir les tâches de la campagne
   - Choisir sa quantité pour chaque tâche
   - Validation atomique

4. **Suivre sa progression**
   - Voir ses tâches dans le tableau de bord
   - Mettre à jour incrémentalement
   - Marquer comme complété

## 🤝 Contribution

Les contributions sont les bienvenues !

1. Fork le projet
2. Créez une branche (`git checkout -b feature/AmazingFeature`)
3. Commit vos changements (`git commit -m 'Add AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrez une Pull Request

## 📄 Licence

Ce projet est sous licence MIT - voir le fichier LICENSE pour plus de détails.

## 📞 Support

Pour toute question ou problème :
- Créez une issue sur GitHub
- Contactez l'équipe de développement

## 🙏 Remerciements

- Communauté Tijaniyya
- Contributeurs du projet
- Supabase pour l'infrastructure backend

---

**Fait avec ❤️ pour la communauté Tijaniyya**
