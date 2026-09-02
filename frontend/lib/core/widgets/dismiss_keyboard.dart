import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Puts the keyboard away when the user taps anywhere that is not a field.
///
/// Wrapped once around the whole app in [DayaaApp], so it is a property of the app rather
/// than something every screen has to remember. A form that only closes its keyboard on some
/// screens is worse than one that never does: the user stops trusting the gesture and starts
/// reaching for the system back button, which on Android also pops the route.
///
/// **Why not `TextField.onTapOutside`.** It fires on pointer down, outside the gesture arena.
/// That is perfect for menus and awkward for phone keyboards: on some real devices the first
/// touch that opens the IME can be followed by a layout shift, and an eager outside callback is
/// enough to take focus straight back. This wrapper waits for a complete tap that started while
/// a field was already focused, so the first tap on a field is never mistaken for a dismissal.
///
/// **Why a tap and not a scroll.** The wrapper follows one pointer from down to up and drops the
/// dismissal as soon as it moves past Flutter's tap slop. Dismissing on scroll sounds tidy and
/// makes a long form unusable: reaching the next field means scrolling, and the keyboard would
/// shut on the way.
///
/// **Why this does not steal taps.** A [Listener] observes pointer events without claiming the
/// gesture, so buttons, rows and chips still receive their own taps. Tracking the movement keeps
/// scrolls from counting as "done typing".
class DismissKeyboard extends StatefulWidget {
  const DismissKeyboard({required this.child, super.key});

  final Widget child;

  @override
  State<DismissKeyboard> createState() => _DismissKeyboardState();
}

class _DismissKeyboardState extends State<DismissKeyboard> {
  _DismissCandidate? _candidate;

  void _onPointerDown(PointerDownEvent event) {
    final focus = FocusManager.instance.primaryFocus;

    _candidate = focus == null
        ? null
        : _DismissCandidate(
            pointer: event.pointer,
            focus: focus,
            origin: event.position,
          );
  }

  void _onPointerMove(PointerMoveEvent event) {
    final candidate = _candidate;
    if (candidate == null || candidate.pointer != event.pointer) return;

    if ((event.position - candidate.origin).distance > kTouchSlop) {
      _candidate = null;
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (_candidate?.pointer == event.pointer) _candidate = null;
  }

  void _onPointerUp(PointerUpEvent event) {
    final candidate = _candidate;
    if (candidate == null || candidate.pointer != event.pointer) return;
    _candidate = null;

    final focus = candidate.focus;
    if (!focus.hasPrimaryFocus || _contains(focus, event.position)) return;

    focus.unfocus();
  }

  bool _contains(FocusNode focus, Offset position) {
    final focusedContext = focus.context;
    final renderObject = focusedContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) return false;

    final bounds = renderObject.localToGlobal(Offset.zero) & renderObject.size;

    return bounds.inflate(kTouchSlop).contains(position);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerCancel: _onPointerCancel,
      onPointerUp: _onPointerUp,
      child: widget.child,
    );
  }
}

class _DismissCandidate {
  const _DismissCandidate({
    required this.pointer,
    required this.focus,
    required this.origin,
  });

  final int pointer;
  final FocusNode focus;
  final Offset origin;
}
