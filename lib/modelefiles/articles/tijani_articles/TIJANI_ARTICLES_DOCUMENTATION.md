# 📚 Tijani Articles Feature - Documentation Complète

## Vue d'ensemble

Le système d'articles Tijani permet de publier, gérer et consulter du contenu spirituel lié à la Tariqa Tijaniyya. Il supporte le multilinguisme (français/arabe), différentes catégories de contenu, et offre une expérience de lecture optimisée.

---

## 🎯 Fonctionnalités Principales

### 1. **Types d'Articles**

Le système supporte 10 catégories d'articles :

| Catégorie | Description | Icon | Couleur |
|-----------|-------------|------|---------|
| **Enseignement** | Cours spirituels, explications | 📚 | Vert #0FA958 |
| **Biographie** | Vies des saints et maîtres | 👤 | Mauve #9B7EBD |
| **Litanie (Wird)** | Textes de dhikr et awrad | 📿 | Or #D4AF37 |
| **Récit** | Histoires spirituelles | 📖 | Bleu #3B82F6 |
| **Fatwa** | Avis religieux | ⚖️ | Rouge #EF4444 |
| **Poème** | Poésie spirituelle | ✍️ | Rose #EC4899 |
| **Dhikr** | Invocations et rappels | 🌟 | Vert #10B981 |
| **Dua** | Supplications | 🤲 | Violet #8B5CF6 |
| **Sagesse** | Paroles de sagesse | 💡 | Orange #F59E0B |
| **Histoire** | Contexte historique | 📜 | Indigo #6366F1 |

### 2. **Contenu Bilingue**

Chaque article contient :
- **Titre** en français et arabe
- **Contenu** en français et arabe
- **Résumé** en français et arabe
- **Tags** en français et arabe
- Support RTL complet pour l'arabe

### 3. **Engagement Utilisateur**

- ❤️ **Likes** : Les utilisateurs peuvent aimer les articles
- 👁️ **Vues** : Compteur automatique de vues
- 🔗 **Partages** : Partage sur réseaux sociaux
- 🔖 **Favoris** : Sauvegarder pour plus tard (à venir)
- 💬 **Commentaires** : Discussions (à venir)

### 4. **Recherche & Filtres**

- Recherche full-text en français et arabe
- Filtres par catégorie
- Filtres par tags
- Filtres par auteur
- Tri par popularité, date, vues

### 5. **Badges & Statuts**

- ⭐ **À la Une** : Articles mis en avant
- 🆕 **Nouveau** : Publié dans les 7 derniers jours
- ✅ **Vérifié** : Contenu validé par un érudit
- 📊 **Niveaux** : Débutant, Intermédiaire, Avancé, Érudit

---

## 📁 Structure du Projet

```
lib/
├── models/
│   └── tijani_article.dart          # Modèle Article + Enums
│
├── services/
│   └── tijani_article_service.dart  # CRUD + API Supabase
│
├── providers/
│   └── tijani_article_provider.dart # State Management
│
├── widgets/
│   └── article_card.dart            # Widget Carte Article
│
├── screens/
│   └── article_detail_screen.dart   # Écran Article Complet
│
└── database/
    └── tijani_articles_schema.sql   # Schéma SQL Supabase
```

---

## 🔧 Installation & Configuration

### Étape 1 : Copier les Fichiers

```bash
# Copier tous les fichiers dans votre projet
cp -r tijani_articles_feature/lib/* votre_projet/lib/
cp tijani_articles_feature/database/tijani_articles_schema.sql votre_projet/
```

### Étape 2 : Dépendances

Ajouter dans `pubspec.yaml` :

```yaml
dependencies:
  supabase_flutter: ^2.0.0
  provider: ^6.1.1
  share_plus: ^7.2.1  # Pour le partage
```

Installer :
```bash
flutter pub get
```

### Étape 3 : Configurer Supabase

1. **Créer la table dans Supabase** :
   - Ouvrir SQL Editor dans Supabase
   - Copier-coller `tijani_articles_schema.sql`
   - Exécuter le script

2. **Vérifier RLS** :
   - Les politiques de sécurité sont automatiquement créées
   - Vérifier dans Database > Policies

### Étape 4 : Configurer le Provider

Dans `main.dart` :

```dart
import 'package:provider/provider.dart';
import 'providers/tijani_article_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        // ... vos autres providers
        
        ChangeNotifierProvider(
          create: (_) => TijaniArticleProvider()..initialize(),
        ),
      ],
      child: MyApp(),
    ),
  );
}
```

### Étape 5 : Utiliser dans l'UI

#### Afficher une liste d'articles :

```dart
import 'package:provider/provider.dart';
import 'widgets/article_card.dart';
import 'providers/tijani_article_provider.dart';

class ArticlesListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Articles Tijani')),
      body: Consumer<TijaniArticleProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: provider.latestArticles.length,
            itemBuilder: (context, index) {
              final article = provider.latestArticles[index];
              return ArticleCard(
                article: article,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArticleDetailScreen(article: article),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

---

## 📖 Utilisation des Composants

### TijaniArticle (Modèle)

```dart
// Créer un article
final article = TijaniArticle(
  id: 'uuid',
  title: 'Les Vertus de la Tariqa',
  titleAr: 'فضائل الطريقة',
  content: 'Contenu...',
  contentAr: 'المحتوى...',
  summary: 'Résumé...',
  summaryAr: 'ملخص...',
  category: ArticleCategory.teaching,
  authorId: 'author-uuid',
  authorName: 'Sheikh Abdallah',
  publishedAt: DateTime.now(),
);

// Accéder aux propriétés
print(article.title);
print(article.formattedPublishDate);
print(article.isNew);
print(article.category.label);

// Incrémenter les stats
final updatedArticle = article.incrementLikes();
```

### TijaniArticleService (API)

```dart
final service = TijaniArticleService();

// Récupérer les articles
final articles = await service.getArticles(limit: 20);
final featured = await service.getFeaturedArticles();
final byCategory = await service.getArticlesByCategory(ArticleCategory.teaching);

// Rechercher
final results = await service.searchArticles('tariqa');

// Récupérer un article spécifique
final article = await service.getArticleById('article-id');

// Engagement
await service.incrementViewCount('article-id');
await service.likeArticle('article-id', 'user-id');
await service.incrementShareCount('article-id');

// Créer/Modifier (admin/auteur)
final newArticle = await service.createArticle(article);
final updated = await service.updateArticle(article);
```

### TijaniArticleProvider (State)

```dart
// Dans un widget
final provider = context.watch<TijaniArticleProvider>();

// Récupérer des articles
await provider.fetchLatestArticles();
await provider.fetchFeaturedArticles();
await provider.fetchArticlesByCategory(ArticleCategory.biography);

// Rechercher
await provider.searchArticles('dhikr');

// Filtrer
provider.setCategory(ArticleCategory.teaching);
provider.addTag('tariqa');

// Article actuel
await provider.setCurrentArticle(article);
final current = provider.currentArticle;
final related = provider.relatedArticles;

// Like/Unlike
await provider.toggleLike('article-id', 'user-id');

// Partager
await provider.shareArticle('article-id');

// Rafraîchir
await provider.refresh();
```

### ArticleCard (Widget)

```dart
// Carte complète
ArticleCard(
  article: article,
  onTap: () => navigateToDetail(article),
  showCategory: true,
  showAuthor: true,
  showStats: true,
  compact: false,
)

// Carte compacte
ArticleCard(
  article: article,
  onTap: () => navigateToDetail(article),
  compact: true,
)
```

### ArticleDetailScreen (Écran)

```dart
// Navigation vers détail
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ArticleDetailScreen(article: article),
  ),
);

// Fonctionnalités incluses :
// - Affichage complet de l'article
// - Basculement FR/AR
// - Like/Unlike
// - Partage
// - Articles liés
// - Scroll to top
```

---

## 🎨 Personnalisation

### Couleurs des Catégories

Modifier dans `lib/models/tijani_article.dart` :

```dart
/// Get color for category
String get color {
  switch (this) {
    case ArticleCategory.teaching:
      return '#0FA958';  // Votre couleur
    case ArticleCategory.biography:
      return '#9B7EBD';  // Votre couleur
    // ...
  }
}
```

### Style des Cartes

Modifier dans `lib/widgets/article_card.dart` :

```dart
// Bordure, ombres, espacements, etc.
Card(
  elevation: 2,  // Modifier ici
  shape: RoundedRectangleBShape(
    borderRadius: BorderRadius.circular(16),  // Modifier ici
  ),
  // ...
)
```

---

## 🔒 Sécurité (RLS)

Les politiques de sécurité sont automatiquement configurées :

### Articles
- ✅ **Lecture** : Tout le monde peut lire les articles publiés
- ✅ **Création** : Utilisateurs authentifiés peuvent créer
- ✅ **Modification** : Seul l'auteur peut modifier
- ✅ **Suppression** : Seul l'auteur peut supprimer

### Likes
- ✅ **Lecture** : Tout le monde peut voir les likes
- ✅ **Ajout** : Utilisateurs peuvent liker
- ✅ **Suppression** : Utilisateurs peuvent unliker

---

## 📊 Base de Données

### Table : tijani_articles

| Colonne | Type | Description |
|---------|------|-------------|
| id | UUID | Identifiant unique |
| title | TEXT | Titre français |
| title_ar | TEXT | Titre arabe |
| content | TEXT | Contenu français |
| content_ar | TEXT | Contenu arabe |
| summary | TEXT | Résumé français |
| summary_ar | TEXT | Résumé arabe |
| category | TEXT | Catégorie |
| author_id | UUID | Référence auteur |
| author_name | TEXT | Nom auteur |
| author_name_ar | TEXT | Nom arabe |
| image_url | TEXT | URL image |
| tags | TEXT[] | Tags français |
| tags_ar | TEXT[] | Tags arabes |
| status | TEXT | draft/review/published/archived |
| view_count | INTEGER | Nombre de vues |
| like_count | INTEGER | Nombre de likes |
| share_count | INTEGER | Nombre de partages |
| is_featured | BOOLEAN | À la une |
| is_verified | BOOLEAN | Vérifié |
| difficulty_level | TEXT | Niveau difficulté |
| estimated_read_time | INTEGER | Temps lecture (min) |
| published_at | TIMESTAMP | Date publication |
| created_at | TIMESTAMP | Date création |
| updated_at | TIMESTAMP | Date MAJ |

### Table : article_likes

| Colonne | Type | Description |
|---------|------|-------------|
| id | UUID | Identifiant unique |
| article_id | UUID | Référence article |
| user_id | UUID | Référence utilisateur |
| liked_at | TIMESTAMP | Date du like |

### Fonctions RPC

- `increment_article_views(article_id)` - Incrémente les vues
- `increment_article_likes(article_id)` - Incrémente les likes
- `decrement_article_likes(article_id)` - Décrémente les likes
- `increment_article_shares(article_id)` - Incrémente les partages

---

## 🧪 Tests

### Test du Service

```dart
void testArticleService() async {
  final service = TijaniArticleService();
  
  // Test récupération
  final articles = await service.getArticles();
  print('Articles récupérés : ${articles.length}');
  
  // Test recherche
  final results = await service.searchArticles('tariqa');
  print('Résultats recherche : ${results.length}');
  
  // Test par catégorie
  final teachings = await service.getArticlesByCategory(
    ArticleCategory.teaching
  );
  print('Enseignements : ${teachings.length}');
}
```

### Test du Provider

```dart
void testArticleProvider() async {
  final provider = TijaniArticleProvider();
  
  await provider.initialize();
  
  print('Featured: ${provider.featuredArticles.length}');
  print('Latest: ${provider.latestArticles.length}');
  
  await provider.searchArticles('dhikr');
  print('Search results: ${provider.searchResults.length}');
}
```

---

## 🚀 Cas d'Usage

### 1. Publier un Enseignement

```dart
final article = TijaniArticle(
  id: uuid.v4(),
  title: 'La Wazifa Quotidienne',
  titleAr: 'الورد اليومي',
  content: '''
La wazifa quotidienne de la Tariqa Tijaniyya...
  ''',
  contentAr: '''
الورد اليومي للطريقة التجانية...
  ''',
  summary: 'Guide complet de la wazifa',
  summaryAr: 'دليل كامل للورد',
  category: ArticleCategory.litany,
  authorId: currentUserId,
  authorName: 'Sheikh Abdallah',
  publishedAt: DateTime.now(),
  tags: ['wazifa', 'wird', 'dhikr'],
  tagsAr: ['ورد', 'أوراد', 'ذكر'],
  status: ArticleStatus.published,
  difficultyLevel: DifficultyLevel.beginner,
  estimatedReadTime: 10,
);

await service.createArticle(article);
```

### 2. Afficher Articles par Catégorie

```dart
class TeachingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TijaniArticleProvider>();
    
    return FutureBuilder(
      future: provider.fetchArticlesByCategory(ArticleCategory.teaching),
      builder: (context, snapshot) {
        final articles = provider.articlesByCategory[ArticleCategory.teaching] ?? [];
        
        return ListView.builder(
          itemCount: articles.length,
          itemBuilder: (context, index) => ArticleCard(
            article: articles[index],
            onTap: () => navigateToDetail(articles[index]),
          ),
        );
      },
    );
  }
}
```

### 3. Recherche d'Articles

```dart
class SearchArticlesScreen extends StatefulWidget {
  @override
  _SearchArticlesScreenState createState() => _SearchArticlesScreenState();
}

class _SearchArticlesScreenState extends State<SearchArticlesScreen> {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TijaniArticleProvider>();

    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher...',
            suffixIcon: IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                provider.searchArticles(_searchController.text);
              },
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: provider.searchResults.length,
            itemBuilder: (context, index) => ArticleCard(
              article: provider.searchResults[index],
              compact: true,
            ),
          ),
        ),
      ],
    );
  }
}
```

---

## 📈 Statistiques & Analytics

### Métriques Disponibles

```dart
// Par article
final views = article.viewCount;
final likes = article.likeCount;
final shares = article.shareCount;
final isPopular = views > 1000;

// Globales
final provider = TijaniArticleProvider();
final popularArticles = await service.getPopularArticles();
final counts = await service.getArticleCountByCategory();

print('Enseignements: ${counts[ArticleCategory.teaching]}');
print('Biographies: ${counts[ArticleCategory.biography]}');
```

---

## 🎯 Prochaines Améliorations

- [ ] Commentaires sur articles
- [ ] Système de favoris/bookmarks
- [ ] Notifications push pour nouveaux articles
- [ ] Mode lecture nocturne
- [ ] Téléchargement offline
- [ ] Audio des articles (text-to-speech)
- [ ] Citations/highlights
- [ ] Système de notes personnelles

---

## 🆘 Troubleshooting

### Problème : Articles ne s'affichent pas

**Solution** : Vérifier RLS policies dans Supabase

### Problème : Erreur de compilation

**Solution** : Vérifier que toutes les dépendances sont installées

### Problème : Likes ne fonctionnent pas

**Solution** : Vérifier que l'utilisateur est authentifié

---

**Documentation créée pour Silkoul Ahzabou Tidiani** 🕌

Version : 1.0.0  
Date : 24 Décembre 2025
