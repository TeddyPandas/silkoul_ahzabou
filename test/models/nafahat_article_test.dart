import 'package:flutter_test/flutter_test.dart';
import 'package:silkoul_ahzabou/models/nafahat_article.dart';

void main() {
  group('NafahatArticle Model Tests', () {
    group('fromJson', () {
      test('parses article from JSON correctly', () {
        final json = {
          'id': 'test-id-123',
          'title': 'Test Article Title',
          'title_ar': 'عنوان المقال للاختبار',
          'content': 'This is the content of the test article.',
          'content_ar': 'هذا هو محتوى المقال للاختبار.',
          'summary': 'Test summary',
          'summary_ar': 'ملخص الاختبار',
          'category': 'teaching',
          'status': 'published',
          'author_id': 'author-123',
          'author_name': 'Test Author',
          'author_name_ar': 'المؤلف الاختباري',
          'is_featured': true,
          'is_verified': true,
          'view_count': 100,
          'like_count': 50,
          'share_count': 25,
          'tags': ['test', 'article'],
          'tags_ar': ['اختبار', 'مقال'],
          'estimated_read_time': 5,
          'difficulty_level': 'beginner',
          'source': 'Test Source',
          'source_ar': 'مصدر الاختبار',
          'image_url': 'https://example.com/image.jpg',
          'published_at': '2024-12-24T12:00:00.000Z',
          'updated_at': '2024-12-24T12:00:00.000Z',
        };

        final article = NafahatArticle.fromJson(json);

        expect(article.id, 'test-id-123');
        expect(article.title, 'Test Article Title');
        expect(article.titleAr, 'عنوان المقال للاختبار');
        expect(article.content, 'This is the content of the test article.');
        expect(article.contentAr, 'هذا هو محتوى المقال للاختبار.');
        expect(article.summary, 'Test summary');
        expect(article.summaryAr, 'ملخص الاختبار');
        expect(article.category, ArticleCategory.teaching);
        expect(article.status, ArticleStatus.published);
        expect(article.authorId, 'author-123');
        expect(article.authorName, 'Test Author');
        expect(article.authorNameAr, 'المؤلف الاختباري');
        expect(article.isFeatured, true);
        expect(article.isVerified, true);
        expect(article.viewCount, 100);
        expect(article.likeCount, 50);
        expect(article.shareCount, 25);
        expect(article.tags, ['test', 'article']);
        expect(article.tagsAr, ['اختبار', 'مقال']);
        expect(article.estimatedReadTime, 5);
        expect(article.difficultyLevel, DifficultyLevel.beginner);
        expect(article.source, 'Test Source');
        expect(article.sourceAr, 'مصدر الاختبار');
        expect(article.imageUrl, 'https://example.com/image.jpg');
        expect(article.publishedAt, isNotNull);
        expect(article.updatedAt, isNotNull);
      });

      test('handles minimal JSON correctly', () {
        final json = {
          'id': 'min-id',
          'title': 'Minimal Title',
          'title_ar': 'عنوان مختصر',
          'content': 'Minimal content',
          'content_ar': 'محتوى مختصر',
          'summary': 'Summary',
          'summary_ar': 'ملخص',
          'category': 'dhikr',
          'status': 'draft',
          'author_id': 'auth-1',
          'author_name': 'Author',
        };

        final article = NafahatArticle.fromJson(json);

        expect(article.id, 'min-id');
        expect(article.isFeatured, false);
        expect(article.isVerified, false);
        expect(article.viewCount, 0);
        expect(article.likeCount, 0);
        expect(article.shareCount, 0);
        expect(article.tags, isEmpty);
        expect(article.tagsAr, isEmpty);
        expect(article.estimatedReadTime, 5);
        expect(article.difficultyLevel, isNull);
        expect(article.source, isNull);
        expect(article.imageUrl, isNull);
      });

      test('handles null values gracefully', () {
        final json = {
          'id': 'null-test',
          'title': 'Title',
          'title_ar': 'عنوان',
          'content': 'Content',
          'content_ar': 'محتوى',
          'summary': 'Summary',
          'summary_ar': 'ملخص',
          'category': 'dhikr',
          'status': 'published',
          'author_id': 'auth-1',
          'author_name': 'Author',
          'view_count': null,
          'like_count': null,
          'share_count': null,
          'tags': null,
          'tags_ar': null,
        };

        final article = NafahatArticle.fromJson(json);

        expect(article.viewCount, 0);
        expect(article.likeCount, 0);
        expect(article.shareCount, 0);
        expect(article.tags, isEmpty);
        expect(article.tagsAr, isEmpty);
      });
    });

    group('toJson', () {
      test('serializes article to JSON correctly', () {
        final article = NafahatArticle(
          id: 'to-json-test',
          title: 'Test Title',
          titleAr: 'عنوان الاختبار',
          content: 'Test content',
          contentAr: 'محتوى الاختبار',
          summary: 'Summary',
          summaryAr: 'ملخص',
          category: ArticleCategory.fatwa,
          status: ArticleStatus.published,
          authorId: 'auth-123',
          authorName: 'Test Author',
          isFeatured: true,
          isVerified: false,
          viewCount: 10,
          likeCount: 5,
          shareCount: 2,
          tags: ['tag1', 'tag2'],
          tagsAr: ['وسم1', 'وسم2'],
          estimatedReadTime: 10,
          publishedAt: DateTime(2024, 12, 24),
        );

        final json = article.toJson();

        expect(json['id'], 'to-json-test');
        expect(json['title'], 'Test Title');
        expect(json['title_ar'], 'عنوان الاختبار');
        expect(json['category'], 'fatwa');
        expect(json['status'], 'published');
        expect(json['is_featured'], true);
        expect(json['is_verified'], false);
        expect(json['view_count'], 10);
        expect(json['tags'], ['tag1', 'tag2']);
        expect(json['tags_ar'], ['وسم1', 'وسم2']);
      });
    });

    group('copyWith', () {
      test('copies with new values', () {
        final article = NafahatArticle(
          id: 'copy-test',
          title: 'Original Title',
          titleAr: 'عنوان أصلي',
          content: 'Original content',
          contentAr: 'محتوى أصلي',
          summary: 'Original summary',
          summaryAr: 'ملخص أصلي',
          category: ArticleCategory.teaching,
          status: ArticleStatus.draft,
          authorId: 'auth-1',
          authorName: 'Author',
          viewCount: 0,
          likeCount: 0,
          shareCount: 0,
          publishedAt: DateTime.now(),
        );

        final copied = article.copyWith(
          title: 'New Title',
          status: ArticleStatus.published,
          viewCount: 100,
        );

        expect(copied.id, 'copy-test');
        expect(copied.title, 'New Title');
        expect(copied.titleAr, 'عنوان أصلي');
        expect(copied.status, ArticleStatus.published);
        expect(copied.viewCount, 100);
        expect(copied.likeCount, 0);
      });
    });

    group('isNew', () {
      test('returns true for articles published in the last 7 days', () {
        final article = NafahatArticle(
          id: 'new-test',
          title: 'New Article',
          titleAr: 'مقال جديد',
          content: 'Content',
          contentAr: 'محتوى',
          summary: 'Summary',
          summaryAr: 'ملخص',
          category: ArticleCategory.teaching,
          status: ArticleStatus.published,
          authorId: 'auth-1',
          authorName: 'Author',
          publishedAt: DateTime.now().subtract(const Duration(days: 3)),
        );

        expect(article.isNew, true);
      });

      test('returns false for old articles', () {
        final article = NafahatArticle(
          id: 'old-test',
          title: 'Old Article',
          titleAr: 'مقال قديم',
          content: 'Content',
          contentAr: 'محتوى',
          summary: 'Summary',
          summaryAr: 'ملخص',
          category: ArticleCategory.teaching,
          status: ArticleStatus.published,
          authorId: 'auth-1',
          authorName: 'Author',
          publishedAt: DateTime.now().subtract(const Duration(days: 10)),
        );

        expect(article.isNew, false);
      });
    });

    group('formattedPublishDate', () {
      test('returns "Aujourd\'hui" for articles published today', () {
        final article = NafahatArticle(
          id: 'today-test',
          title: 'Today Test',
          titleAr: 'اختبار اليوم',
          content: 'Content',
          contentAr: 'محتوى',
          summary: 'Summary',
          summaryAr: 'ملخص',
          category: ArticleCategory.teaching,
          status: ArticleStatus.published,
          authorId: 'auth-1',
          authorName: 'Author',
          publishedAt: DateTime.now(),
        );

        expect(article.formattedPublishDate, "Aujourd'hui");
      });

      test('returns "Hier" for articles published yesterday', () {
        final article = NafahatArticle(
          id: 'yesterday-test',
          title: 'Yesterday Test',
          titleAr: 'اختبار الأمس',
          content: 'Content',
          contentAr: 'محتوى',
          summary: 'Summary',
          summaryAr: 'ملخص',
          category: ArticleCategory.teaching,
          status: ArticleStatus.published,
          authorId: 'auth-1',
          authorName: 'Author',
          publishedAt: DateTime.now().subtract(const Duration(days: 1)),
        );

        expect(article.formattedPublishDate, 'Hier');
      });

      test('returns "Il y a X jours" for recent articles', () {
        final article = NafahatArticle(
          id: 'days-test',
          title: 'Days Test',
          titleAr: 'اختبار الأيام',
          content: 'Content',
          contentAr: 'محتوى',
          summary: 'Summary',
          summaryAr: 'ملخص',
          category: ArticleCategory.teaching,
          status: ArticleStatus.published,
          authorId: 'auth-1',
          authorName: 'Author',
          publishedAt: DateTime.now().subtract(const Duration(days: 5)),
        );

        expect(article.formattedPublishDate, 'Il y a 5 jours');
      });
    });

    group('incrementLikes/Views/Shares', () {
      test('incrementLikes increases likeCount by 1', () {
        final article = NafahatArticle(
          id: 'like-test',
          title: 'Like Test',
          titleAr: 'اختبار الإعجاب',
          content: 'Content',
          contentAr: 'محتوى',
          summary: 'Summary',
          summaryAr: 'ملخص',
          category: ArticleCategory.teaching,
          status: ArticleStatus.published,
          authorId: 'auth-1',
          authorName: 'Author',
          likeCount: 10,
          publishedAt: DateTime.now(),
        );

        final updated = article.incrementLikes();
        expect(updated.likeCount, 11);
      });

      test('incrementViews increases viewCount by 1', () {
        final article = NafahatArticle(
          id: 'view-test',
          title: 'View Test',
          titleAr: 'اختبار المشاهدة',
          content: 'Content',
          contentAr: 'محتوى',
          summary: 'Summary',
          summaryAr: 'ملخص',
          category: ArticleCategory.teaching,
          status: ArticleStatus.published,
          authorId: 'auth-1',
          authorName: 'Author',
          viewCount: 50,
          publishedAt: DateTime.now(),
        );

        final updated = article.incrementViews();
        expect(updated.viewCount, 51);
      });

      test('incrementShares increases shareCount by 1', () {
        final article = NafahatArticle(
          id: 'share-test',
          title: 'Share Test',
          titleAr: 'اختبار المشاركة',
          content: 'Content',
          contentAr: 'محتوى',
          summary: 'Summary',
          summaryAr: 'ملخص',
          category: ArticleCategory.teaching,
          status: ArticleStatus.published,
          authorId: 'auth-1',
          authorName: 'Author',
          shareCount: 5,
          publishedAt: DateTime.now(),
        );

        final updated = article.incrementShares();
        expect(updated.shareCount, 6);
      });

      test('decrementLikes decreases likeCount by 1', () {
        final article = NafahatArticle(
          id: 'unlike-test',
          title: 'Unlike Test',
          titleAr: 'اختبار إلغاء الإعجاب',
          content: 'Content',
          contentAr: 'محتوى',
          summary: 'Summary',
          summaryAr: 'ملخص',
          category: ArticleCategory.teaching,
          status: ArticleStatus.published,
          authorId: 'auth-1',
          authorName: 'Author',
          likeCount: 10,
          publishedAt: DateTime.now(),
        );

        final updated = article.decrementLikes();
        expect(updated.likeCount, 9);
      });

      test('decrementLikes does not go below 0', () {
        final article = NafahatArticle(
          id: 'zero-test',
          title: 'Zero Test',
          titleAr: 'اختبار الصفر',
          content: 'Content',
          contentAr: 'محتوى',
          summary: 'Summary',
          summaryAr: 'ملخص',
          category: ArticleCategory.teaching,
          status: ArticleStatus.published,
          authorId: 'auth-1',
          authorName: 'Author',
          likeCount: 0,
          publishedAt: DateTime.now(),
        );

        final updated = article.decrementLikes();
        expect(updated.likeCount, 0);
      });
    });
  });

  group('ArticleCategory Tests', () {
    test('fromString returns correct category', () {
      expect(ArticleCategory.fromString('teaching'), ArticleCategory.teaching);
      expect(
          ArticleCategory.fromString('biography'), ArticleCategory.biography);
      expect(ArticleCategory.fromString('litany'), ArticleCategory.litany);
      expect(ArticleCategory.fromString('story'), ArticleCategory.story);
      expect(ArticleCategory.fromString('fatwa'), ArticleCategory.fatwa);
      expect(ArticleCategory.fromString('poem'), ArticleCategory.poem);
      expect(ArticleCategory.fromString('dhikr'), ArticleCategory.dhikr);
      expect(ArticleCategory.fromString('dua'), ArticleCategory.dua);
      expect(ArticleCategory.fromString('wisdom'), ArticleCategory.wisdom);
      expect(ArticleCategory.fromString('history'), ArticleCategory.history);
    });

    test('fromString defaults to teaching for unknown values', () {
      expect(ArticleCategory.fromString('unknown'), ArticleCategory.teaching);
      expect(ArticleCategory.fromString(''), ArticleCategory.teaching);
    });

    test('each category has label, labelAr, icon, and colorValue', () {
      for (final category in ArticleCategory.values) {
        expect(category.label, isNotEmpty);
        expect(category.labelAr, isNotEmpty);
        expect(category.icon, isNotEmpty);
        expect(category.colorValue, isNonZero);
      }
    });
  });

  group('ArticleStatus Tests', () {
    test('fromString returns correct status', () {
      expect(ArticleStatus.fromString('draft'), ArticleStatus.draft);
      expect(ArticleStatus.fromString('review'), ArticleStatus.review);
      expect(ArticleStatus.fromString('published'), ArticleStatus.published);
      expect(ArticleStatus.fromString('archived'), ArticleStatus.archived);
    });

    test('fromString defaults to published for unknown values', () {
      expect(ArticleStatus.fromString('unknown'), ArticleStatus.published);
      expect(ArticleStatus.fromString(''), ArticleStatus.published);
    });
  });

  group('DifficultyLevel Tests', () {
    test('fromString returns correct level', () {
      expect(DifficultyLevel.fromString('beginner'), DifficultyLevel.beginner);
      expect(DifficultyLevel.fromString('intermediate'),
          DifficultyLevel.intermediate);
      expect(DifficultyLevel.fromString('advanced'), DifficultyLevel.advanced);
      expect(DifficultyLevel.fromString('scholar'), DifficultyLevel.scholar);
    });

    test('fromString defaults to beginner for unknown values', () {
      expect(DifficultyLevel.fromString('unknown'), DifficultyLevel.beginner);
      expect(DifficultyLevel.fromString(''), DifficultyLevel.beginner);
    });

    test('each level has label, labelAr, and colorValue', () {
      for (final level in DifficultyLevel.values) {
        expect(level.label, isNotEmpty);
        expect(level.labelAr, isNotEmpty);
        expect(level.colorValue, isNonZero);
      }
    });
  });
}
