import 'package:flutter_test/flutter_test.dart';
import 'package:silkoul_ahzabou/models/nafahat_article.dart';
import 'package:silkoul_ahzabou/providers/nafahat_provider.dart';

void main() {
  group('NafahatProvider Tests', () {
    late NafahatProvider provider;

    setUp(() {
      provider = NafahatProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    group('Initial State', () {
      test('initial state has empty lists', () {
        expect(provider.allArticles, isEmpty);
        expect(provider.featuredArticles, isEmpty);
        expect(provider.latestArticles, isEmpty);
        expect(provider.popularArticles, isEmpty);
        expect(provider.searchResults, isEmpty);
        expect(provider.relatedArticles, isEmpty);
        expect(provider.likedArticleIds, isEmpty);
      });

      test('initial state has no loading flags', () {
        expect(provider.isLoading, false);
        expect(provider.isFeaturedLoading, false);
        expect(provider.isSearching, false);
      });

      test('initial state has default pagination', () {
        expect(provider.hasMore, true);
        expect(provider.selectedCategory, isNull);
      });

      test('initial state has no error', () {
        expect(provider.error, isNull);
      });

      test('currentArticle is null initially', () {
        expect(provider.currentArticle, isNull);
      });

      test('searchQuery is empty initially', () {
        expect(provider.searchQuery, isEmpty);
      });
    });

    group('setCategory', () {
      test('sets selectedCategory correctly', () {
        provider.setCategory(ArticleCategory.dhikr);
        expect(provider.selectedCategory, ArticleCategory.dhikr);
      });

      test('setting null category resets to all articles', () {
        provider.setCategory(ArticleCategory.fatwa);
        expect(provider.selectedCategory, ArticleCategory.fatwa);

        provider.setCategory(null);
        expect(provider.selectedCategory, isNull);
      });

      test('changing category resets pagination', () {
        provider.setCategory(ArticleCategory.poem);
        expect(provider.hasMore, true);
      });
    });

    group('setCurrentArticle', () {
      test('sets current article', () {
        final article = _createTestArticle(id: 'current-test');
        provider.setCurrentArticle(article);

        expect(provider.currentArticle, isNotNull);
        expect(provider.currentArticle!.id, 'current-test');
      });
    });

    group('clearSearch', () {
      test('clears search state', () {
        provider.clearSearch();

        expect(provider.isSearching, false);
        expect(provider.searchResults, isEmpty);
        expect(provider.searchQuery, isEmpty);
      });
    });

    group('clear', () {
      test('clears all data', () {
        provider.setCategory(ArticleCategory.story);
        provider.clear();

        expect(provider.allArticles, isEmpty);
        expect(provider.featuredArticles, isEmpty);
        expect(provider.selectedCategory, isNull);
        expect(provider.currentArticle, isNull);
        expect(provider.hasMore, true);
        expect(provider.error, isNull);
      });
    });

    group('notifyListeners', () {
      test('notifies listeners when setCategory is called', () {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.setCategory(ArticleCategory.history);
        expect(notifyCount, greaterThan(0));
      });

      test('notifies listeners when setCurrentArticle is called', () {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.setCurrentArticle(_createTestArticle(id: 'notify-test'));
        expect(notifyCount, greaterThan(0));
      });

      test('notifies listeners when clearSearch is called', () {
        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        provider.clearSearch();
        expect(notifyCount, greaterThan(0));
      });
    });

    group('Tag Management', () {
      test('addTag adds tag to selectedTags', () {
        expect(provider.selectedTags, isEmpty);

        provider.addTag('test-tag');
        expect(provider.selectedTags, contains('test-tag'));
      });

      test('addTag does not add duplicate tags', () {
        provider.addTag('duplicate');
        provider.addTag('duplicate');

        expect(provider.selectedTags.where((t) => t == 'duplicate').length, 1);
      });

      test('removeTag removes tag from selectedTags', () {
        provider.addTag('remove-me');
        expect(provider.selectedTags, contains('remove-me'));

        provider.removeTag('remove-me');
        expect(provider.selectedTags, isNot(contains('remove-me')));
      });
    });

    group('clearFilters', () {
      test('clears category and tags', () {
        provider.setCategory(ArticleCategory.dua);
        provider.addTag('filter-tag');

        provider.clearFilters();

        expect(provider.selectedCategory, isNull);
        expect(provider.selectedTags, isEmpty);
        expect(provider.hasMore, true);
      });
    });
  });
}

/// Helper to create test article
NafahatArticle _createTestArticle({
  required String id,
  String title = 'Test Title',
  ArticleCategory category = ArticleCategory.teaching,
}) {
  return NafahatArticle(
    id: id,
    title: title,
    titleAr: 'عنوان الاختبار',
    content: 'Test content',
    contentAr: 'محتوى الاختبار',
    summary: 'Test summary',
    summaryAr: 'ملخص الاختبار',
    category: category,
    status: ArticleStatus.published,
    authorId: 'author-1',
    authorName: 'Test Author',
    publishedAt: DateTime.now(),
  );
}
