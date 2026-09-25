import 'package:dayaa_client/features/badges/presentation/viewmodel/badges_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Refetches the badges when the app comes back to the foreground.
///
/// **This is what «يعرف أنّ هناك رداً حين يفتح التطبيق» actually means.** A reply arrives while
/// the app is shut; nothing can tell this app about it — there are no sockets and no push
/// notifications — so the only honest moment to find out is the moment the customer returns.
/// [AppLifecycleState.resumed] is that moment, and it covers the cold start too, because a
/// freshly built app resumes into the foreground like any other.
///
/// **Wrapped once around the router**, so it is a property of the app rather than something
/// every screen has to remember. The first `WidgetsBindingObserver` in this codebase, and it
/// stays the only one unless something else earns one: an observer per feature is four places
/// to look when the app does something odd on resume.
///
/// **It refetches, it does not clear.** A resume is a reason to ask, never a reason to assume —
/// see [BadgesCubit.refresh], which keeps the last counts when the request fails.
class BadgeRefresher extends StatefulWidget {
  const BadgeRefresher({required this.child, super.key});

  final Widget child;

  @override
  State<BadgeRefresher> createState() => _BadgeRefresherState();
}

class _BadgeRefresherState extends State<BadgeRefresher>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // The cold start. **Not left to `resumed`**: on some platforms an app launched into the
    // foreground never posts a lifecycle change at all, and the badge would then wait for the
    // first background-and-return before ever appearing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BadgesCubit>().refresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only `resumed`. `inactive` fires for a notification shade pulled halfway down and for a
    // permission dialog, and refetching on those would be several requests for one glance at
    // the screen.
    if (state == AppLifecycleState.resumed) {
      context.read<BadgesCubit>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
