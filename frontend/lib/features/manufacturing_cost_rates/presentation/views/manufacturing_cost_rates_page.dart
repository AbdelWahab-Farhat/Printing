import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/features/manufacturing_cost_rates/models/manufacturing_cost_rate.dart';
import 'package:dayaa/features/manufacturing_cost_rates/presentation/viewmodel/manufacturing_cost_rates_cubit.dart';
import 'package:dayaa/features/manufacturing_cost_rates/presentation/widgets/manufacturing_cost_rate_card.dart';
import 'package:dayaa/features/manufacturing_cost_rates/presentation/widgets/manufacturing_cost_rate_filter_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// معدلات تكلفة التصنيع — what the workshop charges itself per unit of work.
///
/// **The order of this list is the rule it describes.** The server returns the size-specific
/// rates first, then the product-wide ones, then the defaults — which is the order it resolves
/// them in when an order enters printing — so reading down the page is reading the ladder. It is
/// never re-sorted here, and the line above the list says so, because a table of numbers with no
/// explanation of which one wins is a table somebody will edit the wrong row of.
///
/// **Reading and writing are gated separately.** A reader gets the list with no switch, no bin,
/// no button and no form; the server refuses either way, and this is only what keeps a control
/// that would fail off the screen in the first place.
class ManufacturingCostRatesPage extends StatelessWidget {
  const ManufacturingCostRatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ManufacturingCostRatesCubit>(
      create: (_) => sl<ManufacturingCostRatesCubit>()..load(),
      child: const _ManufacturingCostRatesView(),
    );
  }
}

class _ManufacturingCostRatesView extends StatelessWidget {
  const _ManufacturingCostRatesView();

  Future<void> _open(BuildContext context, ManufacturingCostRate? rate) async {
    final cubit = context.read<ManufacturingCostRatesCubit>();

    final saved = await context.push<bool>(
      Routes.manufacturingCostRateForm,
      extra: rate,
    );

    // Only when something actually changed: a refresh after a dismissed form is a request
    // nobody asked for, and it flickers the list under the user's thumb.
    if (saved ?? false) await cubit.refresh();
  }

  Future<void> _toggle(
    BuildContext context,
    ManufacturingCostRate rate, {
    required bool isActive,
  }) async {
    final cubit = context.read<ManufacturingCostRatesCubit>();

    final failure = await cubit.setActivation(rate, isActive: isActive);

    if (!context.mounted) return;

    if (failure != null) {
      context.showFailure(failure);

      return;
    }

    context.showSuccess(
      isActive
          ? 'تم تفعيل معدل ${rate.costTypeLabel}'
          : 'تم إيقاف معدل ${rate.costTypeLabel}',
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ManufacturingCostRate rate,
  ) async {
    final cubit = context.read<ManufacturingCostRatesCubit>();

    final confirmed = await showDestructiveDialog(
      context: context,
      title: 'حذف معدل ${rate.costTypeLabel}؟',
      // The two facts somebody needs before deleting rather than stopping: the orders already
      // priced by this rate keep their numbers, and what takes over afterwards is whatever rung
      // sits below it — which for a size-specific rate is the product's, not «لا شيء».
      description:
          'يختفي المعدل نهائياً، وتبقى تكاليف الطلبيات السابقة كما سُجّلت. الطلبيات الجديدة '
          'ستأخذ المعدل الأعم منه إن وُجد. إن كان المقصود التوقف عن استخدامه فالإيقاف أفضل.',
    );

    if (confirmed != true || !context.mounted) return;

    final failure = await cubit.remove(rate);

    if (!context.mounted) return;

    if (failure != null) {
      context.showFailure(failure);

      return;
    }

    context.showSuccess('تم حذف معدل ${rate.costTypeLabel}');
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ManufacturingCostRatesCubit>();
    final mayManage = sl<Session>().can(AppPermission.manageManufacturingCostRates);

    return Scaffold(
      appBar: AppBar(title: const Text('معدلات تكلفة التصنيع')),
      // A ternary rather than a PermissionGate: an empty widget in this slot still shifts the
      // bottom inset, so the button has to be absent rather than invisible.
      floatingActionButton: mayManage
          ? FloatingActionButton.extended(
              // Unique per screen, because the shell keeps every tab alive in an IndexedStack:
              // two default-tagged FABs in one subtree is the «multiple heroes» assertion.
              heroTag: 'fab-manufacturing-cost-rates',
              onPressed: () => _open(context, null),
              icon: Icon(AppIcons.add),
              label: const Text('معدل جديد'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'تُحتسب تلقائياً عند دخول الطلبية مرحلة الطباعة. الأخص أولاً: المقاس، '
                    'ثم المنتج، ثم الافتراضي.',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                // Rebuilt with the list, so the button's «filtered» fill and the rows it
                // produced can never disagree.
                BlocBuilder<ManufacturingCostRatesCubit, ManufacturingCostRatesState>(
                  builder: (context, state) => ManufacturingCostRateFilterButton(
                    costType: cubit.costType,
                    isActive: cubit.isActive,
                    onApplied: (choice) => cubit.filterBy(
                      costType: choice.costType,
                      isActive: choice.isActive,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<ManufacturingCostRatesCubit, ManufacturingCostRatesState>(
              builder: (context, state) => PagedListView<ManufacturingCostRate>(
                state: state,
                // Named for the filter, because «لا توجد معدلات» in front of somebody who
                // narrowed the list to «خسارة تلف» reads as «the table is empty».
                emptyMessage: cubit.isFiltered
                    ? 'لا توجد معدلات بهذه التصفية'
                    : 'لم يُضف أي معدل بعد',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                // One row measured: a 38 tile with two lines beside it.
                skeletonHeight: 70.h,
                itemBuilder: (context, rate, index) => ManufacturingCostRateCard(
                  key: ValueKey(rate.id),
                  rate: rate,
                  onTap: mayManage ? () => _open(context, rate) : null,
                  onToggleActive: mayManage
                      ? (isActive) => _toggle(context, rate, isActive: isActive)
                      : null,
                  onDelete: mayManage ? () => _confirmDelete(context, rate) : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
