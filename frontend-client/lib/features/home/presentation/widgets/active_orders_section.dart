import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:dayaa_client/features/home/presentation/viewmodel/active_orders_cubit.dart';
import 'package:dayaa_client/features/home/presentation/widgets/active_order_card.dart';
import 'package:dayaa_client/features/home/presentation/widgets/home_section_header.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// «طلبياتي الجارية»: ما في طريقه إلى العميل، وأين وصل.
///
/// **أول ما يفتح له العميل التطبيق بعد أن يطلب.** بطاقةٌ مختصرة ([ActiveOrderCard]) وتحتها شريط
/// الخطوات الخمس. وطلبياتٌ عدة تحت بعضها، كلٌّ منها بعرض الشاشة.
class ActiveOrdersSection extends StatelessWidget {
  const ActiveOrdersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // «طلباتي» تبويب، فـ`go` تنقل الشريط إليه ولا تكدّس نسخةً منه فوق الرئيسية.
        HomeSectionHeader(
          title: 'طلبياتي الجارية',
          onSeeAll: () => context.go(Routes.orders),
        ),
        SizedBox(height: 12.h),
        BlocBuilder<ActiveOrdersCubit, ActiveOrdersState>(
          builder: (context, state) => switch (state) {
            ActiveOrdersLoading() => const _CardPlaceholder(),
            ActiveOrdersFailure(:final failure) => _Retry(
              message: failure.message,
              onRetry: () => context.read<ActiveOrdersCubit>().load(),
            ),
            ActiveOrdersLoaded(:final orders) when orders.isEmpty => const _NothingOnItsWay(),
            ActiveOrdersLoaded(:final orders) => _OrderCards(orders: orders),
          },
        ),
      ],
    );
  }
}

/// البطاقات تحت بعضها، كلٌّ منها بعرض الشاشة.
///
/// **كانت صفّاً يُمرَّر أفقياً وحافة التالية ظاهرة.** فطلب المستخدم أن تكون تحت بعضها
/// (2026-09-25): البطاقة المقطوعة لا تُقرأ، والرئيسية لا تحمل تحت القسم شيئاً يدفعه الطول.
class _OrderCards extends StatelessWidget {
  const _OrderCards({required this.orders});

  final List<CustomerOrder> orders;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, order) in orders.indexed) ...[
            if (index > 0) SizedBox(height: 12.h),
            ActiveOrderCard(order: order),
          ],
        ],
      ),
    );
  }
}

/// لا شيء في الطريق: طريقٌ إلى طلب أكياس مكان البطاقات، لا قسمٌ فارغ.
class _NothingOnItsWay extends StatelessWidget {
  const _NothingOnItsWay();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: AppCard(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(AppIcons.orders, size: 22.sp, color: scheme.onSurfaceVariant),
                SizedBox(width: 10.w),
                Text(
                  'لا طلبيات جارية',
                  style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            // «المنتجات» تبويب، فـ`go` لا `push`، كرابط «عرض الكل» فوقه.
            AppButton(
              label: 'اطلب أكياسك',
              icon: AppIcons.products,
              onPressed: () => context.go(Routes.products),
            ),
          ],
        ),
      ),
    );
  }
}

/// مكان البطاقة محجوزاً بمقاسها أثناء التحميل الأول، كي لا يقفز ما تحتها حين تصل.
class _CardPlaceholder extends StatelessWidget {
  const _CardPlaceholder();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        height: 136.h,
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: scheme.outlineVariant),
        ),
      ),
    );
  }
}

/// طلبياتٌ لم تُحمَّل: رسالة الخادم كما هي، وزرٌّ يسأله مرةً أخرى.
///
/// **هنا لا يغيب القسم كما يغيب صفّ المنتجات.** من فتح التطبيق ليعرف أين طلبيته، فوجد مكانها
/// فارغاً، سيظنّ أنه لا طلبية له.
class _Retry extends StatelessWidget {
  const _Retry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: AppCard(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center, style: context.textTheme.bodyMedium),
            SizedBox(height: 14.h),
            AppButton.outlined(label: 'أعد المحاولة', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
