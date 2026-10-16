/// «المدفوعات الإلكترونية» — شحن المحافظ عبر EzonePay كما يراه الموظفون.
/// Docs/payments/CUSTOMER-WALLET.md §٥.
///
/// **أصنافٌ عادية لا Freezed**، على نسق `wallet_models.dart`: للقراءة، و`fromJson` باليد.
/// **المال نصٌّ من السلك إلى الشاشة**.
library;

String _string(Object? value, [String fallback = '']) => value?.toString() ?? fallback;

String? _stringOrNull(Object? value) => value?.toString();

int? _intOrNull(Object? value) => (value as num?)?.toInt();

DateTime? _dateOrNull(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

Map<String, dynamic>? _mapOrNull(Object? value) => value is Map<String, dynamic> ? value : null;

/// حالة محاولة الشحن — كما يرسلها الخادم.
enum IntentStatus {
  created('created'),
  pending('pending'),
  succeeded('succeeded'),
  failed('failed'),
  expired('expired'),
  needsReview('needs_review'),
  unknown('');

  const IntentStatus(this.wire);

  final String wire;

  static IntentStatus fromWire(Object? value) =>
      values.firstWhere((s) => s.wire == value, orElse: () => IntentStatus.unknown);

  /// ما زالت تنتظر الزبون أو EzonePay.
  bool get isOpen => this == created || this == pending;
}

/// فلتر الصفحة — حالةٌ واحدة، أو الكل.
enum IntentFilter {
  all(null, 'الكل'),
  pending('pending', 'بانتظار الدفع'),
  succeeded('succeeded', 'تم الشحن'),
  needsReview('needs_review', 'تحتاج مراجعة'),
  failed('failed', 'فشل'),
  expired('expired', 'انتهت المهلة');

  const IntentFilter(this.wire, this.label);

  final String? wire;
  final String label;
}

/// محاولة شحنٍ واحدة عبر EzonePay.
class PaymentIntent {
  const PaymentIntent({
    required this.id,
    required this.uuid,
    required this.methodLabel,
    required this.status,
    required this.statusLabel,
    required this.netAmount,
    required this.grossAmount,
    required this.customerFee,
    required this.feePayerLabel,
    required this.reference,
    this.customerId,
    this.customerName,
    this.customerCode,
    this.customerPhone,
    this.orderId,
    this.flow = '',
    this.feeRate,
    this.providerFee,
    this.providerTransactionId,
    this.otpAttempts = 0,
    this.failureReason,
    this.walletEntryId,
    this.expiresAt,
    this.succeededAt,
    this.createdAt,
    this.canRecheck = false,
  });

  final int id;

  /// ما يُسمّى به في المسارات — `online-payments/{uuid}/recheck`.
  final String uuid;

  final int? customerId;
  final String? customerName;
  final String? customerCode;
  final String? customerPhone;

  /// «اشحن وادفع»: الطلبية التي تُدفع بعد الشحن.
  final int? orderId;

  final String methodLabel;

  /// `otp` · `qr` · `link`.
  final String flow;

  final IntentStatus status;
  final String statusLabel;

  /// ما يصل المحفظة.
  final String netAmount;

  /// ما يُخصم من الزبون.
  final String grossAmount;

  /// ما دفعه الزبون فوق الصافي — صفرٌ حين العمولة على المحلّ.
  final String customerFee;

  final String? feeRate;
  final String feePayerLabel;

  /// ما أخذته EzonePay فعلاً — يُعرف بعد الشحن.
  final String? providerFee;

  /// مرجعنا الذي يُرسل لـ EzonePay.
  final String reference;
  final String? providerTransactionId;
  final int otpAttempts;
  final String? failureReason;
  final int? walletEntryId;

  final DateTime? expiresAt;
  final DateTime? succeededAt;
  final DateTime? createdAt;

  /// **الخادم يقرّر**: لم يُشحن، ولا ينتظر شخصاً، ولمن يملك الحقّ.
  final bool canRecheck;

  factory PaymentIntent.fromJson(Map<String, dynamic> json) {
    final customer = _mapOrNull(json['customer']);

    return PaymentIntent(
      id: (json['id'] as num).toInt(),
      uuid: _string(json['uuid']),
      customerId: _intOrNull(customer?['id']),
      customerName: _stringOrNull(customer?['name']),
      customerCode: _stringOrNull(customer?['code']),
      customerPhone: _stringOrNull(customer?['phone']),
      orderId: _intOrNull(json['order_id']),
      methodLabel: _string(json['method_label']),
      flow: _string(json['flow']),
      status: IntentStatus.fromWire(json['status']),
      statusLabel: _string(json['status_label']),
      netAmount: _string(json['net_amount'], '0.00'),
      grossAmount: _string(json['gross_amount'], '0.00'),
      customerFee: _string(json['customer_fee'], '0.00'),
      feeRate: _stringOrNull(json['fee_rate']),
      feePayerLabel: _string(json['fee_payer_label']),
      providerFee: _stringOrNull(json['provider_fee']),
      reference: _string(json['reference']),
      providerTransactionId: _stringOrNull(json['provider_transaction_id']),
      otpAttempts: _intOrNull(json['otp_attempts']) ?? 0,
      failureReason: _stringOrNull(json['failure_reason']),
      walletEntryId: _intOrNull(json['wallet_entry_id']),
      expiresAt: _dateOrNull(json['expires_at']),
      succeededAt: _dateOrNull(json['succeeded_at']),
      createdAt: _dateOrNull(json['created_at']),
      canRecheck: json['can_recheck'] == true,
    );
  }
}

/// طريقة دفعٍ من EzonePay كما ضبطها المحلّ: مفعّلة أو لا، وحدودها لكل زبون.
class OnlinePaymentMethodSetting {
  const OnlinePaymentMethodSetting({
    required this.id,
    required this.method,
    required this.label,
    required this.flow,
    required this.isActive,
    this.dailyLimit,
    this.monthlyLimit,
    this.yearlyLimit,
  });

  final int id;

  /// رقم EzonePay للطريقة.
  final int method;
  final String label;
  final String flow;
  final bool isActive;

  /// فارغٌ: بلا حدّ.
  final String? dailyLimit;
  final String? monthlyLimit;
  final String? yearlyLimit;

  factory OnlinePaymentMethodSetting.fromJson(Map<String, dynamic> json) => OnlinePaymentMethodSetting(
    id: (json['id'] as num).toInt(),
    method: _intOrNull(json['method']) ?? 0,
    label: _string(json['label']),
    flow: _string(json['flow']),
    isActive: json['is_active'] == true,
    dailyLimit: _stringOrNull(json['daily_limit']),
    monthlyLimit: _stringOrNull(json['monthly_limit']),
    yearlyLimit: _stringOrNull(json['yearly_limit']),
  );
}

/// صفحة «طرق الدفع الإلكتروني»: هل الدفع الإلكتروني مفعّل، ومن يدفع العمولة، والطرق.
class OnlinePaymentMethods {
  const OnlinePaymentMethods({required this.enabled, required this.feePayer, required this.methods});

  /// `EZONE_PAY_ENABLED` على الخادم — مطفأً لا يرى الزبون زرّ الشحن.
  final bool enabled;

  /// `customer` · `shop`.
  final String feePayer;
  final List<OnlinePaymentMethodSetting> methods;

  OnlinePaymentMethods withMethod(OnlinePaymentMethodSetting saved) => OnlinePaymentMethods(
    enabled: enabled,
    feePayer: feePayer,
    methods: [for (final m in methods) m.id == saved.id ? saved : m],
  );

  factory OnlinePaymentMethods.fromJson(Map<String, dynamic> json) => OnlinePaymentMethods(
    enabled: json['enabled'] == true,
    feePayer: _string(json['fee_payer'], 'customer'),
    methods: [
      for (final m in (json['methods'] as List<dynamic>? ?? const []))
        if (m is Map<String, dynamic>) OnlinePaymentMethodSetting.fromJson(m),
    ],
  );
}

/// ما يعود بعد «تحويل Ezone إلى المصرف»: العملية، ورصيد «Ezone» بعدها.
class EzonePayout {
  const EzonePayout({required this.operationId, required this.ezoneBalance});

  final int operationId;
  final String ezoneBalance;

  factory EzonePayout.fromJson(Map<String, dynamic> json) => EzonePayout(
    operationId: _intOrNull(json['operation_id']) ?? 0,
    ezoneBalance: _string(json['ezone_balance'], '0.00'),
  );
}
