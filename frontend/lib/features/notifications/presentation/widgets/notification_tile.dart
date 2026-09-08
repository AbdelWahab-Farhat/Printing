import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/features/notifications/models/app_notification.dart';
import 'package:flutter/material.dart';

/// One row of the mailbox.
///
/// **Draws what the server sent and interprets nothing.** `title`, `body` and `route` arrive
/// rendered; the only thing decided here is which glyph goes beside them, and even that falls
/// back rather than failing. A `switch` on `notification.type` in this file would end the
/// property the whole feature exists for — that a type added to the server next month shows up
/// in a build compiled today.
class NotificationTile extends StatelessWidget {
  const NotificationTile({required this.notification, this.onTap, super.key});

  final AppNotification notification;

  /// Null when there is nowhere to go. The tile then renders as a message rather than a control
  /// — an inert row reads as "this is just telling you something", where a tap that visibly does
  /// nothing reads as a broken app.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = !notification.isRead;

    return ListTile(
      onTap: notification.opensSomewhere ? onTap : null,
      leading: Icon(
        _iconFor(notification.icon),
        color: unread ? theme.colorScheme.primary : theme.colorScheme.outline,
      ),
      // Body-size type, not a caption: this row is the message itself, not a label on something
      // else, and the title is what somebody scanning the list actually reads.
      title: Text(
        notification.title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.body, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            '${notification.createdAt.relativeDayLabel} · ${notification.createdAt.timeLabel}',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
          ),
        ],
      ),
      // The unread mark is a dot rather than a bolder background: the list is read in a shop,
      // often in sunlight, and a filled row behind Arabic text costs more legibility than the
      // distinction is worth.
      trailing: unread
          ? Icon(Icons.circle, size: 10, color: theme.colorScheme.primary)
          : null,
      isThreeLine: true,
    );
  }

  /// The server's small, stable icon vocabulary.
  ///
  /// **An unknown key is not an error — it is a newer backend**, and the bell must still draw.
  /// That fallback is not defensive padding; it is the mechanism that lets the server ship a new
  /// notification type without waiting for an app release.
  IconData _iconFor(String key) => switch (key) {
        'warning' => AppIcons.urgent,
        'order' => AppIcons.orders,
        'inventory' => AppIcons.warehouse,
        'money' => AppIcons.payment,
        // The same glyph as the fallback today, named anyway: when a megaphone is added to
        // AppIcons it changes here, in one place, rather than being hunted for.
        'announcement' => AppIcons.notifications,
        _ => AppIcons.notifications,
      };
}
