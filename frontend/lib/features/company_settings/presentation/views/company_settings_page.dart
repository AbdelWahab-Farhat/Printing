import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/company_settings/models/company_settings.dart';
import 'package:dayaa/features/company_settings/presentation/viewmodel/company_settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// إعدادات الاستثمار — the four numbers every صندوق runs on.
///
/// **One calendar for every pool.** The periods are global, so a close is one action over all of
/// them rather than a date remembered per pool: the alternative is a pool whose month ends on the
/// 3rd sitting beside one that ends on the 28th, and a person having to know which.
///
/// **Nothing here can reach a period that has already closed.** «Next close» and «next
/// settlement» are derived — the open period's end date, and the last settlement plus the
/// interval — never stored, so a change only ever affects what has not happened yet. That is a
/// property of the design rather than a guard somebody remembers, and it is why this screen needs
/// no warning about editing history.
class CompanySettingsPage extends StatelessWidget {
  const CompanySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CompanySettingsCubit>(
      create: (_) => sl<CompanySettingsCubit>()..load(),
      child: const _CompanySettingsView(),
    );
  }
}

class _CompanySettingsView extends StatelessWidget {
  const _CompanySettingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات الاستثمار')),
      body: BlocBuilder<CompanySettingsCubit, CompanySettingsState>(
        builder: (context, state) => switch (state) {
          CompanySettingsLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          CompanySettingsFailure(:final failure) => Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Text(failure.message, textAlign: TextAlign.center),
            ),
          ),
          CompanySettingsLoaded(:final settings) => _Form(settings: settings),
        },
      ),
    );
  }
}

class _Form extends StatefulWidget {
  const _Form({required this.settings});

  final CompanySettings settings;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _share;
  late final TextEditingController _profitMonths;
  late final TextEditingController _settlementMonths;
  late final TextEditingController _graceDays;
  late final TextEditingController _minimumTerm;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _share = TextEditingController(
      text: widget.settings.investorProfitSharePercent,
    );
    _profitMonths = TextEditingController(
      text: widget.settings.profitPeriodMonths.toString(),
    );
    _settlementMonths = TextEditingController(
      text: widget.settings.settlementPeriodMonths.toString(),
    );
    _graceDays = TextEditingController(
      text: widget.settings.entryGraceDays.toString(),
    );
    _minimumTerm = TextEditingController(
      text: widget.settings.minimumTermMonths.toString(),
    );
  }

  @override
  void dispose() {
    _share.dispose();
    _profitMonths.dispose();
    _settlementMonths.dispose();
    _graceDays.dispose();
    _minimumTerm.dispose();
    super.dispose();
  }

  /// Shape only. **The server's ranges are the ranges** — it refuses a period over twelve months
  /// and a grace window over twenty-eight days, and copying those bounds here would be a second
  /// set to keep in step.
  String? _whole(String? value, {required String label, int min = 0}) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return '$label مطلوب';

    final number = int.tryParse(Validators.toWesternDigits(text));

    if (number == null) return '$label يجب أن يكون رقماً صحيحاً';
    if (number < min) return '$label لا يقل عن $min';

    return null;
  }

  String? _percent(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'النسبة مطلوبة';

    final number = double.tryParse(Validators.toWesternDigits(text));

    if (number == null) return 'النسبة يجب أن تكون رقماً';
    if (number < 0 || number > 100) return 'النسبة بين صفر ومئة';

    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    final failure = await context.read<CompanySettingsCubit>().save(
      widget.settings.copyWith(
        investorProfitSharePercent: Validators.toWesternDigits(_share.text),
        profitPeriodMonths:
            int.tryParse(Validators.toWesternDigits(_profitMonths.text)) ??
            widget.settings.profitPeriodMonths,
        settlementPeriodMonths:
            int.tryParse(Validators.toWesternDigits(_settlementMonths.text)) ??
            widget.settings.settlementPeriodMonths,
        entryGraceDays:
            int.tryParse(Validators.toWesternDigits(_graceDays.text)) ??
            widget.settings.entryGraceDays,
        minimumTermMonths:
            int.tryParse(Validators.toWesternDigits(_minimumTerm.text)) ??
            widget.settings.minimumTermMonths,
      ),
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (failure != null) {
      context.showError(failure.message);

      return;
    }

    context.showSuccess('تم تحديث الإعدادات — تسري على الفترات القادمة وحدها');
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
        children: [
          AppTextField(
            controller: _share,
            label: 'حصة المستثمرين من الربح (٪)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: _percent,
          ),
          const _Hint(
            // The single most misread field on this screen: changing it does not renegotiate
            // anybody's pool.
            'تُنسخ إلى الصندوق يوم فتحه وتُجمَّد فيه — تغييرها هنا لا يمسّ صندوقاً قائماً',
          ),
          SizedBox(height: 16.h),

          AppTextField(
            controller: _profitMonths,
            label: 'مدة فترة الأرباح (بالأشهر)',
            keyboardType: TextInputType.number,
            validator: (value) =>
                _whole(value, label: 'مدة فترة الأرباح', min: 1),
          ),
          const _Hint('كل فترة تُقفَل على حدة، وتُوزَّع أرباحها وتُفتح التي بعدها'),
          SizedBox(height: 16.h),

          AppTextField(
            controller: _settlementMonths,
            label: 'مدة التسوية (بالأشهر)',
            keyboardType: TextInputType.number,
            validator: (value) => _whole(value, label: 'مدة التسوية', min: 1),
          ),
          const _Hint('دورة مراجعة أطول — لا تُقفل شيئاً ولا تحرّك مالاً'),
          SizedBox(height: 16.h),

          AppTextField(
            controller: _minimumTerm,
            label: 'الحد الأدنى للبقاء (بالأشهر)',
            keyboardType: TextInputType.number,
            validator: (value) => _whole(value, label: 'الحد الأدنى للبقاء'),
          ),
          const _Hint(
            'قبل انقضائها لا يستطيع الشريك طلب سحب رأس ماله. تُحسب من أول مبلغ '
            'دخل به الصندوق — والزيادة عليه لا تعيد العدّ من جديد. صفر يعني بلا حدّ. '
            'رأس مال الشركة نفسه غير مقيَّد بها.',
          ),
          SizedBox(height: 16.h),

          AppTextField(
            controller: _graceDays,
            label: 'مهلة دخول رأس المال (بالأيام)',
            keyboardType: TextInputType.number,
            validator: (value) => _whole(value, label: 'المهلة'),
          ),
          const _Hint(
            'خلال هذه الأيام من بداية الفترة يدخل المال ويعمل الفترة كاملة. '
            'صفر يعني حدّاً صارماً: ما بعد البداية ينتظر الفترة القادمة',
          ),
          SizedBox(height: 28.h),

          AppButton(
            label: 'احفظ',
            isLoading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}

/// One quiet line under a field, saying what the number actually does.
class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 6.h, right: 4.w, left: 4.w),
      child: Text(
        text,
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
