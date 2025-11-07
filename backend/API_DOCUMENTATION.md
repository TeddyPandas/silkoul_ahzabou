# API Documentation - Silkoul Ahzabou Tidiani

**Base URL**: `http://localhost:3000/api`
**Version**: 1.0.0
**Date**: 7 Novembre 2025

---

## Table des Matières

1. [Format des Réponses](#format-des-réponses)
2. [Authentification](#authentification)
3. [Endpoints Campagnes](#endpoints-campagnes)
4. [Endpoints Tâches](#endpoints-tâches)
5. [Codes d'Erreur](#codes-derreur)

---

## Format des Réponses

Toutes les réponses API suivent ce format standardisé :

### Réponse de Succès
```json
{
  "status": "success",
  "message": "Message de succès",
  "data": {
    // Données retournées
  }
}
```

### Réponse Paginée
```json
{
  "status": "success",
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5
  }
}
```

### Réponse d'Erreur
```json
{
  "status": "error",
  "message": "Message d'erreur détaillé"
}
```

---

## Authentification

Toutes les routes protégées nécessitent un token JWT dans le header :

```
Authorization: Bearer <JWT_TOKEN>
```

Le token est extrait automatiquement pour identifier l'utilisateur (`req.userId`).

---

## Endpoints Campagnes

### 1. Créer une Campagne

**POST** `/api/campaigns`

**Authentification**: ✅ Requise

**Body**:
```json
{
  "name": "string (required, 3-100 chars)",
  "description": "string (optional, max 500 chars)",
  "start_date": "ISO8601 (required)",
  "end_date": "ISO8601 (required)",
  "category": "string (optional)",
  "is_public": "boolean (default: true)",
  "access_code": "string (required if is_public=false)",
  "tasks": [
    {
      "name": "string (required)",
      "total_number": "integer (required, > 0)",
      "daily_goal": "integer (optional)"
    }
  ]
}
```

**Exemple de Requête**:
```bash
curl -X POST http://localhost:3000/api/campaigns \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Ramadan 2025",
    "description": "Campagne collective pour le Ramadan",
    "start_date": "2025-03-10T00:00:00Z",
    "end_date": "2025-04-09T23:59:59Z",
    "category": "Ramadan",
    "is_public": true,
    "tasks": [
      {
        "name": "Subhanallah",
        "total_number": 100000,
        "daily_goal": 3334
      },
      {
        "name": "Alhamdulillah",
        "total_number": 100000,
        "daily_goal": 3334
      }
    ]
  }'
```

**Réponse 201**:
```json
{
  "status": "success",
  "message": "Campagne créée avec succès",
  "data": {
    "id": "uuid",
    "name": "Ramadan 2025",
    "reference": "ramadan-2025-1699286400000",
    "description": "Campagne collective pour le Ramadan",
    "start_date": "2025-03-10T00:00:00Z",
    "end_date": "2025-04-09T23:59:59Z",
    "created_by": "user-uuid",
    "category": "Ramadan",
    "is_public": true,
    "access_code": null,
    "is_weekly": false,
    "created_at": "2025-11-07T10:00:00Z",
    "updated_at": "2025-11-07T10:00:00Z",
    "tasks": [
      {
        "id": "task-uuid-1",
        "campaign_id": "uuid",
        "name": "Subhanallah",
        "total_number": 100000,
        "remaining_number": 100000,
        "daily_goal": 3334
      },
      {
        "id": "task-uuid-2",
        "campaign_id": "uuid",
        "name": "Alhamdulillah",
        "total_number": 100000,
        "remaining_number": 100000,
        "daily_goal": 3334
      }
    ]
  }
}
```

**Erreurs**:
- `400 Bad Request`: Validation error (champs manquants ou invalides)
- `401 Unauthorized`: Token manquant ou invalide
- `500 Internal Server Error`: Erreur serveur

**Notes**:
- Le champ `created_by` est extrait automatiquement du token JWT (ne PAS l'inclure dans le body)
- Le champ `reference` est généré automatiquement
- Si `is_public = false`, le champ `access_code` est requis
- Les tâches doivent utiliser `snake_case` : `total_number`, `daily_goal`

---

### 2. Récupérer Toutes les Campagnes (Publiques)

**GET** `/api/campaigns`

**Authentification**: ❌ Optionnelle (pour voir aussi ses campagnes privées)

**Query Parameters**:
- `search` (string, optional): Recherche dans name ou description
- `category` (string, optional): Filtrer par catégorie
- `is_active` (boolean, optional): Uniquement les campagnes actives
- `page` (integer, default: 1): Numéro de page
- `limit` (integer, default: 20): Nombre de résultats par page

**Exemple de Requête**:
```bash
curl http://localhost:3000/api/campaigns?category=Ramadan&page=1&limit=10
```

**Réponse 200**:
```json
{
  "status": "success",
  "data": [
    {
      "id": "uuid",
      "name": "Ramadan 2025",
      "reference": "ramadan-2025-1699286400000",
      "description": "Campagne collective pour le Ramadan",
      "start_date": "2025-03-10T00:00:00Z",
      "end_date": "2025-04-09T23:59:59Z",
      "created_by": "user-uuid",
      "category": "Ramadan",
      "is_public": true,
      "is_weekly": false,
      "created_at": "2025-11-07T10:00:00Z",
      "creator": {
        "id": "user-uuid",
        "display_name": "Ahmed",
        "avatar_url": "https://..."
      },
      "tasks": [
        {
          "id": "task-uuid-1",
          "name": "Subhanallah",
          "total_number": 100000,
          "remaining_number": 50000,
          "daily_goal": 3334
        }
      ]
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 25,
    "totalPages": 3
  }
}
```

---

### 3. Récupérer une Campagne Spécifique

**GET** `/api/campaigns/:id`

**Authentification**: ❌ Optionnelle (requise pour les campagnes privées)

**Exemple de Requête**:
```bash
curl http://localhost:3000/api/campaigns/uuid-de-la-campagne
```

**Réponse 200**:
```json
{
  "status": "success",
  "message": "Campagne récupérée",
  "data": {
    "id": "uuid",
    "name": "Ramadan 2025",
    "reference": "ramadan-2025-1699286400000",
    "description": "Campagne collective pour le Ramadan",
    "start_date": "2025-03-10T00:00:00Z",
    "end_date": "2025-04-09T23:59:59Z",
    "created_by": "user-uuid",
    "category": "Ramadan",
    "is_public": true,
    "access_code": null,
    "is_weekly": false,
    "created_at": "2025-11-07T10:00:00Z",
    "updated_at": "2025-11-07T10:00:00Z",
    "creator": {
      "id": "user-uuid",
      "display_name": "Ahmed",
      "avatar_url": "https://...",
      "email": "ahmed@example.com"
    },
    "tasks": [
      {
        "id": "task-uuid-1",
        "name": "Subhanallah",
        "total_number": 100000,
        "remaining_number": 50000,
        "daily_goal": 3334,
        "created_at": "2025-11-07T10:00:00Z"
      }
    ]
  }
}
```

**Erreurs**:
- `404 Not Found`: Campagne non trouvée
- `403 Forbidden`: Accès refusé (campagne privée sans souscription)

---

### 4. Récupérer Mes Campagnes

**GET** `/api/campaigns/my`

**Authentification**: ✅ Requise

**Query Parameters**:
- `type` (string, optional): `all` (default), `created`, `subscribed`

**Exemple de Requête**:
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
     http://localhost:3000/api/campaigns/my?type=created
```

**Réponse 200**:
```json
{
  "status": "success",
  "message": "Campagnes de l'utilisateur récupérées",
  "data": [
    {
      "id": "uuid",
      "name": "Ma Campagne",
      "relation": "created",
      // ... autres champs
    },
    {
      "id": "uuid-2",
      "name": "Campagne Souscrite",
      "relation": "subscribed",
      "creator": {
        "id": "autre-user-uuid",
        "display_name": "Ali"
      }
      // ... autres champs
    }
  ]
}
```

---

### 5. Vérifier si Je Suis Abonné à une Campagne

**GET** `/api/campaigns/:campaignId/subscription`

**Authentification**: ✅ Requise

**Exemple de Requête**:
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
     http://localhost:3000/api/campaigns/uuid-de-la-campagne/subscription
```

**Réponse 200**:
```json
{
  "status": "success",
  "message": "Statut de souscription vérifié",
  "data": {
    "isSubscribed": true
  }
}
```

**Erreurs**:
- `401 Unauthorized`: Token manquant ou invalide

**Notes**:
- ⚡ Endpoint optimisé pour une vérification rapide
- Ne charge PAS toutes les campagnes, juste une vérification d'existence
- Retourne `false` si non abonné, `true` si abonné

---

### 6. Mettre à Jour une Campagne

**PUT** `/api/campaigns/:id`

**Authentification**: ✅ Requise (créateur uniquement)

**Body** (tous les champs sont optionnels):
```json
{
  "name": "string",
  "description": "string",
  "start_date": "ISO8601",
  "end_date": "ISO8601",
  "category": "string",
  "is_public": "boolean",
  "access_code": "string"
}
```

**Exemple de Requête**:
```bash
curl -X PUT http://localhost:3000/api/campaigns/uuid-de-la-campagne \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Nouvelle description"
  }'
```

**Réponse 200**:
```json
{
  "status": "success",
  "message": "Campagne mise à jour",
  "data": {
    "id": "uuid",
    "name": "Ramadan 2025",
    "description": "Nouvelle description",
    // ... autres champs mis à jour
  }
}
```

**Erreurs**:
- `401 Unauthorized`: Token manquant ou invalide
- `403 Forbidden`: Vous n'êtes pas le créateur de cette campagne
- `404 Not Found`: Campagne non trouvée

---

### 7. Supprimer une Campagne

**DELETE** `/api/campaigns/:id`

**Authentification**: ✅ Requise (créateur uniquement)

**Exemple de Requête**:
```bash
curl -X DELETE http://localhost:3000/api/campaigns/uuid-de-la-campagne \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Réponse 200**:
```json
{
  "status": "success",
  "message": "Campagne supprimée avec succès"
}
```

**Erreurs**:
- `401 Unauthorized`: Token manquant ou invalide
- `403 Forbidden`: Vous n'êtes pas le créateur de cette campagne
- `404 Not Found`: Campagne non trouvée

**Notes**:
- ⚠️ La suppression est définitive
- Les tâches associées sont supprimées en cascade
- Les souscriptions des utilisateurs sont supprimées en cascade

---

## Endpoints Tâches

### 1. S'Abonner à une Campagne

**POST** `/api/tasks/subscribe`

**Authentification**: ✅ Requise

**Body**:
```json
{
  "campaign_id": "uuid (required)",
  "access_code": "string (required if campaign is private)",
  "task_subscriptions": [
    {
      "task_id": "uuid (required)",
      "quantity": "integer (required, > 0)"
    }
  ]
}
```

**Exemple de Requête**:
```bash
curl -X POST http://localhost:3000/api/tasks/subscribe \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "campaign_id": "uuid-de-la-campagne",
    "task_subscriptions": [
      {
        "task_id": "uuid-task-1",
        "quantity": 10000
      },
      {
        "task_id": "uuid-task-2",
        "quantity": 5000
      }
    ]
  }'
```

**Réponse 201**:
```json
{
  "status": "success",
  "message": "Abonnement à la campagne réussi."
}
```

**Erreurs**:
- `400 Bad Request`: Validation error
- `401 Unauthorized`: Token manquant ou invalide
- `403 Forbidden`: Code d'accès invalide pour campagne privée
- `404 Not Found`: Campagne ou tâche non trouvée
- `409 Conflict`: Déjà abonné à cette campagne

**Notes**:
- ⚠️ Utilise une fonction RPC PostgreSQL pour garantir l'atomicité de la transaction
- Les quantités demandées sont vérifiées (disponibilité dans `remaining_number`)
- Le nom du champ est `task_subscriptions` (snake_case), PAS `selectedTasks`
- Si l'abonnement échoue, tout est annulé (rollback)

---

### 2. Récupérer Mes Tâches

**GET** `/api/tasks/my`

**Authentification**: ✅ Requise

**Query Parameters**:
- `campaign_id` (uuid, optional): Filtrer par campagne
- `is_completed` (boolean, optional): Filtrer par statut

**Exemple de Requête**:
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
     http://localhost:3000/api/tasks/my?campaign_id=uuid&is_completed=false
```

**Réponse 200**:
```json
{
  "status": "success",
  "message": "Tâches récupérées",
  "data": [
    {
      "id": "user-task-uuid",
      "user_id": "user-uuid",
      "task_id": "task-uuid",
      "subscribed_quantity": 10000,
      "completed_quantity": 5000,
      "is_completed": false,
      "completed_at": null,
      "created_at": "2025-11-07T10:00:00Z",
      "task": {
        "id": "task-uuid",
        "name": "Subhanallah",
        "total_number": 100000,
        "remaining_number": 50000,
        "daily_goal": 3334,
        "campaign": {
          "id": "campaign-uuid",
          "name": "Ramadan 2025",
          "start_date": "2025-03-10T00:00:00Z",
          "end_date": "2025-04-09T23:59:59Z",
          "category": "Ramadan"
        }
      }
    }
  ]
}
```

---

### 3. Mettre à Jour le Progrès d'une Tâche

**PUT** `/api/tasks/:id/progress`

**Authentification**: ✅ Requise

**Body**:
```json
{
  "completed_quantity": "integer (required, >= 0, <= subscribed_quantity)"
}
```

**Exemple de Requête**:
```bash
curl -X PUT http://localhost:3000/api/tasks/user-task-uuid/progress \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "completed_quantity": 7500
  }'
```

**Réponse 200**:
```json
{
  "status": "success",
  "message": "Progrès mis à jour",
  "data": {
    "id": "user-task-uuid",
    "completed_quantity": 7500,
    "is_completed": false,
    // ... autres champs
  }
}
```

---

### 4. Se Désabonner d'une Campagne

**DELETE** `/api/tasks/campaigns/:campaign_id/unsubscribe`

**Authentification**: ✅ Requise

**Exemple de Requête**:
```bash
curl -X DELETE http://localhost:3000/api/tasks/campaigns/uuid-de-la-campagne/unsubscribe \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Réponse 200**:
```json
{
  "status": "success",
  "message": "Désabonnement réussi"
}
```

**Notes**:
- Les quantités non complétées sont remises dans les tâches (`remaining_number`)
- Les `user_tasks` associées sont supprimées en cascade

---

## Codes d'Erreur

| Code | Signification | Description |
|------|---------------|-------------|
| `200` | OK | Requête réussie |
| `201` | Created | Ressource créée avec succès |
| `204` | No Content | Requête réussie, pas de contenu à retourner |
| `400` | Bad Request | Erreur de validation (champs manquants ou invalides) |
| `401` | Unauthorized | Token d'authentification manquant ou invalide |
| `403` | Forbidden | Accès refusé (droits insuffisants) |
| `404` | Not Found | Ressource non trouvée |
| `409` | Conflict | Conflit (ex: déjà abonné à une campagne) |
| `500` | Internal Server Error | Erreur serveur interne |

---

## Notes Importantes

### Convention de Nommage

⚠️ **IMPORTANT**: Le backend utilise `snake_case` pour tous les champs :
- `total_number` (pas `totalNumber`)
- `daily_goal` (pas `dailyGoal`)
- `task_subscriptions` (pas `taskSubscriptions` ou `selectedTasks`)
- `created_by` (pas `createdBy`)
- `is_public` (pas `isPublic`)
- `access_code` (pas `accessCode`)

### Sécurité

- Le champ `created_by` est **toujours** extrait du token JWT côté backend
- **NE JAMAIS** envoyer `created_by` dans le body d'une requête (sera ignoré)
- Les vérifications de droits (créateur, abonné) sont faites côté backend
- Les codes d'accès sont requis pour accéder aux campagnes privées

### Performances

- L'endpoint `/campaigns/:campaignId/subscription` est optimisé pour une vérification rapide
- Utilisez la pagination pour les listes longues
- Évitez de charger toutes les campagnes si vous avez juste besoin de vérifier une souscription

---

**Dernière mise à jour**: 7 Novembre 2025
**Mainteneur**: Backend Team
**Contact**: backend@silkoul.app
