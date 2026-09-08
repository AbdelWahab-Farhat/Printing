import 'package:freezed_annotation/freezed_annotation.dart';

part 'unread_count.freezed.dart';
part 'unread_count.g.dart';

/// `{ "count": 3 }` — the whole of what the bell needs.
///
/// A type rather than a bare `int` for one reason: it is the shape the endpoint publishes, and a
/// repository returning `Either<Failure, int>` invites a caller to read a failure's absence as a
/// zero. The count is also the badge's only input, so it stays cheap on purpose — the bell never
/// fetches a page of notifications to find out how many are unread.
@freezed
abstract class UnreadCount with _$UnreadCount {
  const factory UnreadCount({required int count}) = _UnreadCount;

  factory UnreadCount.fromJson(Map<String, dynamic> json) => _$UnreadCountFromJson(json);
}
