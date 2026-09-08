import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_notification.freezed.dart';
part 'app_notification.g.dart';

/// إشعار — one item in an account's own mailbox, already rendered by the server.
///
/// **Named `AppNotification`, not `Notification`.** `dart:ui` owns that name and so does
/// `firebase_messaging`; a class called `Notification` here turns every file that touches both
/// into an import-shadowing puzzle for no gain.
///
/// **[title], [body], [icon] and [route] arrive rendered and are drawn as they come.** Nothing in
/// this app may `switch` on [type] to decide what to show — that is not a style preference, it is
/// the property the whole feature is built on: a notification type added to the server next month
/// appears in a build compiled today, with no store submission. The moment a widget writes
/// `if (type == 'stock.low')`, that is gone and every future type needs a release.
///
/// [type] is still parsed and kept, because grouping, filtering and analytics are allowed to read
/// it. Deciding what a row *looks like* is not.
@freezed
abstract class AppNotification with _$AppNotification {
  const factory AppNotification({
    required int id,

    /// The stable dotted string the server publishes — `order.shortage`, `announcement.manual`.
    /// Read it, never branch on it to build the UI. See the class docblock.
    required String type,

    /// What this kind is called, for a screen that groups or filters. Server-supplied, so a new
    /// type is legible without an app release.
    @JsonKey(name: 'type_label') required String typeLabel,

    required String title,
    required String body,

    /// A key from the server's small, stable vocabulary — `warning`, `announcement`, … — and
    /// **not** an icon name from any particular toolkit. An unrecognised key is a newer backend,
    /// not an error: the tile falls back to a plain bell and still draws.
    required String icon,

    /// Where tapping goes, and **nullable by design**. An announcement («اجتماع الساعة ٤») has
    /// nothing to open, and that is the common case rather than an edge one — see
    /// [opensSomewhere].
    String? route,

    /// What the notification is about, when it is about anything. Both null together.
    @JsonKey(name: 'subject_type') String? subjectType,
    @JsonKey(name: 'subject_id') int? subjectId,

    @JsonKey(name: 'is_read') required bool isRead,

    /// When this account read it — null while unread. Separate from [isRead] because the server
    /// publishes both, and a list that sorts or groups by "read this morning" needs the instant.
    @JsonKey(name: 'read_at') DateTime? readAt,

    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _AppNotification;

  const AppNotification._();

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);

  /// Whether tapping this row should do anything at all.
  ///
  /// A tile with no route must not be tappable — offering a tap that visibly does nothing reads
  /// as a broken app, where an inert row reads as a message. The router still has the last word
  /// on a route it does not recognise: an older app against a newer backend lands back on the
  /// list, never on the error page.
  bool get opensSomewhere => route != null && route!.isNotEmpty;
}
