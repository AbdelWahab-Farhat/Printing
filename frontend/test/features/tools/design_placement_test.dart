import 'dart:ui';

import 'package:dayaa/features/tools/models/bag_type.dart';
import 'package:dayaa/features/tools/models/design_placement.dart';
import 'package:flutter_test/flutter_test.dart';

/// **الشرط الذي تقوم عليه الأداة كلها: لا بكسل من التصميم يقع في الهامش.**
///
/// وهو ينكسر بصمت — تصميمٌ زحف سنتيمتراً داخل الطيّة يبدو سليماً على الشاشة، ويُكتشف على ألف
/// كيس مطبوع. فهذه أول الاختبارات وأكثرها تفصيلاً، والحساب كله هنا خالصٌ بلا ويدجت ولا قماشة.
///
/// Arrange - Act - Assert throughout.
void main() {
  /// المثال الذي ورد في المواصفة حرفياً: عرض ٣٥ سم، هامش ٢ سم من كل جانب، فتبقى ٣١.
  const bag = BagType.shipping;

  /// الكيس مرسوماً على الشاشة، وما بداخله منطقة الطباعة.
  const bagRect = Rect.fromLTWH(0, 0, 350, 450);

  group('BagType', () {
    test('تطرح الهوامش من المقاس فتعطي منطقة الطباعة', () {
      // Assert — ٣٥ ‎−‎ ٢ ‎−‎ ٢ = ٣١، وهو الرقم الذي في المواصفة.
      expect(bag.printableWidth, 31);
      expect(bag.printableHeight, 41);
      expect(bag.isPrintable, isTrue);
    });

    test('كل نوعٍ في القائمة كيسٌ يُطبع عليه فعلاً', () {
      // Assert — هوامشُ أكبر من الكيس تعطي مساحةً سالبة لا تُرسم ولا تُقصّ ولا تعني شيئاً.
      // والقيم مكتوبةٌ بأيدينا في `bag_type.dart` وتنتظر معايرة مع المطبعة، وهذا ما يمسكها إن
      // أخطأت — ويمسك كذلك وجهاً مقلوباً داخل الصورة، وهو الخطأ الذي يُري الإطار في الفراغ.
      for (final type in BagType.values) {
        expect(type.isPrintable, isTrue, reason: type.label);
        expect(type.face.left, lessThan(type.face.right), reason: 'وجه ${type.label}');
        expect(type.face.top, lessThan(type.face.bottom), reason: 'وجه ${type.label}');
        expect(type.face.left, greaterThanOrEqualTo(0), reason: 'وجه ${type.label}');
        expect(type.face.bottom, lessThanOrEqualTo(1), reason: 'وجه ${type.label}');
        expect(type.asset, startsWith('assets/mockups/'), reason: type.label);
      }
    });
  });

  group('منطقة الطباعة داخل الكيس المرسوم', () {
    test('تقتطع الهوامش بنفس نسبتها من الكيس الحقيقي', () {
      // Act
      final print = DesignPlacement.printAreaIn(bagRect, bag);

      // Assert — ٢ من ٣٥ = ٥.٧١٪، وعلى ٣٥٠ بكسل تساوي ٢٠.
      expect(print.left, closeTo(20, .001));
      expect(print.width, closeTo(310, .001));
      expect(print.top, closeTo(20, .001));
      expect(print.height, closeTo(410, .001));
    });

    test('هوامش غير متساوية تقتطع كلٌّ من جهتها', () {
      // Arrange — اليد المقطوعة تأكل خمسة سنتيمترات من الأعلى، والقصّة السفلية اثنين.
      const handled = BagType.innerHandle;
      expect(handled.marginTop, 5);

      // Act — وجه الكيس مرسوماً بعشرة بكسلات للسنتيمتر.
      final print = DesignPlacement.printAreaIn(const Rect.fromLTWH(0, 0, 300, 400), handled);

      // Assert
      expect(print.top, closeTo(50, .001));
      expect(print.bottom, closeTo(380, .001));
    });
  });

  group('الوضع الابتدائي', () {
    test('يملأ منطقة الطباعة بلا قصٍّ ولا تشويه', () {
      // Arrange — تصميمٌ مربّع، ومنطقة طباعة أطول منها عرضاً.
      const design = Size(500, 500);
      final print = DesignPlacement.printAreaIn(bagRect, bag);

      // Act
      final rect = const DesignPlacement.initial().rectIn(print, design);

      // Assert — يدخل كاملاً، وبنسبته: لا يُمطّ ليملأ ما ليس على شكله.
      expect(rect.width, closeTo(rect.height, .001));
      expect(rect.width, lessThanOrEqualTo(print.width + .001));
      expect(rect.height, lessThanOrEqualTo(print.height + .001));
      expect(rect.center.dx, closeTo(print.center.dx, .001));
      expect(rect.center.dy, closeTo(print.center.dy, .001));
    });
  });

  group('القيد — لا شيء يدخل الهامش', () {
    /// أقصى ما يمكن أن تصل إليه حافةٌ من حواف التصميم بعد التقييد، عند [scale].
    Rect draggedTo(Offset target, {double scale = 1}) {
      const design = Size(500, 500);
      final print = DesignPlacement.printAreaIn(bagRect, bag);

      final placement = DesignPlacement(scale: scale, offset: target).clamped(print, design);

      return placement.rectIn(print, design);
    }

    test('السحب بعيداً لا يُخرج تصميماً أصغر من المنطقة عنها', () {
      // Arrange — تصميمٌ يدخل كاملاً، يُدفع إلى أقصى اليمين والأسفل بقوة.
      final print = DesignPlacement.printAreaIn(bagRect, bag);

      // Act
      final rect = draggedTo(const Offset(10, 10));

      // Assert — يقف عند الحافة ولا يتجاوزها.
      expect(rect.right, lessThanOrEqualTo(print.right + .001));
      expect(rect.bottom, lessThanOrEqualTo(print.bottom + .001));
      expect(rect.left, greaterThanOrEqualTo(print.left - .001));
      expect(rect.top, greaterThanOrEqualTo(print.top - .001));
    });

    test('والسحب في الاتجاه المضاد كذلك', () {
      // Arrange
      final print = DesignPlacement.printAreaIn(bagRect, bag);

      // Act
      final rect = draggedTo(const Offset(-10, -10));

      // Assert
      expect(rect.left, greaterThanOrEqualTo(print.left - .001));
      expect(rect.top, greaterThanOrEqualTo(print.top - .001));
    });

    test('تصميمٌ مكبَّر فوق المنطقة يبقى مغطّياً لها، فلا تظهر فجوة', () {
      // Arrange — ضِعف المقاس: أكبر من المنطقة في الاتجاهين.
      final print = DesignPlacement.printAreaIn(bagRect, bag);

      // Act — يُدفع إلى أقصى ما يستطيع.
      final rect = draggedTo(const Offset(10, 10), scale: 2);

      // Assert — الحافة اليمنى لا تدخل داخل المنطقة: الفجوة البيضاء بين التصميم والهامش هي
      // بالضبط ما لا يريد الزبون أن يراه في المعاينة.
      expect(rect.right, greaterThanOrEqualTo(print.right - .001));
      expect(rect.left, lessThanOrEqualTo(print.left + .001));
    });

    test('القيد لا يعتمد على مقاس الشاشة', () {
      // Arrange — نفس الوضع، مرسوماً على شاشتين مختلفتين.
      const design = Size(500, 500);
      const placement = DesignPlacement(scale: 1.4, offset: Offset(5, -5));

      final small = DesignPlacement.printAreaIn(const Rect.fromLTWH(0, 0, 350, 450), bag);
      final large = DesignPlacement.printAreaIn(const Rect.fromLTWH(0, 0, 700, 900), bag);

      // Act
      final onSmall = placement.clamped(small, design).rectIn(small, design);
      final onLarge = placement.clamped(large, design).rectIn(large, design);

      // Assert — نفس الموضع نسبةً إلى المنطقة، مهما كان حجم ما رُسم عليه: دوران الهاتف يجب
      // ألّا يحرّك التصميم على الكيس.
      expect(
        (onSmall.left - small.left) / small.width,
        closeTo((onLarge.left - large.left) / large.width, .0001),
      );
    });

    test('التكبير محصورٌ بين حدّين', () {
      // Act
      final tiny = const DesignPlacement.initial().scaledBy(.001);
      final huge = const DesignPlacement.initial().scaledBy(1000);

      // Assert — تصميمٌ بحجم النملة وتصميمٌ لا يظهر منه إلا بكسل، كلاهما ليس معاينة.
      expect(tiny.scale, DesignPlacement.minScale);
      expect(huge.scale, DesignPlacement.maxScale);
    });
  });
}
