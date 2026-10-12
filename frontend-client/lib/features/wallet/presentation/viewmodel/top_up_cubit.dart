import 'dart:async';

import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/utils/uuid.dart';
import 'package:dayaa_client/features/wallet/models/online_top_up_models.dart';
import 'package:dayaa_client/features/wallet/usecases/top_up_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «اشحن محفظتك» من أوّله إلى آخره — CUSTOMER-WALLET §٥:
///
/// 1. **النموذج**: المبلغ والطريقة، وعرضُ الخادم «يصل محفظتك ١٠٠ — تدفع ١٠٢٫٥٠» يُسأل بعد أن
///    يتوقف الزبون عن الكتابة.
/// 2. **الرمز** لطرق OTP: تُرسل EzonePay رسالة، والزبون يكتبه هنا.
/// 3. **الانتظار** لرابط البطاقة: تُفتح صفحة المصرف، ويُسأل الخادم كل بضع ثوانٍ.
/// 4. **النهاية**: شُحنت — والطلبية دُفعت إن كانت «اشحن وادفع» — أو فشلت بسببها.
///
/// **مفتاحُ البدء يبقى حتى يجيب الخادم**: اتصالٌ انقطع بعد أن بدأ الخادمُ الشحن يُعاد بالمفتاح نفسه
/// فيعود بالمحاولة الأولى. رفضٌ من الخادم يُسقطه، فالمحاولة التالية محاولةٌ جديدة.
class TopUpCubit extends Cubit<TopUpState> {
  TopUpCubit({
    required GetTopUpMethods getMethods,
    required QuoteTopUp quote,
    required StartTopUp start,
    required ConfirmTopUpOtp confirmOtp,
    required GetTopUpAttempt getAttempt,
    this.orderId,
    String? initialAmount,
    this.pollEvery = const Duration(seconds: 4),
    this.quoteDelay = const Duration(milliseconds: 450),
  }) : _getMethods = getMethods,
       _quote = quote,
       _start = start,
       _confirmOtp = confirmOtp,
       _getAttempt = getAttempt,
       _amount = initialAmount ?? '',
       super(const TopUpLoading());

  final GetTopUpMethods _getMethods;
  final QuoteTopUp _quote;
  final StartTopUp _start;
  final ConfirmTopUpOtp _confirmOtp;
  final GetTopUpAttempt _getAttempt;

  /// «اشحن وادفع»: تُدفع هذه الطلبية من المحفظة بعد الشحن، على الخادم.
  final int? orderId;

  final Duration pollEvery;
  final Duration quoteDelay;

  String _amount;
  String? _token;
  Timer? _quoteTimer;
  Timer? _poll;

  /// يمنع عرضاً قديماً من أن يُرسم فوق عرضٍ لمبلغٍ كُتب بعده.
  int _quoteRequest = 0;

  /// المبلغ كما كُتب — لحقل النموذج حين يُعاد بناؤه.
  String get amount => _amount;

  Future<void> load() async {
    emit(const TopUpLoading());

    final result = await _getMethods();

    if (isClosed) return;

    result.fold((failure) => emit(TopUpUnavailable(failure: failure)), (methods) {
      final usable = [
        for (final m in methods.methods)
          if (m.isSupported) m,
      ];

      if (!methods.enabled || usable.isEmpty) {
        emit(const TopUpUnavailable());

        return;
      }

      emit(TopUpForm(methods: methods, usable: usable, selected: usable.first));
      _scheduleQuote(immediately: true);
    });
  }

  void select(TopUpMethod method) {
    final form = state;

    if (form is! TopUpForm || form.selected.id == method.id) return;

    _token = null;
    emit(form.copyWith(selected: method, clearQuote: true));
    _scheduleQuote(immediately: true);
  }

  void amountChanged(String text) {
    if (text == _amount) return;

    _amount = text;
    _token = null;

    if (state case final TopUpForm form) emit(form.copyWith(clearQuote: true));

    _scheduleQuote();
  }

  void _scheduleQuote({bool immediately = false}) {
    _quoteTimer?.cancel();

    if (double.tryParse(topUpAmount(_amount)) case final value? when value >= 1) {
      _quoteTimer = Timer(immediately ? Duration.zero : quoteDelay, _askQuote);
    }
  }

  Future<void> _askQuote() async {
    final form = state;

    if (form is! TopUpForm) return;

    final request = ++_quoteRequest;
    final method = form.selected;

    emit(form.copyWith(isQuoting: true));

    final result = await _quote(method: method.id, amount: _amount);

    if (isClosed || request != _quoteRequest) return;

    final now = state;

    if (now is! TopUpForm || now.selected.id != method.id) return;

    // عرضٌ فشل لا يوقف الزبون: يبدأ الشحن ويقول الخادم المبلغ في جوابه. إلا رفضَ المبلغ نفسه —
    // «أقل مبلغٍ يُدفع بهذه الطريقة ١٠» — فيُقال تحت المبلغ وهو يكتبه، لا بعد «تأكيد البيانات».
    emit(
      result.fold(
        (failure) => now.copyWith(isQuoting: false, clearQuote: true, quoteError: _amountRefusal(failure)),
        (quote) => now.copyWith(isQuoting: false, quote: quote),
      ),
    );
  }

  static String? _amountRefusal(Failure failure) => switch (failure) {
    ServerFailure(:final fieldErrors?) => fieldErrors['amount']?.firstOrNull,
    _ => null,
  };

  /// يبدأ الشحن بما في النموذج. يعود بالفشل لتوست — ورفضُ الحقول في `fieldErrors`.
  Future<Failure?> start({String? cardNumber, String? serviceMobileNumber, String? birthYear}) async {
    final form = state;

    if (form is! TopUpForm || form.isStarting) return null;

    emit(form.copyWith(isStarting: true));

    final token = _token ??= uuidV4();
    final result = await _start(
      TopUpRequest(
        method: form.selected.id,
        amount: topUpAmount(_amount),
        clientToken: token,
        orderId: orderId,
        cardNumber: cardNumber,
        serviceMobileNumber: serviceMobileNumber,
        birthYear: birthYear,
      ),
    );

    if (isClosed) return null;

    return result.fold(
      (failure) {
        // لم يُجب الخادم: لعلّه بدأ، فالإعادة بالمفتاح نفسه. أجاب بالرفض: المحاولة التالية جديدة.
        if (failure is! NetworkFailure) _token = null;

        if (state case final TopUpForm now) emit(now.copyWith(isStarting: false));

        return failure;
      },
      (answer) {
        _token = null;
        _follow(answer);

        return null;
      },
    );
  }

  /// الرمز الذي وصل برسالة. رمزٌ خاطئ يعود فشلاً، وتُقرأ المحاولة لما بقي من فرصها.
  Future<Failure?> confirmOtp(String code) async {
    final otp = state;

    if (otp is! TopUpOtp || otp.isSending) return null;

    emit(otp.copyWith(isSending: true));

    final result = await _confirmOtp(otp.attempt.id, code);

    if (isClosed) return null;

    final failure = result.fold<Failure?>((f) => f, (answer) {
      _follow(answer);

      return null;
    });

    if (failure == null) return null;

    final fresh = await _getAttempt(otp.attempt.id);

    if (isClosed) return failure;

    fresh.fold(
      (_) => emit(otp.copyWith(isSending: false)),
      (answer) => answer.attempt.requiresOtp ? emit(TopUpOtp(attempt: answer.attempt)) : _follow(answer),
    );

    return failure;
  }

  /// «تحقّق الآن» على صفحة الانتظار — ولا ينتظر السؤال التالي.
  Future<void> check() async {
    if (state case TopUpWaiting(:final attempt)) await _ask(attempt.id);
  }

  /// من النهاية — فشلت — أو من الرمز، إلى نموذجٍ جديد بالطرق نفسها.
  Future<void> again() async {
    _poll?.cancel();
    _token = null;
    await load();
  }

  void _follow(TopUpAnswer answer) {
    final attempt = answer.attempt;

    if (attempt.isFinal) {
      _poll?.cancel();
      emit(TopUpDone(attempt: attempt, balance: answer.balance));

      return;
    }

    if (attempt.requiresOtp) {
      emit(TopUpOtp(attempt: attempt));

      return;
    }

    emit(TopUpWaiting(attempt: attempt));
    _poll ??= Timer.periodic(pollEvery, (_) {
      if (state case TopUpWaiting(:final attempt)) unawaited(_ask(attempt.id));
    });
  }

  Future<void> _ask(String attemptId) async {
    final result = await _getAttempt(attemptId);

    if (isClosed) return;

    // سؤالٌ فشل يُعاد مع الدورة التالية.
    result.fold((_) {}, (answer) {
      if (state is TopUpWaiting) _follow(answer);
    });
  }

  @override
  Future<void> close() {
    _quoteTimer?.cancel();
    _poll?.cancel();

    return super.close();
  }
}

sealed class TopUpState {
  const TopUpState();
}

final class TopUpLoading extends TopUpState {
  const TopUpLoading();
}

/// الشحن من التطبيق غير متاح الآن — مطفأ، أو لا طريقة، أو تعذّرت القراءة ([failure]).
final class TopUpUnavailable extends TopUpState {
  const TopUpUnavailable({this.failure});

  final Failure? failure;
}

final class TopUpForm extends TopUpState {
  const TopUpForm({
    required this.methods,
    required this.usable,
    required this.selected,
    this.quote,
    this.quoteError,
    this.isQuoting = false,
    this.isStarting = false,
  });

  final TopUpMethods methods;

  /// ما يُعرض من [methods] — طرق QR تنتظر ماسحاً في التطبيق.
  final List<TopUpMethod> usable;
  final TopUpMethod selected;

  /// عرضُ الخادم للمبلغ والطريقة المكتوبين — null قبله أو حين فشل.
  final TopUpQuote? quote;

  /// ما قاله الخادم في المبلغ نفسه حين رفض عرضه — أقلُّ الطريقة أو أكثرُها. يُمسح مع العرض.
  final String? quoteError;
  final bool isQuoting;
  final bool isStarting;

  TopUpForm copyWith({
    TopUpMethod? selected,
    TopUpQuote? quote,
    String? quoteError,
    bool clearQuote = false,
    bool? isQuoting,
    bool? isStarting,
  }) => TopUpForm(
    methods: methods,
    usable: usable,
    selected: selected ?? this.selected,
    quote: clearQuote ? null : (quote ?? this.quote),
    quoteError: clearQuote ? quoteError : (quoteError ?? this.quoteError),
    isQuoting: isQuoting ?? this.isQuoting,
    isStarting: isStarting ?? this.isStarting,
  );
}

final class TopUpOtp extends TopUpState {
  const TopUpOtp({required this.attempt, this.isSending = false});

  final TopUpAttempt attempt;
  final bool isSending;

  TopUpOtp copyWith({bool? isSending}) => TopUpOtp(attempt: attempt, isSending: isSending ?? this.isSending);
}

/// صفحة البطاقة فُتحت، والتطبيق يسأل.
final class TopUpWaiting extends TopUpState {
  const TopUpWaiting({required this.attempt});

  final TopUpAttempt attempt;
}

final class TopUpDone extends TopUpState {
  const TopUpDone({required this.attempt, required this.balance});

  final TopUpAttempt attempt;

  /// رصيد المحفظة بعد الشحن — وبعد دفع الطلبية في «اشحن وادفع».
  final String balance;
}
