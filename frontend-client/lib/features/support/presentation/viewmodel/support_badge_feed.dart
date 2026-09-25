import 'dart:async';

import 'package:dayaa_client/features/badges/models/customer_badge.dart';
import 'package:dayaa_client/features/badges/presentation/viewmodel/badges_cubit.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:dayaa_client/features/support/models/ticket_change.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/open_thread.dart';
import 'package:dayaa_client/features/support/usecases/watch_ticket_changes.dart';
import 'package:flutter/foundation.dart';

/// شارةُ «الدعم» حيّة: ردُّ المحل يرفعها ساعةَ يُكتب، والعميلُ في أيّ شاشةٍ كان.
///
/// **يتبع الجلسة لا الشاشات.** يستمع إلى قناة العميل ما دام داخلاً، ويتركها ساعةَ يخرج — وإلا
/// بقيت قناةُ العميل السابق مفتوحةً على هاتفٍ صار في يد غيره. والجلسةُ تُقرأ من [session]
/// (`TokenStorage.revision`) لأن الدخول والخروج يمرّان كلاهما بالرمز.
///
/// **لا يرفعها لخيطٍ مفتوح** ([OpenThread]): ذاك الخيط يقرأ الردّ ويُعلِّمه مقروءاً في الحال.
class SupportBadgeFeed {
  SupportBadgeFeed({
    required WatchTicketChanges watch,
    required BadgesCubit badges,
    required OpenThread openThread,
    required ValueListenable<int> session,
    required bool Function() isSignedIn,
  }) : _watch = watch,
       _badges = badges,
       _openThread = openThread,
       _session = session,
       _isSignedIn = isSignedIn;

  final WatchTicketChanges _watch;
  final BadgesCubit _badges;
  final OpenThread _openThread;
  final ValueListenable<int> _session;
  final bool Function() _isSignedIn;

  StreamSubscription<TicketChange>? _subscription;
  bool _started = false;

  /// يبدأ ويتبع الجلسة بعدها. **مرةً واحدة**، والثانية لا تفعل شيئاً.
  void start() {
    if (_started) return;

    _started = true;
    _session.addListener(_follow);
    _follow();
  }

  void _follow() {
    unawaited(_subscription?.cancel());
    _subscription = null;

    if (_isSignedIn()) _subscription = _watch().listen(_onChange);
  }

  void _onChange(TicketChange change) {
    final message = change.message;

    if (message == null || message.isMine) return;
    if (_openThread.isShowing(change.ticket.id)) return;

    _badges.bump(CustomerBadge.support);
  }

  @visibleForTesting
  Future<void> stop() async {
    _session.removeListener(_follow);
    _started = false;
    await _subscription?.cancel();
    _subscription = null;
  }
}
