import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/theme/app_tones.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/dates.dart';
import 'package:dayaa_client/core/utils/fixed_point.dart';
import 'package:dayaa_client/core/widgets/filter_option_chip.dart';
import 'package:dayaa_client/core/widgets/paged_list_view.dart';
import 'package:dayaa_client/features/auth/models/customer_account.dart';
import 'package:dayaa_client/features/auth/usecases/get_current_customer.dart';
import 'package:dayaa_client/features/wallet/models/wallet_models.dart';
import 'package:dayaa_client/features/wallet/presentation/viewmodel/wallet_entries_cubit.dart';
import 'package:dayaa_client/features/wallet/presentation/views/top_up_sheet.dart';
import 'package:dayaa_client/features/wallet/usecases/top_up_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// «محفظتي»: الرصيد، وكل ما دخلها وخرج منها. Docs/payments/CUSTOMER-WALLET.md.
///
/// **على شكل محفظة بريمولا** (طلب صاحب العمل ٢٠٢٦-١٠-١١)، بلون ديّا: بطاقةٌ متدرّجة باسم الزبون
/// ورمزه ورصيده، وزرّ «شحن» زجاجيّ عليها، ثم المعاملات بطاقاتٍ تقول «وارد» أو «صادر».
///
/// **تُشحن ولا يُسحب منها**، وتُدفع منها الطلبيات من شاشة الطلبية. زرّ «شحن» يغيب ما دام الشحن
/// الإلكتروني مطفأً — فلا زرّ لا يعمل.
class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WalletEntriesCubit>(
      create: (_) => sl<WalletEntriesCubit>()..load(),
      child: const _WalletView(),
    );
  }
}

class _WalletView extends StatelessWidget {
  const _WalletView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WalletEntriesCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('محفظتي')),
      body: BlocBuilder<WalletEntriesCubit, WalletEntriesState>(
        builder: (context, state) => Column(
          children: [
            SizedBox(height: 12.h),
            _WalletCard(balance: cubit.balance),
            SizedBox(height: 16.h),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  for (final filter in MyWalletFilter.values) ...[
                    if (filter != MyWalletFilter.values.first) SizedBox(width: 8.w),
                    FilterOptionChip(
                      label: filter.label,
                      isSelected: cubit.filter == filter,
                      onTap: () => unawaited(cubit.narrowTo(filter)),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: PagedListView<MyWalletEntry>(
                state: state,
                emptyMessage: cubit.filter == MyWalletFilter.all
                    ? 'لا توجد معاملات حالياً — تظهر هنا عند إجرائها'
                    : 'لا معاملات من هذا النوع',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                skeletonHeight: 120.h,
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                separatorBuilder: (context, index) => SizedBox(height: 12.h),
                itemBuilder: (context, entry, index) => _EntryCard(
                  key: ValueKey(entry.id),
                  entry: entry,
                  onOpenOrder: switch (entry.orderId) {
                    final orderId? => () => context.push(Routes.order(orderId)),
                    null => null,
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── البطاقة ──────────────────────────────────────────────────────────────────────────────

/// بطاقة المحفظة على نسق بريمولا (`wallet_card_section.dart`): تدرّجٌ بلون العلامة، ووهجٌ في
/// الزاوية، والاسم والرمز، والرصيد بحبّة «د.ل»، وزرّ «شحن» زجاجيّ، وأربعة خطوطٍ للزينة.
///
/// تقرأ صاحبها وإن كان الشحن مفعّلاً بنفسها، بلا Cubit — كـ«حسابي».
class _WalletCard extends StatefulWidget {
  const _WalletCard({required this.balance});

  /// null حتى تصل أول صفحة.
  final String? balance;

  @override
  State<_WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<_WalletCard> {
  CustomerAccount? _customer;
  bool _canTopUp = false;

  @override
  void initState() {
    super.initState();
    unawaited(_read());
  }

  Future<void> _read() async {
    if (sl.isRegistered<GetCurrentCustomer>()) {
      final customer = await sl<GetCurrentCustomer>()();

      if (!mounted) return;

      customer.fold((_) {}, (c) => setState(() => _customer = c));
    }

    if (!sl.isRegistered<GetTopUpMethods>()) return;

    final methods = await sl<GetTopUpMethods>()();

    if (!mounted) return;

    methods.fold((_) {}, (m) => setState(() => _canTopUp = m.enabled));
  }

  Future<void> _topUp() async {
    final cubit = context.read<WalletEntriesCubit>();
    final toppedUp = await showTopUpSheet(context, args: TopUpArgs(phone: _customer?.phone));

    if (toppedUp == true) await cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final ink = scheme.onPrimary;
    final customer = _customer;
    final balance = widget.balance;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      height: 0.24.sh,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: ink.withValues(alpha: .10)),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [scheme.primary, scheme.primaryDeep, scheme.primary.withValues(alpha: .85)],
        ),
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            end: -60.w,
            top: -40.h,
            child: Container(
              width: 180.w,
              height: 180.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [ink.withValues(alpha: .18), ink.withValues(alpha: 0)]),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        customer == null
                            ? 'محفظتي'
                            : [customer.name, ?customer.code].join(' - '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleLarge?.copyWith(
                          color: ink,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .2,
                        ),
                      ),
                    ),
                    // الشعار مكتوباً كما في `BrandMark` — كلُّه أبيض هنا: «X» البرتقالية لا تُرى على
                    // بطاقةٍ برتقالية.
                    Text(
                      'FlyerX',
                      textDirection: TextDirection.ltr,
                      style: context.textTheme.titleLarge?.copyWith(
                        color: ink.withValues(alpha: .95),
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      balance == null ? '…' : balance.asMoney,
                      textDirection: TextDirection.ltr,
                      style: context.textTheme.headlineMedium?.copyWith(
                        color: ink,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      decoration: ShapeDecoration(
                        shape: const StadiumBorder(),
                        color: ink.withValues(alpha: .15),
                      ),
                      child: Text(
                        'د.ل',
                        style: context.textTheme.labelLarge?.copyWith(color: ink, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (_canTopUp)
                  _GlassButton(label: 'شحن المحفظة', icon: Icons.south_west_rounded, onTap: _topUp)
                else
                  Text(
                    'تُشحن ولا يُسحب منها، وتُدفع منها طلبياتك',
                    style: context.textTheme.bodySmall?.copyWith(color: ink.withValues(alpha: .85)),
                  ),
                Row(
                  children: [
                    for (var i = 0; i < 4; i++) ...[
                      if (i > 0) SizedBox(width: 18.w),
                      Expanded(
                        child: Container(
                          height: 10.h,
                          decoration: BoxDecoration(
                            color: ink.withValues(alpha: .2),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// زرّ بريمولا الزجاجي على البطاقة: ضبابٌ خلفه، وبياضٌ شفيف، وحدٌّ رفيع.
class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = context.colorScheme.onPrimary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: ink.withValues(alpha: .22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
            side: BorderSide(color: ink.withValues(alpha: .4)),
          ),
          child: InkWell(
            onTap: onTap,
            splashColor: ink.withValues(alpha: .12),
            highlightColor: ink.withValues(alpha: .06),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 11.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: ink, size: 18.sp),
                  SizedBox(width: 6.w),
                  Text(
                    label,
                    style: TextStyle(color: ink, fontSize: 14.sp, fontWeight: FontWeight.w700, letterSpacing: .3),
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

// ── المعاملات ─────────────────────────────────────────────────────────────────────────────

/// معاملةٌ في بطاقة، على نسق بريمولا (`transaction_record_card.dart`): متى، ونوعها بلونها مع «وارد»
/// أو «صادر»، وبأيّ طريقة، والقيمة بإشارتها — و«عرض الطلب» لما يخصّ طلبية.
class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, this.onOpenOrder, super.key});

  final MyWalletEntry entry;
  final VoidCallback? onOpenOrder;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tone = entry.isReversed ? scheme.outline : (entry.isIn ? scheme.paid : scheme.error);
    final struck = entry.isReversed ? TextDecoration.lineThrough : null;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: scheme.primary.withValues(alpha: .1), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (entry.occurredAt case final at?)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                '${at.relativeDayLabel} · ${at.timeLabel}',
                style: context.textTheme.labelMedium?.copyWith(color: scheme.outline, fontSize: 12.sp),
              ),
            ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'نوع العملية : ',
                    style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                        text: entry.typeLabel,
                        style: TextStyle(color: tone, decoration: struck),
                      ),
                    ],
                  ),
                ),
              ),
              _DirectionChip(isIn: entry.isIn, tone: tone),
            ],
          ),
          if (entry.methodLabel case final method?) ...[
            SizedBox(height: 10.h),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: scheme.primary.withValues(alpha: .15)),
                ),
                child: Text(
                  'عبر $method',
                  style: context.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 12.sp),
                ),
              ),
            ),
          ],
          SizedBox(height: 8.h),
          Text(
            'القيمة: ‎${entry.isIn ? '+' : '-'}${entry.amount.asMoney}‎ د.ل',
            style: context.textTheme.titleSmall?.copyWith(
              color: tone,
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
              decoration: struck,
            ),
          ),
          if (entry.isReversed) ...[
            SizedBox(height: 4.h),
            Text('أُلغيت', style: context.textTheme.bodySmall?.copyWith(color: scheme.error)),
          ],
          if (onOpenOrder != null) ...[
            SizedBox(height: 8.h),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: onOpenOrder,
                child: Text('عرض الطلبية ${entry.orderId}'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// «وارد» بالأخضر، و«صادر» بالأحمر — كما في بريمولا.
class _DirectionChip extends StatelessWidget {
  const _DirectionChip({required this.isIn, required this.tone});

  final bool isIn;
  final Color tone;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
    decoration: BoxDecoration(
      color: tone.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(8.r),
      border: Border.all(color: tone.withValues(alpha: .3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(isIn ? Icons.south_west_rounded : Icons.north_east_rounded, size: 16, color: tone),
        const SizedBox(width: 6),
        Text(isIn ? 'وارد' : 'صادر', style: TextStyle(color: tone, fontSize: 12)),
      ],
    ),
  );
}
