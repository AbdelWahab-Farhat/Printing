import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The verdict on one version — «موافقة» or «تعديل مطلوب».
///
/// **The note is required for a change request and optional for an approval**, which is why this
/// is a sheet rather than two buttons on the screen: the words are the whole content of a
/// revision round, and a dialog with a single «تأكيد» invites somebody to send one without them.
///
/// The server refuses an empty note too, and that refusal is the guarantee — this is the part
/// that makes the message land under the field instead of arriving as a toast after the fact.
///
/// Answers with a [ReviewChoice], never a bare verdict: `showModalBottomSheet` returns null when
/// the sheet is **dismissed**, and backing out is not a decision.
Future<ReviewChoice?> showReviewVersionSheet({
  required BuildContext context,
  required DesignTicketFile version,
}) {
  return showModalBottomSheet<ReviewChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _ReviewSheet(version: version),
  );
}

/// The sheet's answer.
@immutable
class ReviewChoice {
  const ReviewChoice({required this.verdict, this.note});

  final DesignSubmissionStatus verdict;
  final String? note;
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.version});

  final DesignTicketFile version;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  final TextEditingController _note = TextEditingController();

  /// Which of the two is being sent. Purely visual state inside one widget, which is the one
  /// thing `setState` is still for.
  DesignSubmissionStatus _verdict = DesignSubmissionStatus.approved;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _needsNote => _verdict == DesignSubmissionStatus.changesRequested;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16.w,
        0,
        16.w,
        MediaQuery.viewInsetsOf(context).bottom + 16.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مراجعة ${widget.version.label}',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 14.h),
          SegmentedButton<DesignSubmissionStatus>(
            segments: const [
              ButtonSegment(
                value: DesignSubmissionStatus.approved,
                label: Text('موافقة'),
              ),
              ButtonSegment(
                value: DesignSubmissionStatus.changesRequested,
                label: Text('طلب تعديل'),
              ),
            ],
            selected: {_verdict},
            onSelectionChanged: (picked) => setState(() => _verdict = picked.first),
          ),
          SizedBox(height: 14.h),
          AppTextField(
            controller: _note,
            label: _needsNote ? 'ما المطلوب تعديله' : 'ملاحظة (اختياري)',
            hint: _needsNote ? 'كبّر الشعار وغيّر رقم الهاتف' : null,
            maxLines: 3,
          ),
          if (_verdict == DesignSubmissionStatus.approved) ...[
            SizedBox(height: 10.h),
            // Said before the tap, not after: approving is the one action here that cannot be
            // undone — it closes the ticket and puts the file on the customer's account.
            Text(
              'الموافقة تُغلق التذكرة وتحفظ التصميم في حساب الزبون.',
              style: text.bodySmall?.copyWith(color: context.colorScheme.onSurfaceVariant),
            ),
          ],
          SizedBox(height: 18.h),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: _needsNote ? 'إرسال طلب التعديل' : 'اعتماد التصميم',
              onPressed: () => Navigator.of(context).pop(
                ReviewChoice(verdict: _verdict, note: _note.text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
