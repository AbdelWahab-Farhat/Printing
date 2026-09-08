import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/notifications/models/app_notification.dart';
import 'package:dayaa/features/notifications/presentation/viewmodel/notifications_cubit.dart';
import 'package:dayaa/features/notifications/repositories/notifications_repository.dart';
import 'package:dayaa/features/notifications/usecases/get_notifications.dart';
import 'package:dayaa/features/notifications/usecases/mark_all_read.dart';
import 'package:dayaa/features/notifications/usecases/mark_notification_read.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Paging itself is proved once in `test/core/pagination/paged_cubit_test.dart`. What is left to
/// prove here is the part that is about notifications: that reading one **patches the row it is
/// already showing** instead of refetching the page, and that a server refusal puts the row back
/// exactly as it was.
///
/// That matters more than it looks. The optimistic patch is what makes the bell feel immediate;
/// the rollback is what stops it lying when the write did not land.
///
/// Arrange - Act - Assert throughout.
class _MockRepository extends Mock implements NotificationsRepository {}

void main() {
  late _MockRepository repository;
  late NotificationsCubit cubit;

  AppNotification unread({int id = 1}) => AppNotification(
    id: id,
    type: 'order.shortage',
    typeLabel: 'نواقص طلبية',
    title: 'طلبية O145 في النواقص',
    body: 'العميل: مخبز الأمل',
    icon: 'warning',
    route: '/orders/145',
    isRead: false,
    createdAt: DateTime(2026, 9, 7, 9, 14),
  );

  Paginated<AppNotification> page(List<AppNotification> items) => Paginated(
    items: items,
    meta: PageMeta(currentPage: 1, perPage: 15, lastPage: 1, total: items.length),
  );

  setUp(() {
    repository = _MockRepository();
    cubit = NotificationsCubit(
      GetNotifications(repository),
      MarkNotificationRead(repository),
      MarkAllRead(repository),
    );
  });

  tearDown(() => cubit.close());

  test('reading one patches the row on screen without refetching the page', () async {
    // Arrange
    final item = unread();
    when(
      () => repository.list(
        unreadOnly: any(named: 'unreadOnly'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => Right(page([item])));
    when(() => repository.markRead(1)).thenAnswer((_) async => const Right('تم'));

    await cubit.load();

    // Act
    await cubit.markRead(item);

    // Assert — the row is read, and the list was fetched exactly once: the patch replaced it
    // rather than asking the server what it already knew.
    final state = cubit.state as PagedLoaded<AppNotification>;
    expect(state.page.items.single.isRead, isTrue);
    verify(() => repository.markRead(1)).called(1);
    verify(
      () => repository.list(
        unreadOnly: any(named: 'unreadOnly'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).called(1);
  });

  test('a refused write puts the row back as it was', () async {
    // Arrange — a 404 is the ordinary refusal here: somebody else's notification id.
    final item = unread();
    when(
      () => repository.list(
        unreadOnly: any(named: 'unreadOnly'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => Right(page([item])));
    when(
      () => repository.markRead(1),
    ).thenAnswer((_) async => const Left(Failure.server(message: 'غير موجود', statusCode: 404)));

    await cubit.load();

    // Act
    await cubit.markRead(item);

    // Assert — unread again, rather than left looking read after a write that never landed.
    final state = cubit.state as PagedLoaded<AppNotification>;
    expect(state.page.items.single.isRead, isFalse);
  });

  test('an already-read notification costs no request', () async {
    // Arrange
    final item = unread().copyWith(isRead: true);
    when(
      () => repository.list(
        unreadOnly: any(named: 'unreadOnly'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => Right(page([item])));

    await cubit.load();

    // Act — tapping it to open the order it is about.
    await cubit.markRead(item);

    // Assert
    verifyNever(() => repository.markRead(any()));
  });
}
