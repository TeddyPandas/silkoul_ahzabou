# 🧠 Infrastructure Brainstorm: SSL & Monitoring

## 🎯 Objectif
Automatiser la gestion SSL (HTTPS) et mettre en place un monitoring efficace pour l'application sur le VPS.

---

## 🔒 Partie 1 : SSL Automatique (HTTPS)

**Pré-requis INDISPENSABLE :** Il faut un **Nom de Domaine** (ex: `api.silkoul.com` ou `silkoul-app.com`) pointant vers l'IP `185.194.216.251`. Le SSL ne peut pas être automatisé sur une IP brute.

### Option A : Nginx Proxy Manager (Recommandé ⭐️)
Une interface graphique (GUI) pour gérer Nginx et les certificats Let's Encrypt.
*   **Comment ça marche :** On remplace votre conteneur `nginx` actuel par `nginx-proxy-manager`.
*   **Avantages :** 
    *   Tout se gère via une UI web (pas de fichiers de config complexes).
    *   Renouvellement SSL 100% automatique.
    *   Gestion facile des redirections.
*   **Inconvénients :** Ajoute une couche (base de données SQLite/MySQL pour l'outil).

### Option B : Traefik
Un reverse proxy moderne conçu pour Docker.
*   **Comment ça marche :** On ajoute des "labels" dans le `docker-compose.yml`.
*   **Avantages :** 
    *   "Infrastructure as Code" (tout est dans le docker-compose).
    *   Détection automatique des nouveaux services.
*   **Inconvénients :** Courbe d'apprentissage plus raide (config YAML sensible).

### Option C : Certbot Sidecar
Garder l'architecture actuelle mais ajouter un conteneur qui renouvelle les certificats.
*   **Avantages :** On garde votre configuration Nginx actuelle presque intacte.
*   **Inconvénients :** Solution "bricolée", script de renouvellement à maintenir, moins robuste que A ou B.

---

## 📊 Partie 2 : Monitoring (Surveillance)

### 1. Uptime Kuma (Disponibilité)
*   **Quoi :** Un tableau de bord type "Status Page".
*   **Fonction :** Ping votre API (`/health`) toutes les 60 secondes.
*   **Alerte :** Envoie un message (Telegram, Discord, Email) si le serveur tombe.
*   **Avis :** **Indispensable.** Très simple à installer (1 conteneur Docker).

### 2. Dozzle (Logs en temps réel)
*   **Quoi :** Visionneuse de logs Docker via le web.
*   **Fonction :** Permet de voir les logs de `api` et `nginx` sans se connecter en SSH.
*   **Avis :** Très pratique pour le débogage rapide.

### 3. Portainer (Gestion Conteneurs)
*   **Quoi :** GUI pour Docker.
*   **Fonction :** Permet de redémarrer les conteneurs, voir l'utilisation CPU/RAM, nettoyer les images inutilisées.
*   **Avis :** Utile pour la maintenance globale du VPS.

---

## 🚀 Plan d'Action Proposé

Je suggère l'approche **"Smart & Visual"** (Option GUI) pour vous faciliter la vie :

1.  **Architecture Cible :**
    *   `Nginx Proxy Manager` (Port 80/443) -> Reçoit tout le trafic.
    *   `Backend API` (Interne) -> Reçoit le trafic via le réseau Docker.
    *   `Uptime Kuma` (Interne) -> Surveille le tout.
    *   `Dozzle` (Interne/Privé) -> Pour voir les logs.

2.  **Étapes de Migration :**
    *   [ ] Acheter/Configurer un domaine (ex: ovh, namecheap).
    *   [ ] Modifier `docker-compose.yml` pour inclure ces nouveaux services.
    *   [ ] Configurer les certificats via l'interface web de Proxy Manager.

**Qu'en pensez-vous ? On part sur cette stack "Nginx Proxy Manager + Uptime Kuma" ?**
