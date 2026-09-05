import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/investors/models/investor_deal.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/deals_cubit.dart';
import 'package:dayaa/features/investors/presentation/widgets/deal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// صفقات المستثمرين — one financed purchase of stock apiece.
class InvestorDealsPage extends StatelessWidget {
  const InvestorDealsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DealsCubit>(
      create: (_) => sl<DealsCubit>()..load(),
      child: const _DealsView(),
    );
  }
}

/// The three answers to «أيّ صفقات؟». No «مسودة»: a deal is born open, on its purchase order.
enum _DealStatus {
  all(null, 'كل الصفقات'),
  open('open', 'مفتوحة'),
  closed('closed', 'مغلقة');

  const _DealStatus(this.wire, this.label);

  final String? wire;
  final String label;
}

class _DealsView extends StatefulWidget {
  const _DealsView();

  @override
  State<_DealsView> createState() => _DealsViewState();
}

class _DealsViewState extends State<_DealsView> {
  _DealStatus _status = _DealStatus.all;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DealsCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('صفقات المستثمرين')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: Column(
              // Both controls span the screen. A trigger shrink-wrapped to «كل الصفقات» is a
              // different width on every option it can show, so the search box above it appears
              // to change length when the filter changes — and a control the width of its own
              // label is the one thing the standing rule about buttons forbids.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SearchField(hint: 'ابحث بالاسم أو الرمز', onChanged: cubit.search),
                SizedBox(height: 10.h),
                // Its own row, under the search rather than beside it: side by side it took a
                // third of the box away from the thing people actually type in.
                _StatusMenu(
                  value: _status,
                  onChanged: (status) {
                    setState(() => _status = status);
                    cubit.filter(status: status.wire);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<DealsCubit, PagedState<InvestorDeal>>(
              builder: (context, state) => PagedListView<InvestorDeal>(
                state: state,
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                emptyMessage: 'لا توجد صفقات',
                onRefresh: cubit.refresh,
                onLoadMore: cubit.loadMore,
                skeletonHeight: 76.h,
                itemBuilder: (context, deal, index) => DealCard(
                  key: ValueKey(deal.id),
                  deal: deal,
                  // The deal screen hands the deal back when opening or closing it moved the
                  // status, and nothing at all when it was only read — so the pill redraws with
                  // no request, and a list scrolled halfway down is not thrown back to the top
                  // to redraw one card. A deal that no longer matches the filter leaves the
                  // list, which is what `belongs` is for.
                  onTap: () async {
                    final changed = await context.push<InvestorDeal>(
                      Routes.investorDeal(deal.id),
                    );
                    if (changed != null) cubit.replace(changed);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Which statuses the list is showing, as a menu rather than a row of chips.
///
/// **A row of four chips spent a whole line of the screen saying three things nobody had
/// chosen.** The answer is one of four and only one, which is a menu's shape — and it collapses
/// to a single control beside the search box, so the list starts one row higher.
///
/// Filled when it is narrowed, so «why is this list short?» is answered before the menu is
/// opened — the same reason the filter buttons elsewhere in the app change colour.
class _StatusMenu extends StatelessWidget {
  const _StatusMenu({required this.value, required this.onChanged});

  final _DealStatus value;
  final ValueChanged<_DealStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isNarrowed = value != _DealStatus.all;

    final foreground = isNarrowed ? scheme.onPrimaryContainer : scheme.onSurface;

    return PopupMenuButton<_DealStatus>(
      tooltip: 'الحالة',
      initialValue: value,
      onSelected: onChanged,
      // Under the button, so the menu never lands on the control that opened it.
      position: PopupMenuPosition.under,
      color: scheme.surfaceContainerLowest,
      // The app's own corner, not Material's 4dp — every plate on this screen is rounder.
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      itemBuilder: (context) => [
        for (final status in _DealStatus.values)
          PopupMenuItem<_DealStatus>(
            value: status,
            child: Text(
              status.label,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: status == value ? FontWeight.w800 : FontWeight.w600,
                color: status == value ? scheme.primary : scheme.onSurface,
              ),
            ),
          ),
      ],
      child: Container(
        padding: EdgeInsetsDirectional.fromSTEB(14.w, 12.h, 10.w, 12.h),
        decoration: BoxDecoration(
          color: isNarrowed ? scheme.primaryContainer : scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            // At the far edge, where a dropdown's arrow sits in every other field in this app.
            Icon(AppIcons.expand, size: 20.sp, color: foreground),
          ],
        ),
      ),
    );
  }
}
