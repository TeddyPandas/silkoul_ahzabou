# 🤝 Guide de Contribution

Merci de votre intérêt pour contribuer à Silkoul Ahzabou Tidiani ! Ce document fournit des directives pour contribuer au projet.

## 📋 Table des Matières

- [Code de Conduite](#code-de-conduite)
- [Comment Contribuer](#comment-contribuer)
- [Standards de Code](#standards-de-code)
- [Processus de Pull Request](#processus-de-pull-request)
- [Reporting de Bugs](#reporting-de-bugs)
- [Suggestions de Fonctionnalités](#suggestions-de-fonctionnalités)

## 🌟 Code de Conduite

Ce projet adhère à un code de conduite basé sur le respect mutuel, l'inclusivité et les valeurs spirituelles de la Tariqa Tijaniyya. En participant, vous vous engagez à maintenir un environnement accueillant et respectueux.

### Nos Engagements

- Respecter tous les contributeurs indépendamment de leur niveau d'expertise
- Accepter les critiques constructives avec grâce
- Se concentrer sur ce qui est meilleur pour la communauté
- Faire preuve d'empathie envers les autres membres

## 💡 Comment Contribuer

### Types de Contributions

Nous accueillons les contributions suivantes:

1. **Corrections de bugs** 🐛
2. **Nouvelles fonctionnalités** ✨
3. **Amélioration de la documentation** 📚
4. **Optimisation des performances** ⚡
5. **Tests** 🧪
6. **Traductions** 🌍

### Avant de Commencer

1. **Vérifier les issues existantes**
   - Rechercher si le bug/feature n'est pas déjà signalé
   - Commenter sur l'issue pour indiquer votre intérêt

2. **Fork le repository**
   ```bash
   git clone https://github.com/your-username/silkoul-ahzabou-backend.git
   cd silkoul-ahzabou-backend
   ```

3. **Créer une branche**
   ```bash
   git checkout -b feature/ma-nouvelle-fonctionnalite
   # ou
   git checkout -b fix/correction-du-bug
   ```

### Conventions de Nommage des Branches

- `feature/` - Nouvelles fonctionnalités
- `fix/` - Corrections de bugs
- `docs/` - Modifications de documentation
- `refactor/` - Refactorisation du code
- `test/` - Ajout/modification de tests
- `perf/` - Améliorations de performance

## 📝 Standards de Code

### Style de Code

1. **ESLint**
   ```bash
   npm run lint
   ```

2. **Prettier** (si configuré)
   ```bash
   npm run format
   ```

### Conventions JavaScript

#### Nommage

```javascript
// Variables et fonctions: camelCase
const userName = 'Ahmed';
function getUserProfile() { }

// Classes: PascalCase
class UserController { }

// Constantes: UPPER_SNAKE_CASE
const MAX_RETRY_ATTEMPTS = 3;

// Fichiers: kebab-case
// user-controller.js, auth-middleware.js
```

#### Structure des Fonctions

```javascript
/**
 * Description de la fonction
 * @param {Type} paramName - Description du paramètre
 * @returns {Type} Description du retour
 */
const functionName = async (paramName) => {
  // Validation
  if (!paramName) {
    throw new ValidationError('paramName requis');
  }

  // Logique métier
  const result = await someOperation(paramName);

  // Retour
  return result;
};
```

#### Gestion des Erreurs

```javascript
// ✅ CORRECT
try {
  const data = await fetchData();
  return successResponse(res, 200, 'Succès', data);
} catch (error) {
  // Logger l'erreur
  console.error('Erreur:', error);
  // Propager une erreur appropriée
  throw new InternalError('Message utilisateur convivial');
}

// ❌ INCORRECT
try {
  const data = await fetchData();
  res.json(data); // Ne pas envoyer de réponse brute
} catch (error) {
  res.status(500).json({ error }); // Ne pas exposer les détails internes
}
```

### Structure des Controllers

```javascript
const controllerFunction = async (req, res) => {
  // 1. Extraction des paramètres
  const { param1, param2 } = req.body;
  const userId = req.userId;

  // 2. Validation (si nécessaire, en plus du middleware)
  if (!param1) {
    throw new ValidationError('param1 requis');
  }

  // 3. Logique métier
  const result = await businessLogic(param1, param2);

  // 4. Réponse standardisée
  return successResponse(res, 200, 'Opération réussie', result);
};
```

### Base de Données

#### Requêtes Supabase

```javascript
// ✅ CORRECT - Utiliser select avec colonnes spécifiques
const { data, error } = await supabase
  .from('campaigns')
  .select('id, name, start_date, end_date')
  .eq('is_public', true)
  .limit(20);

// ❌ INCORRECT - Éviter select('*') pour les grandes tables
const { data, error } = await supabase
  .from('campaigns')
  .select('*');
```

#### Politiques RLS

- Toujours utiliser RLS pour la sécurité
- Tester les politiques avec différents utilisateurs
- Documenter les politiques complexes

### Tests

```javascript
describe('CampaignController', () => {
  describe('createCampaign', () => {
    it('should create a campaign with valid data', async () => {
      // Arrange
      const campaignData = {
        name: 'Test Campaign',
        // ...
      };

      // Act
      const result = await createCampaign(campaignData);

      // Assert
      expect(result).toBeDefined();
      expect(result.name).toBe('Test Campaign');
    });

    it('should throw ValidationError with invalid data', async () => {
      // Arrange
      const invalidData = { name: '' };

      // Act & Assert
      await expect(createCampaign(invalidData))
        .rejects
        .toThrow(ValidationError);
    });
  });
});
```

## 🔄 Processus de Pull Request

### Checklist Avant Soumission

- [ ] Le code suit les standards du projet
- [ ] Les tests passent (`npm test`)
- [ ] La documentation est mise à jour si nécessaire
- [ ] Le commit respecte les conventions
- [ ] Pas de conflits avec la branche principale
- [ ] Les variables sensibles ne sont pas exposées

### Convention de Commits

Utiliser le format [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): description courte

Description détaillée (optionnelle)

Footer (optionnelle)
```

**Types:**
- `feat`: Nouvelle fonctionnalité
- `fix`: Correction de bug
- `docs`: Documentation
- `style`: Formatage, point-virgules manquants, etc.
- `refactor`: Refactorisation du code
- `perf`: Amélioration de performance
- `test`: Ajout/modification de tests
- `chore`: Maintenance, configuration

**Exemples:**

```bash
# Feature
git commit -m "feat(campaigns): add filtering by category"

# Bug fix
git commit -m "fix(auth): resolve token expiration issue"

# Documentation
git commit -m "docs(api): update authentication endpoints"

# Refactoring
git commit -m "refactor(controllers): extract common validation logic"
```

### Soumettre la Pull Request

1. **Push vers votre fork**
   ```bash
   git push origin feature/ma-fonctionnalite
   ```

2. **Créer la Pull Request**
   - Aller sur GitHub
   - Cliquer sur "New Pull Request"
   - Remplir le template

3. **Template de PR**

```markdown
## Description
Description claire de ce que fait la PR

## Type de changement
- [ ] Bug fix
- [ ] Nouvelle fonctionnalité
- [ ] Breaking change
- [ ] Documentation

## Comment tester ?
Étapes pour tester les changements

## Checklist
- [ ] Tests ajoutés/mis à jour
- [ ] Documentation mise à jour
- [ ] Code review effectué
- [ ] Pas de warnings/errors
```

4. **Répondre aux reviews**
   - Être ouvert aux suggestions
   - Faire les modifications demandées
   - Discuter des désaccords de manière constructive

## 🐛 Reporting de Bugs

### Avant de Signaler

1. Vérifier que le bug n'est pas déjà signalé
2. Vérifier que vous utilisez la dernière version
3. Reproduire le bug de manière consistante

### Template de Bug Report

```markdown
## Description du Bug
Description claire et concise du bug

## Comment Reproduire
1. Aller à '...'
2. Cliquer sur '....'
3. Scroller jusqu'à '....'
4. Voir l'erreur

## Comportement Attendu
Ce qui devrait se passer

## Comportement Actuel
Ce qui se passe réellement

## Screenshots
Si applicable, ajouter des screenshots

## Environnement
- OS: [e.g. Ubuntu 20.04]
- Node.js version: [e.g. 18.x]
- Version du backend: [e.g. 1.0.0]

## Logs
```
Coller les logs pertinents
```

## Contexte Additionnel
Toute autre information pertinente
```

## ✨ Suggestions de Fonctionnalités

### Template de Feature Request

```markdown
## Résumé de la Fonctionnalité
Description concise de la fonctionnalité

## Problème Résolu
Quel problème cette fonctionnalité résout-elle ?

## Solution Proposée
Comment cette fonctionnalité pourrait fonctionner

## Alternatives Considérées
Quelles autres solutions avez-vous envisagées ?

## Impact
- Priorité: [Haute/Moyenne/Basse]
- Utilisateurs impactés: [Tous/Créateurs/Participants]
- Complexité estimée: [Haute/Moyenne/Basse]

## Contexte Additionnel
Screenshots, mockups, ou exemples
```

## 🧪 Tests

### Exécuter les Tests

```bash
# Tous les tests
npm test

# Tests spécifiques
npm test -- controllers/campaign_controller.test.js

# Avec coverage
npm run test:coverage
```

### Écrire des Tests

```javascript
// test/controllers/campaign_controller.test.js
const { createCampaign } = require('../../controllers/campaign_controller');

describe('Campaign Controller', () => {
  beforeEach(() => {
    // Setup avant chaque test
  });

  afterEach(() => {
    // Cleanup après chaque test
  });

  test('should create campaign successfully', async () => {
    // Test implementation
  });
});
```

## 📚 Documentation

### Documenter le Code

```javascript
/**
 * Crée une nouvelle campagne de Zikr avec ses tâches
 * 
 * @param {Object} req - Express request object
 * @param {Object} req.body - Campaign data
 * @param {string} req.body.name - Nom de la campagne
 * @param {Date} req.body.start_date - Date de début
 * @param {Date} req.body.end_date - Date de fin
 * @param {Array} req.body.tasks - Liste des tâches
 * @param {Object} res - Express response object
 * 
 * @returns {Promise<Object>} La campagne créée avec ses tâches
 * @throws {ValidationError} Si les données sont invalides
 * 
 * @example
 * POST /api/campaigns
 * {
 *   "name": "Istighfar Ramadan",
 *   "start_date": "2025-03-01",
 *   "end_date": "2025-03-10",
 *   "tasks": [{"name": "Istighfar", "total_number": 10000}]
 * }
 */
const createCampaign = async (req, res) => {
  // Implementation
};
```

### Mettre à Jour le README

Quand vous ajoutez:
- Une nouvelle route → Documenter dans README.md
- Une nouvelle variable d'env → Ajouter dans .env.example et README
- Une dépendance → Expliquer pourquoi dans le commit message

## ⚡ Optimisation

### Performance

- Utiliser les index de base de données appropriés
- Limiter les jointures complexes
- Paginer les résultats
- Mettre en cache les données fréquentes

### Sécurité

- Valider toutes les entrées utilisateur
- Utiliser des requêtes paramétrées
- Implémenter le rate limiting
- Suivre les principes OWASP

## 🎯 Priorités de Développement

### Phase 1 (MVP) - Priorité Haute
- Système d'authentification
- Gestion des campagnes
- Souscription aux tâches
- Suivi des progrès

### Phase 2 - Priorité Moyenne
- Géolocalisation
- Événements
- Paiements
- Analytics avancés

### Phase 3 - Priorité Basse
- Fonctionnalités sociales
- Classements
- Gamification
- Mode hors ligne

## 📞 Contact

Pour toute question:
- **Issues GitHub**: Pour les bugs et features
- **Discussions**: Pour les questions générales
- **Email**: dev@silkoul-ahzabou.com

## 🙏 Remerciements

Merci de contribuer à ce projet qui sert la communauté Tijanie ! Que vos contributions soient récompensées.

**Bismillah al-Rahman al-Rahim** 🕌

---

**Note**: Ce guide est un document vivant et peut être mis à jour. Suggestions bienvenues !
