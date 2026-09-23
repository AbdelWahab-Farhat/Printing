import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:dayaa/features/investment_fund/presentation/viewmodel/investment_fund_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// الطريقان اللذان ينتقل بهما مالٌ بين محفظة المستثمر والصندوق.
///
/// **ولا مالَ يُخلق هنا ولا يُفنى.** الاشتراكُ ينقل رأسَ ماله من محفظته إلى الصندوق ويشتري به
/// وحداتٍ بسعر اليوم؛ والاستردادُ يعيده إلى محفظته ويُلغي وحداتِه. وما يخرج نقداً إلى يده حركةٌ
/// ثالثة تُسجَّل من شاشة محفظته — فهناك يقرّر أيأخذه أم يعيد الاشتراك به.
///
/// ولذلك **لا طريقةَ دفعٍ في هذه الورقة**: لا دينارَ يعبر الطاولة في أيٍّ من الاتجاهين.
enum FundCapitalAction {
  deposit('اشتراك في الصندوق', 'اشتراك'),
  withdrawal('استرداد رأس مال', 'استرداد');

  const FundCapitalAction(this.label, this.verb);

  final String label;
  final String verb;
}

/// يفتح ورقةَ إيداعٍ أو سحب على صندوقٍ مفتوح.
///
/// [cubit] يُمرَّر لا يُقرأ من الشجرة: الورقةُ تُبنى في مسارٍ آخر
/// (`showModalBottomSheet` جذرٌ مستقلّ) فلا تصل إلى `BlocProvider` الذي فوق الصفحة.
Future<void> showFundCapitalSheet({
  required BuildContext context,
  required InvestmentFundCubit cubit,
  required FundCapitalAction action,
  required FundStanding standing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _FundCapitalForm(cubit: cubit, action: action, standing: standing),
  );
}

class _FundCapitalForm extends StatefulWidget {
  const _FundCapitalForm({
    required this.cubit,
    required this.action,
    required this.standing,
  });

  final InvestmentFundCubit cubit;
  final FundCapitalAction action;

  /// اللوحةُ كما قرأها الخادم — منها تُقرأ الأسماءُ والسقوف، فلا نداءَ ثانٍ ولا رقمٌ يُحسب هنا.
  final FundStanding standing;

  @override
  State<_FundCapitalForm> createState() => _FundCapitalFormState();
}

class _FundCapitalFormState extends State<_FundCapitalForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _notes = TextEditingController();

  late final List<_Candidate> _candidates = _buildCandidates();
  late _Candidate? _investor = _candidates.isEmpty ? null : _candidates.first;

  bool _saving = false;

  /// من يجوز أن تقع عليه هذه الحركة، ومعه سقفُه.
  ///
  /// **الاشتراك** من كل من في محفظته رأسُ مال؛ و**الاسترداد** من حَمَلة الوحدات وحدهم. وعرضُ
  /// من لا يملك شيئاً في القائمة يجعل الرفضَ يأتي بعد أن كُتب المبلغ.
  List<_Candidate> _buildCandidates() {
    if (widget.action == FundCapitalAction.deposit) {
      return widget.standing.subscribable
          .where((row) => (double.tryParse(row.walletCapital) ?? 0) > 0)
          .map((row) => _Candidate(row.investorId, row.name, row.walletCapital))
          .toList();
    }

    return widget.standing.investors
        .map((row) => _Candidate(row.investorId, row.name, row.capital))
        .toList();
  }

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  /// الشكلُ، ثم السقفُ الذي وصل مع اللوحة.
  ///
  /// **والسقفُ يُفحص هنا وهناك معاً، ولا تناقضَ في ذلك.** الخادمُ هو الحَكَم — يقرأ الصفَّ
  /// المقفول فيمسك زميلاً سجّل سحباً قبل ثانية — لكن ردَّ الرقم قبل إرساله أرحمُ من رسالة
  /// رفضٍ بعد أن كُتب. أمّا مدةُ الحبس ونافذةُ الاكتتاب ونقدُ الخزينة فجوابُ الخادم وحده: كلُّها
  /// صفوفٌ لم ترها هذه الشاشة.
  String? _validateAmount(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'المبلغ مطلوب';

    final amount = double.tryParse(Validators.toWesternDigits(text));

    if (amount == null) return 'المبلغ يجب أن يكون رقماً';
    if (amount <= 0) return 'المبلغ يجب أن يكون أكبر من صفر';

    final ceiling = double.tryParse(_investor?.available ?? '0') ?? 0;

    if (amount > ceiling) {
      return widget.action == FundCapitalAction.deposit
          ? 'المتاح في محفظته ${_investor?.available.grouped ?? '0'} د.ل'
          : 'ما له في الصندوق ${_investor?.available.grouped ?? '0'} د.ل';
    }

    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final investor = _investor;

    if (investor == null) {
      context.showError('اختر المستثمر');

      return;
    }

    setState(() => _saving = true);

    final amount = Validators.toWesternDigits(_amount.text.trim());
    final notes = _notes.text.trim();

    if (widget.action == FundCapitalAction.deposit) {
      final (receipt, failure) = await widget.cubit.deposit(
        investorId: investor.id,
        amount: amount,
        notes: notes.isEmpty ? null : notes,
      );

      if (!mounted) return;

      setState(() => _saving = false);

      if (failure != null) {
        context.showError(failure.message);

        return;
      }

      Navigator.of(context).pop();

      // **ما اشتراه المال يُقال بعد الكتابة لا قبلها.** السعرُ قد يتحرّك بين فتح الورقة وضغط
      // الزرّ — طلبيةٌ حُصِّلت، مصروفٌ سُجِّل — والرقمُ الصادق هو ما كُتب على الصفّ.
      if (receipt != null) {
        context.showSuccess(
          '${receipt.units.grouped} وحدة بسعر ${receipt.unitPrice} — محبوسة إلى ${receipt.lockedUntil ?? '—'}',
        );
      }

      return;
    }

    final failure = await widget.cubit.withdraw(
      investorId: investor.id,
      amount: amount,
      notes: notes.isEmpty ? null : notes,
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (failure != null) {
      context.showError(failure.message);

      return;
    }

    Navigator.of(context).pop();
    context.showSuccess('رجع رأسُ المال إلى محفظته وأُلغيت وحداتُه');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isDeposit = widget.action == FundCapitalAction.deposit;

    return Padding(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 8.h,
        bottom: context.keyboardInset + 16.h,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                widget.action.label,
                style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4.h),
              Text(
                'سعر الوحدة اليوم ${widget.standing.unitPrice}',
                style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              SizedBox(height: 20.h),

              if (_candidates.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: Text(
                    isDeposit
                        ? 'لا أحد في محفظته رأس مال — يُسجَّل الإيداع من شاشة المستثمر أولاً'
                        : 'لا أحد يملك وحدات في الصندوق',
                    style: context.textTheme.bodyMedium,
                  ),
                )
              else ...[
                AppDropdown<_Candidate>(
                  value: _investor,
                  items: _candidates,
                  // **السقفُ في السطر نفسه**، لأن السؤال الأول عند اختيار الاسم هو «كم له؟»
                  // — وقائمةٌ بلا أرقام تعني اختيارَ اسمٍ ثم اكتشافَ أن لا مال له.
                  labelOf: (row) => '${row.name} — ${row.available.grouped} د.ل',
                  label: 'المستثمر',
                  prefixIcon: AppIcons.investors,
                  onChanged: (row) => setState(() => _investor = row),
                ),
                SizedBox(height: 16.h),
              ],

              AppTextField(
                controller: _amount,
                label: 'المبلغ',
                prefixIcon: AppIcons.payment,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.٫]'))],
                validator: _validateAmount,
              ),
              SizedBox(height: 16.h),

              AppTextField(
                controller: _notes,
                label: 'ملاحظات (اختياري)',
                prefixIcon: AppIcons.notes,
                textInputAction: TextInputAction.done,
                maxLines: 2,
              ),
              SizedBox(height: 24.h),

              AppButton(
                label: widget.action.verb,
                isLoading: _saving,
                onPressed: _saving || _candidates.isEmpty ? null : _submit,
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }
}

/// اسمٌ ومعه سقفُه — ما يُبنى منه صفُّ القائمة.
///
/// صنفٌ صغير بدل تمرير نموذجين مختلفين (مشتركٌ محتمل، وحاملُ وحدات): القائمةُ واحدة والحقلُ
/// واحد، والفرقُ بينهما هو من أين جاء الرقم لا كيف يُعرض.
class _Candidate {
  const _Candidate(this.id, this.name, this.available);

  final int id;
  final String name;
  final String available;
}
