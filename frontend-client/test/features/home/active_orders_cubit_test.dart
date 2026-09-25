import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/features/home/presentation/viewmodel/active_orders_cubit.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/repositories/order_repository.dart';
import 'package:dayaa_client/features/orders/usecases/list_active_orders.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrderRepository extends Mock implements OrderRepository {}

/// «طلبياتي الجارية» على الرئيسية.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockOrderRepository repository;

  const producing = CustomerOrder(
    id: 1,
    code: '1228',
    stage: OrderStage.producing,
    stageLabel: 'قيد الإنتاج',
  );

  Paginated<CustomerOrder> page(List<CustomerOrder> items) => Paginated<CustomerOrder>(
    items: items,
    meta: PageMeta(currentPage: 1, perPage: 15, lastPage: 1, total: items.length),
  );

  setUp(() => repository = _MockOrderRepository());

  ActiveOrdersCubit build() => ActiveOrdersCubit(list: ListActiveOrders(repository));

  void answer(Either<Failure, Paginated<CustomerOrder>> open) {
    when(() => repository.list(page: 1, openOnly: true)).thenAnswer((_) async => open);
    when(
      () => repository.list(page: 1, stage: 'ready'),
    ).thenAnswer((_) async => Right(page(const [])));
  }

  blocTest<ActiveOrdersCubit, ActiveOrdersState>(
    'emits loading then the orders still on their way',
    build: () {
      answer(Right(page(const [producing])));

      return build();
    },
    act: (cubit) => cubit.load(),
    expect: () => const [
      ActiveOrdersState.loading(),
      ActiveOrdersState.loaded([producing]),
    ],
  );

  /// لا طلبية جارية جوابٌ صحيح لا فشل: الرئيسية ترسم مكانها طريقاً إلى طلب أكياس.
  blocTest<ActiveOrdersCubit, ActiveOrdersState>(
    'nothing on its way is an answer, not a failure',
    build: () {
      answer(Right(page(const [])));

      return build();
    },
    act: (cubit) => cubit.load(),
    expect: () => const [
      ActiveOrdersState.loading(),
      ActiveOrdersState.loaded(<CustomerOrder>[]),
    ],
  );

  blocTest<ActiveOrdersCubit, ActiveOrdersState>(
    'a failure carries the server\'s own message',
    build: () {
      answer(const Left(ServerFailure(message: 'الخدمة غير متاحة الآن')));

      return build();
    },
    act: (cubit) => cubit.load(),
    expect: () => const [
      ActiveOrdersState.loading(),
      ActiveOrdersState.failure(ServerFailure(message: 'الخدمة غير متاحة الآن')),
    ],
  );

  /// السحب للتحديث لا يستبدل البطاقات بهياكل فارغة ثم يعيدها.
  blocTest<ActiveOrdersCubit, ActiveOrdersState>(
    'loading again keeps the cards on screen until the new ones arrive',
    build: () {
      answer(Right(page(const [producing])));

      return build();
    },
    seed: () => const ActiveOrdersState.loaded(<CustomerOrder>[]),
    act: (cubit) => cubit.load(),
    expect: () => const [
      ActiveOrdersState.loaded([producing]),
    ],
  );

  /// «فشل صفحة إضافية لا يمسح ما هو معروض» (RULES §4): البطاقات التي على الشاشة أصدق من خطأ.
  blocTest<ActiveOrdersCubit, ActiveOrdersState>(
    'loading again and failing keeps the cards that were there',
    build: () {
      answer(const Left(NetworkFailure(message: 'لا يوجد اتصال')));

      return build();
    },
    seed: () => const ActiveOrdersState.loaded([producing]),
    act: (cubit) => cubit.load(),
    expect: () => <ActiveOrdersState>[],
  );

  blocTest<ActiveOrdersCubit, ActiveOrdersState>(
    'loading again after a failure is how «إعادة المحاولة» works',
    build: () {
      answer(Right(page(const [producing])));

      return build();
    },
    seed: () => const ActiveOrdersState.failure(NetworkFailure(message: 'لا يوجد اتصال')),
    act: (cubit) => cubit.load(),
    expect: () => const [
      ActiveOrdersState.loading(),
      ActiveOrdersState.loaded([producing]),
    ],
  );
}
