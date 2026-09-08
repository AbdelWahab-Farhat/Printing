import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:dayaa/features/purchase_orders/presentation/viewmodel/purchase_order_detail_cubit.dart';
import 'package:dayaa/features/purchase_orders/repositories/purchase_order_repository.dart';
import 'package:dayaa/features/purchase_orders/usecases/purchase_order_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// One purchase order's screen, and the write that reopens it.
///
/// Arrange - Act - Assert throughout.
class _MockPurchaseOrderRepository extends Mock
    implements PurchaseOrderRepository {}

void main() {
  late _MockPurchaseOrderRepository repository;
  late PurchaseOrderDetailCubit cubit;

  /// A completed order whose receipt is still inside the window.
  final completed = PurchaseOrder(
    id: 412,
    vendorId: 3,
    status: PurchaseOrderStatus.completed,
    statusLabel: 'مكتمل',
    orderDate: '2026-09-06',
    receiptReversibleUntil: DateTime.parse('2026-09-10T10:00:00Z'),
    canReverseReceipt: true,
  );

  /// The same order after the receipt was undone: back on «قيد الاستلام», and with nothing left
  /// to undo — which is why the flag has to come from a re-read rather than be assumed.
  final reopened = completed.copyWith(
    status: PurchaseOrderStatus.arrived,
    statusLabel: 'قيد الاستلام',
    receiptReversibleUntil: null,
    canReverseReceipt: false,
  );

  const refusal = Failure.server(
    message:
        'صُرف من الدفعة بعد استلامها — الصواب تسوية جرد لا إلغاء استلام',
    statusCode: 422,
  );

  setUp(() {
    repository = _MockPurchaseOrderRepository();
    cubit = PurchaseOrderDetailCubit(
      purchaseOrderId: 412,
      getOrder: GetPurchaseOrder(repository),
      changeStatus: ChangePurchaseOrderStatus(repository),
      receiveArrival: ReceivePurchaseOrderArrival(repository),
      reverseReceiptUseCase: ReverseReceipt(repository),
    );
  });

  tearDown(() => cubit.close());

  blocTest<PurchaseOrderDetailCubit, PurchaseOrderDetailState>(
    'undoing a receipt reopens the order and re-reads what may still be done to it',
    setUp: () {
      // Arrange — the first read is the completed order, the read after the write is the
      // reopened one. **The write's own answer is not trusted for the flags**: the endpoint
      // returns a `PurchaseOrderResource` like any other, and the screen's whole job is to be
      // right about what is still on offer.
      final reads = <PurchaseOrder>[completed, reopened];

      when(
        () => repository.purchaseOrder(412),
      ).thenAnswer((_) async => Right(reads.removeAt(0)));
      when(
        () => repository.reverseReceipt(412, reason: 'سُجّلت الكمية خطأً'),
      ).thenAnswer((_) async => Right(reopened));
    },
    build: () => cubit,
    // Act
    act: (cubit) async {
      await cubit.load();
      await cubit.reverseReceipt(reason: 'سُجّلت الكمية خطأً');
    },
    // Assert — the order stays on screen throughout, including while the write is in flight.
    expect: () => [
      const PurchaseOrderDetailState.loading(),
      PurchaseOrderDetailState.ready(completed),
      PurchaseOrderDetailState.working(completed),
      PurchaseOrderDetailState.loading(order: completed),
      PurchaseOrderDetailState.ready(reopened),
    ],
    verify: (_) {
      expect(cubit.state.order?.status, PurchaseOrderStatus.arrived);
      // The button is gone because the server said so on the re-read, not because the app
      // worked it out from the new status.
      expect(cubit.state.order?.canReverseReceipt, isFalse);
    },
  );

  blocTest<PurchaseOrderDetailCubit, PurchaseOrderDetailState>(
    "a refusal hands back the server's own sentence and leaves the order untouched",
    setUp: () {
      // Arrange — the API deliberately does not publish whether a batch has been drawn on, so
      // the button is offered on receipts that turn out to be un-reversible. This is that case.
      when(
        () => repository.purchaseOrder(412),
      ).thenAnswer((_) async => Right(completed));
      when(
        () => repository.reverseReceipt(412, reason: 'خطأ'),
      ).thenAnswer((_) async => const Left(refusal));
    },
    build: () => cubit,
    // Act
    act: (cubit) async {
      await cubit.load();
      final failure = await cubit.reverseReceipt(reason: 'خطأ');

      // Assert — handed back rather than swallowed, so the sheet can print it in front of
      // somebody still holding the decision. Each refusal tells the person to do something
      // else, and «حدث خطأ ما» would tell them nothing.
      expect(failure, refusal);
    },
    // Assert — no re-read: the write never happened, and the screen the person was reading is
    // exactly the screen they are returned to, button and all.
    expect: () => [
      const PurchaseOrderDetailState.loading(),
      PurchaseOrderDetailState.ready(completed),
      PurchaseOrderDetailState.working(completed),
      PurchaseOrderDetailState.ready(completed),
    ],
    verify: (_) {
      verify(() => repository.purchaseOrder(412)).called(1);
      expect(cubit.state.order?.canReverseReceipt, isTrue);
    },
  );
}
