import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_snackbar.dart';
import 'package:dayaa_client/features/social_links/models/social_link.dart';
import 'package:dayaa_client/features/social_links/presentation/viewmodel/social_links_cubit.dart';
import 'package:dayaa_client/features/social_links/presentation/views/social_links_page.dart';
import 'package:dayaa_client/features/social_links/repositories/social_link_repository.dart';
import 'package:dayaa_client/features/social_links/usecases/list_social_links.dart';
import 'package:dayaa_client/features/social_links/usecases/save_social_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockSocialLinkRepository extends Mock implements SocialLinkRepository {}

/// «روابط التواصل» على الشاشة: سطرٌ لكل رابط باسم منصّته، و«حفظ» يرسلها كلّها.
///
/// Arrange - Act - Assert throughout.
void main() {
  const facebook = SocialLink(id: 12, url: 'https://facebook.com/alnoor.print');
  const instagram = SocialLink(id: 13, url: 'https://instagram.com/alnoor.print');

  late _MockSocialLinkRepository links;

  /// ما أعادته الشاشة لمن فتحها.
  Object? returned;

  setUpAll(() => registerFallbackValue(<SocialLinkInput>[]));

  setUp(() {
    links = _MockSocialLinkRepository();
    returned = null;
  });

  tearDown(() async {
    resetSnackBars();
    await sl.reset();
  });

  Future<void> open(WidgetTester tester, {List<SocialLink> saved = const [facebook, instagram]}) async {
    tester.view
      ..physicalSize = const Size(430, 932)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    when(() => links.list()).thenAnswer((_) async => Right(saved));

    sl.registerFactory<SocialLinksCubit>(
      () => SocialLinksCubit(list: ListSocialLinks(links), save: SaveSocialLinks(links)),
    );

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        // «حسابي» مكانَ الشاشة التي تفتحها وتلتقط ما تعيده.
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async => returned = await context.push<bool>(Routes.socialLinks),
                child: const Text('افتح الروابط'),
              ),
            ),
          ),
        ),
        GoRoute(path: Routes.socialLinks, builder: (context, state) => const SocialLinksPage()),
      ],
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(430, 932),
        builder: (context, _) => MaterialApp.router(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('افتح الروابط'));
    await tester.pumpAndSettle();
  }

  Finder fieldHolding(String text) => find.widgetWithText(TextFormField, text);

  group('the list', () {
    testWidgets('draws one row per link, named after its platform', (tester) async {
      // Arrange & Act
      await open(tester);

      // Assert
      expect(find.text('روابط التواصل'), findsOneWidget);
      expect(find.text('فيسبوك'), findsOneWidget);
      expect(find.text('إنستغرام'), findsOneWidget);
      expect(fieldHolding('https://facebook.com/alnoor.print'), findsOneWidget);
      expect(fieldHolding('https://instagram.com/alnoor.print'), findsOneWidget);
      expect(find.text('إضافة رابط'), findsOneWidget);
      expect(find.text('حفظ'), findsOneWidget);
    });

    testWidgets('a new row is named as the link is typed', (tester) async {
      // Arrange
      await open(tester);
      await tester.tap(find.text('إضافة رابط'));
      await tester.pump();

      // Act
      await tester.enterText(find.byType(TextFormField).last, 'tiktok.com/@alnoor');
      await tester.pump();

      // Assert — «رابط» قبل الكتابة، واسم المنصّة بعدها.
      expect(find.text('تيك توك'), findsOneWidget);
      expect(find.text('رابط'), findsNothing);
    });

    testWidgets('a row comes off with its bin', (tester) async {
      // Arrange
      await open(tester);

      // Act
      await tester.tap(find.byTooltip('حذف الرابط').first);
      await tester.pump();

      // Assert
      expect(fieldHolding('https://facebook.com/alnoor.print'), findsNothing);
      expect(fieldHolding('https://instagram.com/alnoor.print'), findsOneWidget);
    });

    testWidgets('removing the last saved link still leaves «حفظ» to say so', (tester) async {
      // Arrange — رابطٌ واحد على الخادم: بلا «حفظ» بعد حذفه لا طريق لإبلاغه.
      await open(tester, saved: const [facebook]);

      // Act
      await tester.tap(find.byTooltip('حذف الرابط'));
      await tester.pump();

      // Assert
      expect(find.text('حفظ'), findsOneWidget);
      expect(find.text('لا توجد روابط بعد'), findsNothing);
    });
  });

  group('empty', () {
    testWidgets('says there are none, and offers only «إضافة رابط»', (tester) async {
      // Arrange & Act
      await open(tester, saved: const []);

      // Assert
      expect(find.text('لا توجد روابط بعد'), findsOneWidget);
      expect(find.text('إضافة رابط'), findsOneWidget);
      expect(find.text('حفظ'), findsNothing);
    });

    testWidgets('«إضافة رابط» opens a first row, and «حفظ» with it', (tester) async {
      // Arrange
      await open(tester, saved: const []);

      // Act
      await tester.tap(find.text('إضافة رابط'));
      await tester.pump();

      // Assert
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('رابط'), findsOneWidget);
      expect(find.text('حفظ'), findsOneWidget);
    });

    testWidgets('no more than ten rows can be added', (tester) async {
      // Arrange — حدُّ الخادم نفسه، فالزرّ يتوقّف بدل أن يُردّ الحفظ. تسعةٌ محفوظة، والعاشر يُضاف.
      await open(
        tester,
        saved: [for (var i = 1; i <= 9; i++) SocialLink(id: i, url: 'https://facebook.com/page$i')],
      );
      final addButton = find.widgetWithText(AppButton, 'إضافة رابط');
      // قائمة الشاشة نفسها، لا ما في كلّ خانة نصٍّ من Scrollable.
      final list = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(addButton, 300, scrollable: list);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Act
      await tester.scrollUntilVisible(addButton, 300, scrollable: list);

      // Assert
      expect(tester.widget<AppButton>(addButton).onPressed, isNull);
    });
  });

  group('saving', () {
    testWidgets('sends the whole set, then goes back saying so', (tester) async {
      // Arrange
      when(() => links.save(any())).thenAnswer((_) async => const Right([facebook]));
      await open(tester);
      await tester.tap(find.byTooltip('حذف الرابط').last);
      await tester.pump();

      // Act
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();

      // Assert — الإنستغرام المحذوف غائبٌ عن المجموعة، فيحذفه الخادم.
      final sent = verify(() => links.save(captureAny())).captured.single as List<SocialLinkInput>;
      expect(sent, const [(id: 12, url: 'https://facebook.com/alnoor.print')]);
      expect(returned, isTrue);
      expect(find.text('تم حفظ الروابط'), findsOneWidget);

      resetSnackBars();
      await tester.pump();
    });

    testWidgets('a row that is not a link is caught before anything is sent', (tester) async {
      // Arrange
      await open(tester);
      await tester.tap(find.text('إضافة رابط'));
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).last, 'alnoor print');

      // Act
      await tester.tap(find.text('حفظ'));
      await tester.pump();

      // Assert
      expect(find.text('الرابط غير صحيح'), findsOneWidget);
      verifyNever(() => links.save(any()));
    });

    testWidgets('the server’s complaint about one row is drawn under that row', (tester) async {
      // Arrange
      when(() => links.save(any())).thenAnswer(
        (_) async => const Left(
          ServerFailure(
            message: 'الرابط مكرر',
            statusCode: 422,
            fieldErrors: {
              'social_links.1.url': ['الرابط مكرر'],
            },
          ),
        ),
      );
      await open(tester);

      // Act
      await tester.tap(find.text('حفظ'));
      await tester.pumpAndSettle();

      // Assert — تحت الصف الثاني، والشاشة باقية.
      expect(find.text('الرابط مكرر'), findsOneWidget);
      final secondRow = tester.getTopLeft(fieldHolding('https://instagram.com/alnoor.print'));
      final complaint = tester.getTopLeft(find.text('الرابط مكرر'));
      expect(complaint.dy, greaterThan(secondRow.dy));
      expect(returned, isNull);
    });
  });

  testWidgets('a list that would not load can be asked for again', (tester) async {
    // Arrange
    tester.view
      ..physicalSize = const Size(430, 932)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var calls = 0;
    when(() => links.list()).thenAnswer((_) async {
      calls++;

      return calls == 1
          ? const Left(NetworkFailure(message: 'لا يوجد اتصال'))
          : const Right([facebook]);
    });
    sl.registerFactory<SocialLinksCubit>(
      () => SocialLinksCubit(list: ListSocialLinks(links), save: SaveSocialLinks(links)),
    );
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(430, 932),
        builder: (context, _) => const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: [Locale('ar')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: SocialLinksPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('أعد المحاولة'));
    await tester.pumpAndSettle();

    // Assert
    expect(calls, 2);
    expect(find.text('فيسبوك'), findsOneWidget);
  });
}
