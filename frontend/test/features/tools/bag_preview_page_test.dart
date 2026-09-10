import 'dart:io';
import 'dart:ui' as ui;

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/features/tools/models/bag_preview_painter.dart';
import 'package:dayaa/features/tools/models/bag_type.dart';
import 'package:dayaa/features/tools/presentation/viewmodel/bag_preview_cubit.dart';
import 'package:dayaa/features/tools/presentation/views/bag_preview_page.dart';
import 'package:dayaa/features/tools/usecases/load_bag_mockup.dart';
import 'package:dayaa/features/tools/usecases/load_design_image.dart';
import 'package:dayaa/features/tools/usecases/save_bag_preview_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// شاشة معاينة التصميم على الكيس: ما تقرّره هي وحدها — أيّ زرٍّ يظهر متى، وماذا يصل الرسّام.
///
/// **القيد نفسه ليس هنا.** «لا بكسل من التصميم يقع في الهامش» حسابٌ خالص يُقاس بالبكسل في
/// `design_placement_test.dart`، بلا إيماءةٍ ولا قماشة — وهو المكان الصحيح له.
///
/// **ولا يُفكّ ترميز صورةٍ داخل `testWidgets`.** قراءة الملف وفكّ ترميزه عمليتان حقيقيتان خارج
/// الساعة المزيّفة التي يديرها اختبار الويدجت، فمستقبلٌ يبدأ داخلها لا يكتمل أبداً والاختبار
/// يعلّق. لذلك يُحضَّر الـ Cubit **قبل** أن تُبنى الشجرة، داخل `runAsync`، ثم يُسلَّم للشاشة
/// محمَّلاً — فتُختبر الشاشة على ما تراه فعلاً بلا انتظارٍ لا ينتهي.
///
/// Arrange - Act - Assert throughout.
class _FakePicker implements AttachmentPicker {
  List<PickedFile> answer = const [];

  @override
  Future<List<PickedFile>> pick(AttachmentSource source) async => answer;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late PickedFile logo;
  late _FakePicker picker;

  // خارج `testWidgets`، فالساعة هنا حقيقية ويكتمل ما يُنتظر.
  setUp(() async {
    await Injector.reset();
    temp = await Directory.systemTemp.createTemp('bag_preview_page_test');
    picker = _FakePicker();

    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawRect(
      const Rect.fromLTWH(0, 0, 40, 40),
      Paint()..color = const Color(0xFF112233),
    );
    final image = await recorder.endRecording().toImage(40, 40);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    final file = File('${temp.path}/logo.png')
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
    logo = PickedFile(path: file.path, name: 'logo.png', sizeBytes: file.lengthSync());

    sl
      ..registerSingleton<AttachmentPicker>(picker)
      ..registerLazySingleton<LoadDesignImage>(LoadDesignImage.new)
      ..registerLazySingleton<LoadBagMockup>(LoadBagMockup.new)
      ..registerLazySingleton<SaveBagPreviewImage>(SaveBagPreviewImage.new)
      ..registerFactory<BagPreviewCubit>(
        () => BagPreviewCubit(
          loadImage: sl<LoadDesignImage>(),
          loadMockup: sl<LoadBagMockup>(),
        ),
      );
  });

  tearDown(() async {
    await Injector.reset();
    await temp.delete(recursive: true);
  });

  Widget host() => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => const MaterialApp(
      locale: Locale('ar'),
      supportedLocales: [Locale('ar')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: BagPreviewPage(),
    ),
  );

  /// Pumps the screen on a phone-shaped window.
  ///
  /// **٨٠٠×٦٠٠ الافتراضية لا تصلح هنا:** الكيس يُرسم بنسبته الحقيقية، فعلى نافذةٍ عريضة قصيرة
  /// يصير أطول من الشاشة كلها — وما تحته لا يُبنى، فتفشل الاختبارات على أزرارٍ موجودةٍ في
  /// الشيفرة وغائبةٍ عن الشجرة.
  Future<void> pumpScreen(WidgetTester tester, {bool withDesign = false}) async {
    tester.view
      ..physicalSize = const Size(430 * 3, 1400 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    if (withDesign) {
      // يُحمَّل قبل أن تُبنى الشجرة — انظر رأس الملف.
      final loaded = BagPreviewCubit(
        loadImage: const LoadDesignImage(),
        loadMockup: const LoadBagMockup(),
      );
      await tester.runAsync(() async {
        await loaded.load();
        await loaded.loadDesign(logo);
      });
      expect(loaded.state, isA<BagPreviewReady>(), reason: 'التحضير نفسه فشل');

      sl
        ..unregister<BagPreviewCubit>()
        ..registerFactory<BagPreviewCubit>(() => loaded);
    }

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // صورة الكيس أصلٌ من الحزمة يُفكّ ترميزه، وذلك عملٌ حقيقي خارج الساعة المزيّفة — فيُنتظر
    // هنا كما يُنتظر التصميم، وإلا رُسم الكيس فارغاً في أول إطار وبقي.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// The painter currently drawing the bag.
  BagPreviewPainter painterOf(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((paint) => paint.painter)
      .whereType<BagPreviewPainter>()
      .first;

  testWidgets('يفتح على كيسٍ مرسوم بلا تصميم، ولا زرَّ مشاركةٍ لما ليس موجوداً', (tester) async {
    // Arrange & Act
    await pumpScreen(tester);

    // Assert — الكيس أرضية الشاشة لا نتيجةٌ تُنتظر.
    expect(painterOf(tester).design, isNull);
    expect(painterOf(tester).bag, BagType.initial);
    expect(painterOf(tester).mockup, isNotNull, reason: 'صورة الكيس لم تصل');
    expect(find.text('رفع التصميم'), findsOneWidget);
    expect(find.text('مشاركة المعاينة'), findsNothing);
  });

  testWidgets('لا زرَّ للإرشاد قبل أن يوجد تصميم', (tester) async {
    // Arrange & Act
    await pumpScreen(tester);

    // Assert — لا شيء يُرشد إليه بعد.
    expect(find.byTooltip('إخفاء حدود الطباعة'), findsNothing);
  });

  testWidgets('قائمة الأكياس تقول مساحة الطباعة لا المقاس وحده', (tester) async {
    // Arrange
    await pumpScreen(tester);

    // Act
    await tester.tap(find.text(BagType.initial.label).last);
    await tester.pumpAndSettle();

    // Assert — ٣٥ ‎−‎ ٢ ‎−‎ ٢ = ٣١، وهو الرقم الذي يفرّق بين مقاسين عند الاختيار؛ والمقاس وحده
    // لا يقوله لأن الهوامش تختلف بين نوعٍ وآخر.
    expect(find.textContaining('مساحة الطباعة 31×41'), findsWidgets);
  });

  testWidgets('تصميمٌ محمَّل يظهر على الكيس، ومعه المشاركة وتبديل التصميم', (tester) async {
    // Arrange & Act
    await pumpScreen(tester, withDesign: true);

    // Assert
    expect(painterOf(tester).design, isNotNull);
    expect(find.text('مشاركة المعاينة'), findsOneWidget);
    expect(find.text('تبديل التصميم'), findsOneWidget);
    expect(find.text('رفع التصميم'), findsNothing);
  });

  testWidgets('خطوط الإرشاد ظاهرة أثناء العمل، وتُخفى بضغطة', (tester) async {
    // Arrange
    await pumpScreen(tester, withDesign: true);
    expect(painterOf(tester).showGuides, isTrue);

    // Act
    await tester.tap(find.byTooltip('إخفاء حدود الطباعة'));
    await tester.pumpAndSettle();

    // Assert — «كيف ستبدو نظيفة؟» سؤالٌ يُسأل كل عشر ثوانٍ، وجوابه يجب أن يكون بعرض إبهام.
    expect(painterOf(tester).showGuides, isFalse);
    expect(find.byTooltip('إظهار حدود الطباعة'), findsOneWidget);
  });

  testWidgets('تبديل الكيس يصل الرسّام ولا يُسقط التصميم', (tester) async {
    // Arrange
    await pumpScreen(tester, withDesign: true);
    final design = painterOf(tester).design;

    // Act
    await tester.tap(find.text(BagType.initial.label).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(BagType.transparent.label).last);
    await tester.pumpAndSettle();

    // Assert — نفس الصورة بعينها على مقاسٍ آخر: تجريب الشعار على ثلاثة مقاسات هو الاستعمال،
    // وإعادةُ رفعه في كل مرة هي العمل الذي جاءت الأداة لتوفّره.
    expect(painterOf(tester).bag, BagType.transparent);
    expect(identical(painterOf(tester).design, design), isTrue);
  });
}
