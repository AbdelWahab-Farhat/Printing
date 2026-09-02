import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/business_fields/models/business_field.dart';
import 'package:dayaa/features/business_fields/presentation/viewmodel/business_fields_cubit.dart';
import 'package:dayaa/features/business_fields/presentation/widgets/business_field_card.dart';
import 'package:dayaa/features/business_fields/presentation/widgets/business_field_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// مجالات العمل — the list of trades a customer's shop can be in.
///
/// A curated list, so the screen is a list plus the three things that can happen to a row:
/// rename it, stop offering it, or remove one that should never have been there. Everything
/// else this table is *for* — «كم عميلاً في الشحن؟» — is a report that does not exist yet, and
/// the shop count on each card is the first sentence of it.
///
/// **Reading and writing are gated separately.** A reader gets the list with no switch, no
/// button and no sheet; the server refuses either way, and this is only what keeps a control
/// that would fail off the screen in the first place.
class BusinessFieldsPage extends StatelessWidget {
  const BusinessFieldsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BusinessFieldsCubit>(
      create: (_) => sl<BusinessFieldsCubit>()..load(),
      child: const _BusinessFieldsView(),
    );
  }
}

class _BusinessFieldsView extends StatelessWidget {
  const _BusinessFieldsView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BusinessFieldsCubit>();
    final canManage = sl<Session>().can(AppPermission.manageBusinessFields);

    return Scaffold(
      appBar: AppBar(title: const Text('مجالات العمل')),
      floatingActionButton: canManage
          // A ternary rather than a gate widget: a `SizedBox.shrink()` in the FAB slot still
          // occupies it and shifts the Scaffold's bottom inset.
          ? FloatingActionButton.extended(
              // Unique per screen, because the shell keeps every tab alive in an IndexedStack:
              // two default-tagged FABs in one subtree is the «multiple heroes» assertion.
              heroTag: 'fab-business-fields',
              onPressed: () async {
                final created = await showBusinessFieldSheet(
                  context: context,
                  nextSortOrder: _nextSortOrder(cubit.state),
                );

                // Re-read: the list is in the business's own order, so where a new field lands
                // is the server's answer and not one this screen can invent. Editing an
                // existing one does not re-read — see `_edit`.
                if (created != null) await cubit.refresh();
              },
              icon: Icon(AppIcons.add),
              label: const Text('مجال جديد'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: SearchField(
              hint: 'ابحث عن مجال عمل',
              onChanged: cubit.search,
            ),
          ),
          Expanded(
            child: BlocBuilder<BusinessFieldsCubit, BusinessFieldsState>(
              builder: (context, state) => PagedListView<BusinessField>(
                state: state,
                emptyMessage: 'لا توجد مجالات عمل بعد',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                // One row measured: a 36 tile with two lines beside it.
                skeletonHeight: 68.h,
                itemBuilder: (context, field, index) => BusinessFieldCard(
                  key: ValueKey(field.id),
                  field: field,
                  onTap: canManage ? () => _edit(context, cubit, field) : null,
                  onToggleActive: canManage
                      ? (isActive) =>
                            _toggle(context, cubit, field, isActive: isActive)
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the rename sheet, and offers the delete from inside it — the one place where both
  /// the name and the shop count are already on screen, so «لماذا لا يمكن حذفه؟» is answered
  /// before it is asked.
  Future<void> _edit(
    BuildContext context,
    BusinessFieldsCubit cubit,
    BusinessField field,
  ) async {
    final saved = await showBusinessFieldSheet(
      context: context,
      field: field,
      onDelete: () => _confirmDelete(context, cubit, field),
    );

    // The renamed field, as the server stored it — the row redraws from that rather than the
    // whole page being read again for one line of text.
    if (saved != null) cubit.replace(saved);
  }

  /// Confirms, then removes. Answers whether the field is gone, so the sheet knows to close.
  Future<bool> _confirmDelete(
    BuildContext context,
    BusinessFieldsCubit cubit,
    BusinessField field,
  ) async {
    final confirmed = await showDestructiveDialog(
      context: context,
      title: 'حذف «${field.name}»؟',
      description:
          'يختفي المجال من قوائم الاختيار نهائياً. الحذف متاح لأنه غير مرتبط بأي محل — لو ارتبط '
          'به محل لاحقاً فالإيقاف هو الطريقة.',
    );

    if (confirmed != true || !context.mounted) return false;

    final failure = await cubit.remove(field);

    if (!context.mounted) return failure == null;

    if (failure != null) {
      // The server's own Arabic says which refusal it was — most often «مرتبط بمحلات», when the
      // count on the card was stale. The app does not guess between them.
      context.showFailure(failure);

      return false;
    }

    context.showSuccess('تم حذف ${field.name}');

    return true;
  }

  Future<void> _toggle(
    BuildContext context,
    BusinessFieldsCubit cubit,
    BusinessField field, {
    required bool isActive,
  }) async {
    final failure = await cubit.setActivation(field, isActive: isActive);

    if (!context.mounted) return;

    if (failure != null) {
      context.showFailure(failure);

      return;
    }

    context.showSuccess(
      isActive ? 'تم تفعيل ${field.name}' : 'تم إيقاف ${field.name}',
    );
  }
}

/// Where a newly added field lands in the picker: after everything already on the list.
///
/// Read off what is on screen rather than asked of the server, because it only has to be
/// *after* the rest — the order within a rank falls back to the name, so two fields added on
/// the same page are still sorted rather than arbitrary.
int _nextSortOrder(BusinessFieldsState state) => switch (state) {
  BusinessFieldsLoaded(:final page) when page.items.isNotEmpty =>
    page.items.map((field) => field.sortOrder).reduce((a, b) => a > b ? a : b) +
        10,
  _ => 0,
};
