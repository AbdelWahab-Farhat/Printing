import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/notifications/models/push_preference.dart';
import 'package:dayaa/features/notifications/presentation/viewmodel/push_preferences_cubit.dart';
import 'package:dayaa/features/notifications/repositories/notifications_repository.dart';
import 'package:dayaa/features/notifications/usecases/get_push_preferences.dart';
import 'package:dayaa/features/notifications/usecases/set_push_preference.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// A switch moves on the tap and moves back on a refusal — and only that switch moves back.
///
/// Arrange - Act - Assert throughout.
class _MockRepository extends Mock implements NotificationsRepository {}

void main() {
  late _MockRepository repository;
  late PushPreferencesCubit cubit;

  const groups = [
    PushPreferenceGroup(
      type: 'order.shortage',
      label: 'نواقص طلبية',
      icon: 'warning',
      switches: [PushSwitch(scope: '', label: 'نواقص طلبية', push: true)],
    ),
    PushPreferenceGroup(
      type: 'order.status',
      label: 'حالة طلبية',
      icon: 'order',
      switches: [
        PushSwitch(scope: 'ready', label: 'جاهزة', push: true),
        PushSwitch(scope: 'settled', label: 'تم التسوية', push: true),
      ],
    ),
  ];

  bool pushOf(String type, String scope) => cubit.state.groups!
      .firstWhere((g) => g.type == type)
      .switches
      .firstWhere((s) => s.scope == scope)
      .push;

  void stubSet(Either<Failure, List<PushPreferenceGroup>> answer, {String? scope}) {
    when(
      () => repository.setPushPreference(
        userId: any(named: 'userId'),
        type: any(named: 'type'),
        scope: scope ?? any(named: 'scope'),
        push: any(named: 'push'),
      ),
    ).thenAnswer((_) async => answer);
  }

  setUp(() {
    repository = _MockRepository();
    cubit = PushPreferencesCubit(
      userId: 4,
      getPreferences: GetPushPreferences(repository),
      setPreference: SetPushPreference(repository),
    );
    when(() => repository.pushPreferences(4)).thenAnswer((_) async => const Right(groups));
  });

  tearDown(() => cubit.close());

  test('loading shows the switches the server sent', () async {
    // Act
    await cubit.load();

    // Assert
    expect(cubit.state, const PushPreferencesState.loaded(groups));
  });

  test('a first read that fails has nothing to show', () async {
    // Arrange
    when(
      () => repository.pushPreferences(4),
    ).thenAnswer((_) async => const Left(ServerFailure(message: 'تعذر')));

    // Act
    await cubit.load();

    // Assert
    expect(cubit.state, isA<PushPreferencesFailure>());
  });

  test('a switch is sent with its type and scope and stays where it was put', () async {
    // Arrange
    await cubit.load();
    stubSet(const Right(groups));

    // Act
    await cubit.toggle(type: 'order.status', scope: 'settled', push: false);

    // Assert — the server's answer (here still «on») is not laid back over the tap.
    expect(pushOf('order.status', 'settled'), isFalse);
    expect(pushOf('order.status', 'ready'), isTrue);
    verify(
      () => repository.setPushPreference(
        userId: 4,
        type: 'order.status',
        scope: 'settled',
        push: false,
      ),
    ).called(1);
  });

  test('a refused switch moves back and says why', () async {
    // Arrange
    await cubit.load();
    stubSet(const Left(ServerFailure(message: 'لا يمكن')));

    // Act
    await cubit.toggle(type: 'order.shortage', scope: '', push: false);

    // Assert
    expect(pushOf('order.shortage', ''), isTrue);
    expect(cubit.state, isA<PushPreferencesLoaded>());
    expect((cubit.state as PushPreferencesLoaded).failure, isNotNull);
  });

  test('a refusal moves back only its own switch, not one tapped meanwhile', () async {
    // Arrange — «settled» is refused, «ready» lands; «ready» is tapped while «settled» waits.
    await cubit.load();
    stubSet(const Left(ServerFailure(message: 'لا يمكن')), scope: 'settled');
    stubSet(const Right(groups), scope: 'ready');

    // Act
    final first = cubit.toggle(type: 'order.status', scope: 'settled', push: false);
    final second = cubit.toggle(type: 'order.status', scope: 'ready', push: false);
    await Future.wait([first, second]);

    // Assert
    expect(pushOf('order.status', 'settled'), isTrue);
    expect(pushOf('order.status', 'ready'), isFalse);
  });

  test('a tap before anything has loaded does nothing', () async {
    // Act
    await cubit.toggle(type: 'order.shortage', scope: '', push: false);

    // Assert
    verifyNever(
      () => repository.setPushPreference(
        userId: any(named: 'userId'),
        type: any(named: 'type'),
        scope: any(named: 'scope'),
        push: any(named: 'push'),
      ),
    );
  });
}
