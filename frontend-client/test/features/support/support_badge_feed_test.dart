import 'dart:async';

import 'package:dayaa_client/features/badges/models/customer_badge.dart';
import 'package:dayaa_client/features/badges/presentation/viewmodel/badges_cubit.dart';
import 'package:dayaa_client/features/badges/repositories/badge_repository.dart';
import 'package:dayaa_client/features/badges/usecases/get_badges.dart';
import 'package:dayaa_client/features/support/models/support_ticket.dart';
import 'package:dayaa_client/features/support/models/ticket_change.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/open_thread.dart';
import 'package:dayaa_client/features/support/presentation/viewmodel/support_badge_feed.dart';
import 'package:dayaa_client/features/support/repositories/support_repository.dart';
import 'package:dayaa_client/features/support/usecases/watch_ticket_changes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// شارةُ «الدعم» حيّة، وما لا يجوز لها.
///
/// **ثلاثة أشياء تُحرس.** أن ردَّ المحل يرفعها ساعةَ يصل. وأنها لا ترتفع لما لا يعني العميل —
/// رسالته هو، أو إغلاقٌ بلا كلام، أو ردٌّ على خيطٍ مفتوحٍ أمامه يقرؤه الآن. وأنها تتبع الجلسة:
/// لا قناةَ بلا دخول، وخروجٌ يُغلقها — هاتفٌ صار في يد غيره لا يسمع ردوداً ليست له.
///
/// Arrange - Act - Assert في كل حالة.
class _MockSupportRepository extends Mock implements SupportRepository {}

class _MockBadgeRepository extends Mock implements BadgeRepository {}

void main() {
  late _MockSupportRepository support;
  late BadgesCubit badges;
  late StreamController<TicketChange> changes;
  late ValueNotifier<int> session;
  late OpenThread openThread;
  late bool signedIn;
  late int subscriptions;

  const ticket = SupportTicket(id: 7, subject: 'الطلبية', statusLabel: 'قيد المعالجة');
  const fromShop = TicketMessage(id: 3, from: MessageAuthor.support, body: 'خرجت اليوم');

  SupportBadgeFeed build() => SupportBadgeFeed(
    watch: WatchTicketChanges(support),
    badges: badges,
    openThread: openThread,
    session: session,
    isSignedIn: () => signedIn,
  );

  Future<void> live(TicketChange change) async {
    changes.add(change);
    await Future<void>.delayed(Duration.zero);
  }

  setUp(() {
    support = _MockSupportRepository();
    badges = BadgesCubit(getBadges: GetBadges(_MockBadgeRepository()));
    changes = StreamController<TicketChange>.broadcast(
      onListen: () => subscriptions++,
    );
    session = ValueNotifier<int>(0);
    openThread = OpenThread();
    signedIn = true;
    subscriptions = 0;

    when(() => support.watchChanges()).thenAnswer((_) => changes.stream);
  });

  tearDown(() async {
    await changes.close();
    await badges.close();
  });

  test('a reply from the shop raises the badge the moment it arrives', () async {
    // Arrange
    final feed = build()..start();

    // Act
    await live(const TicketChange(ticket: ticket, message: fromShop));

    // Assert
    expect(badges.state.countOf(CustomerBadge.support), 1);

    await feed.stop();
  });

  test('my own message, and a change with nothing said, leave it alone', () async {
    // Arrange
    final feed = build()..start();

    // Act
    await live(
      const TicketChange(
        ticket: ticket,
        message: TicketMessage(id: 4, from: MessageAuthor.me, body: 'شكراً'),
      ),
    );
    await live(const TicketChange(ticket: ticket));

    // Assert
    expect(badges.state.countOf(CustomerBadge.support), 0);

    await feed.stop();
  });

  test('a reply on the thread the customer is reading does not light it', () async {
    // Arrange
    final feed = build()..start();
    openThread.enter(7);

    // Act
    await live(const TicketChange(ticket: ticket, message: fromShop));

    // Assert — الخيطُ يقرؤه ويُعلِّمه مقروءاً في الحال.
    expect(badges.state.countOf(CustomerBadge.support), 0);

    await feed.stop();
  });

  test('signed out it listens to nothing; signing in opens the channel, signing out closes it', () async {
    // Arrange
    signedIn = false;
    final feed = build()..start();
    final beforeSignIn = subscriptions;

    // Act — دخول.
    signedIn = true;
    session.value++;
    await Future<void>.delayed(Duration.zero);
    final afterSignIn = subscriptions;

    // Act — خروج، ثم ردٌّ متأخرٌ على القناة القديمة.
    signedIn = false;
    session.value++;
    await Future<void>.delayed(Duration.zero);
    await live(const TicketChange(ticket: ticket, message: fromShop));

    // Assert
    expect(beforeSignIn, 0);
    expect(afterSignIn, 1);
    expect(changes.hasListener, isFalse);
    expect(badges.state.countOf(CustomerBadge.support), 0);

    await feed.stop();
  });
}
