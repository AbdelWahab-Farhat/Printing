import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/viewmodel/account_picker_cubit.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «الحساب» على نموذج دفع — أين نزل المال، أو من أين خرج.
///
/// **`AppDropdown` وأولُ صفوفه «تلقائي»** (RULES §٧: `placeholder` حين يكون «غير محدد» جواباً
/// حقيقياً): متروكاً، يضع الخادم المال في حساب صاحبه أو افتراضي الطريقة، و«تلقائي» يسمّي ذلك
/// الحساب كما سمّاه الخادم. القائمة تُسأل من الخادم بحسب الطريقة، فلا تُعرض الخزنة لحوالة، ولا
/// تُعرض عهدة النورس لمالٍ خارج (TREASURY-DESIGN §٥).
///
/// **والسؤال في Cubit** ([AccountPickerCubit]) لا هنا: يُعاد مع تغيّر الطريقة، ويُسقط جواباً
/// وصل بعد أن تغيّرت، وفشلُه يُرسم خطأً بزرّ «إعادة المحاولة» — والنموذج يبقى يُرسل بـ«تلقائي».
///
/// **ويتنحّى حين لا خزينة مسجّلة** — نسخةٌ لا تعرفها، أو اختبارُ نموذجٍ لا يخصّه الحساب.
class TreasuryAccountPicker extends StatelessWidget {
  const TreasuryAccountPicker({
    required this.method,
    required this.value,
    required this.onChanged,
    this.incoming = true,
    this.label,
    this.orderId,
    this.errorText,
    super.key,
  });

  /// قيمة الطريقة على السلك — `cash`، `bank_transfer`، `bank_card`، `libyana`.
  ///
  /// **فارغةٌ لنموذجٍ يسأل أيّ درجٍ دفع لا كيف** — مصروف الصندوق: يُعرض كل حسابٍ يُصرف منه.
  final String? method;
  final bool incoming;

  /// الطلبية التي المال لها — ما دامت تنتظر في مكتب استلام، «تلقائي» خزنةُ ذلك المكتب (§١٩).
  final int? orderId;

  /// الاسم يحمل المعنى بلا سطرٍ تحته: «استُلم في» للمال الداخل، و«دُفع من» للخارج.
  final String? label;

  /// الحساب المختار، أو null لـ«تلقائي».
  final int? value;
  final ValueChanged<int?> onChanged;

  /// رفضُ الخادم لهذا الحقل (`treasury_account_id` وأخواته).
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    if (!sl.isRegistered<GetAccountOptions>() || !sl.isRegistered<GetTreasuryAccounts>()) {
      return const SizedBox.shrink();
    }

    return BlocProvider(
      create: (_) => AccountPickerCubit(getOptions: sl(), getAccounts: sl())
        ..load(method: method, incoming: incoming, orderId: orderId),
      child: _Picker(
        method: method,
        incoming: incoming,
        orderId: orderId,
        label: label ?? (incoming ? 'استُلم في' : 'دُفع من'),
        value: value,
        onChanged: onChanged,
        errorText: errorText,
      ),
    );
  }
}

/// «تلقائي — مصرف علي»: ما سيختاره الخادم، باسمه حين يعرفه.
String automaticLabel(String? suggestedName) =>
    suggestedName == null ? 'تلقائي' : 'تلقائي — $suggestedName';

/// يرسم حالة السؤال، ويعيده حين يتغيّر — طريقةٌ أخرى، أو اتجاهٌ آخر، أو طلبيةٌ أخرى.
class _Picker extends StatefulWidget {
  const _Picker({
    required this.method,
    required this.incoming,
    required this.orderId,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.errorText,
  });

  final String? method;
  final bool incoming;
  final int? orderId;
  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;
  final String? errorText;

  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  @override
  void didUpdateWidget(_Picker old) {
    super.didUpdateWidget(old);

    if (old.method != widget.method ||
        old.incoming != widget.incoming ||
        old.orderId != widget.orderId) {
      unawaited(
        context.read<AccountPickerCubit>().load(
          method: widget.method,
          incoming: widget.incoming,
          orderId: widget.orderId,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountPickerCubit, AccountPickerState>(
      builder: (context, state) => switch (state) {
        // ما دام السؤال في الطريق: «تلقائي» وحده، معطّلاً — الحقل في مكانه، لا يقفز حين يصل.
        AccountPickerLoading() => _dropdown(const [], automatic: 'تلقائي', enabled: false),
        AccountPickerLoaded(:final options) => _dropdown(
          options.accounts,
          automatic: automaticLabel(options.suggestedName),
          suggestedId: options.suggestedId,
        ),
        AccountPickerFailed(:final failure) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _dropdown(const [], automatic: 'تلقائي', enabled: false, error: failure.message),
            SizedBox(height: 8.h),
            AppButton.tonal(
              label: 'إعادة المحاولة',
              icon: AppIcons.refresh,
              onPressed: context.read<AccountPickerCubit>().retry,
            ),
          ],
        ),
      },
    );
  }

  Widget _dropdown(
    List<AccountOption> accounts, {
    required String automatic,
    int? suggestedId,
    bool enabled = true,
    String? error,
  }) {
    // «تلقائي — X» هو الحساب X نفسه، فلا يُعرض X صفاً ثانياً تحته — ومن اختاره يرى «تلقائي».
    final rows = [
      for (final account in accounts)
        if (account.id != suggestedId) account,
    ];
    final chosen = rows.where((account) => account.id == widget.value).firstOrNull;

    return AppDropdown<AccountOption>(
      value: chosen,
      items: rows,
      keyOf: (account) => account.id,
      labelOf: (account) => account.name,
      label: widget.label,
      prefixIcon: AppIcons.treasury,
      placeholder: automatic,
      enabled: enabled,
      errorText: error ?? widget.errorText,
      onChanged: (account) => widget.onChanged(account?.id),
    );
  }
}
