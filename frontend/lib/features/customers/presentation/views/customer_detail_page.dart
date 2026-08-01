import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/permissions/app_permission.dart';
import 'package:printing/core/router/app_router.dart';
import 'package:printing/core/session/session.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/widgets/app_button.dart';
import 'package:printing/core/widgets/app_dialog.dart';
import 'package:printing/features/customers/models/customer.dart';
import 'package:printing/features/customers/presentation/viewmodel/customer_detail_cubit.dart';

/// Everything about one customer, and the things staff do to them.
///
/// Reached by tapping a row in the list — the slot was reserved for it: `CustomerCard.onTap`
/// has existed and been passed `null` since the list was written.
///
/// **The screen reads; the speed dial writes.** Editing opens the same form that registers a
/// customer, because the expensive parts of that form — the shop rows, the map picker, the
/// per-row error mapping — should exist once. Deactivating is its own endpoint and its own
/// action, which is what makes it impossible for saving an edit to switch somebody back on by
/// accident.
class CustomerDetailPage extends StatelessWidget {
  const CustomerDetailPage({required this.customerId, super.key});

  final int customerId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CustomerDetailCubit>(
      create: (_) => sl<CustomerDetailCubit>(param1: customerId)..load(),
      child: const _CustomerDetailView(),
    );
  }
}

class _CustomerDetailView extends StatelessWidget {
  const _CustomerDetailView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CustomerDetailCubit>();

    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<CustomerDetailCubit, CustomerDetailState>(
          // The name once it is known, so the bar stops saying something generic the moment it
          // can say something useful.
          builder: (context, state) => Text(state.customer?.name ?? 'تفاصيل العميل'),
        ),
      ),
      floatingActionButton: BlocBuilder<CustomerDetailCubit, CustomerDetailState>(
        builder: (context, state) {
          final customer = state.customer;
          if (customer == null) return const SizedBox.shrink();

          return _Actions(customer: customer);
        },
      ),
      body: BlocConsumer<CustomerDetailCubit, CustomerDetailState>(
        listener: (context, state) {
          // Only when there is still a page underneath. With nothing to fall back to the body
          // already shows the failure, and a snackbar over it would say the same thing twice.
          if (state case CustomerDetailFailure(:final failure)) {
            if (state.customer != null) context.showFailure(failure);
          }
        },
        builder: (context, state) => switch (state) {
          CustomerDetailLoading() => const Center(child: CircularProgressIndicator()),
          CustomerDetailFailure(:final failure) => _FailureView(
            message: failure.message,
            onRetry: cubit.load,
          ),
          _ => RefreshIndicator(
            onRefresh: cubit.load,
            child: _Body(customer: state.customer!, isChanging: state.isChanging),
          ),
        },
      ),
    );
  }
}

/// The speed dial: the two or three things this screen can do.
///
/// A dial rather than an overflow menu, because these are the actions staff came here for —
/// a glyph in the corner of the app bar is where an action goes to be forgotten. It is absent
/// entirely without `customers.manage`: an empty dial is furniture.
class _Actions extends StatelessWidget {
  const _Actions({required this.customer});

  final Customer customer;

  Future<void> _edit(BuildContext context) async {
    final cubit = context.read<CustomerDetailCubit>();

    await context.push(Routes.editCustomer(customer.id), extra: customer);

    // Re-read rather than trusting what the form returned: the same seconds may have carried
    // somebody else's change, and this screen is the one that has to be right.
    await cubit.load();
  }

  Future<void> _toggleActive(BuildContext context) async {
    final cubit = context.read<CustomerDetailCubit>();

    if (customer.isActive) {
      final confirmed = await showCustomDialog(
        context: context,
        title: 'تعطيل العميل؟',
        description:
            'لن يظهر «${customer.name}» ضمن العملاء النشطين، ويمكن تنشيطه في أي وقت. '
            'بياناته وطلبياته السابقة لا تُحذف.',
        confirmLabel: 'تعطيل',
        cancelLabel: 'إلغاء',
      );

      // Deliberately not `showDestructiveDialog`: that one paints the button in the error
      // colour and stamps a bin on it. Nothing is being destroyed here — the whole reason this
      // API has no delete route is that a customer's history must survive — and a bin over a
      // reversible action is a lie.
      if (confirmed != true) return;
    }

    // Turning somebody back on gets no dialog. A confirmation for an action that costs nothing
    // is a tax on the common case.
    await cubit.setActive(isActive: !customer.isActive);
  }

  @override
  Widget build(BuildContext context) {
    if (!sl<Session>().can(AppPermission.manageCustomers)) return const SizedBox.shrink();

    final scheme = context.colorScheme;

    return SpeedDial(
      icon: AppIcons.more,
      activeIcon: AppIcons.close,
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      overlayColor: scheme.scrim,
      overlayOpacity: 0.35,
      spacing: 10,
      spaceBetweenChildren: 8,
      children: [
        SpeedDialChild(
          child: Icon(AppIcons.designs),
          label: 'التصاميم',
          backgroundColor: scheme.secondaryContainer,
          foregroundColor: scheme.onSecondaryContainer,
          onTap: () => unawaited(context.push(Routes.customerDesigns(customer.id))),
        ),
        SpeedDialChild(
          child: Icon(customer.isActive ? AppIcons.deactivate : AppIcons.activate),
          label: customer.isActive ? 'تعطيل العميل' : 'تنشيط العميل',
          // The one action that changes who can see this customer wears the warning colour —
          // and only in the direction that takes something away.
          backgroundColor: customer.isActive ? scheme.errorContainer : scheme.tertiaryContainer,
          foregroundColor: customer.isActive
              ? scheme.onErrorContainer
              : scheme.onTertiaryContainer,
          onTap: () => unawaited(_toggleActive(context)),
        ),
        SpeedDialChild(
          child: Icon(AppIcons.edit),
          label: 'تعديل العميل',
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          onTap: () => unawaited(_edit(context)),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.customer, required this.isChanging});

  final Customer customer;
  final bool isChanging;

  @override
  Widget build(BuildContext context) {
    final shops = customer.shops;

    return ListView(
      // `always`, so pull-to-refresh works on a customer with no shops — a short page that
      // cannot scroll is a page that cannot be refreshed.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 96.h),
      children: [
        _Identity(customer: customer),
        SizedBox(height: 14.h),

        _StatusBand(customer: customer, isChanging: isChanging),
        SizedBox(height: 14.h),

        _Section(
          title: 'معلومات الاتصال',
          child: Column(
            children: [
              _CopyRow(
                icon: AppIcons.phone,
                label: 'رقم الهاتف',
                value: customer.phone,
                copiedMessage: 'تم نسخ رقم الهاتف',
              ),
              Divider(height: 18.h),
              _CopyRow(
                icon: AppIcons.tag,
                label: 'رمز العميل',
                value: customer.code,
                copiedMessage: 'تم نسخ رمز العميل',
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),

        // Absent, not empty, when the API did not load them — «لا توجد محلات» about a customer
        // whose shops were simply not requested is a lie the model already refuses to tell.
        if (shops != null) _Shops(shops: shops),

        SizedBox(height: 14.h),
        _Meta(customer: customer),
      ],
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isActive = customer.isActive;

    return Row(
      children: [
        CircleAvatar(
          radius: 30.r,
          backgroundColor: isActive ? scheme.primaryContainer : scheme.surfaceContainerHigh,
          child: Text(
            // The same first letter the list card shows, so the two read as the same person.
            customer.name.characters.firstOrNull ?? '؟',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: isActive ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customer.name,
                style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4.h),
              Text(
                customer.code,
                textDirection: TextDirection.ltr,
                style: context.textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Whether this customer is being sold to — the one fact that changes what everything below it
/// means, so it is the only loud thing on the screen.
class _StatusBand extends StatelessWidget {
  const _StatusBand({required this.customer, required this.isChanging});

  final Customer customer;
  final bool isChanging;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isActive = customer.isActive;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isActive ? scheme.surfaceContainerLow : scheme.errorContainer,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? AppIcons.activate : AppIcons.deactivate,
            size: 20.sp,
            color: isActive ? scheme.primary : scheme.onErrorContainer,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              isActive
                  ? 'عميل نشِط'
                  : 'هذا العميل موقوف — بياناته وطلبياته السابقة محفوظة، ويمكن تنشيطه في أي وقت.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: isActive ? scheme.onSurface : scheme.onErrorContainer,
              ),
            ),
          ),
          // The wait lives here rather than on the dial, which cannot hold a spinner. The band
          // keeps its height: only the trailing slot changes.
          if (isChanging) ...[
            SizedBox(width: 10.w),
            SizedBox(
              height: 18.h,
              width: 18.h,
              child: const CircularProgressIndicator(strokeWidth: 2.2),
            ),
          ],
        ],
      ),
    );
  }
}

class _Shops extends StatelessWidget {
  const _Shops({required this.shops});

  final List<CustomerShop> shops;

  @override
  Widget build(BuildContext context) {
    // The count is in the heading because «المحلات» over nothing and «المحلات» over three cards
    // are different facts, and only one of them needs reading.
    return _Section(
      title: shops.isEmpty ? 'المحلات' : 'المحلات (${shops.length})',
      child: shops.isEmpty
          ? Text(
              'لا توجد محلات مسجّلة لهذا العميل',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            )
          : Column(
              children: [
                for (var index = 0; index < shops.length; index++) ...[
                  if (index > 0) Divider(height: 20.h),
                  _ShopRow(shop: shops[index]),
                ],
              ],
            ),
    );
  }
}

class _ShopRow extends StatelessWidget {
  const _ShopRow({required this.shop});

  final CustomerShop shop;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          shop.name,
          style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (shop.hasPin) ...[
          SizedBox(height: 6.h),
          _CopyRow(
            icon: AppIcons.mapPin,
            label: 'الموقع',
            value:
                '${shop.latitude!.toStringAsFixed(6)}, ${shop.longitude!.toStringAsFixed(6)}',
            copiedMessage: 'تم نسخ الإحداثيات',
            // No mini-map per row, deliberately: one FlutterMap per shop is one tile download
            // per shop, in the one place on this screen that repeats.
          ),
        ],
        if (shop.pageUrl case final url? when url.isNotEmpty) ...[
          SizedBox(height: 6.h),
          _CopyRow(
            icon: AppIcons.tag,
            label: 'رابط الصفحة',
            value: url,
            copiedMessage: 'تم نسخ الرابط',
          ),
        ],
        if (!shop.hasPin) ...[
          SizedBox(height: 6.h),
          Text(
            // Shops recorded before the map picker existed. Saying so is what gets it fixed.
            'لا يوجد موقع على الخريطة',
            style: context.textTheme.bodySmall?.copyWith(color: scheme.tertiary),
          ),
        ],
      ],
    );
  }
}

/// A label, a value, and a way to get the value out of the app.
///
/// Copy rather than "call" or "open": there is no `url_launcher` in this project, and a row that
/// looks tappable and does nothing is worse than one that plainly copies.
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
      onTap: () {
        unawaited(Clipboard.setData(ClipboardData(text: value)));
        context.showSuccess(copiedMessage);
      },
      borderRadius: BorderRadius.circular(10.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          children: [
            Icon(icon, size: 18.sp, color: scheme.onSurfaceVariant),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value,
                    // Latin runs — a phone number, a code, coordinates, a URL — read
                    // left-to-right even here.
                    textDirection: TextDirection.ltr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Icon(AppIcons.copy, size: 16.sp, color: scheme.outline),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final created = customer.createdAt;
    if (created == null) return const SizedBox.shrink();

    return Text(
      'أُضيف في ${created.year}/${created.month}/${created.day}',
      textAlign: TextAlign.center,
      style: context.textTheme.bodySmall?.copyWith(
        color: context.colorScheme.onSurfaceVariant,
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
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: child,
        ),
      ],
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
            AppButton.outlined(
              label: 'إعادة المحاولة',
              icon: AppIcons.refresh,
              onPressed: () => unawaited(onRetry()),
            ),
          ],
        ),
      ),
    );
  }
}
