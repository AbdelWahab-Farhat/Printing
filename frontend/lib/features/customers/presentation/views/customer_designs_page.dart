import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/app_speed_dial.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/core/widgets/attachment_sheet.dart';
import 'package:dayaa/features/customers/models/customer_design.dart';
import 'package:dayaa/features/customers/models/design_rules.dart';
import 'package:dayaa/features/customers/presentation/viewmodel/customer_designs_cubit.dart';
import 'package:dayaa/features/customers/presentation/widgets/design_thumbnail.dart';
import 'package:dayaa/features/customers/presentation/widgets/design_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// A customer's library of artwork.
///
/// **Designs belong to the customer, not to an order.** That is the whole point of this screen:
/// the file is sent once, and every order after it is placed by choosing from here rather than
/// by finding the same PDF in somebody's WhatsApp again.
///
/// Reading it needs `customers.view`; adding and removing need `customers.manage`, the same
/// pair that governs the customer themselves. A separate permission would only earn its place
/// the day an account appears that needs one and not the other.
class CustomerDesignsPage extends StatelessWidget {
  const CustomerDesignsPage({required this.customerId, this.customerName, super.key});

  final int customerId;

  /// Whose library this is. Passed from the customer's screen so the bar can say it without a
  /// second request; null on a cold deep link, where the heading stands alone.
  final String? customerName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CustomerDesignsCubit>(
      create: (_) => sl<CustomerDesignsCubit>(param1: customerId)..load(),
      child: _DesignsView(customerName: customerName),
    );
  }
}

class _DesignsView extends StatelessWidget {
  const _DesignsView({this.customerName});

  final String? customerName;

  /// Asks where the file is coming from, opens that picker, and queues whatever came back.
  ///
  /// Three awaits with a `mounted` check between each, because every one of them is a screen
  /// the user can sit in for a minute — the camera especially — and this one can be popped
  /// while they are there.
  Future<void> _addDesign(BuildContext context) async {
    final cubit = context.read<CustomerDesignsCubit>();

    // The server refuses past fifty — see `media.customer_designs.max_per_customer` — and it
    // refuses *after* the bytes have arrived. Saying so before the picker opens saves an
    // upload that was never going to be kept.
    if ((cubit.state.designs?.length ?? 0) >= DesignRules.maxPerCustomer) {
      context.showError(
        'وصل هذا العميل إلى الحد الأقصى (${DesignRules.maxPerCustomer} تصميم). '
        'احذف تصميماً قديماً لإضافة جديد.',
      );

      return;
    }

    final source = await showAttachmentSheet(context: context);
    if (source == null || !context.mounted) return;

    final files = await sl<AttachmentPicker>().pick(source);
    // Cancelling a picker is not a failure and nothing is said about it.
    if (files.isEmpty) return;

    await cubit.add(files);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CustomerDesignsCubit>();

    return BlocBuilder<CustomerDesignsCubit, CustomerDesignsState>(
      builder: (context, state) => PopScope(
        // Leaving mid-upload cancels it silently — the request dies with the Cubit. Asking
        // first is the difference between "I cancelled it" and "it just did not work".
        canPop: !state.isWorking,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;

          final leave = await showCustomDialog(
            context: context,
            title: 'الرفع لم ينتهِ بعد',
            description: 'هناك ملف قيد الرفع. الخروج الآن سيلغيه.',
            confirmLabel: 'خروج',
            cancelLabel: 'بقاء',
            severity: DialogSeverity.warning,
          );

          if ((leave ?? false) && context.mounted) context.pop();
        },
        child: Scaffold(
          floatingActionButtonLocation: AppSpeedDial.location,
          appBar: AppBar(
            title: Column(
              children: [
                const Text('التصاميم'),
                if (customerName != null)
                  Text(
                    customerName!,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          floatingActionButton: AppSpeedDial(
            actions: [
              AppAction(
                label: 'إضافة تصميم',
                icon: AppIcons.add,
                tone: AppActionTone.primary,
                permission: AppPermission.manageCustomers,
                onTap: _addDesign,
              ),
            ],
          ),
          body: switch (state) {
            CustomerDesignsLoading() => const Center(child: CircularProgressIndicator()),
            CustomerDesignsFailure(:final failure) => _FailureView(
              message: failure.message,
              onRetry: cubit.load,
            ),
            CustomerDesignsLoaded() => RefreshIndicator(
              onRefresh: cubit.load,
              child: _Library(state: state),
            ),
          },
        ),
      ),
    );
  }
}

class _Library extends StatelessWidget {
  const _Library({required this.state});

  final CustomerDesignsLoaded state;

  @override
  Widget build(BuildContext context) {
    final isEmpty = state.designs.isEmpty && state.uploads.isEmpty;

    return CustomScrollView(
      // `always`, so pull-to-refresh works on an empty library too — a short page that cannot
      // scroll is a page that cannot be refreshed.
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (state.uploads.isNotEmpty)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
            sliver: SliverList.separated(
              itemCount: state.uploads.length,
              separatorBuilder: (context, index) => SizedBox(height: 8.h),
              itemBuilder: (context, index) => _UploadRow(
                key: ValueKey(state.uploads[index].id),
                upload: state.uploads[index],
              ),
            ),
          ),
        if (isEmpty)
          const SliverFillRemaining(hasScrollBody: false, child: _EmptyLibrary())
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 96.h),
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12.h,
                crossAxisSpacing: 12.w,
                // Slightly taller than square: the thumbnail is the square, and the name lives
                // under it rather than over the artwork, which is the one thing on the tile
                // that must not be covered.
                childAspectRatio: 0.78,
              ),
              itemCount: state.designs.length,
              itemBuilder: (context, index) {
                final design = state.designs[index];

                return _DesignTile(
                  key: ValueKey(design.id),
                  design: design,
                  isBusy: state.busy.contains(design.id),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// One file on its way up: what it is called, how far it has got, and what to do if it stopped.
class _UploadRow extends StatelessWidget {
  const _UploadRow({required this.upload, super.key});

  final DesignUpload upload;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CustomerDesignsCubit>();
    final scheme = context.colorScheme;
    final failed = upload.hasFailed;

    return Container(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
      decoration: BoxDecoration(
        color: failed ? scheme.errorContainer : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Icon(
            failed ? AppIcons.error : AppIcons.designs,
            size: 20.sp,
            color: failed ? scheme.onErrorContainer : scheme.primary,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  upload.file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: failed ? scheme.onErrorContainer : null,
                  ),
                ),
                SizedBox(height: 6.h),
                if (failed)
                  Text(
                    upload.failure!.message,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onErrorContainer,
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      // Indeterminate until the first byte is acknowledged, so a queued file
                      // does not sit at a convincing-looking 0%.
                      value: upload.isUploading && upload.sent > 0 ? upload.progress : null,
                      minHeight: 5.h,
                    ),
                  ),
              ],
            ),
          ),
          if (failed) ...[
            SizedBox(width: 6.w),
            IconButton(
              tooltip: 'إعادة المحاولة',
              // Free to offer: the server answers a file it already holds with the design it
              // already made, so a retry after a dropped connection cannot make a second copy.
              onPressed: () => unawaited(cubit.retry(upload.id)),
              icon: Icon(AppIcons.refresh, color: scheme.onErrorContainer),
            ),
            IconButton(
              tooltip: 'إزالة',
              onPressed: () => cubit.dismiss(upload.id),
              icon: Icon(AppIcons.close, color: scheme.onErrorContainer),
            ),
          ],
        ],
      ),
    );
  }
}

/// One design: its artwork, its name, and everything that can be done to it.
class _DesignTile extends StatelessWidget {
  const _DesignTile({required this.design, required this.isBusy, super.key});

  final CustomerDesign design;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14.r),
                child: DesignThumbnail(design: design, radius: 0),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14.r),
                  onTap: () => unawaited(showDesign(context, design)),
                  onLongPress: () => unawaited(_showOptions(context, design)),
                ),
              ),
              if (isBusy)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.scrim.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              // Bottom-left in Arabic reading order, and out of the way of the artwork.
              PositionedDirectional(
                bottom: 6.h,
                end: 6.w,
                child: _OptionsButton(design: design),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          design.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 2.h),
        Text(
          // The server's own name for the kind, so a format this build has never heard of still
          // says what it is. The size beside it is what tells a 40 KB placeholder from the real
          // print file at a glance.
          [design.kindLabel, ?design.sizeLabel].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _OptionsButton extends StatelessWidget {
  const _OptionsButton({required this.design});

  final CustomerDesign design;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Tooltip(
      // Named, so a screen reader has something to announce and a test has something to find —
      // this is the only way into rename and delete that does not require knowing about the
      // long press.
      message: 'خيارات التصميم',
      child: Material(
        color: scheme.surface.withValues(alpha: 0.85),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          // The same sheet a long press opens. A long press alone is a gesture nobody
          // discovers, and this screen's only destructive action lives behind it.
          onTap: () => unawaited(_showOptions(context, design)),
          child: Padding(
            padding: EdgeInsets.all(6.w),
            child: Icon(AppIcons.more, size: 18.sp, color: scheme.onSurface),
          ),
        ),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.designs, size: 56.sp, color: scheme.outline),
            SizedBox(height: 16.h),
            Text(
              'لا توجد تصاميم لهذا العميل',
              style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8.h),
            Text(
              // Says what to do next, and what the thing is for. An empty screen that only says
              // it is empty leaves somebody wondering whether it is broken.
              'أضف صور أو ملفات PDF لما يُطبع على أكياس هذا العميل، '
              'لتختار منها مباشرة عند إنشاء الطلبات.',
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
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

// ─────────────────────────────────────────────────────────────────────────────
// What a design can be told to do.

// Viewing, saving and opening a design live in `design_viewer.dart`: an order is printed from
// the same file this library holds, and that screen shows it too.

Future<void> _showOptions(BuildContext context, CustomerDesign design) async {
  final cubit = context.read<CustomerDesignsCubit>();
  final mayManage = sl<Session>().can(AppPermission.manageCustomers);

  final choice = await showModalBottomSheet<_DesignAction>(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 8.h),
          ListTile(
            title: Text(
              design.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              [design.kindLabel, ?design.sizeLabel, ?design.dimensionsLabel].join(' · '),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(AppIcons.openExternal),
            title: const Text('فتح الملف'),
            onTap: () => Navigator.of(sheetContext).pop(_DesignAction.open),
          ),
          ListTile(
            leading: Icon(AppIcons.download),
            title: const Text('تحميل'),
            onTap: () => Navigator.of(sheetContext).pop(_DesignAction.save),
          ),
          // Hidden, not disabled, for somebody who may only read: a greyed-out «حذف» advertises
          // a job that is not theirs. The server refuses it either way.
          if (mayManage) ...[
            ListTile(
              leading: Icon(AppIcons.edit),
              title: const Text('إعادة التسمية'),
              onTap: () => Navigator.of(sheetContext).pop(_DesignAction.rename),
            ),
            ListTile(
              leading: Icon(AppIcons.delete, color: context.colorScheme.error),
              title: Text('حذف', style: TextStyle(color: context.colorScheme.error)),
              onTap: () => Navigator.of(sheetContext).pop(_DesignAction.delete),
            ),
          ],
          SizedBox(height: 8.h),
        ],
      ),
    ),
  );

  if (choice == null || !context.mounted) return;

  switch (choice) {
    case _DesignAction.open:
      await showDesign(context, design);
    case _DesignAction.save:
      await saveDesign(context, design);
    case _DesignAction.rename:
      await _rename(context, cubit, design);
    case _DesignAction.delete:
      await _delete(context, cubit, design);
  }
}

enum _DesignAction { open, save, rename, delete }

Future<void> _rename(
  BuildContext context,
  CustomerDesignsCubit cubit,
  CustomerDesign design,
) async {
  final result = await showDialog<({String label, String? notes})>(
    context: context,
    builder: (context) => _RenameDialog(design: design),
  );
  if (result == null) return;

  final failure = await cubit.rename(design.id, label: result.label, notes: result.notes);
  if (!context.mounted) return;

  if (failure == null) {
    context.showSuccess('تم تحديث التصميم');
  } else {
    context.showFailure(failure);
  }
}

Future<void> _delete(
  BuildContext context,
  CustomerDesignsCubit cubit,
  CustomerDesign design,
) async {
  final confirmed = await showCustomDialog(
    context: context,
    title: 'حذف التصميم؟',
    // Deliberately not `showDestructiveDialog`, which paints a bin on the button. The file is
    // not destroyed: the row is hidden and the stored object stays, so an order printed last
    // year can still show what was printed. A bin here would be a lie.
    description:
        'سيختفي «${design.label}» من قائمة تصاميم العميل. '
        'الطلبات السابقة التي استُخدم فيها تبقى كما هي.',
    confirmLabel: 'حذف',
    cancelLabel: 'إلغاء',
    severity: DialogSeverity.warning,
  );
  if (confirmed != true) return;

  final failure = await cubit.remove(design.id);
  if (!context.mounted) return;

  if (failure == null) {
    context.showSuccess('تم حذف التصميم');
  } else {
    context.showFailure(failure);
  }
}

/// The name, and the note under it.
///
/// **The file is not here, and there is no button to replace it.** An order points at a design,
/// so swapping the bytes under a stable id would change what an order placed last year says
/// was printed. A new version is a new upload.
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.design});

  final CustomerDesign design;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _label = TextEditingController(text: widget.design.label);
  late final TextEditingController _notes = TextEditingController(
    text: widget.design.notes ?? '',
  );

  @override
  void dispose() {
    _label.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إعادة التسمية'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            controller: _label,
            label: 'اسم التصميم',
            autofocus: true,
            maxLength: 255,
          ),
          SizedBox(height: 12.h),
          AppTextField(
            controller: _notes,
            label: 'ملاحظات',
            maxLines: 3,
            maxLength: 2000,
            textInputAction: TextInputAction.newline,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
        TextButton(
          onPressed: () {
            final label = _label.text.trim();
            // An empty name is refused here rather than sent: the server would fall back to the
            // filename, which is not what somebody clearing the field asked for.
            if (label.isEmpty) return;

            Navigator.of(context).pop((label: label, notes: _notes.text.trim()));
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
