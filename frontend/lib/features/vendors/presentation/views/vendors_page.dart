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

/// The suppliers we buy from, on a screen of their own.
///
/// **Kept for the deep links and for the permission fallback**, though the tab under «الجهات» is
/// where somebody normally arrives — `/vendors/form` redirects here when the reader may not
/// raise one, and a redirect target has to exist.
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

  @override
  Widget build(BuildContext context) {
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
              onPressed: () => addVendor(context),
              icon: Icon(AppIcons.add),
              label: const Text('مورد جديد'),
            )
          : null,
      body: const VendorsBody(),
    );
  }
}

/// Adds a supplier and puts them at the top of the list behind it.
///
/// Top-level so the «إضافة» dial on [PartiesPage] can call it: the dial and this list share one
/// `VendorsCubit`, and the row goes in from what the form handed back rather than from a re-read.
Future<void> addVendor(BuildContext context) async {
  final cubit = context.read<VendorsCubit>();

  final saved = await context.push<Vendor>(Routes.vendorForm);

  if (saved != null) cubit.insert(saved);
}

/// The suppliers list itself — search box and rows, and nothing around them.
///
/// **A body, not a screen.** It is one tab of «الجهات» as well as the whole of [VendorsPage], so
/// the bar and the button belong to whichever of the two is hosting it. Its `VendorsCubit` comes
/// from above for the same reason: the dial has to insert into *this* list.
class VendorsBody extends StatelessWidget {
  const VendorsBody({super.key});

  /// Opens the supplier's own screen.
  ///
  /// **Not the form.** A row used to drop straight into the editor, which made reading a
  /// supplier's details impossible without appearing to be about to change them.
  Future<void> _open(BuildContext context, Vendor vendor) async {
    final cubit = context.read<VendorsCubit>();

    final changed = await context.push<Vendor>(Routes.vendor(vendor.id), extra: vendor);

    // The supplier itself when something moved, and nothing at all after a screen the user
    // merely read. The row redraws from what came back — a re-read would fetch a page this
    // list is already holding, and throw a scrolled one back to the top to do it.
    if (changed != null) cubit.replace(changed);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VendorsCubit>();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
          child: SearchField(
            // The three columns the server actually searches. Saying so stops somebody typing
            // an invoice number and concluding the search is broken.
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
              skeletonHeight: 216.h,
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
    );
  }
}
