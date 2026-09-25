import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/theme/theme_mode_cubit.dart';
import 'package:dayaa_client/core/theme/theme_mode_sheet.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/widgets/menu_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «الإعدادات»: تفضيلات هذا الجهاز، تُفتح من «حسابي».
///
/// **صفٌّ واحد اليوم، وهذا مقصود.** «مظهر التطبيق» كان صفاً في «حسابي» نفسها، وانتقل إلى هنا حين
/// صار لـ«حسابي» صفٌّ اسمه «الإعدادات». والشاشة هي المكان الذي تنتظره البقية: تفضيلات الإشعارات
/// و«حذف الحساب» في `Docs/customer-app/FUTURE-FEATURES-PLAN.md` §٦.
///
/// **بلا Cubit خاص بها.** ما تعرضه هو [ThemeModeCubit]، وهو مفردٌ فوق الموجّه لأن المظهر ليس صفة
/// شاشة. يُقرأ بـ `bloc:` صريح كما في ورقة المظهر، لا من الشجرة.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 32.h),
          children: [
            BlocBuilder<ThemeModeCubit, ThemeMode>(
              bloc: sl<ThemeModeCubit>(),
              builder: (context, mode) => MenuCard(
                rows: [
                  MenuRow(
                    icon: AppIcons.appearance,
                    label: 'مظهر التطبيق',
                    // الصف يقول ما يلبسه التطبيق دون أن يُفتح، وهذا أغلب سبب لمسه: ليُعرف
                    // الجواب لا ليُغيَّر.
                    value: mode.label,
                    onTap: () => showThemeModeSheet(context).ignore(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
