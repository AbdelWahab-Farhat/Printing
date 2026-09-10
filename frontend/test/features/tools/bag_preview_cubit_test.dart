import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bloc_test/bloc_test.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/features/tools/models/bag_type.dart';
import 'package:dayaa/features/tools/presentation/viewmodel/bag_preview_cubit.dart';
import 'package:dayaa/features/tools/usecases/load_bag_mockup.dart';
import 'package:dayaa/features/tools/usecases/load_design_image.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// الكيس المختار والتصميم المفكوك ترميزه.
///
/// `LoadDesignImage` حقيقية لا مزيَّفة، للسبب نفسه الذي في `qr_tool_cubit_test.dart`: لا شبكة
/// تحتها، والسؤال الوحيد الذي يستحق أن يُسأل — ماذا يحدث لملفٍ لا يُفكّ ترميزه — كان التزييف
/// سيتركه بلا جواب.
///
/// Arrange - Act - Assert throughout.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late BagPreviewCubit cubit;

  /// A real PNG on disk, so the decoder has something it can actually read.
  Future<PickedFile> pngFile(String name) async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawRect(
      const Rect.fromLTWH(0, 0, 40, 40),
      Paint()..color = const Color(0xFF112233),
    );
    final image = await recorder.endRecording().toImage(40, 40);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    final file = File('${temp.path}/$name');
    await file.writeAsBytes(bytes!.buffer.asUint8List());

    return PickedFile(path: file.path, name: name, sizeBytes: file.lengthSync());
  }

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('bag_preview_test');
    cubit = BagPreviewCubit(
      loadImage: const LoadDesignImage(),
      loadMockup: const LoadBagMockup(),
    );
  });

  tearDown(() async {
    await cubit.close();
    await temp.delete(recursive: true);
  });

  test('يفتح على أول كيس، بلا تصميم', () {
    // Assert — الكيس أرضية الشاشة، فهو موجودٌ قبل أن يُرفع شيء.
    expect(cubit.state, const BagPreviewState.empty(bag: BagType.initial));
    expect(cubit.state.design, isNull);
  });

  group('selectBag', () {
    blocTest<BagPreviewCubit, BagPreviewState>(
      'يبدّل الكيس فوراً، ثم تصل صورته',
      build: () => cubit,
      act: (cubit) => cubit.selectBag(BagType.transparent),
      // الاسم في القائمة يتبدّل قبل أن يُفكّ ترميز صورة — أصدق من قائمةٍ تتجمّد.
      expect: () => [
        const BagPreviewState.empty(bag: BagType.transparent),
        isA<BagPreviewEmpty>()
            .having((s) => s.bag, 'bag', BagType.transparent)
            .having((s) => s.mockup, 'mockup', isNotNull),
      ],
    );

    test('صور الأنواع الخمسة كلها في الحزمة وتُفكّ', () async {
      // Arrange & Act & Assert — أصلٌ غير مسجَّل في `pubspec.yaml` لا يظهر إلا هنا أو في يد
      // الموظف أمام كيسٍ فارغ.
      for (final type in BagType.values) {
        final result = await const LoadBagMockup()(type);

        expect(result.isRight(), isTrue, reason: type.label);
      }
    });

    test('تبديل الكيس لا يُسقط التصميم المعروض', () async {
      // Arrange — تصميمٌ على الكيس الأول.
      await cubit.loadDesign(await pngFile('logo.png'));
      final loaded = cubit.state.design;
      expect(loaded, isNotNull);

      // Act — يجرّب نفس الشعار على مقاسٍ آخر.
      await cubit.selectBag(BagType.paper);

      // Assert — نفس الصورة بعينها: إعادةُ رفعها لكل مقاس هي العمل الذي جاءت الأداة لتوفّره.
      expect(cubit.state.bag, BagType.paper);
      expect(identical(cubit.state.design, loaded), isTrue);
    });
  });

  group('loadDesign', () {
    test('يعرض الصورة بمقاسها', () async {
      // Arrange & Act
      await cubit.loadDesign(await pngFile('logo.png'));

      // Assert
      expect(cubit.state, isA<BagPreviewReady>());
      expect(cubit.state.design?.width, 40);
      expect(cubit.state.design?.height, 40);
    });

    test('يرفض PDF برسالةٍ تقول ماذا يفعل، لا بشاشةٍ فارغة', () async {
      // Arrange — المكتبة تقبل الـ PDF، وهذه المعاينة لا تستطيع رسمه.
      final pdf = PickedFile(path: '${temp.path}/x.pdf', name: 'تصميم.pdf', sizeBytes: 10);

      // Act
      await cubit.loadDesign(pdf);

      // Assert
      expect(cubit.state, isA<BagPreviewFailure>());
      expect(
        (cubit.state as BagPreviewFailure).failure.message,
        'المعاينة تحتاج صورة — حوّل ملف PDF إلى PNG أو JPG ثم ارفعه',
      );
    });

    test('ملفٌ لا يُفكّ ترميزه يفشل برسالةٍ تحمل سببها', () async {
      // Arrange — امتدادٌ يكذب على محتواه.
      final broken = File('${temp.path}/broken.png')
        ..writeAsBytesSync(Uint8List.fromList([1, 2, 3, 4]));

      // Act
      await cubit.loadDesign(
        PickedFile(path: broken.path, name: 'broken.png', sizeBytes: 4),
      );

      // Assert
      expect(cubit.state, isA<BagPreviewFailure>());
      expect((cubit.state as BagPreviewFailure).failure.message, 'تعذّر قراءة ملف التصميم');
    });

    test('الفشل يُبقي الكيس المختار ولا يعود إلى الأول', () async {
      // Arrange
      await cubit.selectBag(BagType.transparent);

      // Act
      await cubit.loadDesign(
        PickedFile(path: '${temp.path}/x.pdf', name: 'x.pdf', sizeBytes: 1),
      );

      // Assert — رسالةٌ عن ملف يجب ألّا تُغيّر المقاس الذي اختاره الموظف قبلها.
      expect(cubit.state.bag, BagType.transparent);
    });

    test('تصميمٌ ثانٍ يحلّ محلّ الأول', () async {
      // Arrange
      await cubit.loadDesign(await pngFile('first.png'));
      final first = cubit.state.design;

      // Act
      await cubit.loadDesign(await pngFile('second.png'));

      // Assert
      expect(identical(cubit.state.design, first), isFalse);
    });

    test('فشلٌ بعد نجاح لا يُتلف الصورة المعروضة', () async {
      // Arrange — تصميمٌ معروضٌ، ثم محاولةٌ فاشلة بعده.
      await cubit.loadDesign(await pngFile('logo.png'));

      // Act
      await cubit.loadDesign(
        PickedFile(path: '${temp.path}/x.pdf', name: 'x.pdf', sizeBytes: 1),
      );

      // Assert — الشاشة تعود إلى «ارفع تصميماً» ولا تحمل صورةً أُفرج عن ذاكرتها؛ الرسم بصورةٍ
      // مُتلَفة انهيارٌ لا رسالة.
      expect(cubit.state, isA<BagPreviewFailure>());
      expect(cubit.state.design, isNull);
    });
  });

  group('withBag', () {
    test('لا يحمل رسالة الفشل إلى كيسٍ جديد', () {
      // Arrange
      const failed = BagPreviewState.failure(
        bag: BagType.initial,
        failure: Failure.unexpected(message: 'أياً كان'),
      );

      // Act
      final moved = failed.withBag(BagType.transparent);

      // Assert — تبديل المقاس ليس محاولةً ثانية لقراءة الملف، فلا تبقى الرسالة معلّقة تحته.
      expect(moved, isA<BagPreviewEmpty>());
    });
  });
}
