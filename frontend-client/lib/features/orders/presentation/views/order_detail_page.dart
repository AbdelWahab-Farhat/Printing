import 'dart:async';

import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/bidi.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_speed_dial.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/order_detail_cubit.dart';
import 'package:dayaa_client/features/orders/presentation/widgets/order_destination_card.dart';
import 'package:dayaa_client/features/orders/presentation/widgets/order_lines_card.dart';
import 'package:dayaa_client/features/orders/presentation/widgets/order_money_card.dart';
import 'package:dayaa_client/features/orders/presentation/widgets/order_stage_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// One order: where it is, what is in it, and what it costs.
///
/// **Every number here is the server's.** Nothing on this screen adds a line total to a delivery
/// price — what is owed is the shop's arithmetic, and a second implementation of it in the app
/// would eventually disagree with the invoice the customer is holding.
class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({required this.orderId, super.key});

  final int orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderDetailCubit>(
      create: (_) => sl<OrderDetailCubit>(param1: orderId)..load(),
      child: const _OrderDetailView(),
    );
  }
}

class _OrderDetailView extends StatelessWidget {
  const _OrderDetailView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OrderDetailCubit>();

    return BlocBuilder<OrderDetailCubit, OrderDetailState>(
      builder: (context, state) => switch (state) {
        OrderDetailLoading() => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),

        OrderDetailFailure(:final failure) => Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(failure.message, textAlign: TextAlign.center),
                  SizedBox(height: 16.h),
                  AppButton.outlined(
                    label: 'أعد المحاولة',
                    onPressed: cubit.load,
                  ),
                ],
              ),
            ),
          ),
        ),

        OrderDetailLoaded(:final order) => _Loaded(order: order, onRefresh: cubit.refresh),
      },
    );
  }
}

/// الطلبية على شكل «أ · بطاقة الحالة» الذي اختاره صاحب العمل من ثلاثة اتجاهات (٢٠٢٦-٠٩-٢٥):
/// بطاقةٌ بلون المرحلة فيها الخطوات الخمس، ثم المال، ثم البنود بصورها، ثم التسليم.
///
/// **والسؤال زرٌّ عائم**، بطلبه: كان زراً بعرض الشاشة في آخرها («لديك سؤال عن هذه الطلبية؟»).
/// العائم في مكانه أينما وصل التمرير، ولا يأخذ من الصفحة سطراً.
class _Loaded extends StatelessWidget {
  const _Loaded({required this.order, required this.onRefresh});

  final CustomerOrderDetail order;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Scaffold(
      appBar: AppBar(
        // **الرمز معزولاً من اليسار**، وإلا نزلت «#» على يمين الرقم: «1304#».
        title: Text(
          'طلبية ${'#${order.code}'.ltrIsolated}',
          style: context.textTheme.titleLarge?.copyWith(
            fontSize: 20.sp,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
        ),
        actions: [
          // الرقم هو ما يُقرأ على الهاتف حين يُسأل عن الطلبية، فيُنسخ بلمسة.
          IconButton(
            tooltip: 'نسخ رقم الطلبية',
            icon: Icon(AppIcons.copy, size: 22.sp, color: scheme.onSurfaceVariant),
            onPressed: () {
              unawaited(Clipboard.setData(ClipboardData(text: order.code)));
              context.showSuccess('تم نسخ رقم الطلبية');
            },
          ),
          SizedBox(width: 4.w),
        ],
      ),
      floatingActionButtonLocation: AppSpeedDial.location,
      floatingActionButton: AppSpeedDial(
        actions: [
          AppAction(
            label: 'اسأل عن الطلبية',
            icon: AppIcons.comments,
            tone: AppActionTone.primary,
            // الخيط يُفتح والطلبية مرفقةٌ به، و`push` لا `go`: إغلاقه يعود إلى هنا.
            onTap: (context) => context.push(Routes.supportAbout(order.id)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          // من تحت: ما يرفع آخر بطاقةٍ فوق الزرّ العائم حين يصل التمرير إلى آخرها.
          padding: EdgeInsets.fromLTRB(
            16.w,
            8.h,
            16.w,
            104.h + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            OrderStageCard(order: order),
            SizedBox(height: 24.h),
            OrderMoneyCard(order: order),
            SizedBox(height: 24.h),
            _SectionTitle('المنتجات', count: order.items.length),
            SizedBox(height: 10.h),
            OrderLinesCard(lines: order.items),
            SizedBox(height: 24.h),
            const _SectionTitle('التسليم'),
            SizedBox(height: 10.h),
            OrderDestinationCard(order: order),
          ],
        ),
      ),
    );
  }
}

/// عنوان قسم، وبجانبه عدد ما فيه حين يُعدّ.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.count});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Row(
      children: [
        Text(
          title,
          style: context.textTheme.titleMedium?.copyWith(
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            height: 1.4,
          ),
        ),
        if (count case final count?) ...[
          SizedBox(width: 8.w),
          Container(
            height: 22.h,
            constraints: BoxConstraints(minWidth: 22.w),
            padding: EdgeInsets.symmetric(horizontal: 7.w),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(11.r),
            ),
            child: Text(
              '$count',
              style: context.textTheme.labelMedium?.copyWith(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w800,
                height: 1.2,
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
