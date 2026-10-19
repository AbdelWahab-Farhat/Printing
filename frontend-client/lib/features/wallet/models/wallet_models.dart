/// «محفظتي» — ما ترسله نقاط المحفظة. Docs/payments/CUSTOMER-WALLET.md.
///
/// **أصنافٌ عادية لا Freezed**: للقراءة كلُّها، و`fromJson` مكتوبٌ باليد — فلا تحتاج توليداً.
/// **والمال نصٌّ من السلك إلى الشاشة**: «1250.00» هو ما قاله الخادم.
library;

String _string(Object? value, [String fallback = '']) => value?.toString() ?? fallback;

String? _stringOrNull(Object? value) => value?.toString();

int? _intOrNull(Object? value) => (value as num?)?.toInt();

DateTime? _dateOrNull(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

/// سطرٌ من محفظتي.
///
/// **ما يعرفه العميل وحده**: لا الحساب الذي نزل فيه المال، ولا اسم الموظف، ولا سبب التعديل.
class MyWalletEntry {
  const MyWalletEntry({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.isIn,
    required this.amount,
    this.method,
    this.onlineMethod,
    this.methodLabel,
    this.orderId,
    this.orderCode,
    this.description,
    this.isReversed = false,
    this.occurredAt,
  });

  final int id;

  /// `topup` · `order_payment` · `order_refund` · `adjustment_credit` · `adjustment_debit` ·
  /// `reversal`. نوعٌ لا يعرفه هذا الإصدار يُرسم بـ[typeLabel] الخادم.
  final String type;
  final String typeLabel;

  /// يزيد المحفظة — الخادم يقرّره.
  final bool isIn;

  /// موجبٌ دائماً.
  final String amount;

  /// كيف شُحنت، للشحن وحده: `cash` · `bank_transfer` · `bank_card` · `libyana` · `online`.
  /// خادمٌ قديم لا يرسله، فيُرسم السطر بأيقونة الشحن العامة.
  final String? method;

  /// رقم طريقة EzonePay (١٠٣ ون باي…) لشحنٍ إلكتروني — منه شعار الطريقة على السطر
  /// (`brandOf` في `top_up_catalog.dart`).
  final int? onlineMethod;

  /// كيف شُحنت، باسمها: «كاش»، أو «ون باي» لشحنٍ إلكتروني.
  final String? methodLabel;

  /// دفعُ طلبيةٍ أو ردٌّ منها — تُفتح.
  final int? orderId;

  /// رقم الطلبية كما يُكتب، وحده بلا «طلبية» ولا «#». null من خادمٍ قديم: يُكتب [orderId].
  final String? orderCode;

  /// «الطلبية 1304» لقيود الطلبيات وحدها.
  final String? description;

  final bool isReversed;
  final DateTime? occurredAt;

  factory MyWalletEntry.fromJson(Map<String, dynamic> json) => MyWalletEntry(
    id: (json['id'] as num).toInt(),
    type: _string(json['type']),
    typeLabel: _string(json['type_label']),
    isIn: json['direction'] == 'in',
    amount: _string(json['amount'], '0.00'),
    method: _stringOrNull(json['method']),
    onlineMethod: _intOrNull(json['online_method']),
    methodLabel: _stringOrNull(json['method_label']),
    orderId: _intOrNull(json['order_id']),
    orderCode: _stringOrNull(json['order_code']),
    description: _stringOrNull(json['description']),
    isReversed: json['is_reversed'] == true,
    occurredAt: _dateOrNull(json['occurred_at']),
  );
}

/// فلتر المعاملات — نوعٌ واحد يرسله الخادم، أو الكل.
enum MyWalletFilter {
  all(null, 'الكل'),
  topup('topup', 'الشحن'),
  orderPayment('order_payment', 'المدفوع'),
  orderRefund('order_refund', 'المردود');

  const MyWalletFilter(this.wire, this.label);

  final String? wire;
  final String label;
}

/// رصيد المحفظة كما في `meta.balance` لصفحة المعاملات، أو null حين لا يُرسَل.
String? walletBalanceIn(Map<String, dynamic> meta) => _stringOrNull(meta['balance']);
