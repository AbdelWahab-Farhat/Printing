import 'package:dayaa_client/core/widgets/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// أيقونة SVG تتصرّف كـ`Icon`: مقاسها ولونها من `IconTheme` الذي حولها، فيلوّنها `IconButton`
/// وشريطُ التطبيق والوضعان الفاتح والداكن كما يلوّنون أيّ أيقونة.
///
/// Arrange - Act - Assert throughout.
void main() {
  testWidgets('takes its size and colour from the IconTheme around it, like Icon', (
    tester,
  ) async {
    // Arrange
    const app = MaterialApp(
      home: IconTheme(
        data: IconThemeData(color: Colors.red, size: 30),
        child: SvgIcon(SvgIcon.cart),
      ),
    );

    // Act
    await tester.pumpWidget(app);

    // Assert
    final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));

    expect(picture.width, 30);
    expect(picture.height, 30);
    expect(picture.colorFilter, const ColorFilter.mode(Colors.red, BlendMode.srcIn));
    expect((picture.bytesLoader as SvgAssetLoader).assetName, SvgIcon.cart);
  });

  test('the cart is bundled with the app, and is an SVG', () async {
    // Arrange — ملفٌّ غير مُعلَنٍ في pubspec لا يُحزَم، والأيقونة تختفي بلا خطأٍ على الشاشة.
    TestWidgetsFlutterBinding.ensureInitialized();

    // Act
    final source = await rootBundle.loadString(SvgIcon.cart);

    // Assert
    expect(source, contains('<svg'));
  });
}
