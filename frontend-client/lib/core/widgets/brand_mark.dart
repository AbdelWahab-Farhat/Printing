import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dayaa_client/core/theme/app_tones.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The Daaya mark beside the name «دعاية»: the top bar, the splash screen, and the band above
/// the sign-in screens.
///
/// **One widget at three sizes.** The FlyerX build drew its wordmark three times, once per
/// place, because each place needed a different colour for «Flyer». Here only the name's ink
/// changes ([color]: the page's `onSurface` by default, `onHeader` on the indigo band), so the
/// three became parameters of one widget.
///
/// **The mark sits on a white plate.** `assets/images/logo.png` was drawn for white, and on the
/// night surface or the indigo band its purple outline all but disappears. The plate is
/// [BrandTone.logoPlate], the same white the payment logos sit on. In daylight it is close to
/// the page and reads as the bare logo.
///
/// The mark comes first, so in a right-to-left app it stands at the reading edge, before the
/// name, the way the logo is printed beside it.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, required this.size, this.color});

  /// The name's font size, in logical pixels before `.sp`. The mark is scaled to match it.
  final double size;

  /// The name's ink. Null takes the page's `onSurface`.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final plate = size.sp * 1.3;

    // **Scaled down as one piece when the slot is narrower than the lockup**, as it can be in
    // the top bar between the balance and the cart at a large accessibility text size. A logo
    // that shrinks reads as the logo; a name cut to «دعا…» beside a full-size mark does not.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: plate,
            height: plate,
            padding: EdgeInsets.all(plate * 0.1),
            decoration: BoxDecoration(
              color: scheme.logoPlate,
              borderRadius: BorderRadius.circular(plate * 0.28),
            ),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
              // The name beside it already says «دعاية» to a screen reader.
              excludeFromSemantics: true,
            ),
          ),
          SizedBox(width: size.sp * 0.35),
          Text(
            'دعاية',
            style: context.textTheme.displaySmall?.copyWith(
              fontSize: size.sp,
              fontWeight: FontWeight.w900,
              // No negative tracking, unlike the Latin wordmark this replaced: letter spacing
              // pulls Arabic letters apart and breaks the joins between them.
              height: 1.2,
              color: color ?? scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// The logo's geometry, painted: a purple square and a green one, turned 42° and standing side by
/// side, the green passing behind the purple; and a smaller yellow square laid over both.
///
/// **Painted rather than drawn from `logo.png`** for the two places that use the mark as
/// decoration, much larger than the file and cut by the edge of the thing it sits on: the band
/// above the sign-in screens and the wallet card. A 512px raster would be soft there, and the
/// watermark needs the mark in one colour.
///
/// [opacity] applies to the whole mark at once, so where the yellow lies over a line the two do
/// not add up to a darker seam.
class DaayaMarkPainter extends CustomPainter {
  const DaayaMarkPainter({
    required this.fill,
    required this.firstLine,
    required this.secondLine,
    this.opacity = 1,
  });

  /// One colour for the whole mark: a watermark.
  const DaayaMarkPainter.single(Color color, {double opacity = 1})
    : this(fill: color, firstLine: color, secondLine: color, opacity: opacity);

  /// The square on top. Yellow in the logo.
  final Color fill;

  /// The front outline, on the reading start of the mark. Purple in the logo.
  final Color firstLine;

  /// The outline behind it. Green in the logo.
  final Color secondLine;

  final double opacity;

  // Measured on `logo.png`, in units of the purple square's side (centre of the stroke to centre
  // of the stroke), from the centre of the whole mark.
  static const _turn = 41.6 * math.pi / 180;
  static const _stroke = 0.054;
  static const _corner = 0.153;
  static const _first = Offset(-0.146, 0);
  static const _second = Offset(0.088, 0);
  static const _top = Offset(0.12, 0);
  static const _topSide = 0.795;
  static const _topCorner = 0.16;

  /// The whole mark is this many sides wide; the painter fits that width into its box.
  static const _span = 1.63;

  /// A rounded square of [side] turned by [_turn] about [centre].
  static Path _square(Offset centre, double side, double corner) {
    final local = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: side, height: side),
          Radius.circular(corner),
        ),
      );
    final (cos, sin) = (math.cos(_turn), math.sin(_turn));

    return local.transform(
      Float64List.fromList([
        cos, sin, 0, 0, //
        -sin, cos, 0, 0,
        0, 0, 1, 0,
        centre.dx, centre.dy, 0, 1,
      ]),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final unit = math.min(size.width, size.height) / _span;
    final stroke = _stroke * unit;
    final centre = size.center(Offset.zero);

    final first = _square(centre + _first * unit, unit, _corner * unit);
    final second = _square(centre + _second * unit, unit, _corner * unit);
    final top = _square(centre + _top * unit, _topSide * unit, _topCorner * unit);
    // The front square's outer edge: the green outline stops here, as if passing behind it.
    final front = _square(centre + _first * unit, unit + stroke, (_corner * unit) + stroke / 2);

    canvas.saveLayer(Offset.zero & size, Paint()..color = Color.fromRGBO(0, 0, 0, opacity));

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    canvas
      ..save()
      ..clipPath(Path.combine(PathOperation.difference, Path()..addRect(Offset.zero & size), front))
      ..drawPath(second, line..color = secondLine)
      ..restore()
      ..drawPath(first, line..color = firstLine)
      ..drawPath(top, Paint()..color = fill)
      ..restore();
  }

  @override
  bool shouldRepaint(DaayaMarkPainter oldDelegate) =>
      oldDelegate.fill != fill ||
      oldDelegate.firstLine != firstLine ||
      oldDelegate.secondLine != secondLine ||
      oldDelegate.opacity != opacity;
}
