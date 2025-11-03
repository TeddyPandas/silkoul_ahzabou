#!/bin/bash

# Script d'installation rapide pour Silkoul Ahzabou Tidiani Backend
# Ce script aide à configurer rapidement l'environnement de développement

echo "🕌 Silkoul Ahzabou Tidiani - Installation Backend"
echo "=================================================="
echo ""

# Vérifier Node.js
echo "📦 Vérification de Node.js..."
if ! command -v node &> /dev/null; then
    echo "❌ Node.js n'est pas installé!"
    echo "   Veuillez installer Node.js >= 16.x depuis https://nodejs.org"
    exit 1
fi

NODE_VERSION=$(node -v)
echo "✅ Node.js $NODE_VERSION détecté"
echo ""

# Vérifier npm
echo "📦 Vérification de npm..."
if ! command -v npm &> /dev/null; then
    echo "❌ npm n'est pas installé!"
    exit 1
fi

NPM_VERSION=$(npm -v)
echo "✅ npm $NPM_VERSION détecté"
echo ""

# Installer les dépendances
echo "📥 Installation des dépendances..."
npm install

if [ $? -ne 0 ]; then
    echo "❌ Erreur lors de l'installation des dépendances"
    exit 1
fi

echo "✅ Dépendances installées"
echo ""

# Créer le fichier .env s'il n'existe pas
if [ ! -f .env ]; then
    echo "📝 Création du fichier .env..."
    cp .env.example .env
    echo "✅ Fichier .env créé"
    echo ""
    echo "⚠️  IMPORTANT: Veuillez éditer le fichier .env avec vos propres valeurs:"
    echo "   - SUPABASE_URL"
    echo "   - SUPABASE_ANON_KEY"
    echo "   - SUPABASE_SERVICE_ROLE_KEY"
    echo ""
    echo "   Obtenez ces valeurs depuis votre projet Supabase:"
    echo "   https://supabase.com/dashboard"
    echo ""
else
    echo "✅ Fichier .env existe déjà"
    echo ""
fi

# Créer les dossiers nécessaires
echo "📁 Création des dossiers..."
mkdir -p logs
mkdir -p tmp
echo "✅ Dossiers créés"
echo ""

# Afficher les prochaines étapes
echo "=================================================="
echo "✨ Installation terminée avec succès!"
echo "=================================================="
echo ""
echo "📋 Prochaines étapes:"
echo ""
echo "1. Configurer Supabase:"
echo "   - Créer un projet sur https://supabase.com"
echo "   - Exécuter le script database/schema.sql dans l'éditeur SQL"
echo "   - Copier les clés API dans le fichier .env"
echo ""
echo "2. Éditer le fichier .env avec vos valeurs:"
echo "   nano .env"
echo ""
echo "3. Lancer le serveur de développement:"
echo "   npm run dev"
echo ""
echo "4. Tester l'API:"
echo "   curl http://localhost:3000/health"
echo ""
echo "=================================================="
echo "📚 Ressources utiles:"
echo "   - README.md - Documentation complète"
echo "   - DEPLOYMENT.md - Guide de déploiement"
echo "   - CONTRIBUTING.md - Guide de contribution"
echo "   - api-collection.json - Collection Postman/Thunder Client"
echo "=================================================="
echo ""
echo "🙏 Bismillah al-Rahman al-Rahim"
echo ""
