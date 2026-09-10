import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Where a screen leaves what it hands back to the screen that opened it.
///
/// The obvious channel is `pop(result)`, and for a screen that ends in an answer — a form, a
/// picker, a status move — it still is: the user either finishes it or walks out of it, and
/// walking out means «nothing».
///
/// It does not work for a screen the user simply **leaves**. A detail screen has no finish: it
/// hands back whatever the row looks like now, whenever the user goes. Both back gestures — the
/// iOS edge swipe and the Android system back — pop with no result at all, so such a screen used
/// to wear `PopScope(canPop: false)` and pop its own result from there. That bought the row and
/// sold the gesture: Flutter switches the back gesture off for any route that says it might veto
/// a pop ([ModalRoute.popGestureEnabled] returns false on `RoutePopDisposition.doNotPop`), so
/// every detail screen in the app had a dead edge and only the arrow worked.
///
/// So the row travels **beside** the route instead of through the pop. The opener makes a slot
/// with [PushForResult.pushForResult] and reads it once the screen is gone; the screen writes
/// into it with [HandBack.handBack] as each new reading arrives. The arrow, the Android button,
/// the edge swipe and a bare `pop()` all land on the same value, because none of them is
/// carrying it.
class PopResult {
  PopResult(this.extra);

  /// What the opener would have passed as `extra`. The slot takes that seat on the route, so
  /// route builders read [RoutePayload.payload] rather than `state.extra`.
  final Object? extra;

  /// The newest thing the screen has to say, or null for «nothing the opener does not have».
  Object? value;
}

extension PushForResult on BuildContext {
  /// Opens [location] and answers with what that screen handed back, however it was left.
  ///
  /// The push result itself is deliberately ignored: a screen either hands back through the slot
  /// or it does not, and mixing the two channels is how one of them quietly stops being read.
  Future<T?> pushForResult<T extends Object>(String location, {Object? extra}) async {
    final slot = PopResult(extra);

    await push<void>(location, extra: slot);

    return slot.value as T?;
  }
}

extension HandBack on BuildContext {
  /// From inside a screen: what the opener should redraw once this screen is gone.
  ///
  /// Call it with every reading, not only the interesting ones — null puts the answer back to
  /// «nothing changed», which is what makes an edit that was undone cost the list nothing.
  ///
  /// Does nothing when the screen was opened with a plain `push`. Not every opener wants an
  /// answer, and a screen must not have to know which kind opened it.
  ///
  /// Nor when there is no router overhead at all — a screen pumped on its own in a widget test.
  /// `GoRouterState.of` throws there, and a screen saying something nobody asked to hear is not
  /// an error worth failing a test over.
  void handBack(Object? value) {
    if (GoRouter.maybeOf(this) == null) return;

    final slot = GoRouterState.of(this).extra;

    if (slot is PopResult) slot.value = value;
  }
}

extension RoutePayload on GoRouterState {
  /// The `extra` the opener passed, with any result slot lifted off it.
  ///
  /// **Route builders read this and never `extra`.** A screen opened with
  /// [PushForResult.pushForResult] carries a [PopResult] in that seat, and a builder that cast
  /// `extra` straight to its own type would see the wrapper instead of the object.
  Object? get payload => switch (extra) {
    final PopResult slot => slot.extra,
    final Object? other => other,
  };
}
