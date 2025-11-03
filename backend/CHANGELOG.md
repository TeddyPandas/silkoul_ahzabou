# Changelog

Tous les changements notables de ce projet seront documentés dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/lang/fr/).

## [Non publié]

### À venir
- Système de notifications push
- Intégration de paiement
- Fonctionnalités de géolocalisation
- Événements et Hadara
- Statistiques avancées

## [1.0.0] - 2025-01-29

### ✨ Ajouté

#### Authentification
- Système d'authentification complet avec Supabase Auth
- Support pour Email/Mot de passe
- Support pour Gmail OAuth
- Gestion des sessions JWT
- Refresh tokens
- Déconnexion

#### Gestion des Profils
- Création et mise à jour de profils utilisateurs
- Support pour les informations personnelles (nom, téléphone, adresse, date de naissance)
- Système de Silsila (chaîne d'initiation spirituelle)
- Avatar utilisateur
- Profils publics consultables
- Recherche d'utilisateurs

#### Gestion des Campagnes
- Création de campagnes de Zikr avec tâches multiples
- Campagnes publiques et privées (avec code d'accès)
- Recherche et filtrage de campagnes (par nom, catégorie, statut)
- Pagination des résultats
- CRUD complet sur les campagnes
- Association de tâches aux campagnes
- Support pour les campagnes récurrentes (hebdomadaires)

#### Système de Souscription
- Abonnement atomique aux campagnes
- Sélection multi-tâches avec quantités personnalisées
- Décrémentation automatique et atomique des quantités disponibles
- Protection contre les sursouscriptions (race conditions)
- Vérification des codes d'accès pour les campagnes privées
- Possibilité de se désabonner des campagnes

#### Suivi des Progrès
- Mise à jour incrémentielle des progrès sur les tâches
- Marquage "complète" (système d'honneur)
- Statistiques personnelles détaillées
- Historique des tâches complétées
- Calcul automatique du pourcentage de progression
- Date de complétion enregistrée

#### Sécurité
- Row Level Security (RLS) sur toutes les tables
- Politiques d'accès granulaires
- Validation des entrées avec express-validator
- Protection CSRF avec helmet
- Configuration CORS sécurisée
- Gestion centralisée des erreurs
- Pas d'exposition de données sensibles

#### API & Documentation
- API RESTful complète
- Documentation API détaillée dans README.md
- Collection Postman/Thunder Client
- Réponses standardisées
- Codes HTTP appropriés
- Messages d'erreur clairs et informatifs

#### Base de Données
- Schéma PostgreSQL complet
- Indexes pour les performances
- Triggers pour les timestamps automatiques
- Vues pour les statistiques
- Contraintes d'intégrité
- Support des transactions

#### Infrastructure
- Configuration Supabase
- Scripts de migration SQL
- Variables d'environnement sécurisées
- Logging structuré
- Health check endpoint

### 🛠️ Technique

#### Architecture
- Architecture MVC propre (Routes → Controllers → Services)
- Middleware d'authentification réutilisable
- Middleware de validation avec express-validator
- Gestion d'erreurs centralisée
- Utilitaires pour les réponses standardisées

#### Dépendances Principales
- Express.js 4.18.2
- @supabase/supabase-js 2.39.0
- express-validator 7.0.1
- helmet 7.1.0
- cors 2.8.5
- morgan 1.10.0 (logging)
- dotenv 16.3.1

#### Outils de Développement
- Nodemon pour le rechargement automatique
- ESLint (configuration à venir)
- Prettier (configuration à venir)

### 📚 Documentation
- README.md complet avec:
  - Guide d'installation
  - Documentation API
  - Exemples de requêtes
  - Structure du projet
  - Bonnes pratiques de sécurité
- DEPLOYMENT.md avec guides pour:
  - Heroku
  - Vercel
  - Railway
  - VPS (Ubuntu + PM2 + Nginx)
  - Configuration SSL
- CONTRIBUTING.md avec:
  - Standards de code
  - Processus de PR
  - Conventions de commits
  - Guide de tests
- API Collection JSON pour tests

### 🔒 Sécurité

#### Politiques RLS Implémentées
- **profiles**: Lecture publique, modification restreinte au propriétaire
- **campaigns**: Visibilité basée sur is_public et appartenance
- **tasks**: Accès via les campagnes parentes
- **user_campaigns**: Accès restreint à l'utilisateur
- **user_tasks**: Accès restreint à l'utilisateur propriétaire

#### Validations
- Validation de tous les endpoints avec express-validator
- Vérification des types de données
- Validation des dates (date de fin > date de début)
- Validation des quantités (positives, dans les limites)
- Vérification des UUIDs
- Sanitization des entrées

### 🎨 Design
- Palette de couleurs: Vert, Blanc, Mauve (pour l'interface future)
- Thème spirituel inspiré de l'esthétique Tijanie

### 📊 Modèles de Données

#### Tables Principales
- `silsilas` - Chaînes d'initiation spirituelle
- `profiles` - Profils utilisateurs
- `campaigns` - Campagnes de Zikr
- `tasks` - Tâches individuelles de Zikr
- `user_campaigns` - Souscriptions aux campagnes
- `user_tasks` - Progrès sur les tâches

### ⚡ Performance
- Indexes sur les colonnes fréquemment requêtées
- Pagination sur toutes les listes
- Requêtes optimisées avec Supabase
- Sélection de colonnes spécifiques (pas de SELECT *)

### 🐛 Corrections
- N/A (version initiale)

### 🔄 Changements
- N/A (version initiale)

### ⚠️ Déprécié
- Rien pour le moment

### 🗑️ Supprimé
- N/A (version initiale)

---

## Format des Versions

Le projet utilise le [Semantic Versioning](https://semver.org/):

- **MAJOR** (X.0.0): Changements incompatibles avec les versions précédentes
- **MINOR** (0.X.0): Ajout de fonctionnalités rétrocompatibles
- **PATCH** (0.0.X): Corrections de bugs rétrocompatibles

## Types de Changements

- **✨ Ajouté**: Nouvelles fonctionnalités
- **🔄 Changé**: Modifications de fonctionnalités existantes
- **⚠️ Déprécié**: Fonctionnalités qui seront supprimées
- **🗑️ Supprimé**: Fonctionnalités supprimées
- **🐛 Corrigé**: Corrections de bugs
- **🔒 Sécurité**: Corrections de vulnérabilités

---

[Non publié]: https://github.com/your-org/silkoul-backend/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/your-org/silkoul-backend/releases/tag/v1.0.0
