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

  /// Drops the badge to zero without a request — for «قراءة الكل», where the app already knows
  /// the answer and a round trip would only delay the badge catching up with the screen.
  void clear() => emit(const UnreadBadgeState.loaded(0));
}
