#!/bin/bash

# Script de démarrage rapide pour Silkoul Ahzabou Tidiani Backend
# Ce script aide à extraire et configurer rapidement le backend

echo "🕌 Silkoul Ahzabou Tidiani - Backend Setup"
echo "=========================================="
echo ""

# Vérifier si l'archive existe
if [ ! -f "silkoul-ahzabou-backend.tar.gz" ]; then
    echo "❌  Erreur: Archive silkoul-ahzabou-backend.tar.gz non trouvée"
    echo "   Veuillez télécharger l'archive d'abord"
    exit 1
fi

# Extraire l'archive
echo "📦 Extraction de l'archive..."
tar -xzf silkoul-ahzabou-backend.tar.gz

if [ $? -ne 0 ]; then
    echo "❌ Erreur lors de l'extraction"
    exit 1
fi

echo "✅ Archive extraite"
echo ""

# Aller dans le dossier
cd backend

# Afficher les instructions
echo "=========================================="
echo "✨ Extraction réussie!"
echo "=========================================="
echo ""
echo "📋 Prochaines étapes:"
echo ""
echo "1. Installer Node.js (si pas déjà fait):"
echo "   https://nodejs.org/"
echo ""
echo "2. Installer les dépendances:"
echo "   cd backend"
echo "   npm install"
echo ""
echo "3. Configurer Supabase:"
echo "   - Créer un compte sur https://supabase.com"
echo "   - Créer un nouveau projet"
echo "   - Exécuter database/schema.sql dans SQL Editor"
echo ""
echo "4. Configurer les variables d'environnement:"
echo "   cp .env.example .env"
echo "   nano .env"
echo ""
echo "5. Lancer le serveur:"
echo "   npm run dev"
echo ""
echo "=========================================="
echo "📚 Documentation disponible:"
echo "   - README.md"
echo "   - DEPLOYMENT.md"
echo "   - API_EXAMPLES.md"
echo "=========================================="
echo ""
echo "🙏 Bismillah al-Rahman al-Rahim"
echo ""
