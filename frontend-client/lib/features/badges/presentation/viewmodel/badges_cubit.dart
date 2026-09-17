import 'package:dayaa_client/features/badges/models/customer_badge.dart';
import 'package:dayaa_client/features/badges/usecases/get_badges.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What is waiting for the customer, held for the whole app.
///
/// **A singleton, like [CartCubit] and for a related reason**: the counts belong to the session
/// rather than to a screen, and a tile on «الرئيسية» and a future badge somewhere else must read
/// the same number. A per-screen instance would fetch again on every rebuild and disagree with
/// itself between tabs.
///
/// **The state is a plain map and there is no loading state.** A badge is decoration on a screen
/// that is already useful: a spinner where a number goes would be worse than the number arriving
/// a moment late, and a failure is simply the absence of a badge. Nothing here is ever reported
/// to the user — if the shop replied and the count could not be fetched, the thread is still
/// there to open.
///
/// **What refreshes it**, and it is deliberately a short list:
///   * the app starting,
///   * the app coming back to the foreground — see `BadgeRefresher`,
///   * «الرئيسية» being pulled down,
///   * a thread being read, which is the one moment a count is known to have changed.
///
/// It does **not** update while the app sits open and untouched. There are no sockets and no
/// push notifications in this project, so a reply arriving this second is seen when the customer
/// next returns to the app or pulls the home screen down. That is the honest limit of the cheap
/// answer, and it is written here so nobody has to rediscover it.
class BadgesCubit extends Cubit<Map<CustomerBadge, int>> {
  BadgesCubit({required GetBadges getBadges})
    : _getBadges = getBadges,
      super(const {});

  final GetBadges _getBadges;

  /// Fetches every count.
  ///
  /// **A failure leaves the last known counts alone** rather than clearing them. Blanking the
  /// badge because one request failed would tell the customer their unread replies had been
  /// dealt with, which is the one wrong thing this can say.
  Future<void> refresh() async {
    final result = await _getBadges();

    if (isClosed) return;

    result.fold(
      (_) {},
      (counts) => emit(counts),
    );
  }

  /// Takes a badge to zero without asking the server.
  ///
  /// For the moment a screen *knows* it cleared one — opening a support thread marks it read
  /// server-side, so the count is already stale by the time the screen draws. Refetching would
  /// be a round trip to learn something the app just caused.
  ///
  /// **Optimistic, and safe to be wrong.** The next real refresh corrects it, and the failure
  /// mode is a badge that reappears rather than one that lingers falsely.
  void clear(CustomerBadge badge) {
    if (!state.has(badge)) return;

    emit({...state, badge: 0});
  }
}
