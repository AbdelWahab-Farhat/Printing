import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/widgets/paged_list_view.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/vendors/models/vendor.dart';
import 'package:dayaa/features/vendors/presentation/viewmodel/vendors_cubit.dart';
import 'package:dayaa/features/vendors/presentation/widgets/vendor_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// The suppliers we buy from.
///
/// Every supplier, including the ones we have stopped dealing with: this list is the record, and
/// a purchase order from last year still names one of them. What retirement changes is that a
/// supplier stops being offered when an order is raised, which is the picker's business rather
/// than this one's.
class VendorsPage extends StatelessWidget {
  const VendorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VendorsCubit>(
      create: (_) => sl<VendorsCubit>()..load(),
      child: const _VendorsView(),
    );
  }
}

class _VendorsView extends StatelessWidget {
  const _VendorsView();

  /// Opens the supplier's own screen.
  ///
  /// **Not the form.** A row used to drop straight into the editor, which made reading a
  /// supplier's details impossible without appearing to be about to change them.
  Future<void> _open(BuildContext context, Vendor vendor) async {
    final cubit = context.read<VendorsCubit>();

    final changed = await context.push<bool>(
      Routes.vendor(vendor.id),
      extra: vendor,
    );

    // Only when something actually changed: a refresh after a screen the user merely read is a
    // request nobody asked for, and it flickers the list under their thumb.
    if (changed ?? false) await cubit.refresh();
  }

  Future<void> _add(BuildContext context) async {
    final cubit = context.read<VendorsCubit>();

    final saved = await context.push<bool>(Routes.vendorForm);

    if (saved ?? false) await cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VendorsCubit>();
    final mayManage = sl<Session>().can(AppPermission.manageVendors);

    return Scaffold(
      appBar: AppBar(title: const Text('الموردون')),
      // A ternary rather than a PermissionGate: an empty widget in this slot still shifts the
      // bottom inset, so the button has to be absent rather than invisible.
      floatingActionButton: mayManage
          ? FloatingActionButton.extended(
              // Unique per screen: two default-tagged FABs alive in one subtree is the
              // «multiple heroes» assertion.
              heroTag: 'fab-vendors',
              onPressed: () => _add(context),
              icon: Icon(AppIcons.add),
              label: const Text('مورد جديد'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
            child: SearchField(
              // The three columns the server actually searches. Saying so stops somebody
              // typing an invoice number and concluding the search is broken.
              hint: 'ابحث بالاسم أو المسؤول أو الهاتف',
              onChanged: cubit.search,
            ),
          ),
          Expanded(
            child: BlocBuilder<VendorsCubit, VendorsState>(
              builder: (context, state) => PagedListView<Vendor>(
                state: state,
                emptyMessage: 'لم يُضف مورد بعد',
                onLoadMore: cubit.loadMore,
                onRefresh: cubit.refresh,
                skeletonHeight: 68.h,
                itemBuilder: (context, vendor, index) => VendorCard(
                  key: ValueKey(vendor.id),
                  vendor: vendor,
                  // Always tappable: reading a supplier is not managing one, and the screen it
                  // opens hides the controls a reader cannot use.
                  onTap: () => _open(context, vendor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
