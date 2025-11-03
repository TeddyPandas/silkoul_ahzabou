# Exemples d'Utilisation de l'API

Ce fichier contient des exemples pratiques d'utilisation de l'API Silkoul Ahzabou Tidiani avec curl.

## Variables

```bash
# Configuration de base
export BASE_URL="http://localhost:3000"
export TOKEN="your_jwt_token_here"
```

## 1. Authentification

### Inscription

```bash
curl -X POST "$BASE_URL/api/users/auth/signup" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "ahmed@example.com",
    "password": "password123",
    "display_name": "Ahmed Hassan"
  }'
```

### Connexion

```bash
curl -X POST "$BASE_URL/api/users/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "ahmed@example.com",
    "password": "password123"
  }'
```

Sauvegarder le token reçu:
```bash
export TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

### Déconnexion

```bash
curl -X POST "$BASE_URL/api/users/auth/logout" \
  -H "Authorization: Bearer $TOKEN"
```

## 2. Gestion du Profil

### Récupérer Mon Profil

```bash
curl -X GET "$BASE_URL/api/users/me" \
  -H "Authorization: Bearer $TOKEN"
```

### Mettre à Jour Mon Profil

```bash
curl -X PUT "$BASE_URL/api/users/me" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "display_name": "Ahmed Hassan Updated",
    "phone": "+221771234567",
    "address": "Dakar, Senegal"
  }'
```

### Créer/MAJ Profil Complet

```bash
curl -X POST "$BASE_URL/api/users/profile" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "display_name": "Ahmed Hassan",
    "phone": "+221771234567",
    "address": "Dakar, Senegal",
    "date_of_birth": "1990-01-15",
    "silsila_id": "uuid-de-la-silsila"
  }'
```

### Rechercher des Utilisateurs

```bash
curl -X GET "$BASE_URL/api/users/search?query=ahmed&limit=10"
```

## 3. Silsilas (Chaînes d'Initiation)

### Lister Toutes les Silsilas

```bash
curl -X GET "$BASE_URL/api/users/silsilas"
```

### Créer une Silsila

```bash
curl -X POST "$BASE_URL/api/users/silsilas" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Branche Sénégalaise",
    "description": "Branche Tijanie du Sénégal",
    "parent_id": null
  }'
```

## 4. Campagnes

### Créer une Campagne

```bash
curl -X POST "$BASE_URL/api/campaigns" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Istighfar Ramadan 2025",
    "start_date": "2025-03-01T00:00:00Z",
    "end_date": "2025-03-10T23:59:59Z",
    "description": "Campagne collective d'\''istighfar pour Ramadan",
    "category": "istighfar",
    "is_public": true,
    "tasks": [
      {
        "name": "Istighfar",
        "total_number": 124000,
        "daily_goal": 12400
      },
      {
        "name": "Salawat",
        "total_number": 50000,
        "daily_goal": 5000
      }
    ]
  }'
```

Sauvegarder l'ID de la campagne:
```bash
export CAMPAIGN_ID="uuid-de-la-campagne"
export TASK_ID="uuid-de-la-tache"
```

### Créer une Campagne Privée

```bash
curl -X POST "$BASE_URL/api/campaigns" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Campagne Privée VIP",
    "start_date": "2025-03-01T00:00:00Z",
    "end_date": "2025-03-07T23:59:59Z",
    "description": "Campagne réservée aux membres",
    "is_public": false,
    "access_code": "SECRET2025",
    "tasks": [
      {
        "name": "Wird Special",
        "total_number": 100000
      }
    ]
  }'
```

### Lister Toutes les Campagnes

```bash
curl -X GET "$BASE_URL/api/campaigns?page=1&limit=20"
```

### Rechercher des Campagnes

```bash
# Par nom
curl -X GET "$BASE_URL/api/campaigns?search=ramadan"

# Par catégorie
curl -X GET "$BASE_URL/api/campaigns?category=istighfar"

# Campagnes actives uniquement
curl -X GET "$BASE_URL/api/campaigns?is_active=true"

# Combinaison
curl -X GET "$BASE_URL/api/campaigns?search=ramadan&category=istighfar&page=1&limit=10"
```

### Récupérer une Campagne Spécifique

```bash
curl -X GET "$BASE_URL/api/campaigns/$CAMPAIGN_ID"
```

### Mes Campagnes

```bash
# Toutes mes campagnes (créées et souscrites)
curl -X GET "$BASE_URL/api/campaigns/my" \
  -H "Authorization: Bearer $TOKEN"

# Uniquement les campagnes que j'ai créées
curl -X GET "$BASE_URL/api/campaigns/my?type=created" \
  -H "Authorization: Bearer $TOKEN"

# Uniquement les campagnes auxquelles je suis abonné
curl -X GET "$BASE_URL/api/campaigns/my?type=subscribed" \
  -H "Authorization: Bearer $TOKEN"
```

### Modifier une Campagne

```bash
curl -X PUT "$BASE_URL/api/campaigns/$CAMPAIGN_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Istighfar Ramadan 2025 - Mise à jour",
    "description": "Description mise à jour avec plus de détails"
  }'
```

### Supprimer une Campagne

```bash
curl -X DELETE "$BASE_URL/api/campaigns/$CAMPAIGN_ID" \
  -H "Authorization: Bearer $TOKEN"
```

## 5. Tâches et Souscriptions

### S'abonner à une Campagne Publique

```bash
curl -X POST "$BASE_URL/api/tasks/subscribe" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "campaign_id": "'"$CAMPAIGN_ID"'",
    "task_subscriptions": [
      {
        "task_id": "'"$TASK_ID"'",
        "quantity": 10000
      }
    ]
  }'
```

Sauvegarder l'ID de la tâche utilisateur:
```bash
export USER_TASK_ID="uuid-de-la-user-task"
```

### S'abonner à une Campagne Privée

```bash
curl -X POST "$BASE_URL/api/tasks/subscribe" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "campaign_id": "'"$CAMPAIGN_ID"'",
    "access_code": "SECRET2025",
    "task_subscriptions": [
      {
        "task_id": "'"$TASK_ID"'",
        "quantity": 5000
      }
    ]
  }'
```

### S'abonner à Plusieurs Tâches

```bash
curl -X POST "$BASE_URL/api/tasks/subscribe" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "campaign_id": "'"$CAMPAIGN_ID"'",
    "task_subscriptions": [
      {
        "task_id": "task-id-1",
        "quantity": 10000
      },
      {
        "task_id": "task-id-2",
        "quantity": 5000
      },
      {
        "task_id": "task-id-3",
        "quantity": 2000
      }
    ]
  }'
```

### Récupérer Mes Tâches

```bash
# Toutes mes tâches
curl -X GET "$BASE_URL/api/tasks" \
  -H "Authorization: Bearer $TOKEN"

# Tâches d'une campagne spécifique
curl -X GET "$BASE_URL/api/tasks?campaign_id=$CAMPAIGN_ID" \
  -H "Authorization: Bearer $TOKEN"

# Uniquement les tâches complétées
curl -X GET "$BASE_URL/api/tasks?is_completed=true" \
  -H "Authorization: Bearer $TOKEN"

# Uniquement les tâches non complétées
curl -X GET "$BASE_URL/api/tasks?is_completed=false" \
  -H "Authorization: Bearer $TOKEN"
```

### Mettre à Jour le Progrès (Incrémentiel)

```bash
# Première mise à jour: 3000 complétés
curl -X PUT "$BASE_URL/api/tasks/$USER_TASK_ID/progress" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "completed_quantity": 3000
  }'

# Deuxième mise à jour: 5000 complétés (au total)
curl -X PUT "$BASE_URL/api/tasks/$USER_TASK_ID/progress" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "completed_quantity": 5000
  }'

# Dernière mise à jour: 10000 complétés (complet)
curl -X PUT "$BASE_URL/api/tasks/$USER_TASK_ID/progress" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "completed_quantity": 10000
  }'
```

### Marquer une Tâche comme Complète

```bash
curl -X PUT "$BASE_URL/api/tasks/$USER_TASK_ID/complete" \
  -H "Authorization: Bearer $TOKEN"
```

### Récupérer Mes Statistiques

```bash
curl -X GET "$BASE_URL/api/tasks/stats" \
  -H "Authorization: Bearer $TOKEN"
```

Exemple de réponse:
```json
{
  "status": "success",
  "message": "Statistiques récupérées",
  "data": {
    "total_subscribed": 50000,
    "total_completed": 35000,
    "completed_tasks": 3,
    "total_tasks": 5,
    "progress_percentage": 70.00
  }
}
```

### Se Désabonner d'une Campagne

```bash
curl -X DELETE "$BASE_URL/api/tasks/unsubscribe/$CAMPAIGN_ID" \
  -H "Authorization: Bearer $TOKEN"
```

## 6. Health Check & Info

### Vérifier l'État du Serveur

```bash
curl -X GET "$BASE_URL/health"
```

### Informations sur l'API

```bash
curl -X GET "$BASE_URL/"
```

## 7. Exemples de Workflows Complets

### Workflow 1: Nouveau Utilisateur Rejoint une Campagne

```bash
# 1. Inscription
curl -X POST "$BASE_URL/api/users/auth/signup" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "nouvel@utilisateur.com",
    "password": "motdepasse123",
    "display_name": "Nouvel Utilisateur"
  }'

# Sauvegarder le token
export TOKEN="token-recu"

# 2. Compléter le profil
curl -X POST "$BASE_URL/api/users/profile" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "display_name": "Nouvel Utilisateur",
    "phone": "+221771234567"
  }'

# 3. Rechercher des campagnes
curl -X GET "$BASE_URL/api/campaigns?search=ramadan"

# 4. S'abonner à une campagne
curl -X POST "$BASE_URL/api/tasks/subscribe" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "campaign_id": "campaign-uuid",
    "task_subscriptions": [
      {
        "task_id": "task-uuid",
        "quantity": 5000
      }
    ]
  }'

# 5. Voir mes tâches
curl -X GET "$BASE_URL/api/tasks" \
  -H "Authorization: Bearer $TOKEN"
```

### Workflow 2: Créateur de Campagne

```bash
# 1. Connexion
curl -X POST "$BASE_URL/api/users/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "createur@example.com",
    "password": "password123"
  }'

export TOKEN="token-recu"

# 2. Créer une campagne
curl -X POST "$BASE_URL/api/campaigns" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Ma Nouvelle Campagne",
    "start_date": "2025-03-15T00:00:00Z",
    "end_date": "2025-03-22T23:59:59Z",
    "description": "Description de la campagne",
    "is_public": true,
    "tasks": [
      {
        "name": "Tâche 1",
        "total_number": 100000,
        "daily_goal": 14285
      }
    ]
  }'

export CAMPAIGN_ID="campaign-id-recu"

# 3. Vérifier ma campagne
curl -X GET "$BASE_URL/api/campaigns/$CAMPAIGN_ID" \
  -H "Authorization: Bearer $TOKEN"

# 4. Voir qui s'est abonné (via les statistiques)
curl -X GET "$BASE_URL/api/campaigns/$CAMPAIGN_ID"
```

### Workflow 3: Suivi de Progrès Quotidien

```bash
# Se connecter
export TOKEN="your-token"
export USER_TASK_ID="your-task-id"

# Jour 1: Compléter 2000
curl -X PUT "$BASE_URL/api/tasks/$USER_TASK_ID/progress" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"completed_quantity": 2000}'

# Jour 2: Compléter 4500 (total)
curl -X PUT "$BASE_URL/api/tasks/$USER_TASK_ID/progress" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"completed_quantity": 4500}'

# Jour 3: Compléter 7000 (total)
curl -X PUT "$BASE_URL/api/tasks/$USER_TASK_ID/progress" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"completed_quantity": 7000}'

# Vérifier les statistiques
curl -X GET "$BASE_URL/api/tasks/stats" \
  -H "Authorization: Bearer $TOKEN"
```

## Notes

- Remplacer `$BASE_URL`, `$TOKEN`, `$CAMPAIGN_ID`, etc. par les vraies valeurs
- Tous les UUID doivent être au format UUID v4
- Les dates doivent être au format ISO 8601 (YYYY-MM-DDTHH:mm:ssZ)
- Les quantités doivent être des nombres entiers positifs

## Codes de Statut HTTP

- **200**: Succès
- **201**: Créé
- **204**: Succès sans contenu
- **400**: Erreur de validation
- **401**: Non authentifié
- **403**: Non autorisé
- **404**: Ressource non trouvée
- **409**: Conflit (ressource existe déjà)
- **500**: Erreur serveur

## Format des Réponses

### Succès
```json
{
  "status": "success",
  "message": "Message de succès",
  "data": { ... }
}
```

### Erreur
```json
{
  "status": "error",
  "message": "Description de l'erreur"
}
```

### Avec Pagination
```json
{
  "status": "success",
  "data": [ ... ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5
  }
}
```
