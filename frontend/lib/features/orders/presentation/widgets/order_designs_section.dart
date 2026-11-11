import 'dart:async';

import 'package:dayaa/core/print_colors/print_color.dart';
import 'package:dayaa/core/print_colors/print_colors_editor.dart';
import 'package:dayaa/core/print_colors/print_colors_view.dart';
import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/customers/presentation/widgets/design_thumbnail.dart';
import 'package:dayaa/features/customers/presentation/widgets/design_viewer.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The artwork conversation, version by version — and the three things staff do to it.
///
/// **What is printed now comes first, and only that is open** (2026-10-28). A corrected
/// version used to sit beside the draft it replaced, both «مقترح», and whoever stood at the press
/// could not tell which one to print. Now the current versions — see
/// [OrderDesignVersions.current] — are drawn on top, outlined and marked «الحالية», and
/// everything they replaced folds under «النسخ السابقة» marked «قديمة · لا تُطبع». Folded, not
/// gone: a replaced version is still the record of what the customer was shown, and still
/// downloadable.
///
/// Newest first inside each group: the version under discussion is the one staff need, and it
/// is the one the server puts first.
///
/// A rejected version keeps the sentence it was turned down for. That is the reason versions
/// are rows in the first place: «لم يعجبه التصميم» is only useful if it says what about it.
///
/// **Approving is here rather than on the move screen, and that is the point of the split.**
/// Adding a version is not a status change — the order sits in «قيد التصميم» while versions
/// come and go — and approving one is what *unlocks* printing rather than being a step of its
/// own. Both stay available for as long as the order is open, so the artwork can be corrected
/// whenever, without pretending to move the order to do it.
///
/// **Looking at the artwork needs no permission and no callback.** Tapping a version opens the
/// file full screen, and the button beside it saves a copy to the phone — both read the same
/// signed link the row already carries, so anyone who may see the order may see what is being
/// printed on it. Judging one is the part that is gated.
///
/// Every *action* callback is null for somebody without `orders.designs.manage`, and then this
/// section reads.
class OrderDesignsSection extends StatefulWidget {
  const OrderDesignsSection({
    required this.designs,
    this.onAdd,
    this.onApprove,
    this.onReject,
    this.onEditColors,
    this.isWorking = false,
    this.colorsRequired = false,
    super.key,
  });

  final List<OrderDesign> designs;

  /// The order goes through our press, so every version it may print needs complete colours
  /// before «قيد الطباعة» (PRINT-COLORS.md §9). A version without them says so in red, and the
  /// colours sheet refuses an empty list.
  final bool colorsRequired;

  /// Proposes another version. Null when the order is closed or the user may not.
  final Future<void> Function()? onAdd;

  final Future<void> Function(OrderDesign design)? onApprove;

  /// Given the sentence the version was turned down for — the server insists on one.
  final Future<void> Function(OrderDesign design, String reason)? onReject;

  /// Corrects one version's print colors for this order alone. Null when the order no longer
  /// accepts artwork — the colors lock with it — or the user may not.
  final Future<void> Function(OrderDesign design, List<PrintColor> colors)? onEditColors;

  /// Something is in flight. The buttons stop accepting a second tap; nothing else changes,
  /// because everything else on screen is still true.
  final bool isWorking;

  @override
  State<OrderDesignsSection> createState() => _OrderDesignsSectionState();
}

class _OrderDesignsSectionState extends State<OrderDesignsSection> {
  /// Folded on every visit: the screen opens on what is printed now.
  bool _showPrevious = false;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final designs = widget.designs;
    final current = designs.current;
    final previous = designs.previous;

    // What replaced the folded versions, for «استُبدلت بنسخة ٣». The newest of the current ones:
    // when two faces were attached together, it is the pair that replaced the draft.
    final newestCurrent = current.isEmpty
        ? null
        : current.map((version) => version.version).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (designs.isEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Text(
              'لا توجد نسخة من التصميم بعد',
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        // Every version turned down: nothing is current, so nothing is folded either — the
        // rejections are the whole conversation so far, each with its reason.
        if (current.isEmpty)
          for (final design in designs) _version(design, _Role.plain)
        else ...[
          for (final design in current) _version(design, _Role.current),
          if (previous.isNotEmpty) ...[
            _PreviousToggle(
              count: previous.length,
              isOpen: _showPrevious,
              onTap: () => setState(() => _showPrevious = !_showPrevious),
            ),
            if (_showPrevious)
              for (final design in previous)
                _version(design, _Role.previous, replacedBy: newestCurrent),
          ],
        ],
        if (widget.onAdd != null) ...[
          SizedBox(height: 4.h),
          AppButton.tonal(
            label: designs.isEmpty ? 'إضافة تصميم' : 'إضافة نسخة',
            icon: AppIcons.designs,
            onPressed: widget.isWorking ? null : widget.onAdd,
          ),
        ],
      ],
    );
  }

  Widget _version(OrderDesign design, _Role role, {int? replacedBy}) => _VersionCard(
    design: design,
    role: role,
    replacedBy: replacedBy,
    onApprove: widget.onApprove,
    onReject: widget.onReject,
    onEditColors: widget.onEditColors,
    isWorking: widget.isWorking,
    colorsRequired: widget.colorsRequired,
  );
}

/// Where a version sits in the conversation, which is what decides how loudly it is drawn.
enum _Role {
  /// What is printed now — outlined, marked «الحالية».
  current,

  /// Replaced or rejected — folded, dimmed.
  previous,

  /// Nothing is current (every version was rejected), so nothing is ranked.
  plain,
}

/// One version: the artwork, its number and verdict, and — while it waits — the two buttons.
class _VersionCard extends StatelessWidget {
  const _VersionCard({
    required this.design,
    required this.role,
    required this.replacedBy,
    required this.onApprove,
    required this.onReject,
    required this.onEditColors,
    required this.isWorking,
    this.colorsRequired = false,
  });

  final OrderDesign design;
  final _Role role;

  /// See [OrderDesignsSection.colorsRequired].
  final bool colorsRequired;

  /// A version the press may still print, whose colours are not yet what it needs.
  bool get _colorsMissing =>
      colorsRequired && !design.isRejected && !PrintColor.listIsComplete(design.printColors);

  /// The version that replaced this one. Null unless this is a [_Role.previous] that was not
  /// rejected — a rejection says its own reason instead.
  final int? replacedBy;

  final Future<void> Function(OrderDesign design)? onApprove;
  final Future<void> Function(OrderDesign design, String reason)? onReject;
  final Future<void> Function(OrderDesign design, List<PrintColor> colors)? onEditColors;
  final bool isWorking;

  bool get _isCurrent => role == _Role.current;

  /// Replaced rather than turned down — the one that needs «لا تُطبع» said out loud, because
  /// nothing else on it says it was ever wrong.
  bool get _isReplaced => role == _Role.previous && !design.isRejected;

  Future<void> _reject(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const _RejectionDialog(),
    );

    if (reason == null) return;

    await onReject?.call(design, reason);
  }

  Future<void> _editColors(BuildContext context) async {
    final colors = await showPrintColorsSheet(
      context: context,
      initial: design.printColors,
      required: colorsRequired,
    );

    if (colors == null) return;

    await onEditColors?.call(design, colors);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final quiet = role == _Role.previous;

    final statusColor = _isReplaced
        ? scheme.warn
        : design.isApproved
        ? scheme.tertiary
        : design.isRejected
        ? scheme.error
        : scheme.onSurfaceVariant;

    final border = switch (role) {
      _Role.current => design.isApproved ? scheme.tertiary : scheme.primary,
      _Role.plain => design.isApproved ? scheme.tertiary : Colors.transparent,
      _Role.previous => Colors.transparent,
    };

    final subtitle = [
      if (_isReplaced && replacedBy != null)
        'استُبدلت بنسخة $replacedBy'
      else if (_isCurrent) ...[
        design.statusLabel,
        if (design.createdAt case final at?) at.dayLabel,
      ],
    ].join(' · ');

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: quiet ? 0.3 : 0.5),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: border, width: _isCurrent ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // The artwork itself, and now the way into it: tapping opens the file full
              // screen. «نسخة ٢» and «نسخة ٣» are the same three characters apart, and
              // what was approved is a question about what is *on* them — which used to
              // be unanswerable from this screen without opening the customer's library.
              if (design.design case final file?) ...[
                InkWell(
                  onTap: () => unawaited(showDesign(context, file)),
                  borderRadius: BorderRadius.circular(10.r),
                  child: Opacity(
                    opacity: quiet ? 0.45 : 1,
                    child: DesignThumbnail(design: file, size: _isCurrent ? 56 : 48),
                  ),
                ),
                SizedBox(width: 12.w),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'نسخة ${design.version}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: quiet ? scheme.onSurfaceVariant : null,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        if (_isCurrent)
                          const _CurrentChip()
                        else
                          Flexible(
                            child: Text(
                              _isReplaced ? 'قديمة · لا تُطبع' : design.statusLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (subtitle.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color: _isCurrent ? statusColor : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Saving is one tap from the row, not two from a viewer: the person who
              // needs the file usually needs to send it to the printer, and never looked
              // at it on this screen at all.
              if (design.design case final file?)
                IconButton(
                  tooltip: 'تحميل',
                  onPressed: () => unawaited(saveDesign(context, file)),
                  icon: Icon(
                    AppIcons.download,
                    color: quiet ? scheme.outline : scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          if (design.rejectionReason case final reason?) ...[
            SizedBox(height: 6.h),
            Text(
              reason,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          if (design.notes case final notes?) ...[
            SizedBox(height: 4.h),
            Text(
              notes,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],

          // «ألوان الطباعة» — this order's copy, which is what the press reads. Under the
          // file it belongs to, so «which inks, on which version» needs no second look.
          if (design.printColors.isNotEmpty) ...[
            SizedBox(height: 10.h),
            PrintColorsView(colors: design.printColors),
          ],
          if (_colorsMissing) ...[
            SizedBox(height: 8.h),
            Text(
              design.printColors.isEmpty
                  ? 'مطلوب: ألوان الطباعة — لا تنتقل الطلبية إلى «قيد الطباعة» دونها'
                  : 'مطلوب: لونٌ بلا عيّنة — لا تنتقل الطلبية إلى «قيد الطباعة» دونها',
              style: text.bodySmall?.copyWith(color: scheme.error, fontWeight: FontWeight.w600),
            ),
          ],
          if (onEditColors != null && !design.isRejected)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                icon: Icon(AppIcons.printColors, size: 18.r),
                label: Text(
                  design.printColors.isEmpty ? 'إضافة ألوان الطباعة' : 'تعديل الألوان',
                ),
                onPressed: isWorking ? null : () => _editColors(context),
              ),
            ),

          // A version is judged once — the server refuses a second verdict — so the
          // buttons belong only to the one still waiting for an answer.
          if (!design.isReviewed && (onApprove != null || onReject != null)) ...[
            SizedBox(height: 10.h),
            Row(
              children: [
                if (onApprove != null)
                  Expanded(
                    child: AppButton.tonal(
                      label: 'اعتماد',
                      icon: AppIcons.activate,
                      height: 42.h,
                      onPressed: isWorking ? null : () => onApprove!(design),
                    ),
                  ),
                if (onApprove != null && onReject != null) SizedBox(width: 10.w),
                if (onReject != null)
                  Expanded(
                    child: AppButton.outlined(
                      label: 'رفض',
                      icon: AppIcons.close,
                      height: 42.h,
                      onPressed: isWorking ? null : () => _reject(context),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// «الحالية» — what the press prints from.
class _CurrentChip extends StatelessWidget {
  const _CurrentChip();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'الحالية',
        style: context.textTheme.labelMedium?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// «النسخ السابقة (١)» / «إخفاء النسخ السابقة».
class _PreviousToggle extends StatelessWidget {
  const _PreviousToggle({required this.count, required this.isOpen, required this.onTap});

  final int count;
  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(isOpen ? AppIcons.collapse : AppIcons.expand, size: 20.r),
        label: Text(isOpen ? 'إخفاء النسخ السابقة' : 'النسخ السابقة ($count)'),
      ),
    );
  }
}

/// «لماذا رُفض؟» — the sentence a rejection owes.
///
/// The server refuses a rejection without one, so asking here is what turns a 422 into a
/// question, and the answer is what makes the next version worth making.
class _RejectionDialog extends StatefulWidget {
  const _RejectionDialog();

  @override
  State<_RejectionDialog> createState() => _RejectionDialogState();
}

class _RejectionDialogState extends State<_RejectionDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('رفض التصميم'),
      content: AppTextField(
        controller: _reason,
        label: 'سبب الرفض',
        autofocus: true,
        maxLines: 3,
        maxLength: 1000,
        textInputAction: TextInputAction.newline,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () {
            final reason = _reason.text.trim();
            // Refused here rather than sent: the server answers 422 for an empty one, and a
            // dialog that closes on a refusal is a dialog the user has to reopen.
            if (reason.isEmpty) return;

            Navigator.of(context).pop(reason);
          },
          child: const Text('رفض'),
        ),
      ],
    );
  }
}
