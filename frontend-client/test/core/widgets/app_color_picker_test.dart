import 'package:dayaa_client/core/widgets/app_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// منتقي اللون المشترك — مربّع التشبّع والإضاءة وشريط الصبغة، مقلوبان في العربية.
///
/// Arrange - Act - Assert throughout.
void main() {
  Widget host({required HSVColor color, required ValueChanged<HSVColor> onChanged}) {
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: AppColorPicker(color: color, onChanged: onChanged),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('the top-left corner of the square is the full colour', (tester) async {
    // Arrange
    HSVColor? picked;
    await tester.pumpWidget(
      host(
        color: const HSVColor.fromAHSV(1, 200, 0.2, 0.3),
        onChanged: (hsv) => picked = hsv,
      ),
    );
    final area = find.byKey(AppColorPicker.saturationKey);

    // Act
    await tester.tapAt(tester.getTopLeft(area) + const Offset(1, 1));

    // Assert — the hue is kept; only saturation and value move.
    expect(picked?.hue, 200);
    expect(picked!.saturation, closeTo(1, 0.01));
    expect(picked!.value, closeTo(1, 0.01));
  });

  testWidgets('the hue bar starts at red on the right', (tester) async {
    // Arrange
    HSVColor? picked;
    await tester.pumpWidget(
      host(
        color: const HSVColor.fromAHSV(1, 200, 0.5, 0.5),
        onChanged: (hsv) => picked = hsv,
      ),
    );
    final bar = tester.getRect(find.byKey(AppColorPicker.hueKey));

    // Act
    await tester.tapAt(Offset(bar.right - 1, bar.center.dy));

    // Assert — saturation and value are kept.
    expect(picked!.hue, closeTo(0, 2));
    expect(picked!.saturation, 0.5);
    expect(picked!.value, 0.5);
  });
}
