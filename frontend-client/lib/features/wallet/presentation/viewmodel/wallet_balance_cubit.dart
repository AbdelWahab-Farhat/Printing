import 'package:dayaa_client/features/wallet/usecases/wallet_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// رصيد «محفظتي» للتطبيق كله — تقرؤه الحبّة في الشريط العلوي (`WalletBalanceChip`).
/// Docs/payments/CUSTOMER-WALLET.md.
///
/// **مفرَدٌ كـ`CartCubit` و`BadgesCubit`**: الرصيد للجلسة لا لشاشة، والحبّة فوق الأقسام الأربعة
/// تقرأ الرقم نفسه الذي دفعت منه شاشة الطلبية قبل لحظة.
///
/// **null حتى يصل**، ولا حالة تحميلٍ ولا خطأ: الحبّة ترسم «…» مكان الرقم، ولا يُرسم صفرٌ لم يقله
/// الخادم.
///
/// **ما يحدّثه:**
///   * دخولٌ جديد ([load]) وعودة التطبيق إلى الواجهة ([refresh]) — تتولّاهما الحبّة نفسها؛
///   * جوابٌ عرفته شاشةٌ بلا سؤال ([patch]): «محفظتي» حين تصل صفحتها، وشاشة الطلبية حين تقرأ
///     الرصيد أو تدفع منه.
class WalletBalanceCubit extends Cubit<String?> {
  WalletBalanceCubit({required GetWalletBalance getBalance})
    : _getBalance = getBalance,
      super(null);

  final GetWalletBalance _getBalance;

  /// يبدأ من لا شيء ثم يسأل — لأول ما تُبنى الحبّة بعد الدخول. **لا يُرى رصيد من خرج لحظةً على
  /// حساب من دخل** على الهاتف نفسه، والمفرَد يعيش أطول من الجلسة.
  Future<void> load() {
    emit(null);

    return refresh();
  }

  /// يسأل الخادم. **سؤالٌ فشل يُبقي آخر رصيدٍ معروف**: محوه يرسم «…» على رقمٍ صحيح لأن الاتصال
  /// انقطع.
  Future<void> refresh() async {
    final result = await _getBalance();

    if (isClosed) return;

    result.fold((_) {}, emit);
  }

  /// الرصيد كما قاله الخادم لشاشةٍ أخرى — بعد دفعٍ من المحفظة أو شحنها — فلا يُسأل عنه ثانية.
  void patch(String balance) => emit(balance);
}
