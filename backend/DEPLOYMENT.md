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
```bash
ufw allow ssh
ufw allow http
ufw allow https
ufw enable
```

### Déploiement de l'Application

1. **Cloner le repository**
```bash
cd /var/www
git clone your_repository_url
cd backend
```

2. **Installer les dépendances**
```bash
npm install --production
```

3. **Créer le fichier .env**
```bash
nano .env
# Coller vos variables d'environnement
```

4. **Démarrer avec PM2**
```bash
pm2 start server.js --name silkoul-api
pm2 save
pm2 startup
```

5. **Configuration Nginx (Reverse Proxy)**

Installer Nginx:
```bash
apt install -y nginx
```

Créer la configuration:
```bash
nano /etc/nginx/sites-available/silkoul-api
```

Contenu:
```nginx
server {
    listen 80;
    server_name api.your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Activer le site:
```bash
ln -s /etc/nginx/sites-available/silkoul-api /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
```

6. **Configuration SSL avec Let's Encrypt**

```bash
apt install -y certbot python3-certbot-nginx
certbot --nginx -d api.your-domain.com
```

### Automatisation des Déploiements

Créer un script de déploiement:
```bash
nano /var/www/backend/deploy.sh
```

Contenu:
```bash
#!/bin/bash
cd /var/www/backend
git pull origin main
npm install --production
pm2 restart silkoul-api
echo "✅ Déploiement terminé!"
```

Rendre exécutable:
```bash
chmod +x deploy.sh
```

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
