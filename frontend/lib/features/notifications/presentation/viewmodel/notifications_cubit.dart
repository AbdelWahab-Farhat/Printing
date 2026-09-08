import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/features/notifications/models/app_notification.dart';
import 'package:dayaa/features/notifications/usecases/get_notifications.dart';
import 'package:dayaa/features/notifications/usecases/mark_all_read.dart';
import 'package:dayaa/features/notifications/usecases/mark_notification_read.dart';

/// The notifications list.
///
/// Inherits the debounce, the out-of-order guard and the append-don't-replace pagination from
/// [PagedCubit], and adds the two writes the screen can make.
///
/// **Reading a notification patches the row; it does not refetch the page.** The server's answer
/// to «علّمها مقروءة» carries no news — the app already knows what the row becomes — so a refetch
/// would spend a request to be told what it just did, and would jump the scroll position while
/// the user is still reading. Same reasoning as every other list in this app.
class NotificationsCubit extends PagedCubit<AppNotification> {
  NotificationsCubit(this._getNotifications, this._markRead, this._markAllRead);

  final GetNotifications _getNotifications;
  final MarkNotificationRead _markRead;
  final MarkAllRead _markAllRead;

  /// Narrows the list to unread. Held here rather than passed per call, because [refresh] and
  /// [loadMore] must keep asking the same question the user last asked.
  bool _unreadOnly = false;
  bool get unreadOnly => _unreadOnly;

  /// The badge's count is owned by `UnreadBadgeCubit`, which lives above the shell and outlives
  /// this screen. Marking something read here has to tell it — this is that wire, set by the
  /// page when it builds.
  void Function()? onUnreadCountChanged;

  @override
  Object identityOf(AppNotification item) => item.id;

  /// [search] is ignored: a mailbox has no search on the server, and pretending otherwise would
  /// filter the page already downloaded and call it the whole of it.
  @override
  Future<Either<Failure, Paginated<AppNotification>>> fetchPage({
    String? search,
    required int page,
  }) => _getNotifications(unreadOnly: _unreadOnly, page: page);

  /// Switches between «الكل» and «غير المقروءة» and reloads from page one.
  Future<void> setUnreadOnly({required bool value}) async {
    if (_unreadOnly == value) return;
    _unreadOnly = value;
    await load();
  }

  /// Marks one read and patches its row.
  ///
  /// Already-read rows are not re-sent: tapping to open an order should not spend a request
  /// saying what the server recorded the first time.
  ///
  /// **On the unread-only filter the row leaves the list**, because it no longer answers the
  /// question the list is asking — [removeById] rather than [replace] in that case.
  Future<void> markRead(AppNotification notification) async {
    if (notification.isRead) return;

    // Optimistic: the row changes now, and stays changed unless the server disagrees. A bell
    // that clears on tap and silently un-clears a second later is worse than one that is wrong.
    final read = notification.copyWith(isRead: true, readAt: DateTime.now());
    if (_unreadOnly) {
      removeById(notification.id);
    } else {
      replace(read);
    }
    onUnreadCountChanged?.call();

    final result = await _markRead(notification.id);
    if (isClosed) return;

    result.fold(
      (failure) {
        // Put it back exactly as it was. A 404 lands here too — somebody else's id — and the
        // honest response to that is the same: the row was never ours to change.
        if (_unreadOnly) {
          refresh();
        } else {
          replace(notification);
        }
        onUnreadCountChanged?.call();
      },
      (_) {},
    );
  }

  /// Empties the badge. Reloads rather than patching every row: this changes the whole page, and
  /// on the unread-only filter it empties the list outright.
  Future<void> markAllRead() async {
    final result = await _markAllRead();
    if (isClosed) return;

    result.fold(
      (_) {},
      (_) {
        onUnreadCountChanged?.call();
        refresh();
      },
    );
  }
}
