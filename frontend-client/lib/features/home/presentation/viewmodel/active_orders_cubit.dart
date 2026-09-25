import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/usecases/list_active_orders.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'active_orders_cubit.freezed.dart';
part 'active_orders_state.dart';

/// الـ ViewModel لقسم «طلبياتي الجارية» على الرئيسية.
///
/// **التحميل الأول وحده يرسم الهياكل الفارغة.** السحب للتحديث يُبقي البطاقات على الشاشة حتى
/// يصل الجديد، وإن فشل بقيت كما هي: بطاقاتٌ عمرها دقيقة أصدق من رسالة خطأ مكانها (RULES §4).
class ActiveOrdersCubit extends Cubit<ActiveOrdersState> {
  ActiveOrdersCubit({required ListActiveOrders list})
    : _list = list,
      super(const ActiveOrdersState.loading());

  final ListActiveOrders _list;

  Future<void> load() async {
    final wasShowing = state is ActiveOrdersLoaded;

    if (!wasShowing) emit(const ActiveOrdersState.loading());

    final result = await _list();

    if (isClosed) return;

    result.fold(
      (failure) {
        if (!wasShowing) emit(ActiveOrdersState.failure(failure));
      },
      (orders) => emit(ActiveOrdersState.loaded(orders)),
    );
  }
}
