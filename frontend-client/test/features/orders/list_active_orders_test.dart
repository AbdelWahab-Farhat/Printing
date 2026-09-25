import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/repositories/order_repository.dart';
import 'package:dayaa_client/features/orders/usecases/list_active_orders.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrderRepository extends Mock implements OrderRepository {}

/// الطلبيات التي ما زالت تتحرك: ما تعرضه الرئيسية تحت «طلبياتي الجارية».
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockOrderRepository repository;

  setUp(() => repository = _MockOrderRepository());

  CustomerOrder order(int id, OrderStage stage, {DateTime? placedAt}) => CustomerOrder(
    id: id,
    code: '$id',
    stage: stage,
    stageLabel: stage.name,
    placedAt: placedAt,
  );

  Paginated<CustomerOrder> page(List<CustomerOrder> items) => Paginated<CustomerOrder>(
    items: items,
    meta: PageMeta(currentPage: 1, perPage: 15, lastPage: 1, total: items.length),
  );

  void answer({
    required Either<Failure, Paginated<CustomerOrder>> open,
    required Either<Failure, Paginated<CustomerOrder>> ready,
  }) {
    when(() => repository.list(page: 1, openOnly: true)).thenAnswer((_) async => open);
    when(() => repository.list(page: 1, stage: 'ready')).thenAnswer((_) async => ready);
  }

  test('asks for the moving orders and the ready ones, in the app\'s own words', () async {
    // Arrange
    answer(open: Right(page(const [])), ready: Right(page(const [])));
    final useCase = ListActiveOrders(repository);

    // Act
    await useCase();

    // Assert
    verify(() => repository.list(page: 1, openOnly: true)).called(1);
    verify(() => repository.list(page: 1, stage: 'ready')).called(1);
  });

  /// «قيد التنفيذ» في «طلباتي» يستثني الجاهزة عمداً، لأن شريحتها تجلس بجانبه. أما الرئيسية
  /// فتسأل: ما الذي لم يصلني بعد؟ والجاهزة أول جوابٍ عن هذا السؤال.
  test('the ready orders join the moving ones, newest first', () async {
    // Arrange
    final producing = order(1, OrderStage.producing, placedAt: DateTime(2026, 9, 20));
    final ready = order(2, OrderStage.ready, placedAt: DateTime(2026, 9, 22));
    final underReview = order(3, OrderStage.underReview, placedAt: DateTime(2026, 9, 24));
    answer(open: Right(page([producing, underReview])), ready: Right(page([ready])));
    final useCase = ListActiveOrders(repository);

    // Act
    final result = await useCase();

    // Assert
    expect(result.getOrElse(() => const []), [underReview, ready, producing]);
  });

  /// طلبيةٌ صارت جاهزة بين الطلبين تصل في الجوابين. تُعرض مرةً واحدة، بمرحلتها الأبعد.
  test('an order in both answers is drawn once, as the ready one', () async {
    // Arrange
    final stillProducing = order(7, OrderStage.producing, placedAt: DateTime(2026, 9, 21));
    final nowReady = order(7, OrderStage.ready, placedAt: DateTime(2026, 9, 21));
    answer(open: Right(page([stillProducing])), ready: Right(page([nowReady])));
    final useCase = ListActiveOrders(repository);

    // Act
    final result = await useCase();

    // Assert
    expect(result.getOrElse(() => const []), [nowReady]);
  });

  test('an order with no date goes after the dated ones', () async {
    // Arrange
    final undated = order(1, OrderStage.preparing);
    final dated = order(2, OrderStage.producing, placedAt: DateTime(2026, 9, 1));
    answer(open: Right(page([undated, dated])), ready: Right(page(const [])));
    final useCase = ListActiveOrders(repository);

    // Act
    final result = await useCase();

    // Assert
    expect(result.getOrElse(() => const []), [dated, undated]);
  });

  test('when either question fails, the whole answer fails with its message', () async {
    // Arrange
    const failure = NetworkFailure(message: 'لا يوجد اتصال');
    answer(open: Right(page(const [])), ready: const Left(failure));
    final useCase = ListActiveOrders(repository);

    // Act
    final result = await useCase();

    // Assert
    expect(result, const Left<Failure, List<CustomerOrder>>(failure));
  });
}
