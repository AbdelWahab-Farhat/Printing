import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_snackbar.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/core/widgets/dismiss_keyboard.dart';
import 'package:dayaa/features/investment_settings/models/investment_settings.dart';
import 'package:dayaa/features/investment_settings/presentation/viewmodel/investment_settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// إعدادات الاستثمار — القواعد الأربع التي يحكم بها الصندوقُ نفسَه.
///
/// **لا سطرَ شرحٍ تحت أيّ حقل.** التسميةُ تحمل معناها ووحدتَها، والقاعدةَ الوحيدة التي قد
/// تُرفَض — أن تكون مدةُ التسوية مضاعفاً للفترة — يقولها الخادمُ في رسالته حين تُرفَض فعلاً،
/// لا فقرةٌ تُقرأ كلَّ مرّة وتُنسى.
///
/// وما بعد الحفظ يُعرَض من **جواب الخادم** لا من الحقول: من صحّح رقماً يرى ما صار عليه الأمر.
class InvestmentSettingsPage extends StatelessWidget {
  const InvestmentSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InvestmentSettingsCubit(getSettings: sl(), updateSettings: sl())..load(),
      child: const _InvestmentSettingsView(),
    );
  }
}

class _InvestmentSettingsView extends StatelessWidget {
  const _InvestmentSettingsView();

  @override
  Widget build(BuildContext context) {
    return DismissKeyboard(
      child: Scaffold(
        appBar: AppBar(title: const Text('إعدادات الاستثمار')),
        body: BlocBuilder<InvestmentSettingsCubit, InvestmentSettingsState>(
          builder: (context, state) => switch (state) {
            InvestmentSettingsLoading() => const Center(child: CircularProgressIndicator()),
            InvestmentSettingsFailure(:final failure) => _Failure(message: failure.message),
            InvestmentSettingsLoaded(:final settings) => _Form(settings: settings),
          },
        ),
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center, style: context.textTheme.bodyMedium),
            SizedBox(height: 16.h),
            AppButton(
              label: 'إعادة المحاولة',
              onPressed: () => context.read<InvestmentSettingsCubit>().load(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Form extends StatefulWidget {
  const _Form({required this.settings});

  final InvestmentSettings settings;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late final TextEditingController _share;
  late final TextEditingController _period;
  late final TextEditingController _window;
  late final TextEditingController _settlement;
  late final TextEditingController _lock;
  late final TextEditingController _plainPrice;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final s = widget.settings;
    _share = TextEditingController(text: s.investorProfitSharePercent);
    _period = TextEditingController(text: '${s.periodMonths}');
    _window = TextEditingController(text: '${s.subscriptionWindowDays}');
    _settlement = TextEditingController(text: '${s.settlementMonths}');
    _lock = TextEditingController(text: '${s.capitalLockMonths}');
    // أصفارُ الحشو مقصوصة: الخادمُ يخزّنه بثلاث خاناتٍ لأنه مال، ومن يقرأ مربعاً يريد «32».
    _plainPrice = TextEditingController(
      text: s.defaultPlainSalePrice == null ? '' : trimDecimals(s.defaultPlainSalePrice!),
    );
  }

  @override
  void dispose() {
    for (final controller in [_share, _period, _window, _settlement, _lock, _plainPrice]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final failure = await context.read<InvestmentSettingsCubit>().save(
      InvestmentSettings(
        investorProfitSharePercent: _share.text.trim(),
        periodMonths: int.tryParse(_period.text.trim()) ?? widget.settings.periodMonths,
        subscriptionWindowDays:
            int.tryParse(_window.text.trim()) ?? widget.settings.subscriptionWindowDays,
        settlementMonths:
            int.tryParse(_settlement.text.trim()) ?? widget.settings.settlementMonths,
        capitalLockMonths: int.tryParse(_lock.text.trim()) ?? widget.settings.capitalLockMonths,
        // **فارغٌ يعني null لا ''**: الخادمُ يقرأ الأولى «ارفع الافتراض فتُفتح الحقولُ فارغةً»،
        // والثانيةَ رقماً لا يُفهم فيردّها.
        defaultPlainSalePrice: _plainPrice.text.trim().isEmpty ? null : _plainPrice.text.trim(),
      ),
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (failure == null) {
      await showCustomSnackBar(
        context: context,
        title: 'حُفظت — تسري على ما يُفتح بعدها ولا تمسّ فترةً قائمة',
        type: SnackType.success,
      );

      return;
    }

    await showCustomSnackBar(
      context: context,
      title: failure.message,
      type: SnackType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
      children: [
        // حقلان في الصفّ. والنصيبُ يُقسَم على قدر التسمية لا بالتساوي: «حصة المستثمرين من
        // الربح» تسميةٌ طويلة، ولو أخذت نصفاً كنصفِ جارتها القصيرة لقُصَّت بنقاطٍ ثلاث —
        // والتسميةُ هنا هي الشرح كلّه، فلا يجوز أن يُقصّ منها حرف.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: AppTextField(
                controller: _share,
                label: 'حصة المستثمرين من الربح (%)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              flex: 2,
              child: _Months(controller: _period, label: 'مدة الفترة (شهر)'),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _Months(controller: _window, label: 'نافذة الاكتتاب (يوم)')),
            SizedBox(width: 12.w),
            Expanded(child: _Months(controller: _settlement, label: 'مدة التسوية (شهر)')),
          ],
        ),
        SizedBox(height: 16.h),
        // وحدَه في صفّه: تسميتُه أطولُ الخمس، ونصفُ الشاشة لا يسعها.
        _Months(controller: _lock, label: 'حجز رأس المال بعد إيداعه (شهر)'),
        SizedBox(height: 16.h),
        // **وحدَه أيضاً، وهو الوحيد الذي يُترك فارغاً عن قصد.** فارغٌ يعني «بلا افتراض»: تُفتح
        // حقولُ التمويل خاليةً فتمشي البضاعةُ إلى المطبعة بالتكلفة، ويعود ربحُ المستثمر إلى
        // بيع الطلبية. والوحدةُ في التسمية لأن الرقمَ يُضرب في وزن الرفّ.
        AppTextField(
          controller: _plainPrice,
          label: 'سعر السادة الافتراضي للكيلو (د.ل)',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹.,]')),
          ],
        ),
        SizedBox(height: 32.h),
        AppButton(label: 'حفظ', isLoading: _saving, onPressed: _saving ? null : _save),
      ],
    );
  }
}

/// حقلُ عددٍ صحيح — أرقامٌ لا غير، فلا فاصلةَ عشرية في شهرٍ ولا يوم.
class _Months extends StatelessWidget {
  const _Months({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );
  }
}
