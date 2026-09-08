import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/permission_gate.dart';
import 'package:dayaa/features/notifications/models/app_notification.dart';
import 'package:dayaa/features/notifications/presentation/viewmodel/notifications_cubit.dart';
import 'package:dayaa/features/notifications/presentation/viewmodel/unread_badge_cubit.dart';
import 'package:dayaa/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// صندوق الإشعارات — everything this account has been told.
///
/// **Works on every phone from day one, push or no push.** It is a plain authenticated endpoint
/// and owes FCM nothing, which is worth knowing when somebody asks why iPhones «ما عندهاش
/// إشعارات»: the mailbox is complete there too; the phone is simply not woken by it until the
/// APNs key is in place.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<NotificationsCubit>()
      // The badge lives above the shell and outlives this screen, so reading something here has
      // to tell it. Wired rather than read from context inside the Cubit, which would point the
      // ViewModel at the widget tree.
      ..onUnreadCountChanged = _refreshBadge
      ..load();
  }

  void _refreshBadge() {
    if (!mounted) return;
    context.read<UnreadBadgeCubit>().load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإشعارات'),
          actions: [
            // Beside the thing it produces, not in the drawer: sending is rare, and the list is
            // where the sender comes to confirm it arrived.
            //
            // A courtesy, never a boundary — `can:notifications.broadcast` on the route is the
            // boundary. Gated on `can` and not `isAdmin`: they agree today only because no role
            // holds this permission yet, and the day somebody ticks it onto «مدير الإنتاج» the
            // server would start accepting their announcements while the app went on hiding the
            // button.
            PermissionGate(
              permission: AppPermission.broadcastNotifications,
              child: IconButton(
                tooltip: 'إشعار عام',
                onPressed: () => context.push(Routes.composeAnnouncement),
                icon: const Icon(Icons.campaign_outlined),
              ),
            ),
            TextButton(
              onPressed: () async {
                // Read before the await, not after: the badge Cubit is resolved from a context
                // that may be gone by the time the request returns.
                final badge = context.read<UnreadBadgeCubit>();
                await _cubit.markAllRead();
                badge.clear();
              },
              child: const Text('قراءة الكل'),
            ),
          ],
        ),
        body: BlocBuilder<NotificationsCubit, PagedState<AppNotification>>(
          builder: (context, state) {
            return PagedListView<AppNotification>(
              state: state,
              onLoadMore: _cubit.loadMore,
              onRefresh: _cubit.refresh,
              emptyMessage: 'لا توجد إشعارات',
              itemBuilder: (context, notification, index) => NotificationTile(
                notification: notification,
                onTap: () => _open(notification),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Marks read, then goes — in that order, because the mark is optimistic and the row should
  /// already look read by the time the user comes back.
  ///
  /// **An unrecognised route lands back here, never on the error page.** An older app against a
  /// newer backend is the ordinary case for this, and a tap that goes nowhere is acceptable
  /// where a tap that shows a crash screen is not.
  Future<void> _open(AppNotification notification) async {
    await _cubit.markRead(notification);
    if (!mounted || !notification.opensSomewhere) return;

    try {
      await context.push(notification.route!);
    } on Exception {
      // Deliberately silent: the notification was still read, and the person is still looking at
      // their mailbox. Saying «تعذّر فتح الوجهة» would be true and useless.
    }
  }
}
