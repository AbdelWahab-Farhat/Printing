/// «اشحن محفظتك» عبر EzonePay — ما ترسله نقاط `client/payments`. Docs/payments/CUSTOMER-WALLET.md §٥.
///
/// **أصنافٌ عادية لا Freezed**، و**المال نصٌّ من السلك إلى الشاشة**: العمولةُ يحسبها الخادم وحده،
/// والتطبيق يرسم ما قاله.
library;

import 'package:dayaa_client/core/utils/fixed_point.dart';

String _string(Object? value, [String fallback = '']) => value?.toString() ?? fallback;

String? _stringOrNull(Object? value) => value?.toString();

int? _intOrNull(Object? value) => (value as num?)?.toInt();

/// طريقة شحنٍ يستطيعها هذا الزبون الآن.
class TopUpMethod {
  const TopUpMethod({
    required this.id,
    required this.label,
    required this.flow,
    required this.feePercentage,
    this.needsCardNumber = false,
    this.needsServiceMobileNumber = false,
    this.needsBirthYear = false,
    this.maxAmount,
    this.remaining = const [],
  });

  /// رقم EzonePay للطريقة — يُرسل كما هو.
  final int id;
  final String label;

  /// `otp` · `qr` · `link`.
  final String flow;

  /// «2.5» — للعرض وحده، لا للحساب: ما يُخصم هو عرضُ الخادم.
  final String feePercentage;

  final bool needsCardNumber;
  final bool needsServiceMobileNumber;
  final bool needsBirthYear;

  /// أكبر ما يصل المحفظة في عمليةٍ واحدة — حدُّ EzonePay. فارغٌ: لا حدّ معروف.
  final String? maxAmount;

  /// ما بقي من حدود المحلّ اليوم والشهر والسنة — المحدودةُ وحدها.
  final List<String> remaining;

  /// QR يحتاج ماسحاً في التطبيق — لم يُبنَ بعد، فلا تُعرض طرقه.
  bool get isSupported => flow == 'otp' || flow == 'link';

  /// أصغر ما بقي من حدود المحلّ وحدّ EzonePay — أكثر ما يُشحن بها الآن. null: بلا حد.
  String? get cap {
    final caps = [?maxAmount, ...remaining];

    if (caps.isEmpty) return null;

    return caps.reduce((a, b) => thousandths(a) <= thousandths(b) ? a : b);
  }

  /// تستطيع أن تشحن [amount] كاملاً — عربون السلة يُشحن بمبلغه لا بأقل.
  bool canFund(String amount) => switch (cap) {
    final limit? => thousandths(limit) >= thousandths(amount),
    null => true,
  };

  factory TopUpMethod.fromJson(Map<String, dynamic> json) {
    final limits = json['limits'];

    return TopUpMethod(
      id: _intOrNull(json['id']) ?? 0,
      label: _string(json['label']),
      flow: _string(json['flow']),
      feePercentage: _string(json['fee_percentage'], '0'),
      needsCardNumber: json['needs_card_number'] == true,
      needsServiceMobileNumber: json['needs_service_mobile_number'] == true,
      needsBirthYear: json['needs_birth_year'] == true,
      maxAmount: _stringOrNull(json['max_amount']),
      remaining: [
        if (limits is Map<String, dynamic>)
          for (final period in limits.values)
            if (period is Map<String, dynamic>) ?_stringOrNull(period['remaining']),
      ],
    );
  }
}

/// ما تعرضه شاشة الشحن: هل الشحن متاح، ومن يدفع العمولة، والطرق.
class TopUpMethods {
  const TopUpMethods({required this.enabled, required this.feePayer, required this.methods});

  /// مطفأ: لا زرّ شحن في التطبيق.
  final bool enabled;

  /// `customer` — تُضاف العمولة إلى ما يُخصم — أو `shop`.
  final String feePayer;
  final List<TopUpMethod> methods;

  bool get feeOnCustomer => feePayer != 'shop';

  factory TopUpMethods.fromJson(Map<String, dynamic> json) => TopUpMethods(
    enabled: json['enabled'] == true,
    feePayer: _string(json['fee_payer'], 'customer'),
    methods: [
      for (final m in (json['methods'] as List<dynamic>? ?? const []))
        if (m is Map<String, dynamic>) TopUpMethod.fromJson(m),
    ],
  );
}

/// «تضيف ١٠٠ ← تدفع ١٠٢٫٥٠» — عرضُ الخادم قبل أن يبدأ الشحن.
class TopUpQuote {
  const TopUpQuote({required this.amount, required this.total, required this.fee});

  /// ما يصل المحفظة.
  final String amount;

  /// ما يُخصم من الزبون.
  final String total;

  /// ما يدفعه الزبون فوق [amount] — صفرٌ حين العمولة على المحلّ.
  final String fee;

  factory TopUpQuote.fromJson(Map<String, dynamic> json) => TopUpQuote(
    amount: _string(json['amount'], '0.00'),
    total: _string(json['total'], '0.00'),
    fee: _string(json['fee'], '0.00'),
  );
}

/// محاولة شحن كما يتابعها التطبيق.
class TopUpAttempt {
  const TopUpAttempt({
    required this.id,
    required this.methodLabel,
    required this.flow,
    this.methodId = 0,
    required this.status,
    required this.statusLabel,
    required this.isFinal,
    required this.amount,
    required this.total,
    required this.fee,
    this.requiresOtp = false,
    this.otpAttemptsLeft = 0,
    this.paymentUrl,
    this.orderId,
    this.failureReason,
  });

  /// المعرّف العام — ما يُسأل عنه ويُرسل إليه الرمز.
  final String id;

  /// رقم EzonePay للطريقة — شعارُها وطولُ رمزها في `top_up_catalog.dart`.
  final int methodId;
  final String methodLabel;
  final String flow;

  /// `created` · `pending` · `succeeded` · `failed` · `expired` · `needs_review`.
  final String status;
  final String statusLabel;

  /// لا تتغيّر بعد الآن — يتوقف السؤال.
  final bool isFinal;

  final bool requiresOtp;
  final int otpAttemptsLeft;

  /// صفحة البطاقة المصرفية، ما دامت تنتظر.
  final String? paymentUrl;

  final String amount;
  final String total;
  final String fee;

  /// «اشحن وادفع»: الطلبية التي تُدفع بعد الشحن.
  final int? orderId;
  final String? failureReason;

  bool get succeeded => status == 'succeeded';

  factory TopUpAttempt.fromJson(Map<String, dynamic> json) => TopUpAttempt(
    id: _string(json['id']),
    methodId: _intOrNull(json['method']) ?? 0,
    methodLabel: _string(json['method_label']),
    flow: _string(json['flow']),
    status: _string(json['status']),
    statusLabel: _string(json['status_label']),
    isFinal: json['is_final'] == true,
    requiresOtp: json['requires_otp'] == true,
    otpAttemptsLeft: _intOrNull(json['otp_attempts_left']) ?? 0,
    paymentUrl: _stringOrNull(json['payment_url']),
    amount: _string(json['amount'], '0.00'),
    total: _string(json['total'], '0.00'),
    fee: _string(json['fee'], '0.00'),
    orderId: _intOrNull(json['order_id']),
    failureReason: _stringOrNull(json['failure_reason']),
  );
}

/// ما يعود من بدء الشحن والرمز والسؤال: المحاولة، ورصيد المحفظة ساعتها.
class TopUpAnswer {
  const TopUpAnswer({required this.attempt, required this.balance});

  final TopUpAttempt attempt;
  final String balance;

  factory TopUpAnswer.fromJson(Map<String, dynamic> json) => TopUpAnswer(
    attempt: TopUpAttempt.fromJson(json['intent'] as Map<String, dynamic>),
    balance: _string(json['balance'], '0.00'),
  );
}

/// ما يطلبه بدء الشحن.
class TopUpRequest {
  const TopUpRequest({
    required this.method,
    required this.amount,
    required this.clientToken,
    this.orderId,
    this.orderAmount,
    this.cardNumber,
    this.serviceMobileNumber,
    this.birthYear,
  });

  final int method;
  final String amount;
  final String clientToken;
  final int? orderId;

  /// كم يُدفع للطلبية من المحفظة بعد الشحن — العربون الذي اختاره الزبون. بدونه: ما تستطيعه المحفظة.
  final String? orderAmount;
  final String? cardNumber;
  final String? serviceMobileNumber;
  final String? birthYear;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'method': method,
    'amount': amount,
    'client_token': clientToken,
    'order_id': ?orderId,
    if (orderId != null) 'order_amount': ?orderAmount,
    if (cardNumber case final v? when v.trim().isNotEmpty) 'card_number': v.trim(),
    if (serviceMobileNumber case final v? when v.trim().isNotEmpty) 'service_mobile_number': v.trim(),
    if (birthYear case final v? when v.trim().isNotEmpty) 'birth_year': v.trim(),
  };
}
