import 'package:flutter/material.dart';

/// Puts the keyboard away when the user taps anywhere that is not a field.
///
/// Wrapped once around the whole app in [DayaaApp], so it is a property of the app rather
/// than something every screen has to remember. A form that only closes its keyboard on some
/// screens is worse than one that never does: the user stops trusting the gesture and starts
/// reaching for the system back button, which on Android also pops the route.
///
/// **Why not `TextField.onTapOutside`.** Flutter's default for that callback only hides the
/// keyboard on desktop and web; on Android and iOS it deliberately keeps focus. Setting it on
/// [AppTextField] would fix every field that goes through the shared widget and miss the raw
/// `TextFormField`s — the price grid on the add-product screen is a dozen of them. One wrapper
/// covers the app, including anything added later by somebody who never reads this file.
///
/// **Why a tap and not a scroll.** Only `onTap` fires here, so a drag leaves the keyboard
/// alone. Dismissing on scroll sounds tidy and makes a long form unusable: reaching the next
/// field means scrolling, and the keyboard would shut on the way.
///
/// **Why this does not steal taps.** The gesture arena resolves in favour of the deepest
/// recogniser, so a button, a list row or a chip still wins its own tap — this only takes the
/// ones nothing else claimed. `HitTestBehavior.translucent` is what lets it see taps landing on
/// bare background, which is exactly where a user taps to mean "I am done typing".
class DismissKeyboard extends StatelessWidget {
  const DismissKeyboard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      // Read through the root focus scope rather than `FocusManager.instance.primaryFocus`
      // directly: with nothing focused there is nothing to unfocus, and calling it anyway
      // would hand focus back to the scope for no reason on every stray tap.
      onTap: () {
        final focus = FocusManager.instance.primaryFocus;

        if (focus != null && focus.hasPrimaryFocus) focus.unfocus();
      },
      child: child,
    );
  }
}
