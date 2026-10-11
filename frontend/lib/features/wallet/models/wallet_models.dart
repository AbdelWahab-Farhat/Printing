/// «محفظة العميل» — ما ترسله نقاط المحفظة. Docs/payments/CUSTOMER-WALLET.md.
///
/// **أصنافٌ عادية لا Freezed**، على نسق `treasury_models.dart`: كلُّها للقراءة، و`fromJson` مكتوبٌ
/// باليد — فلا تحتاج توليداً.
///
/// **المال نصٌّ من السلك إلى الشاشة**: «1250.00» هو ما قاله الخادم.
library;

String _string(Object? value, [String fallback = '']) => value?.toString() ?? fallback;

String? _stringOrNull(Object? value) => value?.toString();

int? _intOrNull(Object? value) => (value as num?)?.toInt();

DateTime? _dateOrNull(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

Map<String, dynamic>? _mapOrNull(Object? value) => value is Map<String, dynamic> ? value : null;

/// سطرٌ واحد من محفظة عميل.
class CustomerWalletEntry {
  const CustomerWalletEntry({
    required this.id,
    required this.customerId,
    required this.type,
    required this.typeLabel,
    required this.isIn,
    required this.amount,
    this.customerName,
    this.customerCode,
    this.methodLabel,
    this.accountName,
    this.orderId,
    this.reference,
    this.notes,
    this.hasReceipt = false,
    this.receiptIsImage = false,
    this.receiptUrl,
    this.receiptFilename,
    this.occurredAt,
    this.isReversed = false,
    this.canReverse = false,
    this.isReversal = false,
    this.reversalReason,
    this.recorderName,
  });

  final int id;
  final int customerId;

  /// `topup` · `order_payment` · `order_refund` · `adjustment_credit` · `adjustment_debit` ·
  /// `reversal`. نوعٌ لا يعرفه هذا الإصدار يُرسم بـ[typeLabel] الخادم.
  final String type;
  final String typeLabel;

  /// يزيد المحفظة. **الخادم يقرّره** — العكسُ عكسُ ما يعكسه.
  final bool isIn;

  /// موجبٌ دائماً — الاتجاه في [isIn].
  final String amount;

  /// يُرسلان في «المعاملات المالية» وحدها، فهي تجمع العملاء كلهم.
  final String? customerName;
  final String? customerCode;

  /// طريقة الشحن والحساب الذي نزل فيه — للشحن وحده.
  final String? methodLabel;
  final String? accountName;

  /// دفعُ طلبيةٍ من المحفظة أو ردٌّ إليها.
  final int? orderId;

  final String? reference;
  final String? notes;

  final bool hasReceipt;
  final bool receiptIsImage;
  final String? receiptUrl;
  final String? receiptFilename;

  final DateTime? occurredAt;

  /// عُكس — يُرسم مشطوباً.
  final bool isReversed;

  /// **الخادم وحده يقول إن كان يُعكس من هنا** — شحنٌ أو تعديلٌ لم يُعكس، ولمن يملك الحقّ.
  final bool canReverse;

  final bool isReversal;

  /// سببُ العكس، تحت السطر المشطوب.
  final String? reversalReason;

  final String? recorderName;

  /// «+50.00» / «-30.00».
  String get signedAmount => isIn ? amount : '-$amount';

  /// السطر نفسه بعد أن عُكس.
  CustomerWalletEntry markedReversed({String? reason}) => CustomerWalletEntry(
    id: id,
    customerId: customerId,
    type: type,
    typeLabel: typeLabel,
    isIn: isIn,
    amount: amount,
    customerName: customerName,
    customerCode: customerCode,
    methodLabel: methodLabel,
    accountName: accountName,
    orderId: orderId,
    reference: reference,
    notes: notes,
    hasReceipt: hasReceipt,
    receiptIsImage: receiptIsImage,
    receiptUrl: receiptUrl,
    receiptFilename: receiptFilename,
    occurredAt: occurredAt,
    isReversed: true,
    isReversal: isReversal,
    reversalReason: reason ?? reversalReason,
    recorderName: recorderName,
  );

  factory CustomerWalletEntry.fromJson(Map<String, dynamic> json) => CustomerWalletEntry(
    id: (json['id'] as num).toInt(),
    customerId: _intOrNull(json['customer_id']) ?? 0,
    type: _string(json['type']),
    typeLabel: _string(json['type_label']),
    isIn: json['direction'] == 'in',
    amount: _string(json['amount'], '0.00'),
    customerName: _stringOrNull(_mapOrNull(json['customer'])?['name']),
    customerCode: _stringOrNull(_mapOrNull(json['customer'])?['code']),
    methodLabel: _stringOrNull(json['method_label']),
    accountName: _stringOrNull(_mapOrNull(json['treasury_account'])?['name']),
    orderId: _intOrNull(json['order_id']),
    reference: _stringOrNull(json['reference']),
    notes: _stringOrNull(json['notes']),
    hasReceipt: json['has_receipt'] == true,
    receiptIsImage: json['receipt_is_image'] == true,
    receiptUrl: _stringOrNull(json['receipt_url']),
    receiptFilename: _stringOrNull(json['receipt_filename']),
    occurredAt: _dateOrNull(json['occurred_at']),
    isReversed: json['is_reversed'] == true,
    canReverse: json['can_reverse'] == true,
    isReversal: json['type'] == 'reversal',
    reversalReason: _stringOrNull(_mapOrNull(json['reversal'])?['reason']),
    recorderName: _stringOrNull(_mapOrNull(json['recorder'])?['name']),
  );
}

/// محفظة عميل: رصيدها.
class CustomerWallet {
  const CustomerWallet({required this.customerId, required this.balance});

  final int customerId;
  final String balance;

  factory CustomerWallet.fromJson(Map<String, dynamic> json) => CustomerWallet(
    customerId: _intOrNull(json['customer_id']) ?? 0,
    balance: _string(json['balance'], '0.00'),
  );
}

/// ما يعود بعد كتابةٍ على المحفظة: السطر الذي كتبه الخادم، والرصيد بعده.
class WalletWrite {
  const WalletWrite({required this.entry, required this.balance});

  final CustomerWalletEntry entry;
  final String balance;

  factory WalletWrite.fromJson(Map<String, dynamic> json) => WalletWrite(
    entry: CustomerWalletEntry.fromJson(json['entry'] as Map<String, dynamic>),
    balance: _string(json['balance'], '0.00'),
  );
}

/// فلتر السجل — نوعٌ واحد يرسله الخادم، أو الكل.
enum WalletEntryFilter {
  all(null, 'الكل'),
  topup('topup', 'الشحن'),
  orderPayment('order_payment', 'دفع الطلبيات'),
  orderRefund('order_refund', 'الردود');

  const WalletEntryFilter(this.wire, this.label);

  final String? wire;
  final String label;
}

/// كيف وصل المال إلى المحفظة في المكتب — طرق دفع الطلبيات الأربع، بلا المحفظة نفسها.
enum TopUpMethod {
  cash('cash', 'كاش'),
  bankTransfer('bank_transfer', 'حوالة'),
  bankCard('bank_card', 'بطاقة مصرفية'),
  libyana('libyana', 'ليبيانا');

  const TopUpMethod(this.wire, this.label);

  final String wire;
  final String label;

  /// الحوالة وحدها تتطلب الواصل — قاعدةُ الخادم وقيدُ القاعدة.
  bool get requiresReceipt => this == TopUpMethod.bankTransfer;
}
