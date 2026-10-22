import 'dart:async';
import 'dart:math' as math;

import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// اسحب الرسالة جانباً لتردّ عليها، كما في بريمولا وتيليغرام وواتساب.
///
/// **السحبُ نحو نهاية السطر وحده** — اليسارُ بالعربية — فلا يتنازع مع التمرير ولا مع الرجوع.
/// الرسالةُ تتبع الإصبع إلى حدٍّ ثم تقف، والسهمُ يظهر خلفها بالشفافية؛ وتجاوزُ العتبة يقول «ردّ»
/// بلمسةٍ خفيفة، والإفلاتُ يردّ ويعيدها مكانها.
///
/// **إزاحةٌ وشفافيةٌ وحدهما** (RULES §٧)، و«تقليل الحركة» يعيدها مكانها بلا رجعةٍ متحرّكة.
class SwipeToReply extends StatefulWidget {
  const SwipeToReply({required this.child, required this.onReply, this.enabled = true, super.key});

  final Widget child;
  final VoidCallback onReply;
  final bool enabled;

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply> with SingleTickerProviderStateMixin {
  /// المسافةُ التي تقول «ردّ».
  double get _threshold => 56.w;

  /// أبعدُ ما تتبع فيه الرسالةُ الإصبع.
  double get _limit => 72.w;

  late final AnimationController _back = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    value: 0,
  )..addListener(() => setState(() => _offset = _released * (1 - _back.value)));

  double _offset = 0;
  double _released = 0;
  bool _armed = false;

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  /// نهايةُ السطر: اليسار بالعربية، فالسحبُ سالبٌ على المحور.
  double get _sign => Directionality.of(context) == TextDirection.rtl ? -1 : 1;

  void _onUpdate(DragUpdateDetails details) {
    final next = (_offset + details.delta.dx * _sign).clamp(0.0, _limit);
    final armed = next >= _threshold;

    if (armed && !_armed) unawaited(HapticFeedback.selectionClick());

    setState(() {
      _offset = next;
      _armed = armed;
    });
  }

  void _onEnd(DragEndDetails _) {
    if (_armed) widget.onReply();

    _armed = false;
    _released = _offset;

    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _offset = 0);
    } else {
      unawaited(_back.forward(from: 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    final scheme = context.colorScheme;
    final shown = math.min(1.0, _offset / _threshold);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: _onUpdate,
      onHorizontalDragEnd: _onEnd,
      child: Stack(
        alignment: AlignmentDirectional.centerEnd,
        children: [
          PositionedDirectional(
            end: 8.w,
            child: Opacity(
              opacity: shown,
              child: Icon(AppIcons.reply, size: 22.sp, color: scheme.primary),
            ),
          ),
          Transform.translate(offset: Offset(_offset * _sign, 0), child: widget.child),
        ],
      ),
    );
  }
}
