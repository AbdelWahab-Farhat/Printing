import 'dart:async';

import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/router/pop_result.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/card_pressable.dart';
import 'package:dayaa/features/employee_wallet/presentation/viewmodel/my_wallet_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// مدخل «محفظتي»: سطرٌ بسيط يُضغط — طلب صاحب العمل ٢٠٢٦-١١-٠٦، والخيار «أ» في الشاشتين.
///
/// [MyWalletRow.new] داخل بطاقة الموظف على الرئيسية، و[MyWalletRow.strip] **السطر نفسه** في بطاقته
/// فوق طابور المصمم، لأن من لا يقرأ الطلبيات لا يصل إلى الرئيسية أصلاً.
///
/// **يقرأ [MyWalletCubit] من فوقه**: تملكه الشاشة، فسحبُ التحديث يعيد قراءته معها. وفشلُ قراءة الرصيد
/// لا يُسقط شيئاً: يبقى السطر بلا رقم، ويفتح «محفظتي» وفيها الرسالة وإعادة المحاولة.
class MyWalletRow extends StatelessWidget {
  const MyWalletRow({super.key}) : _isStrip = false;

  const MyWalletRow.strip({super.key}) : _isStrip = true;

  final bool _isStrip;

  Future<void> _open(BuildContext context) async {
    final cubit = context.read<MyWalletCubit>();
    final balance = await context.pushForResult<String>(Routes.myWallet);

    if (balance != null) cubit.show(balance);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    // حبرُ بطاقة الموظف: البطاقةُ تدرّجُ العلامة في الوضعين، فما عليها يُرسم من `onPrimary`.
    final ink = scheme.onPrimary;

    // زرٌّ واحد لقارئ الشاشة: يقرأ الاسم والرقم معاً، ويبقى الضغط له.
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: CardPressable(
          onTap: () => unawaited(_open(context)),
          child: Container(
            // حدٌّ أدنى لا ارتفاعٌ ثابت: خطٌّ مكبَّر في إعدادات الهاتف لا يُقصّ.
            constraints: BoxConstraints(minHeight: _isStrip ? 52.h : 48.h),
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: _isStrip ? 16.w : 12.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_isStrip ? 16.r : 14.r),
              color: _isStrip ? null : ink.withValues(alpha: 0.10),
              gradient: _isStrip
                  ? LinearGradient(
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
                      colors: [scheme.primary, scheme.tertiary],
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(AppIcons.wallet, size: 20.sp, color: ink),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'محفظتي',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                BlocBuilder<MyWalletCubit, MyWalletState>(
                  builder: (context, state) => switch (state) {
                    MyWalletLoaded(:final balance) => Padding(
                      padding: EdgeInsetsDirectional.only(start: 10.w),
                      child: Text(
                        '${balance.grouped} د.ل',
                        // الرقمُ يُقرأ من اليسار ولو داخل بطاقةٍ من اليمين.
                        textDirection: TextDirection.ltr,
                        style: context.textTheme.titleMedium?.copyWith(
                          color: ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _ => const SizedBox.shrink(),
                  },
                ),
                SizedBox(width: 10.w),
                Icon(AppIcons.forward, size: 18.sp, color: ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
