# 🕌 Silkoul Ahzabou Tidiani - Backend API

Backend Node.js + Express pour l'application mobile de gestion des campagnes de Zikr pour les disciples Tijani.

## 📋 Table des Matières

- [Fonctionnalités](#fonctionnalités)
- [Architecture](#architecture)
- [Installation](#installation)
- [Configuration](#configuration)
- [Utilisation](#utilisation)
- [Documentation API](#documentation-api)
- [Structure du Projet](#structure-du-projet)
- [Sécurité](#sécurité)

## ✨ Fonctionnalités

### Phase 1 - MVP (Implémenté)

- ✅ **Authentification**
  - Connexion avec email/mot de passe
  - Support pour Gmail OAuth (via Supabase)
  - Gestion des sessions JWT
  - Refresh tokens

- ✅ **Gestion des Campagnes**
  - Création de campagnes avec tâches multiples
  - Campagnes publiques et privées (avec code d'accès)
  - Recherche et filtrage de campagnes
  - CRUD complet sur les campagnes

- ✅ **Système de Souscription**
  - Abonnement atomique aux campagnes
  - Sélection multi-tâches avec quantités
  - Décrémentation automatique des quantités disponibles
  - Protection contre les sursouscriptions

- ✅ **Suivi des Progrès**
  - Mise à jour incrémentielle des progrès
  - Marquage "complète" (système d'honneur)
  - Statistiques personnelles
  - Historique des tâches

- ✅ **Gestion des Profils**
  - Profils utilisateurs complets
  - Système de Silsila (généalogie spirituelle)
  - Recherche d'utilisateurs

## 🏗️ Architecture

```
┌─────────────────────────────────────┐
│         Flutter Mobile App          │
└──────────────┬──────────────────────┘
               │
               │ HTTP/REST
               │
┌──────────────▼──────────────────────┐
│      Node.js + Express API          │
│                                     │
│  ┌──────────────────────────────┐  │
│  │  Routes                      │  │
│  │  - campaigns                 │  │
│  │  - tasks                     │  │
│  │  - users                     │  │
│  └──────┬───────────────────────┘  │
│         │                           │
│  ┌──────▼───────────────────────┐  │
│  │  Controllers                 │  │
│  │  - Business Logic            │  │
│  └──────┬───────────────────────┘  │
│         │                           │
│  ┌──────▼───────────────────────┐  │
│  │  Middleware                  │  │
│  │  - Auth                      │  │
│  │  - Validation                │  │
│  └──────────────────────────────┘  │
└──────────────┬──────────────────────┘
               │
               │ Supabase SDK
               │
┌──────────────▼──────────────────────┐
│      Supabase (PostgreSQL)          │
│                                     │
│  - Auth (JWT)                       │
│  - Database (RLS)                   │
│  - Real-time subscriptions          │
└─────────────────────────────────────┘
```

## 📦 Installation

### Prérequis

- Node.js >= 16.x
- npm ou yarn
- Compte Supabase (gratuit)

### Étapes

1. **Cloner le repository**
```bash
git clone <your-repo-url>
cd backend
```

2. **Installer les dépendances**
```bash
npm install
```

3. **Configurer les variables d'environnement**
```bash
cp .env.example .env
```

Éditer `.env` avec vos valeurs:
```env
PORT=3000
NODE_ENV=development

SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
```

4. **Configurer la base de données Supabase**

Voir le fichier `database/schema.sql` pour les scripts de création des tables.

5. **Lancer le serveur**

Développement:
```bash
npm run dev
```

Production:
```bash
npm start
```

## ⚙️ Configuration

### Variables d'Environnement

| Variable | Description | Requis |
|----------|-------------|--------|
| `PORT` | Port du serveur | Non (défaut: 3000) |
| `NODE_ENV` | Environnement (development/production) | Non |
| `SUPABASE_URL` | URL du projet Supabase | Oui |
| `SUPABASE_ANON_KEY` | Clé publique Supabase | Oui |
| `SUPABASE_SERVICE_ROLE_KEY` | Clé admin Supabase | Non |
| `ALLOWED_ORIGINS` | Origines CORS autorisées | Non |

### Configuration Supabase

1. Créer un projet sur [supabase.com](https://supabase.com)
2. Récupérer les clés API dans Settings > API
3. Exécuter les migrations SQL (voir `/database/schema.sql`)
4. Configurer les politiques RLS (Row Level Security)

## 🚀 Utilisation

### Démarrage Rapide

```bash
# Installation
npm install

# Configuration
cp .env.example .env
# Éditer .env avec vos valeurs

# Lancer en mode développement
npm run dev

# Le serveur démarre sur http://localhost:3000
```

### Tests de l'API

Vous pouvez tester l'API avec:
- **Postman** : Importer la collection (à venir)
- **curl** : Voir les exemples ci-dessous
- **Thunder Client** (VS Code extension)

#### Exemple: Créer une campagne

```bash
curl -X POST http://localhost:3000/api/campaigns \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "name": "Istighfar Ramadan 2025",
    "start_date": "2025-03-01T00:00:00Z",
    "end_date": "2025-03-10T23:59:59Z",
    "description": "Campagne collective d'\''istighfar",
    "is_public": true,
    "tasks": [
      {
        "name": "Istighfar",
        "total_number": 124000
      }
    ]
  }'
```

## 📚 Documentation API

### Base URL
```
http://localhost:3000/api
```

### Authentification

Toutes les routes protégées nécessitent un header `Authorization`:
```
Authorization: Bearer <jwt_token>
```

### Endpoints Principaux

#### 🔐 Authentification (`/api/users/auth`)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/auth/login` | Connexion |
| POST | `/auth/signup` | Inscription |
| POST | `/auth/logout` | Déconnexion |
| POST | `/auth/refresh` | Rafraîchir le token |

#### 👤 Profils (`/api/users`)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/me` | Mon profil |
| PUT | `/me` | Mettre à jour mon profil |
| POST | `/profile` | Créer/MAJ profil complet |
| GET | `/:id` | Profil public |
| GET | `/search` | Rechercher utilisateurs |
| GET | `/silsilas` | Liste des silsilas |
| POST | `/silsilas` | Créer une silsila |

#### 📋 Campagnes (`/api/campaigns`)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/` | Créer une campagne |
| GET | `/` | Lister les campagnes |
| GET | `/my` | Mes campagnes |
| GET | `/:id` | Détails d'une campagne |
| PUT | `/:id` | Modifier une campagne |
| DELETE | `/:id` | Supprimer une campagne |

#### ✅ Tâches (`/api/tasks`)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/subscribe` | S'abonner à une campagne |
| GET | `/` | Mes tâches |
| GET | `/stats` | Mes statistiques |
| PUT | `/:id/progress` | MAJ progrès incrémentiel |
| PUT | `/:id/complete` | Marquer complète |
| DELETE | `/unsubscribe/:campaign_id` | Se désabonner |

### Exemples de Requêtes

#### 1. Inscription
```http
POST /api/users/auth/signup
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepassword123",
  "display_name": "Ahmed Hassan"
}
```

#### 2. Créer une Campagne
```http
POST /api/campaigns
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Salawat Challenge",
  "start_date": "2025-03-01T00:00:00Z",
  "end_date": "2025-03-07T23:59:59Z",
  "description": "1 million de Salawat en 7 jours",
  "category": "salawat",
  "is_public": true,
  "tasks": [
    {
      "name": "Salat al-Fatih",
      "total_number": 1000000,
      "daily_goal": 142857
    }
  ]
}
```

#### 3. S'abonner à une Campagne
```http
POST /api/tasks/subscribe
Authorization: Bearer <token>
Content-Type: application/json

{
  "campaign_id": "uuid-de-la-campagne",
  "task_subscriptions": [
    {
      "task_id": "uuid-de-la-tache",
      "quantity": 10000
    }
  ]
}
```

#### 4. Mettre à Jour le Progrès
```http
PUT /api/tasks/:user_task_id/progress
Authorization: Bearer <token>
Content-Type: application/json

{
  "completed_quantity": 5000
}
```

### Codes de Réponse

| Code | Signification |
|------|--------------|
| 200 | Succès |
| 201 | Créé |
| 204 | Succès sans contenu |
| 400 | Erreur de validation |
| 401 | Non authentifié |
| 403 | Non autorisé |
| 404 | Ressource non trouvée |
| 409 | Conflit (ressource existe déjà) |
| 500 | Erreur serveur |

### Format des Réponses

#### Succès
```json
{
  "status": "success",
  "message": "Opération réussie",
  "data": { ... }
}
```

#### Erreur
```json
{
  "status": "error",
  "message": "Description de l'erreur"
}
```

## 📁 Structure du Projet

```
backend/
├── config/
│   └── supabase.js          # Configuration Supabase
├── controllers/
│   ├── campaign_controller.js
│   ├── task_controller.js
│   └── user_controller.js
├── middleware/
│   ├── auth.js              # Middleware d'authentification
│   └── validation.js        # Validations avec express-validator
├── routes/
│   ├── campaigns.js
│   ├── tasks.js
│   └── users.js
├── utils/
│   ├── errors.js            # Classes d'erreurs personnalisées
│   └── response.js          # Helpers de réponse
├── .env.example             # Template des variables d'env
├── .gitignore
├── package.json
├── README.md
└── server.js                # Point d'entrée
```

## 🔒 Sécurité

### Row Level Security (RLS)

Le projet utilise les politiques RLS de Supabase pour sécuriser l'accès aux données:

- **profiles**: Lecture publique, modification restreinte
- **campaigns**: Visibilité basée sur is_public et créateur
- **tasks**: Accès via les campagnes
- **user_tasks**: Accès restreint à l'utilisateur propriétaire

### Bonnes Pratiques Implémentées

- ✅ Authentification JWT via Supabase
- ✅ Validation des entrées avec express-validator
- ✅ Protection CSRF avec helmet
- ✅ CORS configuré
- ✅ Variables d'environnement pour les secrets
- ✅ Gestion d'erreurs centralisée
- ✅ Rate limiting (à implémenter en production)

### Recommandations pour la Production

1. **Variables d'environnement**
   - Ne jamais commiter `.env`
   - Utiliser des secrets managers (AWS Secrets Manager, etc.)

2. **HTTPS**
   - Toujours utiliser HTTPS en production
   - Configurer SSL/TLS

3. **Rate Limiting**
   - Ajouter express-rate-limit
   - Limiter les requêtes par IP

4. **Monitoring**
   - Logs structurés (Winston, Pino)
   - Monitoring d'erreurs (Sentry)
   - Métriques de performance

5. **Base de données**
   - Sauvegardes régulières
   - Indexes pour les requêtes fréquentes
   - Connection pooling

## 🤝 Contribution

1. Fork le projet
2. Créer une branche (`git checkout -b feature/AmazingFeature`)
3. Commit les changements (`git commit -m 'Add AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## 📝 License

Ce projet est sous licence MIT.

## 👥 Contact

Pour toute question ou support:
- Email: support@silkoul-ahzabou.com
- GitHub Issues: [Issues](https://github.com/your-repo/issues)

## 🙏 Remerciements

- La communauté Tijani
- Supabase pour l'infrastructure backend
- Tous les contributeurs

---

**Bismillah al-Rahman al-Rahim** 🕌
