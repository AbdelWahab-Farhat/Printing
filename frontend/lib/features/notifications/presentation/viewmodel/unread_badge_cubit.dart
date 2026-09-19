import 'package:dayaa/features/notifications/presentation/viewmodel/unread_badge_state.dart';
import 'package:dayaa/features/notifications/usecases/get_unread_count.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The number on the bell, and nothing else.
///
/// Provided **above the shell** so it survives tab switches — the bell is in the app bar, which
/// outlives every page under it.
///
/// **Refreshed on events, never on a timer.** It reloads on sign-in, on app resume, when a push
/// arrives in the foreground, and on returning from the notifications list. Polling every N
/// seconds to catch what push already delivers is battery spent duplicating a working channel,
/// and it would keep doing it all night on a phone left on a shop counter.
class UnreadBadgeCubit extends Cubit<UnreadBadgeState> {
  UnreadBadgeCubit(this._getUnreadCount) : super(const UnreadBadgeState.initial());

  final GetUnreadCount _getUnreadCount;

  Future<void> load() async {
    // Deliberately no `loading` emit when a count is already on screen: the badge would blink to
    // nothing and back on every resume, which reads as a bug. The first fetch shows nothing
    // anyway, because `initial` draws a bare bell.
    if (state is! UnreadBadgeLoaded) emit(const UnreadBadgeState.loading());

    final result = await _getUnreadCount();
    if (isClosed) return;

    result.fold(
      (failure) => emit(UnreadBadgeState.failure(failure)),
      (unread) => emit(UnreadBadgeState.loaded(unread.count)),
    );
  }

  /// Sets the badge from a number the app already holds, without a request.
  ///
  /// **Every write endpoint that changes the count answers with the new one**, so a round trip
  /// to ask what we were just told would only delay the badge catching up with the screen.
  /// Opening a ticket's conversation is the case this was added for: the mark-read call returns
  /// the account's new total, and the bell must not go on showing what it cleared.
  void setCount(int count) => emit(UnreadBadgeState.loaded(count < 0 ? 0 : count));

  /// Drops the badge to zero without a request — for «قراءة الكل», where the app already knows
  /// the answer.
  void clear() => setCount(0);
}
