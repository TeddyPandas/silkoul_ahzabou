# 📱 Assets Zikr - Guide d'Utilisation

## 📂 Structure des Dossiers

```
zikr_assets/
├── logo/                          # Logos et icônes d'application
│   ├── original_logo.jpg          # Logo source original
│   ├── app_logo_512.png           # Pour store listings
│   ├── app_logo_1024.png          # Pour iOS App Store
│   ├── app_icon_192.png           # Android adaptive icon
│   ├── app_icon_144.png           # Web
│   └── app_icon_72.png            # Notifications
│
├── icons/navigation/              # Icônes de la barre de navigation
│   ├── home.png                   # 80x80px
│   ├── campaigns.png              # 80x80px
│   ├── community.png              # 80x80px
│   └── profile.png                # 80x80px
│
├── illustrations/                 # Illustrations pour les campagnes
│   ├── ramadan_campaign.png       # 400x300px
│   ├── daily_zikr_campaign.png    # 400x300px
│   └── community_campaign.png     # 400x300px
│
├── backgrounds/                   # Fonds d'écran
│   ├── splash_screen.png          # 1080x1920px
│   └── campaign_card_bg.png       # 350x200px
│
└── placeholders/                  # Images par défaut
    └── avatar_placeholder.png     # 200x200px
```

## 🎨 Palette de Couleurs

### Couleurs Principales
- **Vert Foncé**: `#2D5F5D` (RGB: 45, 95, 93)
- **Vert Moyen**: `#4A9B8E` (RGB: 74, 155, 142)
- **Vert Clair**: `#6BC4B8` (RGB: 107, 196, 184)
- **Mauve**: `#8B6F9F` (RGB: 139, 111, 159)
- **Mauve Clair**: `#B19CD9` (RGB: 177, 156, 217)
- **Blanc**: `#FFFFFF`
- **Gris**: `#757575`

## 📥 Installation dans Flutter

### 1. Copier les assets dans votre projet Flutter

```bash
# Depuis le dossier racine de votre projet Flutter
mkdir -p assets/images assets/icons assets/backgrounds

# Copier les assets générés
cp -r /home/claude/zikr_assets/logo/* assets/images/
cp -r /home/claude/zikr_assets/icons/* assets/icons/
cp -r /home/claude/zikr_assets/illustrations/* assets/images/
cp -r /home/claude/zikr_assets/backgrounds/* assets/backgrounds/
cp -r /home/claude/zikr_assets/placeholders/* assets/images/
```

### 2. Configuration du pubspec.yaml

Ajoutez dans votre `pubspec.yaml`:

```yaml
flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/icons/navigation/
    - assets/backgrounds/
```

### 3. Configuration des icônes d'application

#### Android (android/app/src/main/res/)

Copiez les logos dans les dossiers mipmap:
```bash
# Utilisez app_icon_192.png pour toutes les tailles
cp assets/images/app_icon_192.png android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
cp assets/images/app_icon_144.png android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
cp assets/images/app_icon_72.png android/app/src/main/res/mipmap-hdpi/ic_launcher.png
```

#### iOS (ios/Runner/Assets.xcassets/AppIcon.appiconset/)

Utilisez `app_logo_1024.png` et générez les tailles avec un outil comme:
- [App Icon Generator](https://appicon.co/)
- Xcode directement

### 4. Générer les icônes automatiquement avec flutter_launcher_icons

Ajoutez dans `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/images/app_logo_512.png"
  adaptive_icon_background: "#2D5F5D"
  adaptive_icon_foreground: "assets/images/app_logo_512.png"
```

Puis exécutez:
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

## 🔤 Polices Recommandées

### Téléchargement des Polices

#### 1. Police Arabe - Amiri
- **URL**: https://fonts.google.com/specimen/Amiri
- **Télécharger**: Cliquez sur "Download family"
- **Installation**: Extraire dans `assets/fonts/arabic/`

#### 2. Police Anglaise - Poppins
- **URL**: https://fonts.google.com/specimen/Poppins
- **Télécharger**: Cliquez sur "Download family"
- **Installation**: Extraire dans `assets/fonts/english/`

### Configuration des polices dans pubspec.yaml

```yaml
flutter:
  fonts:
    - family: Amiri
      fonts:
        - asset: assets/fonts/arabic/Amiri-Regular.ttf
        - asset: assets/fonts/arabic/Amiri-Bold.ttf
          weight: 700
    
    - family: Poppins
      fonts:
        - asset: assets/fonts/english/Poppins-Regular.ttf
        - asset: assets/fonts/english/Poppins-Medium.ttf
          weight: 500
        - asset: assets/fonts/english/Poppins-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/english/Poppins-Bold.ttf
          weight: 700
```

## 💻 Utilisation dans le Code

### Afficher le logo

```dart
Image.asset(
  'assets/images/app_logo_512.png',
  width: 100,
  height: 100,
)
```

### Utiliser les icônes de navigation

```dart
BottomNavigationBar(
  items: [
    BottomNavigationBarItem(
      icon: Image.asset('assets/icons/navigation/home.png', width: 24),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Image.asset('assets/icons/navigation/campaigns.png', width: 24),
      label: 'Campaigns',
    ),
    BottomNavigationBarItem(
      icon: Image.asset('assets/icons/navigation/community.png', width: 24),
      label: 'Community',
    ),
    BottomNavigationBarItem(
      icon: Image.asset('assets/icons/navigation/profile.png', width: 24),
      label: 'Profile',
    ),
  ],
)
```

### Utiliser les couleurs du thème

```dart
// lib/utils/app_colors.dart
class AppColors {
  static const Color tealPrimary = Color(0xFF2D5F5D);
  static const Color tealLight = Color(0xFF4A9B8E);
  static const Color tealAccent = Color(0xFF6BC4B8);
  static const Color mauve = Color(0xFF8B6F9F);
  static const Color mauveLight = Color(0xFFB19CD9);
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray = Color(0xFF757575);
}
```

### Configurer le thème de l'app

```dart
// main.dart
MaterialApp(
  theme: ThemeData(
    primaryColor: AppColors.tealPrimary,
    scaffoldBackgroundColor: AppColors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.tealPrimary,
      primary: AppColors.tealPrimary,
      secondary: AppColors.tealAccent,
    ),
    fontFamily: 'Poppins',
    textTheme: TextTheme(
      bodyLarge: TextStyle(fontFamily: 'Amiri'),
      bodyMedium: TextStyle(fontFamily: 'Poppins'),
    ),
  ),
)
```

## 📊 Tailles Recommandées

| Asset Type | Taille | Format | Usage |
|------------|--------|--------|-------|
| Logo Store | 512x512 | PNG | Play Store, promotions |
| Logo iOS | 1024x1024 | PNG | App Store |
| Icon Adaptive | 192x192 | PNG | Android launcher |
| Icon Web | 144x144 | PNG | PWA, web |
| Splash Screen | 1080x1920 | PNG | Écran de démarrage |
| Nav Icons | 80x80 | PNG | Navigation bar |
| Campaign Cards | 400x300 | PNG | Illustrations |
| Avatar | 200x200 | PNG | Profil utilisateur |

## 🎯 Prochaines Étapes

1. ✅ Assets de base générés
2. ⬜ Télécharger et installer les polices (Amiri + Poppins)
3. ⬜ Copier les assets dans le projet Flutter
4. ⬜ Configurer pubspec.yaml
5. ⬜ Générer les icônes launcher
6. ⬜ Tester sur émulateur/device

## 🔧 Outils Recommandés

- **Image Optimization**: [TinyPNG](https://tinypng.com/) - Compresser les PNG
- **Icon Generator**: [App Icon Generator](https://appicon.co/)
- **Color Picker**: [Coolors](https://coolors.co/)
- **SVG Editor**: [Figma](https://figma.com/) ou [Inkscape](https://inkscape.org/)

## 📝 Notes

- Tous les assets sont en PNG pour une meilleure qualité
- Les couleurs utilisent la palette vert/blanc/mauve du design original
- Les icônes de navigation sont simples et minimalistes
- Le splash screen utilise le logo original avec gradient

---

**Créé avec ❤️ pour l'application Zikr - Silkoul Ahzabou Tidiani**
