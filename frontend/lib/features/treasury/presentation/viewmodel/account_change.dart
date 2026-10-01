import 'package:dayaa/features/treasury/models/treasury_models.dart';

/// ما تُسلّمه صفحة الحساب لمن فتحها حين تُغلق — ولا شيء حين لم يتغيّر شيء.
///
/// **صنفان لأن الجوابين مختلفان:** التعديل يعرف التطبيقُ أثره كاملاً — الحساب بعد الحفظ في ردّ
/// الخادم نفسه — فيُرقَّع صفُّه في مكانه. أما المال الذي تحرّك فيغيّر المجموع، وحساباً آخر في
/// التحويل، و«مال الشركة نفسها» — وتلك حساباتُ الخادم، فتُقرأ مرةً واحدة.
sealed class AccountChange {
  const AccountChange();
}

/// عُدِّل الحساب ولم يتحرّك مال: هذا هو بعد الحفظ.
final class AccountEdited extends AccountChange {
  const AccountEdited(this.account);

  final TreasuryAccount account;
}

/// سُجِّلت عمليةٌ أو عُكست — الأرصدة تغيّرت.
final class AccountMoneyMoved extends AccountChange {
  const AccountMoneyMoved();
}
