/// ما يُرسم لكل طريقة شحن — شعارها، ومصرفها، وأسماء حقولها، وطول رمزها. على نسق بريمولا
/// (`payment_method_enum.dart`)، والأرقام أرقامُ EzonePay نفسها (١٠١–١١١). CUSTOMER-WALLET §٥.
///
/// **الاسم من الخادم لا من هنا**؛ هذا ما لا يرسله: صورةٌ محزومة، وسطرٌ يقول أيّ مصرف، وكيف يُسمّى
/// الحقل لهذه الطريقة. طريقةٌ لا يعرفها هذا الإصدار تُرسم بأيقونةٍ وأسماءٍ عامة.
library;

class TopUpBrand {
  const TopUpBrand({this.asset, this.subtitle, this.cardLabel, this.mobileLabel, this.otpLength = 6});

  /// `assets/payment/…` — null: أيقونة البطاقة العامة.
  final String? asset;

  /// «مصرف الوحدة» — تحت الاسم في القائمة.
  final String? subtitle;

  /// ما يسمّيه الزبون — EzonePay يسمّيه `cardNumber`.
  final String? cardLabel;

  /// رقم الهاتف لدى الخدمة.
  final String? mobileLabel;

  /// أرقام رمز التحقق — مربعاتٌ بعددها.
  final int otpLength;
}

const _purchaseCode = 'رمز الشراء';

const Map<int, TopUpBrand> _brands = {
  101: TopUpBrand(asset: 'assets/payment/moamalat.png', subtitle: 'البطاقات المصرفية المفعّلة أونلاين'),
  102: TopUpBrand(asset: 'assets/payment/mobicash.png', subtitle: 'مصرف الوحدة', cardLabel: _purchaseCode),
  103: TopUpBrand(asset: 'assets/payment/onepay.png', cardLabel: _purchaseCode),
  104: TopUpBrand(asset: 'assets/payment/masrifipay.png', subtitle: 'مصرف الجمهورية', cardLabel: _purchaseCode),
  105: TopUpBrand(asset: 'assets/payment/yussorpay.png', subtitle: 'مصرف التجاري الوطني', cardLabel: _purchaseCode),
  106: TopUpBrand(
    asset: 'assets/payment/edfali.png',
    subtitle: 'خاص بمصرف التجارة والتنمية',
    mobileLabel: 'رقم هاتف ادفعلي',
    otpLength: 4,
  ),
  107: TopUpBrand(asset: 'assets/payment/sadad.png', subtitle: 'خاصة بشركة المدار', mobileLabel: 'رقم هاتف سداد'),
  108: TopUpBrand(asset: 'assets/payment/saharapay.png', subtitle: 'مصرف الصحاري', cardLabel: _purchaseCode),
  111: TopUpBrand(asset: 'assets/payment/libyana.png', mobileLabel: 'رقم هاتف ليبيانا'),
};

TopUpBrand brandOf(int method) => _brands[method] ?? const TopUpBrand();

/// ليبيانا: الرقم اختياري — فارغاً يأخذ الخادم هاتف الحساب. يُعرض ليشحن من خطٍّ آخر، كما في بريمولا.
const int libyana = 111;
