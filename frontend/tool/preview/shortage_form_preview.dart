// A harness, not a test: it draws «نقص جديد» to PNGs so the fork at the top of the form can be
// looked at without the phone. Named outside `test/` so `flutter test` never collects it.
//
//   PREVIEW_OUT=/tmp flutter test tool/preview/shortage_form_preview.dart
//
// Two traps, both handled below: the app's text theme goes through GoogleFonts, which cannot
// fetch in a test, so the bundled Almarai is registered under the family the theme asks for; and
// Material's icon font is not loaded in a test, so icon glyphs come out as empty squares.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/theme/theme.dart';
import 'package:dayaa/features/shortages/models/shortage.dart';
import 'package:dayaa/features/shortages/presentation/viewmodel/save_shortage_cubit.dart';
import 'package:dayaa/features/shortages/presentation/views/shortage_form_page.dart';
import 'package:dayaa/features/shortages/repositories/shortage_repository.dart';
import 'package:dayaa/features/shortages/usecases/shortage_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// Nothing is ever submitted here — the harness only draws.
class _IdleRepository implements ShortageRepository {
  @override
  Object noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// «كيس شحن — 25*35», so the product side can be seen with an answer in it rather than empty.
const _productShortage = Shortage(
  id: 7,
  code: 'N7',
  source: ShortageSource.manual,
  sourceLabel: 'يدوي',
  name: 'كيس شحن — 25*35',
  unit: 'kilogram',
  unitLabel: 'كجم',
  requiredQuantity: '30.000',
  suppliedQuantity: '0.000',
  remainingQuantity: '30.000',
  totalPaid: '0.00',
  status: ShortageStatus.fresh,
  statusLabel: 'جديد',
  isEditable: true,
  productId: 3,
  productVariantId: 12,
  product: ShortageProductRef(id: 3, name: 'كيس شحن'),
  variant: ShortageVariantRef(id: 12, label: '25*35'),
);

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader('Cairo');
    for (final file in ['Almarai-Regular.ttf', 'Almarai-Bold.ttf']) {
      loader.addFont(
        File('assets/fonts/$file').readAsBytes().then((bytes) => ByteData.view(bytes.buffer)),
      );
    }
    await loader.load();
  });

  testWidgets('draw both sides of the fork', (tester) async {
    await Injector.reset();
    final repository = _IdleRepository();
    sl.registerFactory<SaveShortageCubit>(
      () => SaveShortageCubit(
        createShortage: CreateShortage(repository),
        updateShortage: UpdateShortage(repository),
      ),
    );

    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final key = GlobalKey();

    Future<void> open(Shortage? shortage) async {
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: ScreenUtilInit(
            designSize: const Size(430, 932),
            builder: (context, _) => MaterialApp(
              debugShowCheckedModeBanner: false,
              // Drawn dark, which is how the shop reads it.
              theme: MaterialTheme(
                Typography.material2021().white.apply(fontFamily: 'Cairo'),
              ).dark(),
              locale: const Locale('ar'),
              supportedLocales: const [Locale('ar')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: ShortageFormPage(shortage: shortage),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> shoot(String name) async {
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('${Platform.environment['PREVIEW_OUT'] ?? '.'}/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
      });
    }

    Future<void> choose(String option) async {
      await tester.tap(find.byType(DropdownButtonFormField<ShortageType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(option).last);
      await tester.pumpAndSettle();
    }

    await open(null);
    await shoot('shortage-1-product-empty');

    await open(_productShortage);
    await shoot('shortage-2-product-chosen');

    await open(null);
    await tester.tap(find.text('مستلزمات'));
    await tester.pumpAndSettle();
    await choose('ورق طباعة');
    await shoot('shortage-3-supplies-named');

    await choose('أخرى');
    await shoot('shortage-4-supplies-other');
  });
}
