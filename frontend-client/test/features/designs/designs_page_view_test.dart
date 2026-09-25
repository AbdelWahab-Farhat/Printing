import 'package:cached_network_image/cached_network_image.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:dayaa_client/core/widgets/dismiss_keyboard.dart';
import 'package:dayaa_client/features/designs/models/customer_design.dart';
import 'package:dayaa_client/features/designs/presentation/viewmodel/designs_cubit.dart';
import 'package:dayaa_client/features/designs/presentation/views/designs_page.dart';
import 'package:dayaa_client/features/designs/presentation/widgets/design_viewer.dart';
import 'package:dayaa_client/features/designs/repositories/design_repository.dart';
import 'package:dayaa_client/features/designs/usecases/list_designs.dart';
import 'package:dayaa_client/features/designs/usecases/remove_design.dart';
import 'package:dayaa_client/features/designs/usecases/rename_design.dart';
import 'package:dayaa_client/features/designs/usecases/save_design_to_device.dart';
import 'package:dayaa_client/features/designs/usecases/upload_design.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// الضغط على تصميمٍ يفتحه، والتسمية والتحميل والحذف في زرّ خياراته.
///
/// **الضغط كان يسمّي، وهذا ما رفضه صاحب العمل** (٢٠٢٦-٠٩-٢٥): من يضغط صورةً يريد أن يراها،
/// ونافذةُ اسمٍ تنفتح مكانها تبدو عطلاً. فالصورة تُكبَّر، وملف PDF يُسلَّم لعارض الهاتف.
///
/// Arrange - Act - Assert throughout.
class _MockDesignRepository extends Mock implements DesignRepository {}

void main() {
  late _MockDesignRepository repository;
  late List<String> launched;

  const logoUrl = 'https://files.example/logo.png?signature=abc';
  const briefUrl = 'https://files.example/eid.pdf?signature=abc';

  const logo = CustomerDesign(
    id: 1,
    label: 'شعار المتجر',
    kind: DesignKind.image,
    kindLabel: 'صورة',
    originalFilename: 'logo.png',
    fileUrl: logoUrl,
  );
  const brief = CustomerDesign(
    id: 2,
    label: 'كيس العيد',
    kind: DesignKind.pdf,
    kindLabel: 'PDF',
    originalFilename: 'eid.pdf',
    fileUrl: briefUrl,
  );

  Future<void> arrange(WidgetTester tester) async {
    await Injector.reset();

    // هاتفٌ حقيقي لا مساحة الاختبار الافتراضية، كي تُبنى البطاقات كلها في الشبكة.
    tester.view
      ..physicalSize = const Size(430 * 3, 932 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    repository = _MockDesignRepository();
    when(() => repository.list()).thenAnswer((_) async => const Right([logo, brief]));
    // الجلب يفشل عمداً: ما يُختبر هو أن التحميل طلبه، ونجاحه كان سيأخذ الاختبار إلى
    // `path_provider` وورقة المشاركة، ولا ربط لهما هنا.
    when(
      () => repository.fileBytes(any()),
    ).thenAnswer((_) async => const Left(NetworkFailure(message: 'لا يوجد اتصال')));

    sl
      ..registerLazySingleton<SaveDesignToDevice>(() => SaveDesignToDevice(repository))
      ..registerFactory<DesignsCubit>(
        () => DesignsCubit(
          list: ListDesigns(repository),
          upload: UploadDesign(repository),
          rename: RenameDesign(repository),
          remove: RemoveDesign(repository),
        ),
      );

    // الصورة في ذاكرة الصور مسبقاً: مدير التخزين ومكوّناته لا تعمل تحت `flutter_test`.
    final image = await tester.runAsync(() => createTestImage(width: 4, height: 4));
    PaintingBinding.instance.imageCache.putIfAbsent(
      const CachedNetworkImageProvider(logoUrl),
      () => OneFrameImageStreamCompleter(SynchronousFuture(ImageInfo(image: image!))),
    );

    // ما يُسلَّم لعارض الهاتف يُسجَّل هنا بدل أن يُفتح.
    launched = [];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      (call) async {
        if (call.method == 'launch') {
          launched.add((call.arguments as Map<Object?, Object?>)['url']! as String);
        }

        return true;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher'),
        null,
      ),
    );
  }

  Widget host() => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) =>
          DismissKeyboard(child: child ?? const SizedBox.shrink()),
      home: const DesignsPage(),
    ),
  );

  tearDown(() async {
    PaintingBinding.instance.imageCache.clear();
    await Injector.reset();
  });

  Future<void> openPage(WidgetTester tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
  }

  /// زرّ خيارات البطاقة التي تحمل [label].
  Future<void> openOptionsOf(WidgetTester tester, String label) async {
    final card = find.ancestor(of: find.text(label), matching: find.byType(AppCard)).first;

    await tester.tap(
      find.descendant(of: card, matching: find.byTooltip('خيارات التصميم')),
    );
    await tester.pumpAndSettle();
  }

  /// التوست يبقى ثلاث ثوانٍ ثم ينسحب؛ يُنتظر حتى يغيب كي لا يبقى شيءٌ معلّقاً بعد الاختبار.
  Future<void> outlastToast(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('الضغط على التصميم', () {
    testWidgets('الصورة تُكبَّر ولا تُسمّى', (tester) async {
      // Arrange
      await arrange(tester);
      await openPage(tester);

      // Act
      await tester.tap(find.text('شعار المتجر'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(DesignViewer), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.text('تسمية التصميم'), findsNothing);
    });

    testWidgets('الصورة المكبّرة تُحمَّل من شاشتها، بالرابط الذي تحمله الآن', (tester) async {
      // Arrange
      await arrange(tester);
      await openPage(tester);
      await tester.tap(find.text('شعار المتجر'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byTooltip('تحميل'));
      await tester.pump();

      // Assert — والفشل يُقال، لا يُبتلع.
      verify(() => repository.fileBytes(logoUrl)).called(1);
      expect(find.text('لا يوجد اتصال'), findsOneWidget);

      await outlastToast(tester);
    });

    testWidgets('ملف PDF يُسلَّم لعارض الهاتف، لا نافذة تسميةٍ ولا عارض صور', (tester) async {
      // Arrange
      await arrange(tester);
      await openPage(tester);

      // Act
      await tester.tap(find.text('كيس العيد'));
      await tester.pumpAndSettle();

      // Assert
      expect(launched, [briefUrl]);
      expect(find.byType(DesignViewer), findsNothing);
      expect(find.text('تسمية التصميم'), findsNothing);
    });
  });

  group('زرّ الخيارات', () {
    testWidgets('يعرض التحميل والتسمية والحذف', (tester) async {
      // Arrange
      await arrange(tester);
      await openPage(tester);

      // Act
      await openOptionsOf(tester, 'شعار المتجر');

      // Assert
      expect(find.text('تحميل'), findsOneWidget);
      expect(find.text('إعادة التسمية'), findsOneWidget);
      expect(find.text('حذف'), findsOneWidget);
    });

    testWidgets('«تحميل» يجلب الملف بالرابط الذي تحمله الشاشة الآن', (tester) async {
      // Arrange
      await arrange(tester);
      await openPage(tester);
      await openOptionsOf(tester, 'كيس العيد');

      // Act
      await tester.tap(find.text('تحميل'));
      await tester.pump();

      // Assert
      verify(() => repository.fileBytes(briefUrl)).called(1);
      expect(find.text('لا يوجد اتصال'), findsOneWidget);

      await outlastToast(tester);
    });

    testWidgets('«حذف» يسأل أولاً، ولا يُحذف شيءٌ قبل الجواب', (tester) async {
      // Arrange
      await arrange(tester);
      await openPage(tester);
      await openOptionsOf(tester, 'شعار المتجر');

      // Act
      await tester.tap(find.text('حذف'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('حذف «شعار المتجر»؟'), findsOneWidget);
      verifyNever(() => repository.remove(any()));
    });
  });
}
