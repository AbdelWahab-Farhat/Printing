import 'dart:ui' as ui;

import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/tools/models/bag_preview_painter.dart';
import 'package:dayaa/features/tools/models/bag_type.dart';
import 'package:dayaa/features/tools/models/design_placement.dart';
import 'package:flutter/material.dart';

/// الكيس ومعه التصميم، ويداً تحرّكه.
///
/// **القيد يُطبَّق عند كل إطار لا عند نهاية السحب.** الإصبع لا يستطيع أن يجرّ التصميم خارج
/// منطقة الطباعة ثم يراه يقفز راجعاً حين يُرفع: المقاومة يجب أن تُحسّ لحظةَ تجاوز الحدّ، وهي
/// الطريقة الوحيدة التي يفهم بها المستخدم أن هناك حدّاً أصلاً.
class BagCanvas extends StatelessWidget {
  const BagCanvas({
    required this.bag,
    required this.mockup,
    required this.design,
    required this.placement,
    required this.showGuides,
    required this.onPlacementChanged,
    super.key,
  });

  final BagType bag;
  final ui.Image? mockup;
  final ui.Image? design;
  final DesignPlacement placement;
  final bool showGuides;

  /// يُنادى بالوضع **بعد تقييده**، فلا يصل إلى أحد وضعٌ غير مسموح.
  final ValueChanged<DesignPlacement> onPlacementChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final sheet = mockup;
        final image = design;

        // بلا صورة كيسٍ لا وجه ولا منطقة طباعة ولا شيء يُسحب.
        final printArea = sheet == null
            ? Rect.zero
            : DesignPlacement.printAreaIn(
                BagPreviewPainter.faceIn(BagPreviewPainter.imageRectIn(size, sheet), bag),
                bag,
              );

        return _Gestures(
          // لا إيماءات قبل أن يوجد تصميم: كيسٌ فارغ يتحرّك تحت الإصبع يوحي بأن شيئاً حدث.
          enabled: image != null && sheet != null,
          printArea: printArea,
          designSize: image == null
              ? Size.zero
              : Size(image.width.toDouble(), image.height.toDouble()),
          placement: placement,
          onChanged: onPlacementChanged,
          child: CustomPaint(
            painter: BagPreviewPainter(
              bag: bag,
              mockup: sheet,
              placement: placement,
              design: image,
              showGuides: showGuides,
              guideColor: context.colorScheme.primary,
              marginColor: context.colorScheme.onSurface.withValues(alpha: .10),
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

/// السحب والقرص، مقيَّدين.
class _Gestures extends StatefulWidget {
  const _Gestures({
    required this.enabled,
    required this.printArea,
    required this.designSize,
    required this.placement,
    required this.onChanged,
    required this.child,
  });

  final bool enabled;
  final Rect printArea;
  final Size designSize;
  final DesignPlacement placement;
  final ValueChanged<DesignPlacement> onChanged;
  final Widget child;

  @override
  State<_Gestures> createState() => _GesturesState();
}

class _GesturesState extends State<_Gestures> {
  /// الوضع لحظةَ نزول الإصبع، وقياسُ القرصة عندها.
  ///
  /// **التكبير يُحسب من بداية القرصة لا من الإطار السابق.** `scale` في `ScaleUpdateDetails` هو
  /// نسبةٌ إلى لحظة البداية؛ ضربُه في الوضع الحالي كل إطار يضاعفه أُسّياً، فتقفز الصورة من ربع
  /// المقاس إلى أقصاه في نصف قرصة.
  DesignPlacement _start = const DesignPlacement.initial();
  Offset _focal = Offset.zero;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return GestureDetector(
      onScaleStart: (details) {
        _start = widget.placement;
        _focal = details.focalPoint;
      },
      onScaleUpdate: (details) {
        final moved = _start
            .scaledBy(details.scale)
            .movedBy(details.focalPoint - _focal, widget.printArea);

        widget.onChanged(moved.clamped(widget.printArea, widget.designSize));
      },
      child: widget.child,
    );
  }
}
