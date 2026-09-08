import 'dart:async';

import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/features/notifications/presentation/viewmodel/unread_badge_cubit.dart';
import 'package:dayaa/features/notifications/presentation/viewmodel/unread_badge_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The bell, with its count.
///
/// **One widget for two places.** The staff shell has an app bar and so does the investor
/// portal, and the portal sits *outside* the shell — top level beside the splash and the login
/// screen, so the investor gets a page and no way out of it. A badge written inline in `RootPage`
/// would therefore be invisible to every investor, and the whole cost of not making that mistake
/// is this file existing.
///
/// Reads [UnreadBadgeCubit], which is provided above the shell so the count survives tab
/// switches.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();

    // Two of the four refresh moments live here, because the bell is the thing that shows the
    // number and is present in both shells:
    //   * mounted — a signed-in session that has never fetched a count yet;
    //   * resumed — pushes that arrived while the app was in the background.
    // The other two are the push arriving in the foreground (wired in `main`) and returning
    // from the list (below). **None of them is a timer**: polling for what push already
    // delivers is battery spent on a phone that sits on a counter all night.
    final cubit = context.read<UnreadBadgeCubit>();
    if (cubit.state is UnreadBadgeInitial) unawaited(cubit.load());

    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(context.read<UnreadBadgeCubit>().load()),
    );
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UnreadBadgeCubit, UnreadBadgeState>(
      builder: (context, state) {
        // `initial` and `failure` both draw a bare bell on purpose. A count that failed to load
        // is not a zero, and must not be shown as one; and the mailbox behind the bell may well
        // open fine, so the way in stays available either way.
        final count = state is UnreadBadgeLoaded ? state.count : 0;

        return IconButton(
          tooltip: 'الإشعارات',
          onPressed: () async {
            await context.push(Routes.notifications);
            if (!context.mounted) return;
            // Coming back is one of the four moments the count is refreshed — the user may have
            // read everything while they were in there.
            await context.read<UnreadBadgeCubit>().load();
          },
          icon: Badge(
            isLabelVisible: count > 0,
            // Capped for width, not for truth: «+99» keeps the app bar from reflowing when a
            // long weekend of orders piles up. Western digits, because that is what every other
            // number in this app renders as - see `GroupedDigits`.
            label: Text(count > 99 ? '+99' : '$count'),
            child: Icon(AppIcons.notifications),
          ),
        );
      },
    );
  }
}
