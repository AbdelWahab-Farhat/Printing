import 'dart:async';

import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/utils/fixed_point.dart';
import 'package:dayaa_client/core/utils/uuid.dart';
import 'package:dayaa_client/features/orders/models/basket_quote.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/models/deposit_rules.dart' as rules;
import 'package:dayaa_client/features/orders/usecases/choose_order_deposit.dart';
import 'package:dayaa_client/features/wallet/models/online_top_up_models.dart';
import 'package:dayaa_client/features/wallet/usecases/top_up_usecases.dart';
import 'package:dayaa_client/features/wallet/usecases/wallet_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_deposit_cubit.freezed.dart';

/// ورقة «اختر العربون» على طلبيةٍ قبلها المتجر بعد المراجعة.
@freezed
abstract class OrderDepositState with _$OrderDepositState {
  const factory OrderDepositState({
    /// الحدّان كما أرسلهما الخادم مع الطلبية.
    required DepositOffer offer,

    /// العربون المختار، بالدينار الكامل — يبدأ بأقلّه.
    String? amount,

    /// كيف يُدفع. **لا اختيارَ مسبقاً.**
    CheckoutPayment? payment,

    /// الطريقة الإلكترونية حين [payment] إلكتروني.
    int? onlineMethodId,

    @Default(<TopUpMethod>[]) List<TopUpMethod> onlineMethods,

    /// `null` حين لم يصل — فلا يُعرض «من المحفظة» قابلاً للاختيار.
    String? walletBalance,

    @Default(false) bool isSubmitting,
    Failure? lastFailure,
  }) = _OrderDepositState;
}

extension OrderDepositStateX on OrderDepositState {
  String? get amountError => rules.depositAmountError(offer, amount);

  bool get walletCovers => rules.walletCoversDeposit(walletBalance, amount);

  TopUpMethod? get selectedOnlineMethod =>
      onlineMethods.where((method) => method.id == onlineMethodId).firstOrNull;

  bool get isReady => rules.depositChoiceIsReady(
    offer: offer,
    payment: payment,
    amount: amount,
    walletBalance: walletBalance,
    onlineMethod: selectedOnlineMethod,
  );

  /// رفض الخادم للمبلغ — تحت حقله.
  String? get amountServerError => switch (lastFailure) {
    ServerFailure(:final fieldErrors?) => fieldErrors['amount']?.firstOrNull,
    _ => null,
  };

  /// رفض الخادم للطريق، أو للعربون كلّه («لم يعد اختيار العربون متاحاً») — تحت الطرق.
  String? get otherServerError => switch (lastFailure) {
    ServerFailure(:final fieldErrors?) =>
      fieldErrors['payment']?.firstOrNull ?? fieldErrors['deposit']?.firstOrNull,
    _ => null,
  };
}

/// العربون على طلبيةٍ قبلها المتجر بعد المراجعة (صاحب العمل، 2026-10-19) — خطوة السلة نفسها، مؤجَّلة.
///
/// **القواعد قواعد السلة** (`deposit_rules.dart`)، **والإلكتروني يُشحن أولاً**: الورقة تفتح الشحن
/// بمبلغ العربون مقفلاً، وحين ينجح [toppedUp] يجعل الطريقَ المحفظة، ثم [submit]. [submit] يرفض أن
/// يرسل وطريقُه ما زال إلكترونياً.
class OrderDepositCubit extends Cubit<OrderDepositState> {
  OrderDepositCubit({
    required this.order,
    required ChooseOrderDeposit choose,
    GetWalletBalance? walletBalance,
    GetTopUpMethods? topUpMethods,
  }) : _choose = choose,
       _walletBalance = walletBalance,
       _topUpMethods = topUpMethods,
       super(
         OrderDepositState(
           offer: order.depositOffer!,
           // بالدينار الكامل: «125.00» من الخادم يُكتب «125».
           amount: order.depositOffer!.minAmount!.asPlainNumber,
         ),
       );

  final CustomerOrderDetail order;
  final ChooseOrderDeposit _choose;
  final GetWalletBalance? _walletBalance;
  final GetTopUpMethods? _topUpMethods;

  /// مفتاح دفعة المحفظة حتى تنجح: إرسالٌ انقطع بعد أن دفع الخادم يُعاد بالمفتاح نفسه فلا يدفع ثانية.
  String? _token;

  Future<void> load() async {
    await Future.wait([refreshWallet(), _loadOnline()]);
  }

  void chooseAmount(String typed) {
    final amount = topUpAmount(typed);

    // مبلغٌ آخر دفعةٌ أخرى، لا إعادةٌ للأولى.
    if (amount != state.amount) _token = null;

    emit(state.copyWith(amount: amount, lastFailure: null));
  }

  /// «ادفع كامل القيمة».
  void payFull() => chooseAmount(state.offer.maxAmount!.asPlainNumber);

  void choosePayment(CheckoutPayment payment) =>
      emit(state.copyWith(payment: payment, onlineMethodId: null, lastFailure: null));

  void chooseOnline(int methodId) => emit(
    state.copyWith(payment: CheckoutPayment.online, onlineMethodId: methodId, lastFailure: null),
  );

  Future<void> refreshWallet() async {
    final read = _walletBalance;
    if (read == null) return;

    final result = await read();

    if (isClosed) return;

    result.fold((_) {}, (balance) => emit(state.copyWith(walletBalance: balance)));
  }

  /// **الشحن تمّ** — العربون في المحفظة الآن، فيُدفع منها. فإن رُفض الإرسال بعدها بقي المال في
  /// المحفظة و«من المحفظة» مختارةٌ للمحاولة التالية — لا شحنٌ ثانٍ.
  Future<void> toppedUp() async {
    await refreshWallet();

    if (!isClosed) emit(state.copyWith(payment: CheckoutPayment.wallet, onlineMethodId: null));
  }

  /// يرسل الاختيار. يعيد الطلبية كما صارت، أو `null` و`lastFailure` يقول لماذا.
  Future<CustomerOrderDetail?> submit() async {
    final payment = state.payment;

    // الإلكتروني لا يُرسل قبل أن ينجح الشحن — [toppedUp] يجعله المحفظة.
    if (state.isSubmitting || !state.isReady || payment == null || payment == CheckoutPayment.online) {
      return null;
    }

    emit(state.copyWith(isSubmitting: true, lastFailure: null));

    final result = await _choose(
      order.id,
      CheckoutDeposit(
        payment: payment,
        amount: state.amount!,
        clientToken: payment == CheckoutPayment.wallet ? (_token ??= uuidV4()) : null,
      ),
    );

    if (isClosed) return result.fold((_) => null, (chosen) => chosen);

    return result.fold(
      (failure) {
        // لم يُجب الخادم: لعلّه دفع، فالإعادة بالمفتاح نفسه. أجاب بالرفض: المحاولة التالية جديدة.
        if (failure is! NetworkFailure) _token = null;

        emit(state.copyWith(isSubmitting: false, lastFailure: failure));

        return null;
      },
      (chosen) {
        emit(state.copyWith(isSubmitting: false));

        return chosen;
      },
    );
  }

  /// طرق الشحن التي يدعمها التطبيق — كما تقرّرها ورقة الشحن. شحنٌ مطفأ أو سؤالٌ فشل: لا شيء.
  Future<void> _loadOnline() async {
    final ask = _topUpMethods;
    if (ask == null) return;

    final result = await ask();

    if (isClosed) return;

    result.fold((_) {}, (methods) {
      if (!methods.enabled) return;

      emit(
        state.copyWith(
          onlineMethods: [
            for (final method in methods.methods)
              if (method.isSupported) method,
          ],
        ),
      );
    });
  }
}
