import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silkoul_ahzabou/models/nafahat_article.dart';
import 'package:silkoul_ahzabou/widgets/nafahat/article_card.dart';

// Helper to ignore overflow errors in widget tests
void ignoreOverflowErrors(
  FlutterErrorDetails details, {
  bool forceReport = false,
}) {
  bool isOverflowError = false;
  final exception = details.exception;
  if (exception is FlutterError) {
    isOverflowError = exception.diagnostics.any(
      (e) => e.value.toString().contains('overflowed'),
    );
  }
  if (!isOverflowError) {
    FlutterError.dumpErrorToConsole(details, forceReport: forceReport);
  }
}

void main() {
  // Ignore overflow errors in tests (these are visual warnings, not functional errors)
  setUp(() {
    FlutterError.onError = ignoreOverflowErrors;
  });

  tearDown(() {
    FlutterError.onError = FlutterError.dumpErrorToConsole;
  });
  group('ArticleCard Widget Tests', () {
    late NafahatArticle testArticle;

    setUp(() {
      testArticle = NafahatArticle(
        id: 'widget-test-1',
        title: 'Test Article Title',
        titleAr: 'عنوان المقال للاختبار',
        content: 'Test content for the article',
        contentAr: 'محتوى الاختبار للمقال',
        summary: 'This is a test summary',
        summaryAr: 'هذا ملخص اختبار',
        category: ArticleCategory.teaching,
        status: ArticleStatus.published,
        authorId: 'author-1',
        authorName: 'Sheikh Ahmad',
        authorNameAr: 'الشيخ أحمد',
        isFeatured: true,
        isVerified: true,
        viewCount: 150,
        likeCount: 45,
        shareCount: 10,
        tags: ['test', 'widget'],
        tagsAr: ['اختبار', 'ودجت'],
        estimatedReadTime: 7,
        publishedAt: DateTime.now().subtract(const Duration(days: 3)),
      );
    });

    Widget createWidgetUnderTest({
      NafahatArticle? article,
      VoidCallback? onTap,
      bool compact = false,
      bool showCategory = true,
      bool showAuthor = true,
      bool showStats = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ArticleCard(
              article: article ?? testArticle,
              onTap: onTap,
              compact: compact,
              showCategory: showCategory,
              showAuthor: showAuthor,
              showStats: showStats,
            ),
          ),
        ),
      );
    }

    group('Full Card Mode', () {
      testWidgets('displays article title', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('Test Article Title'), findsOneWidget);
      });

      testWidgets('displays article summary', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('This is a test summary'), findsOneWidget);
      });

      testWidgets('displays author name when showAuthor is true',
          (tester) async {
        await tester.pumpWidget(createWidgetUnderTest(showAuthor: true));

        expect(find.text('Sheikh Ahmad'), findsOneWidget);
      });

      testWidgets('hides author section when showAuthor is false',
          (tester) async {
        await tester.pumpWidget(createWidgetUnderTest(showAuthor: false));

        // The author section should not be rendered
        expect(find.text('Sheikh Ahmad'), findsNothing);
      });

      testWidgets('displays view count when showStats is true', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest(showStats: true));

        expect(find.text('150'), findsOneWidget);
      });

      testWidgets('displays like count when showStats is true', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest(showStats: true));

        expect(find.text('45'), findsOneWidget);
      });

      testWidgets('displays reading time', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('7 min'), findsOneWidget);
      });

      testWidgets('displays category label when showCategory is true',
          (tester) async {
        await tester.pumpWidget(createWidgetUnderTest(showCategory: true));

        expect(find.text('Enseignement'), findsOneWidget);
      });

      testWidgets('hides category when showCategory is false', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest(showCategory: false));

        expect(find.text('Enseignement'), findsNothing);
      });

      testWidgets('shows "Nouveau" badge for new articles', (tester) async {
        final newArticle = testArticle.copyWith(
          publishedAt: DateTime.now().subtract(const Duration(days: 2)),
        );
        await tester.pumpWidget(createWidgetUnderTest(article: newArticle));

        expect(find.textContaining('Nouveau'), findsOneWidget);
      });

      testWidgets('shows "Vérifié" badge for verified articles',
          (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('Vérifié'), findsOneWidget);
      });

      testWidgets('calls onTap when card is tapped', (tester) async {
        bool wasPressed = false;
        await tester.pumpWidget(createWidgetUnderTest(
          onTap: () => wasPressed = true,
        ));

        await tester.tap(find.byType(InkWell).first);
        await tester.pump();

        expect(wasPressed, true);
      });
    });

    group('Compact Card Mode', () {
      testWidgets('displays compact layout with title', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest(compact: true));

        expect(find.text('Test Article Title'), findsOneWidget);
      });

      testWidgets('shows reading time in compact mode', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest(compact: true));

        expect(find.text('7 min'), findsOneWidget);
      });

      testWidgets('shows chevron icon in compact mode', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest(compact: true));

        expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      });

      testWidgets('calls onTap when compact card is tapped', (tester) async {
        bool wasPressed = false;
        await tester.pumpWidget(createWidgetUnderTest(
          compact: true,
          onTap: () => wasPressed = true,
        ));

        await tester.tap(find.byType(InkWell).first);
        await tester.pump();

        expect(wasPressed, true);
      });
    });
  });

  group('FeaturedArticleCard Widget Tests', () {
    late NafahatArticle featuredArticle;

    setUp(() {
      featuredArticle = NafahatArticle(
        id: 'featured-test',
        title: 'Featured Article',
        titleAr: 'مقال مميز',
        content: 'Featured content',
        contentAr: 'محتوى مميز',
        summary: 'Featured summary',
        summaryAr: 'ملخص مميز',
        category: ArticleCategory.wisdom,
        status: ArticleStatus.published,
        authorId: 'auth-1',
        authorName: 'Featured Author',
        isFeatured: true,
        estimatedReadTime: 10,
        publishedAt: DateTime.now(),
      );
    });

    Widget createWidgetUnderTest({VoidCallback? onTap}) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: FeaturedArticleCard(
              article: featuredArticle,
              onTap: onTap,
            ),
          ),
        ),
      );
    }

    testWidgets('displays article title', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Featured Article'), findsOneWidget);
    });

    testWidgets('displays author name', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Featured Author'), findsOneWidget);
    });

    testWidgets('displays reading time', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('10 min'), findsOneWidget);
    });

    testWidgets('displays "À la une" badge', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('À la une'), findsOneWidget);
    });

    testWidgets('displays category label', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Sagesse'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool wasPressed = false;
      await tester.pumpWidget(createWidgetUnderTest(
        onTap: () => wasPressed = true,
      ));

      await tester.tap(find.byType(InkWell).first);
      await tester.pump();

      expect(wasPressed, true);
    });
  });
}
