# 🚀 Guide de Déploiement - Silkoul Ahzabou Tidiani Backend

## Table des Matières

- [Options de Déploiement](#options-de-déploiement)
- [Déploiement sur Heroku](#déploiement-sur-heroku)
- [Déploiement sur Vercel](#déploiement-sur-vercel)
- [Déploiement sur Railway](#déploiement-sur-railway)
- [Déploiement sur VPS](#déploiement-sur-vps)
- [Configuration de Supabase](#configuration-de-supabase)
- [Variables d'Environnement](#variables-denvironnement)
- [Post-Déploiement](#post-déploiement)

## Options de Déploiement

### Comparaison Rapide

| Plateforme | Gratuit | Facilité | Base de données | Recommandé pour |
|------------|---------|----------|-----------------|-----------------|
| Heroku | Oui (limité) | ⭐⭐⭐⭐⭐ | Via Supabase | MVP/Test |
| Vercel | Oui | ⭐⭐⭐⭐ | Via Supabase | Serverless |
| Railway | Oui | ⭐⭐⭐⭐⭐ | Via Supabase | Développement |
| VPS (Digital Ocean, etc.) | Non | ⭐⭐⭐ | PostgreSQL propre | Production |

## Déploiement sur Heroku

### Prérequis
- Compte Heroku
- Heroku CLI installé

### Étapes

1. **Créer un fichier `Procfile`**
```
web: node server.js
```

2. **Initialiser Git (si pas déjà fait)**
```bash
git init
git add .
git commit -m "Initial commit"
```

3. **Créer l'application Heroku**
```bash
heroku create silkoul-ahzabou-api
```

4. **Configurer les variables d'environnement**
```bash
heroku config:set NODE_ENV=production
heroku config:set SUPABASE_URL=pabase_url
heroku config:set SUPABASE_ANON_KEY=your_anon_key
heroku config:set SUPABASE_SERVICE_ROLE_KEY=your_service_key
heroku config:set ALLOWED_ORIGINS=https://your-frontend-domain.com
```

5. **Déployer**
```bash
git push heroku main
```

6. **Vérifier les logs**
```bash
heroku logs --tail
```

7. **Ouvrir l'application**
```bash
heroku open
```

### Configuration SSL
Heroku fournit automatiquement SSL/TLS pour les applications.

## Déploiement sur Vercel

### Prérequis
- Compte Vercel
- Vercel CLI (optionnel)

### Étapes

1. **Créer un fichier `vercel.json`**
```json
{
  "version": 2,
  "builds": [
    {
      "src": "server.js",
      "use": "@vercel/node"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "server.js"
    }
  ],
  "env": {
    "NODE_ENV": "production"
  }
}
```

2. **Via l'interface web**
   - Aller sur [vercel.com](https://vercel.com)
   - Importer votre repository GitHub/GitLab
   - Configurer les variables d'environnement
   - Déployer

3. **Via CLI**
```bash
npm install -g vercel
vercel login
vercel
```

4. **Configurer les variables d'environnement**
Dans le dashboard Vercel → Settings → Environment Variables

## Déploiement sur Railway

### Prérequis
- Compte Railway

### Étapes

1. **Via l'interface web**
   - Aller sur [railway.app](https://railway.app)
   - New Project → Deploy from GitHub repo
   - Sélectionner votre repository

2. **Configurer les variables**
   - Dans Settings → Variables
   - Ajouter toutes les variables d'environnement

3. **Générer le domaine**
   - Settings → Generate Domain

4. **Déploiement automatique**
   - Railway déploie automatiquement à chaque push sur la branche principale

## Déploiement sur VPS

### Prérequis
- VPS (Ubuntu 20.04+ recommandé)
- Accès SSH
- Nom de domaine (optionnel mais recommandé)

### Configuration du Serveur

1. **Connexion SSH**
```bash
ssh root@your_server_ip
```

2. **Mise à jour du système**
```bash
apt update && apt upgrade -y
```

3. **Installation de Node.js**
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt install -y nodejs
node --version
npm --version
```

4. **Installation de PM2**
```bash
npm install -g pm2
```

5. **Configuration du firewall**
### Déploiement avec Docker (Recommandé)

Cette méthode est plus robuste et évite les conflits de dépendances.

1. **Prérequis sur le VPS**
   - Docker installé
   - Docker Compose installé
   - Git installé

2. **Installation Rapide**
   ```bash
   # Cloner le dépôt
   git clone https://github.com/votre-user/silkoul-ahzabou-backend.git
   cd silkoul-ahzabou-backend/backend
   
   # Créer le fichier .env
   cp .env.example .env
   nano .env # Remplir avec vos valeurs de production
   
   # Lancer le déploiement
   chmod +x deploy.sh
   ./deploy.sh
   ```

3. **Ce que fait le script `deploy.sh`**
   - Vérifie la présence de Docker
   - Tire la dernière version du code (git pull)
   - Construit les images Docker
   - Lance les conteneurs (API + Nginx) en arrière-plan
   - Nettoie les images inutilisées

4. **Vérification**
   ```bash
   docker ps
   # Vous devriez voir deux conteneurs : backend-api et backend-nginx
   ```

5. **Configuration Nginx (Avancé)**
### Automatisation Complète (Recommandé)

1.  **Préparation du Serveur (Bootstrap)**
    Depuis votre machine locale, exécutez le script d'initialisation :
    ```bash
    cd backend
    ./setup_vps.sh root@VOTRE_IP_VPS
    ```
    Cela va installer Docker, Docker Compose, et configurer le pare-feu automatiquement.

2.  **Déploiement Continu (CI/CD)**
    Le fichier `.github/workflows/deploy.yml` est configuré pour déployer automatiquement à chaque push sur `main`.
    
    Pour que cela fonctionne, ajoutez ces **Secrets** dans votre dépôt GitHub (Settings > Secrets and variables > Actions) :
    -   `VPS_HOST` : L'adresse IP de votre VPS
    -   `VPS_USER` : Le nom d'utilisateur (ex: root)
    -   `SSH_PRIVATE_KEY` : Votre clé privée SSH (contenu de `~/.ssh/id_rsa`)
    -   `SUPABASE_URL` : Votre URL Supabase
    -   `SUPABASE_ANON_KEY` : Clé anon
    -   `SUPABASE_SERVICE_ROLE_KEY` : Clé service role

3.  **Mise à jour manuelle**
    Si besoin, vous pouvez toujours vous connecter et lancer `./deploy.sh` manuellement.


## Configuration de Supabase

### Étapes

1. **Créer un projet Supabase**
   - Aller sur [supabase.com](https://supabase.com)
   - New Project
   - Choisir un nom et une région proche de vos utilisateurs

2. **Exécuter les migrations SQL**
   - Aller dans SQL Editor
   - Copier-coller le contenu de `database/schema.sql`
   - Exécuter

3. **Récupérer les clés API**
   - Settings → API
   - Copier `URL`, `anon key`, et `service_role key`

4. **Configurer l'authentification**
   - Authentication → Providers
   - Activer Email, Google OAuth, etc.
   - Configurer les URLs de redirection

## Variables d'Environnement

### Production

```env
NODE_ENV=production
PORT=3000

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_production_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_production_service_key

# CORS
ALLOWED_ORIGINS=https://your-frontend.com,https://www.your-frontend.com

# Optional: Monitoring
SENTRY_DSN=your_sentry_dsn
```

### Sécurité

⚠️ **IMPORTANT**: Ne jamais commiter de fichier `.env` contenant des clés de production!

## Post-Déploiement

### Vérifications

1. **Health Check**
```bash
curl https://your-api-domain.com/health
```

2. **Test des endpoints**
```bash
# Test signup
curl -X POST https://your-api-domain.com/api/users/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
```

3. **Monitoring**
   - Configurer Sentry pour les erreurs
   - Mettre en place UptimeRobot pour la disponibilité
   - Configurer des alertes

### Maintenance

1. **Logs**
```bash
# Heroku
heroku logs --tail

# PM2
pm2 logs silkoul-api

# Nginx
tail -f /var/log/nginx/error.log
```

2. **Mises à jour**
```bash
# Vérifier les packages obsolètes
npm outdated

# Mettre à jour
npm update

# Audit de sécurité
npm audit
npm audit fix
```

3. **Sauvegardes Supabase**
   - Configurer les sauvegardes automatiques dans Supabase
   - Télécharger manuellement des backups réguliers

### Performance

1. **Rate Limiting**
```bash
npm install express-rate-limit
```

Ajouter dans `server.js`:
```javascript
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limite par IP
});

app.use('/api/', limiter);
```

2. **Compression**
```bash
npm install compression
```

```javascript
const compression = require('compression');
app.use(compression());
```

3. **Caching**
Considérer Redis pour le caching des requêtes fréquentes.

## Dépannage

### Problèmes Courants

1. **Erreur de connexion Supabase**
   - Vérifier les clés API
   - Vérifier les politiques RLS
   - Vérifier les CORS dans Supabase

2. **Port déjà utilisé**
```bash
# Trouver le processus
lsof -i :3000

# Tuer le processus
kill -9 <PID>
```

3. **PM2 ne redémarre pas**
```bash
pm2 delete all
pm2 start server.js --name silkoul-api
pm2 save
```

## Ressources

- [Documentation Heroku](https://devcenter.heroku.com/)
- [Documentation Vercel](https://vercel.com/docs)
- [Documentation Railway](https://docs.railway.app/)
- [Documentation Supabase](https://supabase.com/docs)
- [PM2 Documentation](https://pm2.keymetrics.io/docs/)

---

Pour toute question, ouvrir une issue sur GitHub ou contacter l'équipe de développement.
