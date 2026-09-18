import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/theme/app_tones.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/bidi.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/dates.dart';
import 'package:dayaa_client/core/utils/fixed_point.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:dayaa_client/features/notifications/presentation/views/notifications_button.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/order_detail_cubit.dart';
import 'package:dayaa_client/features/orders/presentation/views/stage_pill.dart';
import 'package:flutter/material.dart';
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
                  OutlinedButton(
                    onPressed: cubit.load,
                    child: const Text('أعد المحاولة'),
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

class _Loaded extends StatelessWidget {
  const _Loaded({required this.order, required this.onRefresh});

  final CustomerOrderDetail order;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('طلبية #${order.code}'),
        actions: const [NotificationsButton()],
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
          children: [
            // **The stage, and what it means, at the top.** «بانتظار المراجعة» is the one that
            // has to say what it means: an order from the app is not accepted by arriving — a
            // person reads it first — and this screen must not congratulate the customer on
            // something the shop has not agreed to. The sentence is the server's `stage_hint`,
            // the same one the list card draws.
            _StageHeader(order: order),

            if (order.timeline.isNotEmpty) ...[
              SizedBox(height: 22.h),
              const _SectionTitle('مسار الطلبية'),
              SizedBox(height: 12.h),
              _Timeline(entries: order.timeline),
            ],

            SizedBox(height: 22.h),
            const _SectionTitle('المنتجات'),
            SizedBox(height: 10.h),
            AppCard(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  for (final line in order.items) _LineRow(line: line),
                  _Money(order: order),
                ],
              ),
            ),

            SizedBox(height: 22.h),
            const _SectionTitle('الوجهة'),
            SizedBox(height: 10.h),
            AppCard(padding: EdgeInsets.all(16.w), child: _Destination(order: order)),

            SizedBox(height: 24.h),
            OutlinedButton.icon(
              // The thread opens with the order already attached — a customer who has a
              // question about *this* order should not have to describe which one it is.
              // `push`: the thread opens over this order, and closing it comes straight back
              // here. `go` would replace the stack and strand the customer on a support screen
              // with no way back to the order they were asking about.
              onPressed: () => context.push(Routes.supportAbout(order.id)),
              icon: Icon(AppIcons.comments, size: 18.sp),
              label: const Text('لديك سؤال عن هذه الطلبية؟'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Where the order is, and what that means, as one card.
///
/// **Both lines are the server's.** `stage_label` names the stage and `stage_hint` says what is
/// happening — see `CustomerOrderStage`. The only decision taken here is the orange hairline,
/// which goes on the two stages that are about the customer: waiting to be reviewed, and being
/// designed.
class _StageHeader extends StatelessWidget {
  const _StageHeader({required this.order});

  final CustomerOrderDetail order;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tone = stageTone(scheme, order.stage);
    final wantsYou =
        order.stage == OrderStage.underReview || order.stage == OrderStage.designing;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: tone.background,
                borderRadius: BorderRadius.circular(999.r),
              ),
              child: Text(
                order.stageLabel,
                style: context.textTheme.labelMedium?.copyWith(
                  color: tone.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Spacer(),
            if (order.placedAt case final placedAt?)
              Text(
                placedAt.dayLabel,
                style: context.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        if (order.stageHint case final hint?) ...[
          SizedBox(height: 10.h),
          Text(
            hint,
            style: context.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],

        // **Why, in the shop's own words.** The stage's hint says what happened and where to
        // take it; this is the sentence somebody wrote about *this* order, and it is the only
        // reason string the server sends to this app — an order's `cancellation_reason` is
        // written for the accountant and never leaves the staff side.
        //
        // Set apart rather than run on after the hint: it is a different voice, and a refusal
        // read as one continuous paragraph loses which half is the shop speaking.
        if (order.rejectionReason case final reason?) ...[
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              reason,
              style: context.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
        ],
      ],
    );

    return wantsYou
        ? AppCard.accent(padding: EdgeInsets.all(16.w), child: body)
        : AppCard(padding: EdgeInsets.all(16.w), child: body);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
  );
}

/// **The stages reached, not the transitions recorded.** The workshop writes a row for every
/// move and five of them collapse into «قيد التجهيز» — the server folds them and keeps the
/// moment each stage was first reached, so this draws one tick per thing that happened.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.entries});

  final List<OrderTimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      children: [
        for (var index = 0; index < entries.length; index++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    // **The last entry is where the order is now**, and the design rings it
                    // rather than filling it: a hollow orange circle reads as «هنا», a filled
                    // green one as «تمّ». Everything above it has happened.
                    _TimelineDot(isCurrent: index == entries.length - 1),
                    if (index != entries.length - 1)
                      Expanded(
                        child: Container(width: 2.w, color: scheme.paid),
                      ),
                  ],
                ),
                SizedBox(width: 13.w),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 18.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entries[index].stageLabel,
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: index == entries.length - 1 ? scheme.primary : null,
                          ),
                        ),
                        if (entries[index].reachedAt case final at?)
                          Text(
                            at.stampLabel,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A reached step, or the one the order is standing on.
class _TimelineDot extends StatelessWidget {
  const _TimelineDot({required this.isCurrent});

  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: 22.w,
      height: 22.w,
      margin: EdgeInsets.only(top: 2.h),
      decoration: BoxDecoration(
        color: isCurrent ? scheme.surface : scheme.paid,
        shape: BoxShape.circle,
        border: isCurrent ? Border.all(color: scheme.primary, width: 3.w) : null,
      ),
      child: isCurrent
          ? null
          : Icon(AppIcons.check, size: 13.sp, color: scheme.onPaidContainer),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line});

  final OrderLine line;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.productName.bidiSafe,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  [
                    ?line.variantLabel,
                    // **The quantity is always known; the price may not be.** A line the shop
                    // has not quoted yet says so in place of the «× السعر» half rather than
                    // dropping the row — the customer ordered it and is entitled to see it.
                    if (line.unitPrice case final price?)
                      '${line.quantity.asQuantity} × ${price.asMoney} د.ل'
                    else
                      '${line.quantity.asQuantity} · $awaitingQuoteLabel',
                  ].join(' · ').bidiSafe,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            line.lineTotal?.asMoney ?? '—',
            style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _Destination extends StatelessWidget {
  const _Destination({required this.order});

  final CustomerOrderDetail order;

  @override
  Widget build(BuildContext context) {
    // **The snapshot the order carries, not a live lookup** — a renamed district must not
    // rewrite where an old order said it was headed.
    final where = [?order.cityName, ?order.regionName, ?order.addressDetails].join(' — ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (order.fulfilmentTypeLabel case final label?)
          Text(label, style: context.textTheme.bodySmall),
        if (where.isNotEmpty) Text(where, style: context.textTheme.bodyMedium),
        if (order.recipientName case final name?)
          Text(
            [name, ?order.recipientPhone].join(' · '),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _Money extends StatelessWidget {
  const _Money({required this.order});

  final CustomerOrderDetail order;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      children: [
        Divider(height: 8.h, color: scheme.outlineVariant),
        SizedBox(height: 10.h),
        if (order.deliveryPrice case final amount? when amount._isSomething)
          _MoneyRow('التوصيل', amount),
        if (order.designFee case final amount? when amount._isSomething)
          _MoneyRow('التصميم', amount),
        if (order.discount case final amount? when amount._isSomething)
          _MoneyRow('الخصم', amount),
        // **Green, and the design writes it as a subtraction.** What has already been handed
        // over is the one line on this card that is good news.
        if (order.paidAmount case final amount? when amount._isSomething)
          _MoneyRow('المدفوع', amount, color: scheme.paid),
        Divider(height: 20.h, color: scheme.outlineVariant),

        // **The balance is the server's figure**, not `total - paid` worked out here — a second
        // implementation of the shop's arithmetic eventually disagrees with the invoice the
        // customer is holding.
        //
        // And it is drawn in `primary`, not `error`: money still owed on an order that is going
        // fine is not a fault, and red says something went wrong.
        // **A word where the figure would be, while the shop has not priced it.** Showing the
        // server's stored total here would be showing the sum of the priced lines only — a
        // smaller number than the customer will be asked for, printed under the word
        // «الإجمالي» on their own screen.
        _Total(
          label: order.isAwaitingQuote
              ? 'الإجمالي'
              : order.balance == null
              ? 'الإجمالي'
              : 'المتبقّي',
          amount: order.isAwaitingQuote ? null : (order.balance ?? order.total),
        ),
      ],
    );
  }
}

/// The one number the customer came for.
class _Total extends StatelessWidget {
  const _Total({required this.label, required this.amount});

  final String label;

  /// Null while the shop has not priced every line — the phrase is drawn in place of the
  /// figure, and the «د.ل» beside it is dropped with it. A currency suffix on a sentence reads
  /// as a number that failed to render.
  final String? amount;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          label,
          style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        Text(
          amount?.asMoney ?? awaitingQuoteLabel,
          style: amount == null
              ? context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                )
              : context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: scheme.primary,
                ),
        ),
        if (amount != null) ...[
          SizedBox(width: 4.w),
          Text(
            'د.ل',
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow(this.label, this.amount, {this.color});

  final String label;
  final String amount;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = context.textTheme.bodyMedium?.copyWith(color: color);

    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text('${amount.asMoney} د.ل', style: style),
        ],
      ),
    );
  }
}

extension on String {
  /// Whether an amount is worth a row of its own.
  ///
  /// **The server has no null for «لا خصم».** `discount`, `design_fee` and `delivery_price` are
  /// decimal columns that are never null, so they arrive as `'0.00'` and every order draws
  /// «الخصم 0.00 د.ل» — a line whose only content is that the line exists. The design draws
  /// none of them.
  ///
  /// Compared as thousandths rather than against the string `'0.00'`: the same nothing arrives
  /// as `'0'`, `'0.00'` and `'0.000'` depending on which column it came from.
  bool get _isSomething => thousandths(this) != BigInt.zero;
}
