import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// ما يعرضه منتقي «الحساب» على نماذج الدفع: الحسابات التي تقبلها الطريقة، والذي سيختاره الخادم
/// حين يُترك «تلقائي». TREASURY-DESIGN §٥.
///
/// **السؤال يتغيّر مع النموذج** — الطريقة، والاتجاه، والطلبية — و[load] يُنادى مع كل تغيير.
/// عدّادٌ يُسقط الجواب الذي وصل بعد أن تغيّر السؤال: قائمةُ الكاش المتأخرة لا تُرسم فوق قائمة
/// الحوالة.
class AccountPickerCubit extends Cubit<AccountPickerState> {
  AccountPickerCubit({
    required GetAccountOptions getOptions,
    required GetTreasuryAccounts getAccounts,
  }) : _getOptions = getOptions,
       _getAccounts = getAccounts,
       super(const AccountPickerLoading());

  final GetAccountOptions _getOptions;
  final GetTreasuryAccounts _getAccounts;

  int _requestId = 0;
  _Question? _last;

  /// [method] قيمة الطريقة على السلك — `cash`، `bank_transfer`…
  ///
  /// **فارغٌ لنموذجٍ يسأل أيّ درجٍ دفع لا كيف** — مصروف الصندوق أو الصفقة: يُعرض كل حسابٍ مفعّل
  /// يُصرف منه، و«تلقائي» ما يختاره الخادم للنقد الخارج (حساب المسجّل النقدي، وإلا الخزنة).
  Future<void> load({required String? method, required bool incoming, int? orderId}) {
    _last = _Question(method: method, incoming: incoming, orderId: orderId);

    return _ask(_last!);
  }

  /// السؤال الأخير نفسه، بعد فشل.
  Future<void> retry() async {
    if (_last case final question?) await _ask(question);
  }

  Future<void> _ask(_Question question) async {
    final requestId = ++_requestId;

    emit(const AccountPickerLoading());

    final method = question.method;
    final result = method == null
        ? await _spendable()
        : await _getOptions(
            method: method,
            incoming: question.incoming,
            orderId: question.orderId,
          );

    // تغيّر السؤال والجوابُ في الطريق — هذا جوابُ سؤالٍ لم يعد أحدٌ يسأله.
    if (isClosed || requestId != _requestId) return;

    emit(
      result.fold(
        (failure) => AccountPickerFailed(failure),
        (options) => AccountPickerLoaded(options),
      ),
    );
  }

  /// كل حسابٍ مفعّل يُصرف منه، واسمُ ما يختاره الخادم لكاشٍ خارج.
  Future<Either<Failure, AccountOptions>> _spendable() async {
    final (accounts, cash) = await (
      _getAccounts(activeOnly: true),
      _getOptions(method: 'cash', incoming: false),
    ).wait;

    return accounts.flatMap(
      (list) => cash.map(
        (suggestion) => AccountOptions(
          accounts: [
            for (final account in list.accounts)
              if (account.isSpendable && account.isActive)
                AccountOption(
                  id: account.id,
                  name: account.name,
                  kindLabel: account.kindLabel,
                  isDefault: account.isDefault,
                ),
          ],
          suggestedId: suggestion.suggestedId,
          suggestedName: suggestion.suggestedName,
        ),
      ),
    );
  }
}

/// ما سُئل الخادم عنه آخر مرة — لـ«إعادة المحاولة».
class _Question {
  const _Question({required this.method, required this.incoming, required this.orderId});

  final String? method;
  final bool incoming;
  final int? orderId;
}

sealed class AccountPickerState {
  const AccountPickerState();
}

final class AccountPickerLoading extends AccountPickerState {
  const AccountPickerLoading();
}

final class AccountPickerLoaded extends AccountPickerState {
  const AccountPickerLoaded(this.options);

  final AccountOptions options;
}

final class AccountPickerFailed extends AccountPickerState {
  const AccountPickerFailed(this.failure);

  final Failure failure;
}
