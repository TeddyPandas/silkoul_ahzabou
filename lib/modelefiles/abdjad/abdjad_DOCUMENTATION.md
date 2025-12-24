Documentation Projet : Nombres en Son (Abjad & 3D)
📝 Présentation du Projet

Cette application est une plateforme interactive qui convertit des données textuelles et numériques en une expérience sensorielle (audio et visuelle). Elle s'appuie sur le système numérique traditionnel Abjad pour la langue arabe et sur la puissance du GPU via Three.js pour la partie visuelle.
🛠 Pile Technologique

    Frontend : HTML5, CSS3 Moderne.

    Moteur Audio : Web Audio API (Live & Offline Rendering).

    Moteur 3D : Three.js (WebGL) avec système de particules.

    Langage : JavaScript ES6+ (Modules).

    Algorithmes : Mapping Abjad, Enveloppes ADSR, Conversion Buffer-to-WAV.

🚀 Fonctionnalités Clés

    Synthèse Musicale : Transformation de texte (Latin/Arabe) et nombres en mélodies.

    Calculateur Abjad : Outil intégré pour obtenir la valeur numérique d'un texte arabe.

    Visualisation 3D Réactive : Une nébuleuse de 8 000 particules qui "danse" selon les fréquences audio.

    Export WAV : Possibilité de télécharger la mélodie générée en haute qualité.

    Contrôles Avancés : Choix des gammes, type d'onde, durée, et réglages de l'accentuation.

📋 Plan d'Implémentation (Steps)
Phase 1 : Infrastructure et Audio de base

    Step 1 : Mise en place de l'AudioContext et de la chaîne de gain.

    Step 2 : Implémentation du parsing (Latin -> 1-26, Arabe -> Abjad 1-1000).

    Step 3 : Création de l'enveloppe ADSR pour adoucir le son.

Phase 2 : Visualisation 3D (Three.js)

    Step 4 : Initialisation de la scène Three.js avec un rendu performant.

    Step 5 : Création du système de particules via BufferGeometry.

    Step 6 : Liaison de l'AnalyserNode aux positions Y des particules pour la réactivité.

Phase 3 : Fonctionnalités Avancées

    Step 7 : Intégration du calculateur Abjad indépendant.

    Step 8 : Développement de la logique d'exportation via OfflineAudioContext.

    Step 9 : Ajout des OrbitControls pour permettre à l'utilisateur d'explorer la scène 3D.

Phase 4 : Optimisation et Déploiement

    Step 10 : Gestion du responsive design pour le canvas 3D.

    Step 11 : Tests de compatibilité sur serveur local (CORS).

phase 5 : Evolution future
    Partage social : Générer une image de la visualisation pour accompagner le fichier WAV.
    

Structure de l'application Flutter


lib/
├── core/
│   ├── abjad_engine.dart      # Logique de calcul (Abjad/Séquentiel)
│   └── audio_engine.dart      # Synthèse et ADSR
├── screens/
│   ├── calculators/
│   │   ├── particle_visualizer.dart # Visualisation 3D (Shaders)
│   │   └── control_panel.dart       # Sliders et Inputs
│   
├── shaders/
│   └── particles.frag         # Code GLSL pour les particules



Pour recréer l'effet de "nébuleuse de particules dansantes" en Flutter sans utiliser de moteur de jeu lourd comme Unity, nous allons utiliser une approche "bas niveau" mais très performante : le CustomPainter combiné à des mathématiques vectorielles 3D.
Le concept technique en Flutter

    Les Données (Le Modèle) : Nous allons créer une liste de milliers d'objets Particle. Chaque particule aura une position 3D (x, y, z), une couleur et une vitesse.

    Le Moteur Physique (L'Animation) : À chaque rafraîchissement de l'écran (environ 60 fois par seconde), nous allons mettre à jour la position de chaque particule. Nous simulerons une rotation globale de la caméra pour donner un effet de profondeur.

    Le Rendu (Le Peintre) : C'est le cœur du système. Le CustomPainter va prendre ces coordonnées 3D et les "projeter" sur l'écran 2D de votre téléphone.

        Perspective : Plus une particule est loin (Z grand), plus elle sera dessinée petite et proche du centre.

    La Réactivité Audio : Quand le son joue, nous allons "injecter" de l'énergie dans le système, poussant les particules vers l'extérieur pour créer l'effet d'explosion/danse.
    
    Pour gérer facilement la 3D (vecteurs, matrices), nous avons besoin d'un package mathématique standard de Flutter.

Ajoutez ceci à votre pubspec.yaml :
