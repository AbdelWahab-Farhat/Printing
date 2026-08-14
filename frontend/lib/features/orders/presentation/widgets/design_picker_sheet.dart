import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/attachment_sheet.dart';
import 'package:dayaa/features/customers/models/customer_design.dart';
import 'package:dayaa/features/customers/models/design_rules.dart';
import 'package:dayaa/features/customers/presentation/viewmodel/customer_designs_cubit.dart';
import 'package:dayaa/features/customers/presentation/widgets/design_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Choosing the artwork an order is about to carry.
///
/// **Both ways in, one screen.** A repeat customer's design is already in their library and is
/// ticked; a new one is uploaded here — into the *library*, because the file is the customer's
/// property and every order after this one should be able to point at it too. What leaves this
/// sheet is a list of designs, never a file.
///
/// Reuses the library's own Cubit rather than repeating its upload queue: the retry on a
/// dropped connection, the one-at-a-time sending and the per-file progress are hard-won and
/// belong to one place.
///
/// Returns null when the user backs out — an ordinary ending, reported nowhere.
Future<List<CustomerDesign>?> showDesignPicker({
  required BuildContext context,
  required int customerId,
  required List<CustomerDesign> selected,
}) {
  return showModalBottomSheet<List<CustomerDesign>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (_) => BlocProvider<CustomerDesignsCubit>(
      create: (_) => sl<CustomerDesignsCubit>(param1: customerId)..load(),
      child: _DesignPicker(selected: selected),
    ),
  );
}

class _DesignPicker extends StatefulWidget {
  const _DesignPicker({required this.selected});

  final List<CustomerDesign> selected;

  @override
  State<_DesignPicker> createState() => _DesignPickerState();
}

class _DesignPickerState extends State<_DesignPicker> {
  /// Ids rather than models: the library reloads while this is open — an upload finishing is
  /// exactly that — and a set of objects would hold the version from before the reload.
  late Set<int> _chosen = {for (final design in widget.selected) design.id};

  /// What the library held last time it was read, so a design that appears after an upload can
  /// be told from one that was always there.
  Set<int>? _known;

  /// Anything that arrived while this sheet was open was uploaded from it, so it is what the
  /// user came here to pick. Ticking it saves the tap that only ever has one answer.
  void _tickWhatArrived(List<CustomerDesign> designs) {
    final ids = {for (final design in designs) design.id};
    final previous = _known;
    _known = ids;

    if (previous == null) return;

    final arrived = ids.difference(previous);
    if (arrived.isEmpty) return;

    // After the frame: this runs from a build, and setState during one is not allowed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _chosen = {..._chosen, ...arrived});
    });
  }

  Future<void> _upload() async {
    final cubit = context.read<CustomerDesignsCubit>();

    if ((cubit.state.designs?.length ?? 0) >= DesignRules.maxPerCustomer) {
      context.showError(
        'وصل هذا العميل إلى الحد الأقصى (${DesignRules.maxPerCustomer} تصميم). '
        'احذف تصميماً قديماً من شاشة العميل لإضافة جديد.',
      );

      return;
    }

    final source = await showAttachmentSheet(context: context, title: 'إضافة تصميم');
    if (source == null || !mounted) return;

    final files = await sl<AttachmentPicker>().pick(source);
    // Cancelling a picker is not a failure and nothing is said about it.
    if (files.isEmpty) return;

    await cubit.add(files);
  }

  void _confirm(List<CustomerDesign> library) {
    Navigator.of(context).pop([
      for (final design in library)
        if (_chosen.contains(design.id)) design,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerDesignsCubit, CustomerDesignsState>(
      builder: (context, state) {
        final library = state.designs;
        if (library != null) _tickWhatArrived(library);

        return Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: context.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Text(
                    'اختيار التصاميم',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'مكتبة العميل',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Flexible(
                child: switch (state) {
                  CustomerDesignsLoading() => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  CustomerDesignsFailure(:final failure) => _Message(text: failure.message),
                  CustomerDesignsLoaded(:final designs, :final uploads) =>
                    designs.isEmpty && uploads.isEmpty
                        ? const _Message(
                            text: 'لا توجد تصاميم لهذا العميل بعد — ارفع الأول من الزر تحت',
                          )
                        : ListView(
                            shrinkWrap: true,
                            children: [
                              for (final upload in uploads)
                                _UploadRow(upload: upload),
                              for (final design in designs)
                                _DesignRow(
                                  design: design,
                                  isChosen: _chosen.contains(design.id),
                                  onTap: () => setState(() {
                                    _chosen.contains(design.id)
                                        ? _chosen.remove(design.id)
                                        : _chosen.add(design.id);
                                  }),
                                ),
                            ],
                          ),
                },
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: AppButton.outlined(
                      label: 'رفع تصميم',
                      icon: AppIcons.add,
                      onPressed: _upload,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: AppButton(
                      label: 'تم (${_chosen.length})',
                      // Nothing chosen is a legitimate answer — it is how somebody undoes a
                      // selection they made a moment ago and leaves the field empty.
                      onPressed: () => _confirm(library ?? const []),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// One design in the library, ticked or not.
class _DesignRow extends StatelessWidget {
  const _DesignRow({required this.design, required this.isChosen, required this.onTap});

  final CustomerDesign design;
  final bool isChosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: isChosen ? scheme.primaryContainer : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            child: Row(
              children: [
                // The file itself, not a glyph standing for it: two versions of one logo are
                // «الشعار الأزرق» and «الشعار الأزرق — نسخة معدّلة», and told apart by their
                // names alone they are two identical rows of text.
                DesignThumbnail(design: design, size: 44),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    design.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isChosen ? scheme.onPrimaryContainer : scheme.onSurface,
                    ),
                  ),
                ),
                if (isChosen)
                  Icon(AppIcons.activate, size: 20.sp, color: scheme.onPrimaryContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A file on its way into the library. It cannot be chosen until it has arrived and has an id.
class _UploadRow extends StatelessWidget {
  const _UploadRow({required this.upload});

  final DesignUpload upload;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18.w,
              height: 18.w,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                value: upload.hasFailed ? 0 : upload.progress,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                upload.hasFailed
                    ? '${upload.file.name} — ${upload.failure!.message}'
                    : upload.file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: upload.hasFailed ? scheme.error : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 8.w),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
