import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket_query.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_ticket.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_tickets_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// «التذاكر المرتبطة» — كلُّ تذكرةٍ تحمل هذه الطلبية، من الأنواع الثلاثة، كلٌّ بنوعه بجانبها،
/// المفتوحةُ أولاً والمغلقةُ معها. طلبُ المالك ٢٠٢٦-١٠-٢٨، كقسمها في بريمولا.
///
/// **يرسم رأسَه بنفسه**، لا عنوانَ البطاقة حوله: «إضافة تذكرة» في الرأس، وما يُنشأ بها يجب أن
/// يظهر تحته حين يعود صاحبه — فالزرّ والقائمةُ تحت مزوّدٍ واحد.
///
/// والصفُّ يفتح شاشةَ نوعه، وبعد العودة تُقرأ القائمةُ ثانيةً: ما أُجيب أو أُغلق هناك يغيّر حالته.
class OrderTicketsSection extends StatelessWidget {
  const OrderTicketsSection({required this.order, super.key});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderTicketsCubit>(
      create: (_) => sl<OrderTicketsCubit>()..load(order.id),
      child: _Tickets(order: order),
    );
  }
}

class _Tickets extends StatelessWidget {
  const _Tickets({required this.order});

  final Order order;

  /// النموذجُ نفسه الذي يفتحه «فتح تذكرة» من ذراع الطلبية، والطلبيةُ وعميلُها فيه.
  Future<void> _add(BuildContext context) => _thenReload(
    context,
    context.push<Object?>(
      Routes.newInternalTicket,
      extra: InternalTicketSubject(
        orderId: order.id,
        orderCode: order.code,
        customerId: order.customer?.id,
        customerName: order.customer?.name,
      ),
    ),
  );

  Future<void> _open(BuildContext context, String path) =>
      _thenReload(context, context.push<Object?>(path));

  Future<void> _thenReload(BuildContext context, Future<Object?> away) async {
    final cubit = context.read<OrderTicketsCubit>();
    await away;
    if (!cubit.isClosed) await cubit.reload();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'التذاكر المرتبطة',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => unawaited(_add(context)),
              icon: Icon(AppIcons.add, size: 20.r),
              label: const Text('إضافة تذكرة'),
            ),
          ],
        ),
        BlocBuilder<OrderTicketsCubit, OrderTicketsState>(
          builder: (context, state) => switch (state) {
            // صامتٌ وهو يُحمَّل: الصفحةُ كاملةٌ بدونه، وزرُّ الإضافة فوقه يعمل من الآن.
            OrderTicketsLoading() => const SizedBox.shrink(),
            OrderTicketsFailure() => Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => unawaited(context.read<OrderTicketsCubit>().reload()),
                icon: Icon(AppIcons.refresh, size: 18.r),
                label: const Text('تعذّر تحميل التذاكر — إعادة المحاولة'),
              ),
            ),
            OrderTicketsLoaded(:final tickets) when tickets.isEmpty => Padding(
              padding: EdgeInsets.only(top: 4.h, bottom: 4.h),
              child: Text(
                'لا توجد تذاكر مرتبطة بهذه الطلبية',
                style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            OrderTicketsLoaded(:final tickets) => Column(
              children: [
                for (final ticket in tickets)
                  _TicketRow(
                    ticket: ticket,
                    onTap: switch (_pathOf(ticket)) {
                      final path? => () => unawaited(_open(context, path)),
                      null => null,
                    },
                  ),
              ],
            ),
          },
        ),
      ],
    );
  }

  /// شاشةُ النوع. لا شيء لنوعٍ لا يعرفه هذا الإصدار: يُرسم ولا يُفتح.
  static String? _pathOf(OrderTicket ticket) => switch (ticket.kind) {
    OrderTicketKind.internal => Routes.internalTicket(ticket.id),
    OrderTicketKind.design => Routes.designTicket(ticket.id),
    OrderTicketKind.support => Routes.supportTicket(ticket.id),
    OrderTicketKind.unknown => null,
  };
}

/// صفٌّ واحد: الكودُ ونوعُه بجانبه، والعنوانُ تحتهما، والحالةُ بنقطتها في الطرف الآخر.
class _TicketRow extends StatelessWidget {
  const _TicketRow({required this.ticket, required this.onTap});

  final OrderTicket ticket;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    // **المفتوحةُ بلون التنبيه والمغلقةُ هادئة**: «قيد المعالجة» عملٌ لم ينتهِ بعد على هذه الطلبية،
    // وهو ما جاء القارئ ليراه. والنقطةُ ممتلئةٌ أو مفرّغة، فالفرقُ لا يحمله اللونُ وحده.
    final tone = ticket.isOpen ? scheme.warn : scheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: 56.h),
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          ticket.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      _KindChip(label: ticket.kindLabel),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    ticket.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              width: 8.r,
              height: 8.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ticket.isOpen ? tone : null,
                border: ticket.isOpen ? null : Border.all(color: tone, width: 1.5),
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              ticket.statusLabel,
              style: text.labelLarge?.copyWith(color: tone, fontWeight: FontWeight.w700),
            ),
            if (onTap != null) ...[
              SizedBox(width: 4.w),
              Icon(AppIcons.forward, size: 20.r, color: scheme.onSurfaceVariant),
            ],
          ],
        ),
      ),
    );
  }
}

/// «موظفين» / «تصميم» / «عميل» — بجانب الكود، كما طلبها المالك.
class _KindChip extends StatelessWidget {
  const _KindChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: context.textTheme.labelSmall?.copyWith(
          color: scheme.onSecondaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
