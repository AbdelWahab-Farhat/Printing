import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/models/order_note.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/order_notes_cubit.dart';
import 'package:dayaa_client/features/orders/repositories/order_notes_repository.dart';
import 'package:dayaa_client/features/orders/usecases/read_order_notes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrderNotesRepository extends Mock implements OrderNotesRepository {}

/// شاشة «الملاحظات»: تحمّل ملاحظات الطلبية — وتحميلها هو ما يعلّمها مقروءة عند الخادم.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockOrderNotesRepository repository;

  const refused = OrderNote(
    id: 41,
    stage: OrderStage.rejected,
    stageLabel: 'مرفوضة',
    text: 'التصميم غير واضح',
  );

  setUp(() => repository = _MockOrderNotesRepository());

  OrderNotesCubit build() =>
      OrderNotesCubit(orderId: 1309, read: ReadOrderNotes(repository));

  blocTest<OrderNotesCubit, OrderNotesState>(
    'loads the notes of its own order',
    setUp: () => when(() => repository.notes(1309)).thenAnswer((_) async => const Right([refused])),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const OrderNotesState.loading(),
      const OrderNotesState.loaded([refused]),
    ],
    verify: (_) => verify(() => repository.notes(1309)).called(1),
  );

  blocTest<OrderNotesCubit, OrderNotesState>(
    'a failed load says why, so the screen can offer to try again',
    setUp: () => when(
      () => repository.notes(1309),
    ).thenAnswer((_) async => const Left(Failure.network(message: 'لا اتصال'))),
    build: build,
    act: (cubit) => cubit.load(),
    expect: () => [
      const OrderNotesState.loading(),
      const OrderNotesState.failure(Failure.network(message: 'لا اتصال')),
    ],
  );
}
