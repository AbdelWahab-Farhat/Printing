import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/pagination/changes.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/app_speed_dial.dart';
import 'package:dayaa/features/audit/models/audit_subject.dart';
import 'package:dayaa/features/vendors/models/vendor.dart';
import 'package:dayaa/features/vendors/presentation/viewmodel/vendor_detail_cubit.dart';
import 'package:dayaa/features/vendors/presentation/viewmodel/vendor_purchase_order_counts_cubit.dart';
import 'package:dayaa/features/vendors/presentation/widgets/vendor_purchase_orders_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// One supplier: who they are, how to reach them, and what can be done about them.
///
/// **The list opens this, not the form.** Tapping a row used to drop straight into the editor,
/// which made reading a supplier's details impossible without appearing to be about to change
/// them — and made the phone number, the thing most often wanted, something you had to open a
/// text box to read.
///
/// Pops with `true` when anything was written, so the list behind refreshes rather than showing
/// a row that no longer matches.
class VendorDetailPage extends StatelessWidget {
  const VendorDetailPage({required this.vendorId, this.vendor, super.key});

  final int vendorId;

  /// The row that was tapped, when there was one. A deep link carries none, and the screen
  /// waits for the read instead.
  final Vendor? vendor;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<VendorDetailCubit>(
          create: (_) =>
              sl<VendorDetailCubit>(param1: vendorId, param2: vendor)..load(),
        ),
        // Provided even when the reader may not see purchase orders: a Cubit nobody reads costs
        // nothing, while a provider that appears and disappears with a permission is a
        // `ProviderNotFound` waiting for the first screen that forgets to check. The *request*
        // is what is guarded — see [_Body].
        BlocProvider<VendorPurchaseOrderCountsCubit>(
          create: (_) => sl<VendorPurchaseOrderCountsCubit>(param1: vendorId),
        ),
      ],
      child: const _VendorDetailView(),
    );
  }
}

class _VendorDetailView extends StatefulWidget {
  const _VendorDetailView();

  @override
  State<_VendorDetailView> createState() => _VendorDetailViewState();
}

/// Stateful for one reason: it remembers the supplier as it changed, so `pop` can hand the list
/// behind the new row instead of making it re-read the page. That is screen lifecycle, not
/// business state — the Cubit owns the supplier itself.
class _VendorDetailViewState extends State<_VendorDetailView> {
  final _changes = Changes<Vendor>();

  /// Whether this reader may see purchase orders at all. Read once: it cannot change while the
  /// screen is open, and it decides both whether the numbers are asked for and whether the
  /// section is drawn — one answer, so the two can never disagree.
  final bool _maySeePurchaseOrders = sl<Session>().can(
    AppPermission.viewPurchaseOrders,
  );

  @override
  void initState() {
    super.initState();

    // Not asked for at all without the permission: the server answers 403, and a request whose
    // only possible outcome is a refusal is a request nobody should send.
    if (_maySeePurchaseOrders) {
      context.read<VendorPurchaseOrderCountsCubit>().load();
    }
  }

  /// Both readers, on one pull. The counts are as stale as the record beside them.
  Future<void> _reload(BuildContext context) async {
    await Future.wait([
      context.read<VendorDetailCubit>().load(),
      if (_maySeePurchaseOrders)
        context.read<VendorPurchaseOrderCountsCubit>().load(),
    ]);
  }

  Future<void> _edit(BuildContext context) async {
    final cubit = context.read<VendorDetailCubit>();
    final vendor = cubit.state.vendor;
    if (vendor == null) return;

    final saved = await context.push<Vendor>(Routes.vendorForm, extra: vendor);
    if (saved == null || !mounted) return;

    // What the form hands back is the server's own reading of the supplier it just stored — the
    // same bytes a re-read would return, a request earlier.
    cubit.show(saved);
  }

  Future<void> _toggleActive(BuildContext context) async {
    final cubit = context.read<VendorDetailCubit>();
    final vendor = cubit.state.vendor;
    if (vendor == null) return;

    if (vendor.isActive) {
      final confirmed = await showCustomDialog(
        context: context,
        title: 'تعطيل المورد؟',
        description:
            'لن يظهر «${vendor.name}» عند إنشاء أمر شراء، ويمكن تنشيطه في أي وقت. '
            'أوامر الشراء والشحنات السابقة لا تتغيّر.',
        confirmLabel: 'تعطيل',
        cancelLabel: 'إلغاء',
      );

      // Deliberately not a destructive dialog: nothing is being destroyed — the whole reason
      // this API has no delete route is that a supplier's history must survive — and a bin over
      // a reversible action is a lie.
      if (confirmed != true) return;
    }

    // Turning somebody back on gets no dialog. A confirmation for an action that costs nothing
    // is a tax on the common case.
    final failure = await cubit.setActive(isActive: !vendor.isActive);
    if (!context.mounted) return;

    if (failure != null) {
      context.showFailure(failure);

      return;
    }

    context.showSuccess(
      vendor.isActive
          ? 'تم تعطيل «${vendor.name}»'
          : 'تم تنشيط «${vendor.name}»',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VendorDetailCubit>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Always through here, so the back button and the app bar's arrow return the same thing.
        context.pop(_changes.result);
      },
      child: Scaffold(
        floatingActionButtonLocation: AppSpeedDial.location,
        appBar: AppBar(
          title: BlocBuilder<VendorDetailCubit, VendorDetailState>(
            // The name once it is known, so the bar stops saying something generic the moment
            // it can say something useful.
            builder: (context, state) =>
                Text(state.vendor?.name ?? 'تفاصيل المورد'),
          ),
        ),
        floatingActionButton: BlocBuilder<VendorDetailCubit, VendorDetailState>(
          builder: (context, state) {
            final vendor = state.vendor;
            if (vendor == null) return const SizedBox.shrink();

            return _Actions(
              vendor: vendor,
              onEdit: _edit,
              onToggleActive: _toggleActive,
            );
          },
        ),
        body: BlocConsumer<VendorDetailCubit, VendorDetailState>(
          // Every reading goes past here, whatever produced it — the form, the activation
          // toggle, a pull that picked up somebody else's change. What differs from the first
          // one is what the list behind is handed on the way out.
          listener: (context, state) => _changes.saw(state.vendor),
          builder: (context, state) {
            final vendor = state.vendor;

            if (vendor == null) {
              return switch (state) {
                VendorDetailFailure(:final failure) => _FailureView(
                  message: failure.message,
                  onRetry: cubit.load,
                ),
                _ => const Center(child: CircularProgressIndicator()),
              };
            }

            return RefreshIndicator(
              onRefresh: () => _reload(context),
              child: _Body(
                vendor: vendor,
                showPurchaseOrders: _maySeePurchaseOrders,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// What this screen can do, as data.
///
/// [AppSpeedDial] filters these by permission and collapses to a plain button when only one
/// survives, so a reader who may look at suppliers and not change them sees one button rather
/// than a dial with a single arm.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.vendor,
    required this.onEdit,
    required this.onToggleActive,
  });

  final Vendor vendor;
  final Future<void> Function(BuildContext context) onEdit;
  final Future<void> Function(BuildContext context) onToggleActive;

  @override
  Widget build(BuildContext context) {
    return AppSpeedDial(
      actions: [
        // **First, and this is where buying begins.** The form it opens has no supplier field:
        // naming the vendor by *which screen you are on* is what makes the wrong one
        // unnameable — the same reasoning «طلبية جديدة» follows on a customer.
        //
        // Absent for a deactivated supplier: this is somebody the shop has stopped buying from,
        // and turning them back on is one tap away on this same screen.
        if (vendor.isActive)
          AppAction(
            label: 'أمر شراء جديد',
            icon: AppIcons.purchaseOrders,
            tone: AppActionTone.primary,
            permission: AppPermission.managePurchaseOrders,
            onTap: (context) => context.push(
              Routes.newVendorPurchaseOrder(vendor.id),
              extra: vendor,
            ),
          ),
        AppAction(
          label: 'تعديل المورد',
          icon: AppIcons.edit,
          tone: AppActionTone.primary,
          permission: AppPermission.manageVendors,
          onTap: onEdit,
        ),
        AppAction(
          label: vendor.isActive ? 'تعطيل المورد' : 'تنشيط المورد',
          icon: vendor.isActive ? AppIcons.deactivate : AppIcons.activate,
          // Only the direction that takes something away wears the warning colour.
          tone: vendor.isActive ? AppActionTone.warning : AppActionTone.neutral,
          permission: AppPermission.manageVendors,
          onTap: onToggleActive,
        ),
        // Same place it sits on a customer's screen, and for the same reason: a note is not a
        // field on this record, so it belongs behind the button that lists what can be *done*
        // rather than in the body that says what the supplier *is*.
        AppAction(
          label: 'الملاحظات',
          icon: AppIcons.comments,
          // `vendors.view` — the permission that opened this screen. Writing a note about
          // somebody you may read about is not a further privilege.
          permission: AppPermission.viewVendors,
          onTap: (context) => context.push(
            Routes.vendorComments(vendor.id),
            extra: vendor.name,
          ),
        ),
        AppAction(
          label: 'سجل التعديلات',
          icon: AppIcons.history,
          // `logs.view`, not `vendors.view`, and that is the server's own line: a history shows
          // what *everyone* has done. Editing a supplier does not make somebody an auditor.
          permission: AppPermission.viewActivityLogs,
          onTap: (context) => context.push(
            Routes.activityLog(AuditSubject.vendor, vendor.id),
            extra: vendor.name,
          ),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.vendor, required this.showPurchaseOrders});

  final Vendor vendor;

  /// Absent, not disabled, for a reader without `purchase_orders.view` — a way in that opens a
  /// screen the server refuses is worse than no way in, which is what «أمر شراء جديد» already
  /// does in the actions menu.
  final bool showPurchaseOrders;

  @override
  Widget build(BuildContext context) {
    return ListView(
      // `always`, so pull-to-refresh works on a supplier short enough not to scroll.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 96.h),
      children: [
        _Identity(vendor: vendor),
        SizedBox(height: 14.h),
        // Above the contact details, because somebody opening a supplier in working hours asks
        // «أين طلبيتنا؟» more often than they ask for the phone number — which is one swipe away.
        if (showPurchaseOrders) ...[
          BlocBuilder<
            VendorPurchaseOrderCountsCubit,
            VendorPurchaseOrderCountsState
          >(
            builder: (context, state) => VendorPurchaseOrdersSection(
              vendorId: vendor.id,
              vendorName: vendor.name,
              state: state,
              onOpen: (filter) =>
                  context.push(Routes.purchaseOrdersFiltered, extra: filter),
            ),
          ),
          SizedBox(height: 14.h),
        ],
        _Section(
          title: 'معلومات الاتصال',
          child: Column(
            children: [
              _CopyRow(
                icon: AppIcons.phone,
                label: 'رقم الهاتف',
                value: vendor.phone,
                copiedMessage: 'تم نسخ رقم الهاتف',
              ),
              if (vendor.contactPerson case final person?) ...[
                Divider(height: 18.h),
                _Row(
                  icon: AppIcons.person,
                  label: 'الشخص المسؤول',
                  value: person,
                ),
              ],
              if (vendor.email case final email?) ...[
                Divider(height: 18.h),
                _CopyRow(
                  icon: AppIcons.email,
                  label: 'البريد الإلكتروني',
                  value: email,
                  copiedMessage: 'تم نسخ البريد الإلكتروني',
                ),
              ],
              if (vendor.address case final address?) ...[
                Divider(height: 18.h),
                _Row(icon: AppIcons.mapPin, label: 'العنوان', value: address),
              ],
            ],
          ),
        ),
        SizedBox(height: 14.h),
        _Section(
          title: 'السجل',
          child: Column(
            children: [
              _Row(
                icon: AppIcons.today,
                label: 'أُضيف في',
                value: _day(vendor.createdAt) ?? '—',
              ),
              Divider(height: 18.h),
              _Row(
                icon: AppIcons.history,
                label: 'آخر تعديل',
                value: _day(vendor.updatedAt) ?? '—',
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The day, in the reader's own zone. A supplier's record is read by date, never by minute.
  static String? _day(DateTime? at) => at?.dayLabel;
}

/// The name, and whether we still deal with them.
class _Identity extends StatelessWidget {
  const _Identity({required this.vendor});

  final Vendor vendor;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isActive = vendor.isActive;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Container(
            height: 52.w,
            width: 52.w,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              AppIcons.vendors,
              color: scheme.onPrimaryContainer,
              size: 26.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vendor.name,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? scheme.secondaryContainer
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: Text(
                    // Said in full rather than as a single word: «متوقف» alone reads as a
                    // problem with the supplier, when what it describes is our own decision.
                    isActive ? 'نتعامل معه' : 'توقّفنا عن التعامل معه',
                    style: context.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? scheme.onSecondaryContainer
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.primary,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18.sp, color: scheme.onSurfaceVariant),
        SizedBox(width: 10.w),
        Text(
          label,
          style: context.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// A row whose value is worth having on the clipboard — a phone number, an email.
class _CopyRow extends StatelessWidget {
  const _CopyRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.copiedMessage,
  });

  final IconData icon;
  final String label;
  final String value;
  final String copiedMessage;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return InkWell(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: value));
        if (context.mounted) context.showSuccess(copiedMessage);
      },
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child: Row(
          children: [
            Icon(icon, size: 18.sp, color: scheme.onSurfaceVariant),
            SizedBox(width: 10.w),
            Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              value,
              // Latin either way — a phone number and an email both read left to right.
              textDirection: TextDirection.ltr,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8.w),
            Icon(AppIcons.copy, size: 16.sp, color: scheme.outline),
          ],
        ),
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.error, size: 48.sp, color: context.colorScheme.error),
            SizedBox(height: 16.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 20.h),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: Icon(AppIcons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
