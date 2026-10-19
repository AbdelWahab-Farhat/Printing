import 'dart:async';
import 'dart:math' as math;

import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/pagination/paged_state.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/theme/app_tones.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/dates.dart';
import 'package:dayaa_client/core/utils/fixed_point.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:dayaa_client/core/widgets/filter_option_chip.dart';
import 'package:dayaa_client/core/widgets/paged_list_view.dart';
import 'package:dayaa_client/features/auth/models/customer_account.dart';
import 'package:dayaa_client/features/auth/usecases/get_current_customer.dart';
import 'package:dayaa_client/features/wallet/models/online_top_up_models.dart';
import 'package:dayaa_client/features/wallet/models/top_up_catalog.dart';
import 'package:dayaa_client/features/wallet/models/wallet_models.dart';
import 'package:dayaa_client/features/wallet/presentation/viewmodel/wallet_balance_cubit.dart';
import 'package:dayaa_client/features/wallet/presentation/viewmodel/wallet_entries_cubit.dart';
import 'package:dayaa_client/features/wallet/presentation/views/top_up_sheet.dart';
import 'package:dayaa_client/features/wallet/usecases/top_up_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// «محفظتي»: الرصيد، وكل ما دخلها وخرج منها. Docs/payments/CUSTOMER-WALLET.md.
///
/// **تصميم «بطاقة FlyerX»** (ب، اختاره صاحب العمل ٢٠٢٦-١٠-١٦ من لوحة التصميم): بطاقةٌ كحلية عليها
/// «X» العلامة البرتقالية، بالرصيد والاسم والرمز وحدها — بلا جملةٍ تشرح المحفظة. تحتها «شحن المحفظة»
/// بشعارات طرق الدفع، ثم المعاملات سطراً سطراً تحت أيامها.
///
/// زرّ الشحن يغيب ما دام الشحن الإلكتروني مطفأً — فلا زرّ لا يعمل.
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
      body: BlocConsumer<WalletEntriesCubit, WalletEntriesState>(
        // الرصيد الذي وصل مع الصفحة — بعد شحنٍ أيضاً — هو ما يرسمه الشريط العلوي بعد الرجوع.
        listener: (context, state) {
          if (cubit.balance case final balance?) sl<WalletBalanceCubit>().patch(balance);
        },
        builder: (context, state) {
          final entries = switch (state) {
            PagedLoaded<MyWalletEntry>(:final page) => page.items,
            _ => const <MyWalletEntry>[],
          };
          // محفظةٌ لم تتحرّك بعد: لا فلاتر فوق قائمةٍ فارغة. فلترٌ ضيّق فارغ يُبقيها ليُرجَع عنه.
          final showsFilters = !(state is PagedLoaded<MyWalletEntry> &&
              entries.isEmpty &&
              cubit.filter == MyWalletFilter.all);

          return Column(
            children: [
              SizedBox(height: 8.h),
              _Header(balance: cubit.balance),
              if (showsFilters) ...[
                SizedBox(height: 18.h),
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
              ],
              Expanded(
                child: PagedListView<MyWalletEntry>(
                  state: state,
                  emptyMessage: cubit.filter == MyWalletFilter.all
                      ? 'لا معاملات بعد'
                      : 'لا معاملات من هذا النوع',
                  onLoadMore: cubit.loadMore,
                  onRefresh: cubit.refresh,
                  skeletonHeight: 64.h,
                  padding: EdgeInsets.only(top: 4.h, bottom: 24.h),
                  separatorBuilder: (context, index) => index + 1 < entries.length &&
                          _sameDay(entries[index], entries[index + 1])
                      ? Divider(height: 1, indent: 83.w, endIndent: 22.w)
                      : const SizedBox.shrink(),
                  itemBuilder: (context, entry, index) => _EntryRow(
                    key: ValueKey(entry.id),
                    entry: entry,
                    day: index == 0 || !_sameDay(entries[index - 1], entry)
                        ? entry.occurredAt?.relativeShortDayLabel
                        : null,
                    onOpenOrder: switch (entry.orderId) {
                      final orderId? => () => context.push(Routes.order(orderId)),
                      null => null,
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// سطران في يومٍ واحد — وسطرٌ بلا تاريخ لا يفتح يوماً جديداً.
bool _sameDay(MyWalletEntry a, MyWalletEntry b) {
  final (x, y) = (a.occurredAt, b.occurredAt);

  if (x == null || y == null) return true;

  return x.year == y.year && x.month == y.month && x.day == y.day;
}

// ── الرأس: البطاقة وزرّ الشحن ────────────────────────────────────────────────────────────────

/// البطاقة و«شحن المحفظة» تحتها. تقرأ صاحبها وطرق الشحن بنفسها، بلا Cubit — كـ«حسابي».
class _Header extends StatefulWidget {
  const _Header({required this.balance});

  /// null حتى تصل أول صفحة.
  final String? balance;

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  CustomerAccount? _customer;

  /// الطرق التي يعرضها التطبيق والشحن مفعّل — فارغةٌ والشحن مطفأ، فلا زرّ.
  List<TopUpMethod> _methods = const [];

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

    methods.fold((_) {}, (m) {
      final shown = [
        for (final method in m.methods)
          if (method.isSupported) method,
      ];

      setState(() => _methods = m.enabled ? shown : const []);
    });
  }

  Future<void> _topUp() async {
    final cubit = context.read<WalletEntriesCubit>();
    final toppedUp = await showTopUpSheet(context, args: TopUpArgs(phone: _customer?.phone));

    if (toppedUp == true) await cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BalanceCard(balance: widget.balance, customer: _customer),
          if (_methods.isNotEmpty) ...[
            SizedBox(height: 15.h),
            _TopUpButton(methods: _methods, onTap: _topUp),
          ],
        ],
      ),
    );
  }
}

/// البطاقة: كحليّ الترويسة (`HeaderTone`) لا لون الصفحة، فتبقى بطاقةً في الوضعين، وعليها «X»
/// العلامة — شريطان متقاطعان، البرتقالي الصريح فوق طرفه الأعمق، كأيقونة التطبيق. ثم «الرصيد» والرقم،
/// والاسم والرمز في أسفلها. لا ظلّ: البطاقة تنفصل عن الصفحة بلونها.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, required this.customer});

  final String? balance;
  final CustomerAccount? customer;

  /// ميل شريطي «X» — ٣٤°.
  static const _tilt = 34 * math.pi / 180;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final customer = this.customer;
    final balance = this.balance;

    return Container(
      height: 220.h,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.header,
        borderRadius: BorderRadius.circular(26.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .4)),
      ),
      child: Stack(
        children: [
          for (final (angle, color) in [(-_tilt, scheme.primaryDeep), (_tilt, scheme.primary)])
            PositionedDirectional(
              end: 46.w,
              top: -77.h,
              child: Transform.rotate(
                angle: angle,
                child: Container(
                  width: 62.w,
                  height: 374.h,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(31.r)),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 22.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الرصيد',
                      style: text.titleSmall?.copyWith(
                        color: scheme.onHeaderVariant,
                        fontSize: 16.5.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          balance == null ? '…' : balance.asMoney,
                          textDirection: TextDirection.ltr,
                          style: text.displaySmall?.copyWith(
                            color: scheme.onHeader,
                            fontSize: 52.sp,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                        SizedBox(width: 9.w),
                        Text(
                          'د.ل',
                          style: text.titleLarge?.copyWith(
                            color: scheme.onHeaderVariant,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (customer != null)
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          customer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleMedium?.copyWith(
                            color: scheme.onHeader,
                            fontSize: 16.5.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (customer.code case final code?) ...[
                        SizedBox(width: 9.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            color: scheme.onHeader.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            code,
                            textDirection: TextDirection.ltr,
                            style: text.labelLarge?.copyWith(
                              color: scheme.onHeader,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
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

/// «شحن المحفظة»: بطاقةٌ بعرض الشاشة، دائرةٌ برتقالية بعلامة الزيادة، والاسم، وتحته **شعارات الطرق
/// كلها** — فيعرف الزبون قبل أن يلمس بأيّ شيءٍ يشحن (صاحب العمل ٢٠٢٦-١٠-١٦: «كل صور طرق الدفع…
/// كلهم»). اللمسة تفتح ورقة الشحن.
class _TopUpButton extends StatelessWidget {
  const _TopUpButton({required this.methods, required this.onTap});

  final List<TopUpMethod> methods;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return AppCard.raised(
      onTap: onTap,
      padding: EdgeInsets.fromLTRB(14.w, 13.h, 14.w, 15.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                child: Icon(AppIcons.add, color: scheme.onPrimary, size: 24.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'شحن المحفظة',
                  style: context.textTheme.titleMedium?.copyWith(fontSize: 18.5.sp, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ExcludeSemantics(child: _LogoRow(methods: methods)),
        ],
      ),
    );
  }
}

/// شعار كل طريقةٍ في دائرته، صفّاً بعرض الزرّ — التسع كلها تتّسع على أصغر هاتف. ما لا يتّسع له
/// الصفّ، أو طريقةٌ لا يعرف هذا الإصدار شعارها، يُعدّ في «+N» آخره.
class _LogoRow extends StatelessWidget {
  const _LogoRow({required this.methods});

  final List<TopUpMethod> methods;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final disc = 33.w;
    final logos = [for (final method in methods) ?brandOf(method.id).asset];

    return LayoutBuilder(
      builder: (context, constraints) {
        // أقلّ فجوةٍ تُبقي الدوائر منفصلة، وأكثرها لا يفرّقها على هاتفٍ عريض.
        final minGap = 3.w;
        final fits = ((constraints.maxWidth - disc) / (disc + minGap)).floor() + 1;
        final counted = logos.length < methods.length || logos.length > fits;
        final shown = counted ? logos.take(math.max(0, fits - 1)).toList() : logos;
        final rest = methods.length - shown.length;
        final discs = shown.length + (rest > 0 ? 1 : 0);
        final gap = discs < 2
            ? 0.0
            : ((constraints.maxWidth - discs * disc) / (discs - 1)).clamp(minGap, 8.w).toDouble();

        return Row(
          children: [
            for (final (i, asset) in shown.indexed) ...[
              if (i > 0) SizedBox(width: gap),
              _Disc(
                size: disc,
                child: Image.asset(asset, width: disc * .74, height: disc * .74, fit: BoxFit.contain),
              ),
            ],
            if (rest > 0) ...[
              if (shown.isNotEmpty) SizedBox(width: gap),
              _Disc(
                size: disc,
                fill: scheme.surfaceContainerHigh,
                child: Text(
                  '+$rest',
                  textDirection: TextDirection.ltr,
                  style: context.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// دائرةٌ بشعرة — لشعار طريقةٍ في الزرّ وعلى السطر، على ورقةٍ بيضاء في الوضعين (`logoPlate`).
class _Disc extends StatelessWidget {
  const _Disc({required this.size, required this.child, this.fill});

  final double size;
  final Widget child;
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: fill ?? scheme.logoPlate,
        shape: BoxShape.circle,
        border: Border.all(color: scheme.outlineVariant, width: 1.5),
      ),
      child: child,
    );
  }
}

// ── المعاملات ─────────────────────────────────────────────────────────────────────────────

/// معاملةٌ في سطر: أيقونة نوعها (أو شعار الطريقة التي شُحنت بها)، واسمها، وتحته الطريقة أو رقم
/// الطلبية مع الوقت، والمبلغ بإشارته ووحدته — الأخضر للداخل، والحبر لما دُفع. وفوق أوّل سطرٍ في
/// كل يوم اسمُ اليوم. سطرُ طلبيةٍ يفتحها.
class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, this.day, this.onOpenOrder, super.key});

  final MyWalletEntry entry;

  /// «اليوم»، «أمس»، «12 أكتوبر» — لأوّل سطرٍ في يومه وحده.
  final String? day;
  final VoidCallback? onOpenOrder;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final reversed = entry.isReversed;
    final tone = reversed ? scheme.outline : (entry.isIn ? scheme.paid : scheme.onSurface);
    final detail = [
      if (entry.orderId case final orderId?) entry.orderCode ?? '$orderId' else ?entry.methodLabel,
      ?entry.occurredAt?.timeLabel,
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (day case final day?)
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(22.w, 18.h, 22.w, 4.h),
            child: Text(
              day,
              style: text.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        InkWell(
          onTap: onOpenOrder,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 11.h),
            child: Row(
              children: [
                _EntryIcon(entry: entry),
                SizedBox(width: 13.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              entry.typeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleMedium?.copyWith(fontSize: 17.5.sp, fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (reversed) ...[
                            SizedBox(width: 7.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 9.w),
                              decoration: BoxDecoration(
                                color: scheme.errorContainer,
                                borderRadius: BorderRadius.circular(7.r),
                              ),
                              child: Text(
                                'أُلغيت',
                                style: text.labelLarge?.copyWith(
                                  color: scheme.onErrorContainer,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (detail.isNotEmpty)
                        Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: 9.w),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${entry.isIn ? '+' : '−'}${entry.amount.asMoney}',
                      textDirection: TextDirection.ltr,
                      style: text.titleLarge?.copyWith(
                        color: tone,
                        fontSize: 21.sp,
                        fontWeight: FontWeight.w800,
                        decoration: reversed ? TextDecoration.lineThrough : null,
                        decorationColor: tone,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'د.ل',
                      style: text.labelLarge?.copyWith(
                        color: reversed ? scheme.outline : scheme.onSurfaceVariant,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// ما يقف على طرف السطر: **شعار الطريقة** لشحنٍ إلكتروني أو برصيد ليبيانا، وإلا أيقونة النوع على
/// لونه — الشحن أخضر، ودفع الطلبية برتقالي العلامة، والردّ أزرق «قيد المعالجة»، والتعديل والعكس
/// محايدان. حركةٌ أُلغيت رماديةٌ كلها.
class _EntryIcon extends StatelessWidget {
  const _EntryIcon({required this.entry});

  final MyWalletEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final size = 48.w;
    final logo = switch (entry) {
      MyWalletEntry(type: 'topup', :final onlineMethod?) => brandOf(onlineMethod).asset,
      MyWalletEntry(type: 'topup', method: 'libyana') => brandOf(libyana).asset,
      _ => null,
    };

    if (logo != null) {
      return Opacity(
        opacity: entry.isReversed ? .5 : 1,
        child: _Disc(
          size: size,
          child: Image.asset(logo, width: size * .74, height: size * .74, fit: BoxFit.contain),
        ),
      );
    }

    final (icon, fill, ink) = switch (entry.type) {
      'topup' => (
        switch (entry.method) {
          'cash' => AppIcons.payment,
          'bank_transfer' => AppIcons.bankTransfer,
          'bank_card' => AppIcons.bankCard,
          _ => AppIcons.wallet,
        },
        scheme.paid.withValues(alpha: .12),
        scheme.paid,
      ),
      'order_payment' => (AppIcons.orders, scheme.primary.withValues(alpha: .12), scheme.primaryDeep),
      'order_refund' => (AppIcons.refund, scheme.infoContainer, scheme.onInfoContainer),
      'reversal' => (AppIcons.undo, scheme.surfaceContainerHigh, scheme.onSurfaceVariant),
      _ => (AppIcons.edit, scheme.surfaceContainerHigh, scheme.onSurfaceVariant),
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: entry.isReversed ? scheme.surfaceContainerHigh : fill,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 23.sp, color: entry.isReversed ? scheme.outline : ink),
    );
  }
}
