import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/widgets/product_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// صورة المنتج تطير من «أضف إلى السلة» إلى أيقونة السلة في الشريط — تأكيد الإضافة بلا كلمة.
///
/// **إزاحةٌ وشفافية، ولا شيء غيرهما** (قاعدة الحركة في RULES §7): الصورة بمقاسٍ واحد طوال
/// الطريق — لا تصغر وهي تقترب من السلة — تصعد من الزر ثم تميل إلى السلة في قوس، وتبهت في ربع
/// طريقها الأخير.
///
/// **ومع تقليل الحركة لا تطير أصلاً**، ولا يعمل مؤقّت: المستدعي لا يطلقها حين
/// `MediaQuery.disableAnimationsOf` صحيحة، ويقول «أُضيف إلى سلتك» بالكلمات بدلها.
abstract final class CartFlight {
  /// كم تستغرق الرحلة من الزر إلى السلة.
  static const duration = Duration(milliseconds: 700);

  /// تطير [image] من مركز [from] إلى مركز [to]. لا تفعل شيئاً إن لم يكن أحدهما مرسوماً.
  static void launch(
    BuildContext context, {
    required GlobalKey from,
    required GlobalKey to,
    required String? image,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    final canvas = overlay?.context.findRenderObject();
    if (overlay == null || canvas is! RenderBox) return;

    final start = _centerOf(from, canvas);
    final end = _centerOf(to, canvas);
    if (start == null || end == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _Flight(start: start, end: end, image: image, onLanded: entry.remove),
    );
    overlay.insert(entry);
  }

  static Offset? _centerOf(GlobalKey key, RenderBox canvas) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;

    return canvas.globalToLocal(box.localToGlobal(box.size.center(Offset.zero)));
  }
}

class _Flight extends StatefulWidget {
  const _Flight({
    required this.start,
    required this.end,
    required this.image,
    required this.onLanded,
  });

  final Offset start;
  final Offset end;
  final String? image;
  final VoidCallback onLanded;

  @override
  State<_Flight> createState() => _FlightState();
}

class _FlightState extends State<_Flight> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: CartFlight.duration,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(widget.onLanded);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final size = 44.w;

    // نقطة التحكّم فوق الزر وعلى ارتفاع السلة: تصعد الصورة أولاً، ثم تميل إليها.
    final start = widget.start;
    final end = widget.end;
    final bend = Offset(start.dx, end.dy);

    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = Curves.easeInOutCubic.transform(_controller.value);
            final rest = 1 - t;
            final point = start * (rest * rest) + bend * (2 * rest * t) + end * (t * t);

            return Stack(
              children: [
                Positioned(
                  left: point.dx - size / 2,
                  top: point.dy - size / 2,
                  child: Opacity(
                    opacity: t < 0.75 ? 1 : ((1 - t) / 0.25).clamp(0.0, 1.0),
                    child: child,
                  ),
                ),
              ],
            );
          },
          child: Container(
            key: const ValueKey('cart-flight'),
            width: size,
            height: size,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: scheme.outlineVariant, width: 1.5),
            ),
            child: ProductThumbnail(image: widget.image),
          ),
        ),
      ),
    );
  }
}
