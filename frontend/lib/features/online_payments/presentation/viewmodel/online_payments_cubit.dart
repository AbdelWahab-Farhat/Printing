import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/online_payments/models/online_payment_models.dart';
import 'package:dayaa/features/online_payments/usecases/online_payment_usecases.dart';

/// «المدفوعات الإلكترونية» — كل محاولة شحنٍ عبر EzonePay، الأحدث أولاً، تُقصر على حالة ويُبحث فيها
/// بمرجعنا أو اسم الزبون أو هاتفه. CUSTOMER-WALLET §٥.
///
/// `meta.enabled` و`meta.ezone_balance` يصلان مع الصفحة: هل الدفع الإلكتروني مفعّل، وما تحمله
/// EzonePay للمحلّ.
class OnlinePaymentsCubit extends PagedCubit<PaymentIntent> {
  OnlinePaymentsCubit({required GetPaymentIntents getIntents, required RecheckPaymentIntent recheck})
    : _getIntents = getIntents,
      _recheck = recheck;

  final GetPaymentIntents _getIntents;
  final RecheckPaymentIntent _recheck;

  IntentFilter filter = IntentFilter.all;

  /// فلترٌ آخر — والبحثُ المكتوب يبقى معه.
  Future<void> narrowTo(IntentFilter value) {
    if (value == filter) return Future<void>.value();

    filter = value;

    return load(search: currentSearch);
  }

  Map<String, dynamic> get _meta => switch (state) {
    PagedLoaded<PaymentIntent>(:final page) => page.extraMeta,
    _ => const <String, dynamic>{},
  };

  /// `null` قبل أن تصل الصفحة الأولى.
  bool? get enabled => _meta['enabled'] as bool?;

  String? get ezoneBalance => _meta['ezone_balance']?.toString();

  /// «إعادة التحقق»: يسأل EzonePay، ويضع المحاولة كما عادت مكانها.
  Future<Either<Failure, PaymentIntent>> recheck(PaymentIntent intent) async {
    final result = await _recheck(intent.uuid);

    result.fold((_) {}, replace);

    return result;
  }

  @override
  Object identityOf(PaymentIntent item) => item.id;

  @override
  bool belongs(PaymentIntent item) => filter.wire == null || item.status.wire == filter.wire;

  @override
  Future<Either<Failure, Paginated<PaymentIntent>>> fetchPage({String? search, required int page}) =>
      _getIntents(page: page, filter: filter, search: search);
}

typedef OnlinePaymentsState = PagedState<PaymentIntent>;
