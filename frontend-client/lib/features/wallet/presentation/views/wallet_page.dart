import 'dart:async';

import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/dates.dart';
import 'package:dayaa_client/core/utils/fixed_point.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:dayaa_client/core/widgets/filter_option_chip.dart';
import 'package:dayaa_client/core/widgets/paged_list_view.dart';
import 'package:dayaa_client/features/wallet/models/wallet_models.dart';
import 'package:dayaa_client/features/wallet/presentation/viewmodel/wallet_entries_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// «محفظتي»: الرصيد، وكل ما دخلها وخرج منها. Docs/payments/CUSTOMER-WALLET.md.
///
/// **تُشحن ولا يُسحب منها**، وتُدفع منها الطلبيات من شاشة الطلبية. الشحنُ اليوم من المتجر، والشحن
/// من التطبيق قادم — فالرأس يقول ذلك ولا يعرض زرّاً لا يعمل.
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
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
              child: _BalanceCard(balance: cubit.balance),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
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
                    ? 'لم تتحرّك محفظتك بعد'
                    : 'لا معاملات من هذا النوع',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                skeletonHeight: 72.h,
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, entry, index) => _EntryRow(
                  key: ValueKey(entry.id),
                  entry: entry,
                  onTap: switch (entry.orderId) {
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

/// الرصيد بخطٍّ كبير، وتحته كيف تُشحن المحفظة اليوم.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  /// null حتى تصل أول صفحة.
  final String? balance;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return AppCard.accent(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
      child: Row(
        children: [
          Icon(AppIcons.wallet, size: 34.sp, color: scheme.primary),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'رصيد المحفظة',
                  style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
                SizedBox(height: 4.h),
                Text(
                  balance == null ? '…' : '${balance!.asMoney} د.ل',
                  style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 6.h),
                Text(
                  'تُشحن من المتجر، وتُدفع منها طلبياتك. الشحن من التطبيق قريباً.',
                  style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// سطرٌ من المعاملات: النوع والتاريخ، والمبلغ بإشارته ولونه.
class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry, this.onTap, super.key});

  final MyWalletEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tone = entry.isReversed
        ? scheme.onSurfaceVariant
        : entry.isIn
        ? scheme.primary
        : scheme.error;
    final struck = entry.isReversed ? TextDecoration.lineThrough : null;
    final quiet = context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

    final story = [
      ?entry.methodLabel,
      ?entry.description,
      if (entry.occurredAt case final at?) at.stampLabel,
    ].join(' · ');

    final row = Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.typeLabel,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    decoration: struck,
                  ),
                ),
                if (story.isNotEmpty) ...[
                  SizedBox(height: 3.h),
                  Text(story, maxLines: 2, overflow: TextOverflow.ellipsis, style: quiet),
                ],
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            '${entry.isIn ? '+' : '−'}${entry.amount.asMoney} د.ل',
            textDirection: TextDirection.ltr,
            style: context.textTheme.titleMedium?.copyWith(
              color: tone,
              fontWeight: FontWeight.w900,
              decoration: struck,
            ),
          ),
        ],
      ),
    );

    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}
