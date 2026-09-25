part of 'active_orders_cubit.dart';

/// كل ما يمكن أن يكونه قسم «طلبياتي الجارية».
@freezed
sealed class ActiveOrdersState with _$ActiveOrdersState {
  const factory ActiveOrdersState.loading() = ActiveOrdersLoading;

  /// **قائمةٌ فارغة جوابٌ صحيح لا فشل**: لا شيء في الطريق، فيُرسم مكان البطاقات طريقٌ إلى طلب
  /// أكياس.
  const factory ActiveOrdersState.loaded(List<CustomerOrder> orders) = ActiveOrdersLoaded;

  const factory ActiveOrdersState.failure(Failure failure) = ActiveOrdersFailure;
}
