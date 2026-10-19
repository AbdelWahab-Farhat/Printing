import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/fixed_point.dart';
import 'package:dayaa_client/features/wallet/presentation/viewmodel/wallet_balance_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// رصيد «محفظتي» في حبّةٍ خفيفة بطرف الشريط العلوي: أيقونة المحفظة و«200 د.ل»، وتفتح «محفظتي»
/// بلمسة (طلب المستخدم، 2026-10-16).
///
/// **خفيفةٌ بلون التبويب النشط في الشريط السفلي**: البرتقالي نفسه بشفافيته، فتُقرأ من العلامة
/// لا زرّاً يُلحّ. والرقم بلون النص لا بالبرتقالي: رقمٌ برتقالي على برتقاليٍّ فاتح لا يُقرأ.
///
/// **تُرسم دائماً، و«…» مكان الرقم حتى يصل**: هي في الطرف، ولو ظهرت متأخرةً لدفعت الدعم والسلة
/// إلى الداخل.
///
/// **تسأل عن الرصيد حين تُبنى وحين يعود التطبيق إلى الواجهة.** تُبنى مع الـ shell، أي مع كل دخول —
/// فتبدأ من لا شيء ([WalletBalanceCubit.load]). والعودة لأن الرصيد يتغيّر والتطبيق مغلق: شحنٌ
/// نقديٌّ في المحل، أو ردٌّ من طلبية. **ولا تُترك العودة لـ`BadgeRefresher`**: ذاك ملفوفٌ حول
/// الموجّه كله، فيسأل وشاشة الدخول معروضة؛ وهذه لا تعيش إلا والعميل داخل.
class WalletBalanceChip extends StatefulWidget {
  const WalletBalanceChip({super.key});

  @override
  State<WalletBalanceChip> createState() => _WalletBalanceChipState();
}

class _WalletBalanceChipState extends State<WalletBalanceChip> with WidgetsBindingObserver {
  final _balance = sl<WalletBalanceCubit>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _balance.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // `resumed` وحده، كـ`BadgeRefresher`: `inactive` يأتي مع نصف سحبةٍ لستارة الإشعارات.
    if (state == AppLifecycleState.resumed) _balance.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return BlocBuilder<WalletBalanceCubit, String?>(
      bloc: _balance,
      builder: (context, balance) => Tooltip(
        message: 'محفظتي',
        child: Material(
          color: scheme.primary.withValues(alpha: 0.12),
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push(Routes.wallet),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(10.w, 6.h, 12.w, 6.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.wallet, size: 18.sp, color: scheme.primary),
                  SizedBox(width: 6.w),
                  Text(
                    '${balance?.asMoney ?? '…'} د.ل',
                    style: context.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
