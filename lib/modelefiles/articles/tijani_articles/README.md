# 📚 Modélisation Articles Tijani - Package Complet

> Système complet de gestion d'articles spirituels pour la Tariqa Tijaniyya

---

## 📦 Contenu du Package

```
tijani_articles/
│
├── 📖 DOCUMENTATION
│   ├── TIJANI_ARTICLES_DOCUMENTATION.md    # Documentation complète (30 pages)
│   ├── QUICK_REFERENCE.md                  # Guide rapide (5 min)
│   └── README.md                            # Ce fichier
│
├── 💻 CODE SOURCE
│   ├── lib/
│   │   ├── models/
│   │   │   └── tijani_article.dart         # Modèle Article + Enums (400 lignes)
│   │   │
│   │   ├── services/
│   │   │   └── tijani_article_service.dart # Service API Supabase (350 lignes)
│   │   │
│   │   ├── providers/
│   │   │   └── tijani_article_provider.dart # State Management (300 lignes)
│   │   │
│   │   ├── widgets/
│   │   │   └── article_card.dart           # Widget Carte Article (400 lignes)
│   │   │
│   │   └── screens/
│   │       └── article_detail_screen.dart  # Écran Détail Complet (450 lignes)
│   │
│   └── database/
│       └── tijani_articles_schema.sql      # Schéma SQL Supabase (350 lignes)
│
└── 📊 STATISTIQUES
    • Lignes de code : ~2250
    • Fichiers : 8
    • Temps d'installation : 10-15 min
    • Niveau : Intermédiaire
```

---

## ✨ Fonctionnalités

### 📝 **10 Types d'Articles**

- 📚 **Enseignement** - Cours spirituels
- 👤 **Biographie** - Vies des saints
- 📿 **Litanie (Wird)** - Textes de dhikr
- 📖 **Récit** - Histoires spirituelles
- ⚖️ **Fatwa** - Avis religieux
- ✍️ **Poème** - Poésie spirituelle
- 🌟 **Dhikr** - Invocations
- 🤲 **Dua** - Supplications
- 💡 **Sagesse** - Paroles de sagesse
- 📜 **Histoire** - Contexte historique

### 🌍 **Bilingue FR/AR**

- Titre, contenu, résumé en 2 langues
- Tags multilingues
- Support RTL complet
- Basculement FR ↔ AR dans l'interface

### 💖 **Engagement Utilisateur**

- ❤️ Système de likes
- 👁️ Compteur de vues
- 🔗 Partage sur réseaux sociaux
- 📊 Statistiques détaillées

### 🔍 **Recherche & Filtres**

- Recherche full-text FR + AR
- Filtres par catégorie
- Filtres par tags
- Filtres par auteur
- Tri par popularité/date

### ⭐ **Badges & Statuts**

- ⭐ À la Une
- 🆕 Nouveau (< 7j)
- ✅ Vérifié
- 📊 Niveaux (Débutant → Érudit)

---

## 🚀 Installation Rapide

### 1. **Copier les Fichiers** (2 min)

```bash
# Copier tout le dossier lib/ dans votre projet
cp -r tijani_articles/lib/* votre_projet/lib/

# Copier le schéma SQL
cp tijani_articles/database/tijani_articles_schema.sql votre_projet/
```

### 2. **Installer Dépendances** (2 min)

```yaml
# pubspec.yaml
dependencies:
  supabase_flutter: ^2.0.0
  provider: ^6.1.1
  share_plus: ^7.2.1
```

```bash
flutter pub get
```

### 3. **Configurer Supabase** (3 min)

1. Ouvrir Supabase SQL Editor
2. Copier-coller `tijani_articles_schema.sql`
3. Exécuter le script
4. ✅ Tables, RLS et fonctions créées !

### 4. **Configurer Provider** (2 min)

```dart
// main.dart
import 'providers/tijani_article_provider.dart';

MultiProvider(
  providers: [
    ChangeNotifierProvider(
      create: (_) => TijaniArticleProvider()..initialize(),
    ),
  ],
  child: MyApp(),
)
```

### 5. **Utiliser dans l'UI** (1 min)

```dart
// Afficher une liste d'articles
Consumer<TijaniArticleProvider>(
  builder: (context, provider, _) {
    return ListView.builder(
      itemCount: provider.latestArticles.length,
      itemBuilder: (context, i) => ArticleCard(
        article: provider.latestArticles[i],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArticleDetailScreen(
              article: provider.latestArticles[i],
            ),
          ),
        ),
      ),
    );
  },
)
```

**🎉 C'est terminé ! L'app affiche maintenant les articles !**

---

## 📖 Documentation

### Pour Commencer

1. **QUICK_REFERENCE.md** (5 min)
   - Installation pas à pas
   - Exemples de code
   - Cheat sheet

2. **TIJANI_ARTICLES_DOCUMENTATION.md** (30 min)
   - Guide complet
   - Architecture détaillée
   - Cas d'usage avancés
   - API complète

### Ordre de Lecture

```
Débutant    : QUICK_REFERENCE.md
Intermédiaire : README.md (ce fichier)
Avancé      : TIJANI_ARTICLES_DOCUMENTATION.md
```

---

## 🎯 Exemples d'Utilisation

### Créer un Article

```dart
final article = TijaniArticle(
  id: uuid.v4(),
  title: 'Les Vertus de la Tariqa Tijaniyya',
  titleAr: 'فضائل الطريقة التجانية',
  content: 'Contenu complet en français...',
  contentAr: 'المحتوى الكامل بالعربية...',
  summary: 'Introduction aux vertus...',
  summaryAr: 'مقدمة للفضائل...',
  category: ArticleCategory.teaching,
  authorId: currentUser.id,
  authorName: 'Sheikh Abdallah',
  tags: ['tariqa', 'tijaniyya', 'spiritualité'],
  tagsAr: ['طريقة', 'تجانية', 'روحانية'],
  publishedAt: DateTime.now(),
  status: ArticleStatus.published,
);

await service.createArticle(article);
```

### Rechercher des Articles

```dart
final provider = context.read<TijaniArticleProvider>();

// Recherche
await provider.searchArticles('tariqa');

// Filtrer par catégorie
provider.setCategory(ArticleCategory.teaching);

// Filtrer par tag
provider.addTag('dhikr');

// Afficher les résultats
ListView(
  children: provider.searchResults.map(
    (article) => ArticleCard(article: article)
  ).toList(),
)
```

### Afficher un Article

```dart
// Navigation
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ArticleDetailScreen(article: article),
  ),
);

// Fonctionnalités incluses :
// ✅ Affichage complet FR + AR
// ✅ Basculement de langue
// ✅ Like/Unlike
// ✅ Partage
// ✅ Articles liés
// ✅ Scroll to top
```

---

## 🗄️ Base de Données

### Tables

**tijani_articles** - Articles principaux
- 25 colonnes
- Support bilingue complet
- Métriques d'engagement
- Métadonnées flexibles (JSONB)

**article_likes** - Likes utilisateurs
- Relation many-to-many
- Constraint unique (1 like/user/article)

### RLS Policies

✅ **Sécurité** configurée automatiquement :
- Lecture publique (articles publiés)
- Modification par auteur uniquement
- Likes gérés par utilisateur

### Fonctions RPC

```sql
increment_article_views(article_id)
increment_article_likes(article_id)
decrement_article_likes(article_id)
increment_article_shares(article_id)
```

---

## 📊 Statistiques du Package

| Métrique | Valeur |
|----------|--------|
| **Lignes de code** | 2250+ |
| **Fichiers Dart** | 5 |
| **Fichiers SQL** | 1 |
| **Documentation** | 2 (45 pages) |
| **Temps d'installation** | 10-15 min |
| **Dépendances** | 3 |
| **Tables DB** | 2 |
| **RLS Policies** | 8 |
| **Fonctions RPC** | 4 |
| **Catégories** | 10 |
| **Langues** | 2 (FR/AR) |

---

## 🎨 Personnalisation

### Couleurs des Catégories

Modifier dans `lib/models/tijani_article.dart` :

```dart
String get color {
  switch (this) {
    case ArticleCategory.teaching:
      return '#0FA958';  // Votre couleur
    // ...
  }
}
```

### Style des Widgets

Tous les widgets sont personnalisables :
- Cartes : `lib/widgets/article_card.dart`
- Écran détail : `lib/screens/article_detail_screen.dart`

---

## ✅ Checklist d'Installation

- [ ] Copier fichiers lib/
- [ ] Copier fichier SQL
- [ ] Ajouter dépendances pubspec.yaml
- [ ] `flutter pub get`
- [ ] Exécuter SQL dans Supabase
- [ ] Configurer provider dans main.dart
- [ ] Tester affichage articles
- [ ] Tester navigation vers détail
- [ ] Tester recherche
- [ ] Tester likes
- [ ] ✅ Installation complète !

---

## 🔧 Support

### En cas de problème

1. Vérifier que toutes les dépendances sont installées
2. Vérifier que le SQL a été exécuté dans Supabase
3. Vérifier les RLS policies
4. Consulter la documentation complète

### Resources

- **Guide rapide** : `QUICK_REFERENCE.md`
- **Documentation complète** : `TIJANI_ARTICLES_DOCUMENTATION.md`
- **Supabase Docs** : https://supabase.com/docs

---

## 🎯 Prochaines Améliorations

- [ ] Commentaires sur articles
- [ ] Favoris/Bookmarks
- [ ] Mode lecture nocturne
- [ ] Téléchargement offline
- [ ] Audio des articles (TTS)
- [ ] Système de citations
- [ ] Notes personnelles

---

## 📜 License

MIT License - Libre d'utilisation pour votre projet

---

## 🙏 Crédits

**Made with ❤️ for Silkoul Ahzabou Tidiani** 🕌

---

**Bismillah al-Rahman al-Rahim**

Version : 1.0.0  
Date : 24 Décembre 2025  
Auteur : Claude (Anthropic)

---

## 🚀 Commencer Maintenant !

```bash
# 1. Lire le guide rapide
cat QUICK_REFERENCE.md

# 2. Copier les fichiers
cp -r lib/* ../votre_projet/lib/

# 3. Installer
flutter pub get

# 4. Configurer Supabase
# (voir QUICK_REFERENCE.md)

# 5. Profiter ! 🎉
```
