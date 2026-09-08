import 'package:dayaa/core/error/failure.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'unread_badge_state.freezed.dart';

/// What the bell knows.
///
/// A sealed union rather than adjacent nullable fields, per RULES §4 — «loaded with a count» and
/// «failed» are different facts, and a `count` of 0 beside a non-null `failure` is a state this
/// shape cannot express.
@freezed
sealed class UnreadBadgeState with _$UnreadBadgeState {
  /// Before the first fetch. **The bell still draws** — with no badge, not with a zero.
  const factory UnreadBadgeState.initial() = UnreadBadgeInitial;

  const factory UnreadBadgeState.loading() = UnreadBadgeLoading;

  const factory UnreadBadgeState.loaded(int count) = UnreadBadgeLoaded;

  /// The count could not be fetched. **The bell is still tappable** — the mailbox behind it may
  /// well load fine, and hiding the way in because a number failed would be the worse trade.
  const factory UnreadBadgeState.failure(Failure failure) = UnreadBadgeFailure;
}
