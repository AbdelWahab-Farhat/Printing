import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/router/pop_result.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/fund_detail_body.dart';
import 'package:dayaa/features/investors/presentation/widgets/investor_money_tile.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_dialogs.dart';
import 'package:dayaa/features/wallet/models/wallet_models.dart';
import 'package:dayaa/features/wallet/presentation/viewmodel/customer_wallet_cubit.dart';
import 'package:dayaa/features/wallet/presentation/viewmodel/wallet_entries_cubit.dart';
import 'package:dayaa/features/wallet/presentation/widgets/adjust_wallet_dialog.dart';
import 'package:dayaa/features/wallet/presentation/widgets/top_up_sheet.dart';
import 'package:dayaa/features/wallet/presentation/widgets/wallet_entry_row.dart';
import 'package:dayaa/features/warehouses/presentation/widgets/day_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// محفظة عميلٍ واحد: رصيدها، وكل حركة — الشحن، ودفع الطلبيات، والردود، والتعديلات.
/// Docs/payments/CUSTOMER-WALLET.md.
///
/// **على شكل محفظة المستثمر** بطلب صاحب العمل (٢٠٢٦-١٠-١١): الرصيدُ في البطاقة الكبيرة بصورة
/// المحفظة ([InvestorMoneyTile.hero])، والفعلُ شريطٌ بعرض الشاشة في أسفلها لا زرٌّ عائم، والسجلُّ
/// بأيامه وسطورِ محفظة المستثمر، ورقائقُ الأنواع تلتفّ ولا تُمرَّر، ومدى الأيام في الشريط.
///
/// **تُشحن ولا يُسحب منها**: لا زرّ سحب. الدفعُ منها على طلبيةٍ من دفعات الطلبية.
///
/// **تعيد `true` لمن فتحها حين تحرّك المال**، فتقرأ شاشةُ العميل رصيدها من جديد.
class CustomerWalletPage extends StatelessWidget {
  const CustomerWalletPage({required this.customerId, this.customerName, super.key});

  final int customerId;

  /// تحت العنوان — يُمرَّر ولا يُطلب، كما تفعل صفحة المستثمر.
  final String? customerName;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<CustomerWalletCubit>(param1: customerId)..load()),
        BlocProvider(create: (_) => sl<WalletEntriesCubit>(param1: customerId)..load()),
      ],
      child: _WalletView(customerName: customerName ?? 'العميل'),
    );
  }
}

class _WalletView extends StatelessWidget {
  const _WalletView({required this.customerName});

  final String customerName;

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<WalletEntriesCubit>();

    return BlocConsumer<CustomerWalletCubit, CustomerWalletState>(
      listener: (context, state) {
        // ما تغيّر يُسلَّم لمن فتح الصفحة، كيفما أُغلقت.
        if (context.read<CustomerWalletCubit>().moneyMoved) context.handBack(true);

        if (state case CustomerWalletLoaded(:final refreshFailure?)) {
          context.showFailure(refreshFailure);
        }
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('المحفظة'),
              Text(
                customerName,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'حسب التاريخ',
              icon: const Icon(Icons.date_range_rounded),
              onPressed: () => _pickRange(context, entries),
            ),
          ],
        ),
        // **الفعلُ شريطٌ في الأسفل** كصفحة المستثمر: إبهامٌ واحد، وزرٌّ بعرض الهاتف لا يُخفي آخر
        // سطرٍ في السجل.
        bottomNavigationBar: state is CustomerWalletLoaded
            ? _ActionBar(customerName: customerName)
            : null,
        body: switch (state) {
          CustomerWalletLoading() => const Center(child: CircularProgressIndicator()),
          CustomerWalletFailed(:final failure) => _Failed(
            failure: failure,
            onRetry: context.read<CustomerWalletCubit>().load,
          ),
          CustomerWalletLoaded(:final balance) => Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 4.h),
                child: InvestorMoneyTile.hero(
                  label: 'رصيد المحفظة',
                  amount: balance,
                  artwork: 'assets/images/wallet.png',
                  caption: 'تُشحن ولا يُسحب منها — تُدفع منها الطلبيات',
                ),
              ),
              _TypeBar(selected: entries.filter, onSelect: entries.narrowTo),
              if (entries.from case final from?)
                if (entries.to case final to?)
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 4.h),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: InputChip(
                        label: Text(AppDates.span(from, to)),
                        onDeleted: () => unawaited(entries.between(null, null)),
                      ),
                    ),
                  ),
              const Expanded(child: _History()),
            ],
          ),
        },
      ),
    );
  }

  Future<void> _pickRange(BuildContext context, WalletEntriesCubit entries) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: now,
      initialDateRange: entries.from != null && entries.to != null
          ? DateTimeRange(start: entries.from!, end: entries.to!)
          : null,
    );

    if (picked == null) return;

    await entries.between(picked.start, picked.end);
  }
}

/// الكلُّ ثم الأنواع — **تلتفّ ولا تُمرَّر**، كرقائق سجلّ المستثمر: فلترٌ لا يُرى لا يُسأل.
class _TypeBar extends StatelessWidget {
  const _TypeBar({required this.selected, required this.onSelect});

  final WalletEntryFilter selected;
  final Future<void> Function(WalletEntryFilter) onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 6.h),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final filter in WalletEntryFilter.values)
              FilterOptionChip(
                label: filter.label,
                isSelected: filter == selected,
                onTap: () => unawaited(onSelect(filter)),
              ),
          ],
        ),
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WalletEntriesCubit>();

    return BlocBuilder<WalletEntriesCubit, WalletEntriesState>(
      builder: (context, state) {
        final items = state is PagedLoaded<CustomerWalletEntry>
            ? state.page.items
            : const <CustomerWalletEntry>[];

        return PagedListView<CustomerWalletEntry>(
          state: state,
          emptyMessage: cubit.filter == WalletEntryFilter.all && cubit.from == null
              ? 'لم تتحرّك هذه المحفظة بعد'
              : 'لا حركات تطابق هذا الفلتر',
          onLoadMore: cubit.loadMore,
          onRefresh: () async {
            await Future.wait([cubit.refresh(), context.read<CustomerWalletCubit>().load()]);
          },
          skeletonHeight: 96.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          separatorBuilder: (context, index) => const FundHairline(),
          itemBuilder: (context, entry, index) {
            final previous = index > 0 && index - 1 < items.length ? items[index - 1] : null;
            final row = CustomerWalletEntryRow(
              key: ValueKey(entry.id),
              entry: entry,
              onTap: switch (entry.orderId) {
                final orderId? => () => context.push(Routes.order(orderId)),
                null => null,
              },
              onReverse: entry.canReverse && !entry.isReversed
                  ? () => unawaited(_reverse(context, entry))
                  : null,
            );

            if (entry.occurredAt case final at? when startsNewDay(previous?.occurredAt, at)) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [DayHeader(at: at, first: index == 0), row],
              );
            }

            return row;
          },
        );
      },
    );
  }

  /// يُلغي الحركة بسببٍ إجباري — يرفضه الخادم إن كان المال قد صُرف.
  Future<void> _reverse(BuildContext context, CustomerWalletEntry entry) async {
    final header = context.read<CustomerWalletCubit>();
    final entries = context.read<WalletEntriesCubit>();

    final reason = await askForReason(
      context,
      title: 'إلغاء «${entry.typeLabel}»',
      confirmLabel: 'إلغاء الحركة',
    );

    if (reason == null || !context.mounted) return;

    final result = await entries.reverse(entry, reason: reason);

    if (!context.mounted) return;

    result.fold(context.showFailure, (write) {
      header.applyBalance(write.balance);
      context.showSuccess('أُلغيت الحركة');
    });
  }
}

/// «شحن المحفظة» و«تعديل الرصيد» على شريطٍ بعرض الشاشة — كلٌّ بصلاحيته، **وغائبٌ لا معطّل**:
/// من يقرأ المحفظة ولا يحرّكها يرى الشاشة تنتهي حيث ينتهي سجلّها.
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.customerName});

  final String customerName;

  @override
  Widget build(BuildContext context) {
    final session = sl<Session>();
    final mayTopUp = session.can(AppPermission.topUpCustomerWallets);
    final mayAdjust = session.can(AppPermission.adjustCustomerWallets);

    if (!mayTopUp && !mayAdjust) return const SizedBox.shrink();

    return Container(
      color: context.colorScheme.surface,
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
        child: Row(
          children: [
            if (mayTopUp)
              Expanded(
                flex: 3,
                child: AppButton(
                  label: 'شحن المحفظة',
                  icon: AppIcons.walletTopUp,
                  onPressed: () => _topUp(context),
                ),
              ),
            if (mayTopUp && mayAdjust) SizedBox(width: 10.w),
            if (mayAdjust)
              Expanded(
                flex: 2,
                child: AppButton.outlined(
                  label: 'تعديل الرصيد',
                  icon: AppIcons.edit,
                  onPressed: () => _adjust(context),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _topUp(BuildContext context) async {
    final header = context.read<CustomerWalletCubit>();
    final entries = context.read<WalletEntriesCubit>();

    final saved = await showTopUpSheet(
      context: context,
      customerName: customerName,
      onSubmit:
          ({
            required amount,
            required method,
            treasuryAccountId,
            reference,
            notes,
            receipt,
          }) async {
            final result = await header.topUp(
              amount: amount,
              method: method,
              treasuryAccountId: treasuryAccountId,
              reference: reference,
              notes: notes,
              receiptPath: receipt?.path,
              receiptFilename: receipt?.name,
            );

            return result.fold((failure) => failure, (write) {
              entries.addWritten(write.entry);

              return null;
            });
          },
    );

    if (saved == true && context.mounted) context.showSuccess('تم شحن المحفظة');
  }

  Future<void> _adjust(BuildContext context) async {
    final header = context.read<CustomerWalletCubit>();
    final entries = context.read<WalletEntriesCubit>();

    final saved = await showAdjustWalletDialog(
      context: context,
      onSubmit: ({required amount, required credit, required reason}) async {
        final result = await header.adjust(amount: amount, credit: credit, reason: reason);

        return result.fold((failure) => failure, (write) {
          entries.addWritten(write.entry);

          return null;
        });
      },
    );

    if (saved == true && context.mounted) context.showSuccess('تم تعديل الرصيد');
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.failure, required this.onRetry});

  final Failure failure;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(failure.message, textAlign: TextAlign.center),
            SizedBox(height: 16.h),
            AppButton.tonal(label: 'إعادة المحاولة', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
