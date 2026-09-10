import 'dart:io';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/features/tools/models/qr_code_painter.dart';
import 'package:dayaa/features/tools/models/qr_ink.dart';
import 'package:dayaa/features/tools/presentation/viewmodel/qr_tool_cubit.dart';
import 'package:dayaa/features/tools/presentation/views/qr_tool_page.dart';
import 'package:dayaa/features/tools/presentation/widgets/qr_code_view.dart';
import 'package:dayaa/features/tools/presentation/widgets/qr_ink_picker.dart';
import 'package:dayaa/features/tools/usecases/generate_qr_code.dart';
import 'package:dayaa/features/tools/usecases/save_qr_code_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// شاشة أداة QR: ما يظهر متى، ولماذا يتبدّل اللون بلا ضغطة ثانية.
///
/// السطر الأخير هو ما يستحق اختباراً أصلاً — القرار بأن «إنشاء الرمز» ترمّز، وأن اللون طلاءٌ
/// بعده — لأنه الفرق الوحيد عن أداة الموقع في التفاعل، وهو الذي ينقضه أول من يقرأ الملف ويظنّه
/// سهواً.
///
/// Arrange - Act - Assert throughout.
void main() {
  late Directory temp;

  setUp(() async {
    await Injector.reset();
    sl
      ..registerLazySingleton<GenerateQrCode>(GenerateQrCode.new)
      ..registerLazySingleton<SaveQrCodeImage>(SaveQrCodeImage.new)
      ..registerFactory<QrToolCubit>(() => QrToolCubit(generate: sl<GenerateQrCode>()));

    temp = await Directory.systemTemp.createTemp('qr_page_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => call.method == 'getTemporaryDirectory' ? temp.path : null,
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    await temp.delete(recursive: true);
    await Injector.reset();
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
      home: QrToolPage(),
    ),
  );

  /// The painter currently drawing the code, or nothing if no code is on screen.
  QrCodePainter? paintedCode(WidgetTester tester) {
    final view = find.byType(QrCodeView);
    if (view.evaluate().isEmpty) return null;

    return tester
            .widget<CustomPaint>(find.descendant(of: view, matching: find.byType(CustomPaint)))
            .painter
        as QrCodePainter?;
  }

  Future<void> generate(WidgetTester tester, String data) async {
    await tester.enterText(find.byType(TextFormField), data);
    await tester.tap(find.text('إنشاء الرمز'));
    await tester.pump();
  }

  testWidgets('يفتح بلا رمز', (tester) async {
    // Arrange & Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — مكان الرمز موجود، والرمز ليس بعد؛ ولا زرَّ تحميلٍ لصورةٍ غير موجودة.
    expect(paintedCode(tester), isNull);
    expect(find.text('تحميل الصورة'), findsNothing);
  });

  testWidgets('حقلٌ فارغ يُردّ برسالة تحته لا بتوست فوق الشاشة', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('إنشاء الرمز'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('هذا الحقل مطلوب'), findsOneWidget);
    expect(paintedCode(tester), isNull);
  });

  testWidgets('«إنشاء الرمز» يرسم ما كُتب، ويُظهر زر التحميل', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await generate(tester, 'https://daaya.ly');

    // Assert
    expect(paintedCode(tester)?.art.data, 'https://daaya.ly');
    expect(find.text('تحميل الصورة'), findsOneWidget);
  });

  testWidgets('اللون يُبدَّل في المعاينة بلا ضغطة ثانية، والرمز هو هو', (tester) async {
    // Arrange — رمزٌ على الشاشة بالحبر الافتراضي.
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await generate(tester, 'https://daaya.ly');
    final before = paintedCode(tester)!;
    expect(before.color, QrInk.black);

    // Act — لونٌ آخر من الصف، بلا لمس زر الإنشاء.
    final other = QrInk.palette.firstWhere((ink) => ink != QrInk.black);
    await tester.tap(find.byWidgetPredicate((widget) => _isSwatchOf(widget, other)));
    await tester.pumpAndSettle();

    // Assert — الطلاء تغيّر، والترميز لم يُعَد: نفس الكائن، لأنه نفس الرمز بحبرٍ آخر.
    final after = paintedCode(tester)!;
    expect(after.color, other);
    expect(identical(after.art, before.art), isTrue);
  });

  testWidgets('الشفافية تصل الرسّام كما ضُبطت', (tester) async {
    // Arrange — الافتراضي مفعَّل، كما في أداة الموقع.
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await generate(tester, 'https://daaya.ly');
    expect(paintedCode(tester)?.transparentBackground, isTrue);

    // Act
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    // Assert
    expect(paintedCode(tester)?.transparentBackground, isFalse);
  });

  testWidgets('نصٌّ جديد لا يبدّل المعروض حتى يُضغط الزر', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await generate(tester, 'https://daaya.ly');

    // Act — يُكتب محتوى آخر ولا يُضغط شيء.
    await tester.enterText(find.byType(TextFormField), '0910000000');
    await tester.pumpAndSettle();

    // Assert — رمزٌ يتبدّل تحت الإصبع مع كل حرف هو رمزٌ لا يعرف الموظف أيَّ نسخةٍ منه حمَّل.
    expect(paintedCode(tester)?.art.data, 'https://daaya.ly');
  });

  group('حين تُفتح لتُعيد ملفاً', () {
    /// آخر ما سلّمته الشاشة لمن فتحها. يُملأ حين تُغلق، لا حين تُفتح.
    PickedFile? handed;

    setUp(() => handed = null);

    /// The screen as a design library opens it, with somewhere for its answer to land.
    Future<void> openPicker(WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(430, 932),
          builder: (context, _) => MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    final file = await Navigator.of(context).push<PickedFile>(
                      MaterialPageRoute(builder: (_) => const QrToolPage.picking()),
                    );
                    handed = file;
                  },
                  child: const Text('افتح'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();
    }



    // **ما يحدث بعد الضغط على «إضافة إلى التصاميم» لا يُختبر هنا، وذلك قرارٌ لا نقص.**
    // تحويل الرسم إلى بايتات PNG يجري على خيط التصيير، ولا تُنهيه ساعةُ `pumpAndSettle`
    // المزيّفة؛ والزرّ أثناء انشغاله يُدير خيطاً حول حافته بلا توقّف، فالشجرة لا تستقرّ أبداً
    // (§7). اختبارٌ يقضي عشر ثوانٍ في `runAsync` ثم ينتهي بالمهلة على جهازٍ مشغول ليس اختباراً.
    //
    // والضمانة نفسها مأخوذةٌ أرخص وأوثق في `save_qr_code_image_test.dart`: هناك يُكتب الملف
    // فعلاً، ويُتحقَّق أن `DesignRules` تقبله — وهي بالضبط البوّابة التي سيمرّ منها حين ترفعه
    // مكتبة العميل. ما يبقى هنا هو ما تقرّره هذه الشاشة وحدها: أيُّ زرٍّ يظهر، ومتى.

    testWidgets('لا زرَّ إضافةٍ قبل أن يوجد رمز', (tester) async {
      // Arrange & Act
      await openPicker(tester);

      // Assert
      expect(find.text('إضافة إلى التصاميم'), findsNothing);
    });

    testWidgets('«تحميل الصورة» يبقى متاحاً بجانب الإضافة', (tester) async {
      // Arrange
      await openPicker(tester);

      // Act
      await generate(tester, 'https://daaya.ly');

      // Assert — الأداة نفسها لا تتغيّر بتغيّر من فتحها؛ يتغيّر إجراؤها الأول فقط.
      expect(find.text('إضافة إلى التصاميم'), findsOneWidget);
      expect(find.text('تحميل الصورة'), findsOneWidget);
    });

    testWidgets('الخروج بلا رمز يسلّم لا شيء', (tester) async {
      // Arrange
      await openPicker(tester);

      // Act — العودة من الشاشة كما يعود من فتحها ثم بدا له.
      Navigator.of(tester.element(find.text('إنشاء الرمز'))).pop();
      await tester.pumpAndSettle();

      // Assert — الخروج نهايةٌ عادية، ولا يُرفع شيء.
      expect(handed, isNull);
    });
  });

  testWidgets('حين تُفتح من الدرج لا تعرض «إضافة إلى التصاميم»', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await generate(tester, 'https://daaya.ly');

    // Assert — لا مكان يذهب إليه الملف، وزرٌّ لا يفتح شيئاً أسوأ من زرٍّ غائب.
    expect(find.text('إضافة إلى التصاميم'), findsNothing);
    expect(find.text('تحميل الصورة'), findsOneWidget);
  });

  testWidgets('الألوان السريعة صفٌّ واحد لا يلتفّ', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act — كل قرصٍ في الصفّ، بما فيه قرص المنتقي في آخره.
    final tops = <double>{
      for (final ink in QrInk.palette)
        tester.getTopLeft(find.byWidgetPredicate((w) => _isSwatchOf(w, ink))).dy,
    };

    // Assert — ارتفاعٌ واحد لكلها يعني سطراً واحداً؛ والتفافُ آخرِ لونٍ إلى سطرٍ وحده هو ما
    // كان يفعله `Wrap` قبله.
    expect(tops, hasLength(1));
    expect(find.byType(Wrap), findsNothing);
  });

  testWidgets('المنتقي يفتح على أي لون خارج القائمة السريعة', (tester) async {
    // Arrange — رمزٌ بالحبر الافتراضي، والمنتقي آخر الصفّ.
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await generate(tester, 'https://daaya.ly');
    expect(paintedCode(tester)!.color, QrInk.black);

    // Act — يُفتح المنتقي، ويُنقر أعلى يمين مربّع التشبّع: تشبّعٌ كامل وإضاءةٌ كاملة عند
    // الصبغة صفر — أحمرُ خالص، وهو ليس من الألوان السريعة.
    await tester.tap(find.byWidgetPredicate(_isCustomSwatch));
    await tester.pumpAndSettle();

    final area = find.byKey(QrInkPicker.saturationKey);
    await tester.tapAt(tester.getTopLeft(area) + const Offset(1, 1));
    await tester.pumpAndSettle();

    await tester.tap(find.text('اختيار هذا اللون'));
    await tester.pumpAndSettle();

    // Assert — اللون طُبِّق على الرمز المعروض بلا إعادة ترميز: أحمرُ مشبَّع، وليس من القائمة.
    // (لا يُقارن بـ `0xFFFF0000` بالضبط: النقر يقع على بُعد بكسل من الركن، فالتشبّع ٠٫٩٩ لا ١.)
    final picked = paintedCode(tester)!.color;
    expect(picked.g, isZero);
    expect(picked.b, isZero);
    expect(picked.r, greaterThan(.98));
    expect(QrInk.palette, isNot(contains(picked)));
  });

  testWidgets('الخروج من المنتقي بلا اختيار لا يغيّر الحبر', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await generate(tester, 'https://daaya.ly');

    // Act — تُفتح الورقة ثم تُغلق بالعودة.
    await tester.tap(find.byWidgetPredicate(_isCustomSwatch));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('لون مخصّص'))).pop();
    await tester.pumpAndSettle();

    // Assert
    expect(paintedCode(tester)!.color, QrInk.black);
  });
}

/// The rainbow disc at the end of the row — the one that opens the picker.
bool _isCustomSwatch(Widget widget) {
  if (widget is! Container) return false;
  final decoration = widget.decoration;

  return decoration is BoxDecoration && decoration.gradient is SweepGradient;
}

/// A colour swatch drawn in [ink] — the circle, not the row around it.
bool _isSwatchOf(Widget widget, Color ink) {
  if (widget is! Container) return false;
  final decoration = widget.decoration;

  return decoration is BoxDecoration &&
      decoration.shape == BoxShape.circle &&
      decoration.color == ink;
}
