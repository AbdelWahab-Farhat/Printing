import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «طلبية تعويض» in the staff app — Docs/orders/ORDER-COMPENSATION.md.
///
/// The goods leave stock like any order's; the customer owes nothing; their cost is reported as
/// a compensation loss. Behind `orders.compensation`.

/// Why an order is sent out free, as the server's `CompensationReason` names it.
///
/// **A copy of the server's list**, which the new-order form needs before any order exists to
/// carry the label. An order already taken shows the server's own label instead.
const compensationReasons = <(String, String)>[
  ('print_defect', 'خطأ طباعة'),
  ('wrong_item', 'منتج أو مقاس خاطئ'),
  ('delivery_damage', 'تلف في التوصيل'),
  ('previous_shortage', 'نقص في طلبية سابقة'),
  ('goodwill', 'مجاملة'),
  ('other', 'أخرى'),
];

/// The one reason that must bring its own words.
const compensationReasonNeedingNote = 'other';

/// What a compensation is, as the form holds it until it is sent.
class CompensationDraft {
  CompensationDraft();

  bool isOn = false;
  String? reason;
  final TextEditingController note = TextEditingController();

  /// The order being made good, when one was picked. Optional (owner's decision).
  Order? original;

  /// A reason is chosen, and «أخرى» has words.
  bool get isComplete =>
      !isOn ||
      (reason != null && (reason != compensationReasonNeedingNote || note.text.trim().isNotEmpty));

  void dispose() => note.dispose();
}

/// The switch and, when it is on, the reason, the words and the original order.
///
/// **Says what it does the moment it is on**: the customer pays nothing, the discount and the
/// additional cost go, and the goods' cost is booked as a loss.
class CompensationFields extends StatelessWidget {
  const CompensationFields({
    required this.draft,
    required this.customerId,
    required this.onChanged,
    this.reasonError,
    this.originalError,
    this.showSwitch = true,
    super.key,
  });

  final CompensationDraft draft;

  /// The customer whose orders the original is picked from.
  final int customerId;

  /// Called after every change, so the page can redraw and re-check its button.
  final VoidCallback onChanged;

  final String? reasonError;
  final String? originalError;

  /// False on the sheet, which is already about turning it on.
  final bool showSwitch;

  Future<void> _pickOriginal(BuildContext context) async {
    final chosen = await showOrderPicker(
      context: context,
      customerId: customerId,
      title: 'الطلبية الأصلية',
    );

    if (chosen != null) {
      draft.original = chosen;
      onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showSwitch)
          Material(
            type: MaterialType.transparency,
            child: SwitchListTile.adaptive(
              value: draft.isOn,
              onChanged: (value) {
                draft.isOn = value;
                onChanged();
              },
              contentPadding: EdgeInsets.zero,
              title: Row(
                children: [
                  Icon(
                    AppIcons.compensation,
                    size: 18.sp,
                    color: draft.isOn ? scheme.primary : scheme.outline,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'طلبية تعويض — بلا مقابل',
                    style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        if (draft.isOn) ...[
          const CompensationNotice(),
          SizedBox(height: 12.h),
          Text('سبب التعويض', style: context.textTheme.labelLarge),
          SizedBox(height: 6.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (final (code, label) in compensationReasons)
                ChoiceChip(
                  label: Text(label),
                  selected: draft.reason == code,
                  onSelected: (_) {
                    draft.reason = code;
                    onChanged();
                  },
                ),
            ],
          ),
          if (reasonError case final error?) ...[
            SizedBox(height: 4.h),
            Text(error, style: context.textTheme.bodySmall?.copyWith(color: scheme.error)),
          ],
          SizedBox(height: 10.h),
          AppTextField(
            controller: draft.note,
            label: draft.reason == compensationReasonNeedingNote ? 'التفاصيل (مطلوبة)' : 'التفاصيل',
            hint: 'ماذا حدث؟',
            maxLines: 2,
            onChanged: (_) => onChanged(),
          ),
          SizedBox(height: 10.h),
          if (draft.original case final original?)
            Row(
              children: [
                Icon(AppIcons.link, size: 18.sp, color: scheme.primary),
                SizedBox(width: 6.w),
                Expanded(child: Text('تعويض عن الطلبية ${original.code}')),
                IconButton(
                  tooltip: 'إزالة',
                  icon: Icon(AppIcons.close, size: 18.sp),
                  onPressed: () {
                    draft.original = null;
                    onChanged();
                  },
                ),
              ],
            )
          else
            AppButton.tonal(
              label: 'اختيار الطلبية الأصلية (اختياري)',
              icon: AppIcons.link,
              onPressed: () => _pickOriginal(context),
            ),
          if (originalError case final error?) ...[
            SizedBox(height: 4.h),
            Text(error, style: context.textTheme.bodySmall?.copyWith(color: scheme.error)),
          ],
        ],
      ],
    );
  }
}

/// What turning it on does — amber, above the reason.
class CompensationNotice extends StatelessWidget {
  const CompensationNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        'الزبون لا يدفع شيئاً عن هذه البضاعة: إجمالي الطلبية صفر، ولا خصم ولا تكلفة إضافية. '
        'البضاعة تخرج من المخزن كالعادة، وتكلفتها تُسجَّل «خسائر تعويض» على الشركة — '
        'وبضاعة المستثمرين تُرَدّ لهم بسعر تكلفتها.',
        style: context.textTheme.bodySmall?.copyWith(color: scheme.onTertiaryContainer),
      ),
    );
  }
}

/// «تعويض» — on the order card and the order screen.
class CompensationBadge extends StatelessWidget {
  const CompensationBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.compensation, size: 13.sp, color: scheme.onSecondaryContainer),
          SizedBox(width: 4.w),
          Text(
            'تعويض',
            style: context.textTheme.labelSmall?.copyWith(
              color: scheme.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// What the order screen says about a compensation: why, and the orders on either end.
class CompensationSummary extends StatelessWidget {
  const CompensationSummary({required this.order, this.onOpenOrder, super.key});

  final Order order;

  /// Opens a linked order by id.
  final ValueChanged<int>? onOpenOrder;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final style = context.textTheme.bodyMedium;

    Widget link(String text, int id) => InkWell(
      onTap: onOpenOrder == null ? null : () => onOpenOrder!(id),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child: Text(text, style: style?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700)),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (order.isCompensation) ...[
          Row(
            children: [
              const CompensationBadge(),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  [?order.compensationReasonLabel, ?order.compensationNote].join(' — '),
                  style: style,
                ),
              ),
            ],
          ),
          if (order.compensatesOrderId case final id?)
            link('تعويض عن الطلبية ${order.compensatesOrderCode ?? '#$id'}', id),
        ],
        for (final other in order.compensatedBy) link('عُوِّضت بالطلبية ${other.code}', other.id),
      ],
    );
  }
}

/// What the sheet answers with — plain values, so nothing it built outlives it.
typedef CompensationChoice = ({bool isOn, String? reason, String? note, int? originalId});

/// «طلبية تعويض» on an order already taken — answers with what to send, or null.
///
/// Turning it off needs no reason, so that side is one button.
Future<CompensationChoice?> showCompensationSheet({
  required BuildContext context,
  required Order order,
}) {
  return showModalBottomSheet<CompensationChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _CompensationSheet(order: order),
  );
}

class _CompensationSheet extends StatefulWidget {
  const _CompensationSheet({required this.order});

  final Order order;

  @override
  State<_CompensationSheet> createState() => _CompensationSheetState();
}

class _CompensationSheetState extends State<_CompensationSheet> {
  late final CompensationDraft _draft = CompensationDraft()..isOn = !widget.order.isCompensation;

  @override
  void dispose() {
    // Here, after the exit animation has finished with the text box — never by the caller.
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final turningOn = !widget.order.isCompensation;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16.w,
          4.h,
          16.w,
          16.h + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                turningOn ? 'تحويلها إلى طلبية تعويض' : 'إرجاعها طلبية عادية',
                style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 10.h),
              if (turningOn)
                CompensationFields(
                  draft: _draft,
                  customerId: widget.order.customerId,
                  showSwitch: false,
                  onChanged: () => setState(() {}),
                )
              else
                Text(
                  'يعود إجمالي الطلبية إلى سعر بنودها، ويُطلب من الزبون دفعه.',
                  style: context.textTheme.bodyMedium,
                ),
              SizedBox(height: 16.h),
              AppButton(
                label: turningOn ? 'اجعلها طلبية تعويض' : 'أرجِعها طلبية عادية',
                onPressed: _draft.isComplete
                    ? () => Navigator.of(context).pop<CompensationChoice>((
                        isOn: _draft.isOn,
                        reason: _draft.reason,
                        note: _draft.note.text,
                        originalId: _draft.original?.id,
                      ))
                    : null,
              ),
              SizedBox(height: 8.h),
              AppButton(
                label: 'إلغاء',
                variant: AppButtonVariant.outlined,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
