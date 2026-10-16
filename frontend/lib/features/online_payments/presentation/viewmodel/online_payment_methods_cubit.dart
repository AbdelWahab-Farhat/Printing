import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/online_payments/models/online_payment_models.dart';
import 'package:dayaa/features/online_payments/usecases/online_payment_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «طرق الدفع الإلكتروني» — كل طريقةٍ من EzonePay: مفعّلة أو لا، وحدودها لكل زبون.
///
/// **يُحفظ كل تغييرٍ ساعةَ يحدث**، كإعدادات المالية، والطريقةُ كما عادت من الخادم تُرسم مكانها.
class OnlinePaymentMethodsCubit extends Cubit<OnlinePaymentMethodsState> {
  OnlinePaymentMethodsCubit({
    required GetOnlinePaymentMethods getMethods,
    required UpdateOnlinePaymentMethod updateMethod,
  }) : _getMethods = getMethods,
       _updateMethod = updateMethod,
       super(const OnlinePaymentMethodsLoading());

  final GetOnlinePaymentMethods _getMethods;
  final UpdateOnlinePaymentMethod _updateMethod;

  Future<void> load() async {
    final result = await _getMethods();

    if (isClosed) return;

    emit(result.fold(OnlinePaymentMethodsFailed.new, OnlinePaymentMethodsLoaded.new));
  }

  Future<Failure?> setActive(OnlinePaymentMethodSetting method, bool active) =>
      _save(method, isActive: active);

  /// الحدود كما كُتبت — الفارغُ «بلا حد».
  Future<Failure?> setLimits(
    OnlinePaymentMethodSetting method, {
    required String daily,
    required String monthly,
    required String yearly,
  }) => _save(method, daily: daily, monthly: monthly, yearly: yearly, withLimits: true);

  Future<Failure?> _save(
    OnlinePaymentMethodSetting method, {
    bool? isActive,
    String? daily,
    String? monthly,
    String? yearly,
    bool withLimits = false,
  }) async {
    final result = await _updateMethod(
      method.id,
      isActive: isActive,
      daily: daily,
      monthly: monthly,
      yearly: yearly,
      withLimits: withLimits,
    );

    return result.fold((failure) => failure, (saved) {
      if (isClosed) return null;

      if (state case OnlinePaymentMethodsLoaded(:final methods)) {
        emit(OnlinePaymentMethodsLoaded(methods.withMethod(saved)));
      }

      return null;
    });
  }
}

sealed class OnlinePaymentMethodsState {
  const OnlinePaymentMethodsState();
}

final class OnlinePaymentMethodsLoading extends OnlinePaymentMethodsState {
  const OnlinePaymentMethodsLoading();
}

final class OnlinePaymentMethodsFailed extends OnlinePaymentMethodsState {
  const OnlinePaymentMethodsFailed(this.failure);

  final Failure failure;
}

final class OnlinePaymentMethodsLoaded extends OnlinePaymentMethodsState {
  const OnlinePaymentMethodsLoaded(this.methods);

  final OnlinePaymentMethods methods;
}
