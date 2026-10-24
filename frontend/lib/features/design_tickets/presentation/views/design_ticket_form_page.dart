import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/files/local_files.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/core/widgets/attachment_sheet.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket.dart';
import 'package:dayaa/features/design_tickets/presentation/widgets/assign_designer_sheet.dart';
import 'package:dayaa/features/design_tickets/usecases/design_ticket_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Raising a design request.
///
/// **The customer is read, never chosen, when the form is opened from a customer's screen** — the
/// same shape «طلبية جديدة» uses. Opened from the section's own door it has to be picked, and
/// that is the one field this form refuses to submit without.
///
/// **The designer is asked for here, of whoever may answer.** The form used to withhold the
/// field on the argument that routing is a separate grant — true, but the effect was that every
/// ticket went to the pool and somebody had to reopen it to hand it to anybody. The endpoint has
/// always taken `assigned_designer_id` on create; only this screen withheld it.
///
/// It is drawn for `design_tickets.assign` and for nobody else, which is the half of that
/// argument worth keeping: a picker a clerk may not use is a field that teaches them they are
/// not allowed to touch it.
///
/// **It opens on the pool, and that is a real answer rather than an empty one.** «لا أعرف من
/// الفارغ الآن» is the ordinary case; left there, every designer is told and the first to accept
/// takes it.
///
/// **المرفقاتُ تُختار هنا وتصل مع الطلب**، فيُبلَّغ المصمّم بتذكرةٍ فيها شعارُها. والصفُّ صفُّ
/// «تذكرة داخلية جديدة» نفسه، ويقبل PDF كما تقبله شاشة التذكرة.
class DesignTicketFormPage extends StatefulWidget {
  const DesignTicketFormPage({required this.customer, super.key});

  /// كـ`media.design_tickets.max_files_on_create` على الخادم، وما زاد يُرفق من شاشة التذكرة.
  static const int maxFiles = 10;

  /// Whose artwork this is. The form cannot be opened without one.
  final Customer customer;

  @override
  State<DesignTicketFormPage> createState() => _DesignTicketFormPageState();
}

class _DesignTicketFormPageState extends State<DesignTicketFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();

  bool _isSaving = false;

  /// Who to address it to. **Null is the shared pool** — not a missing answer, which is why the
  /// row says so in words rather than sitting blank.
  int? _designerId;
  String? _designerName;

  /// بالترتيب الذي اختيرت به، وهو ترتيبها على التذكرة.
  final List<PickedFile> _files = [];

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDesigner() async {
    final choice = await showAssignDesignerSheet(
      context: context,
      currentDesignerId: _designerId,
    );

    // Null is a dismissal; the pool arrives as a choice carrying a null id.
    if (choice == null || !mounted) return;

    setState(() {
      _designerId = choice.userId;
      _designerName = choice.name;
    });
  }

  Future<void> _addFile() async {
    final source = await showAttachmentSheet(context: context, title: 'إضافة مرفق');
    if (source == null || !mounted) return;

    final picked = await sl<AttachmentPicker>().pick(
      source,
      // كقائمة شاشة التذكرة، وهي `config('media.design_tickets.mimes')`.
      extensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'],
    );
    if (picked.isEmpty || !mounted) return;

    setState(() {
      _files.addAll(picked.take(DesignTicketFormPage.maxFiles - _files.length));
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final result = await sl<CreateDesignTicket>()(
      customerId: widget.customer.id,
      title: _title.text,
      description: _description.text,
      assignedDesignerId: _designerId,
      files: List<PickedFile>.of(_files),
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    result.fold(
      (failure) => context.showFailure(failure),
      (ticket) {
        context.showSuccess('تم إرسال طلب التصميم');
        Navigator.of(context).pop<DesignTicket>(ticket);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = sl<Session>();
    final mayManage = session.can(AppPermission.manageDesignTickets);
    final mayRoute = session.can(AppPermission.assignDesignTickets);

    return Scaffold(
      appBar: AppBar(title: const Text('طلب تصميم')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
          children: [
            Text(
              widget.customer.name,
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 16.h),
            AppTextField(
              controller: _title,
              label: 'عنوان الطلب',
              hint: 'تصميم كيس شحن — أسود',
              validator: Validators.required,
            ),
            SizedBox(height: 14.h),
            // **One box, not two.** «وصف الطلب» and «الملاحظات والتعليمات» were separate on the
            // argument that one is read on the card and the other once the ticket is opened —
            // a distinction nobody filling the form has any way to act on. Two boxes asking for
            // the same thing in different words get the request split down the middle, and then
            // the designer has to read both to know what was asked.
            AppTextField(
              controller: _description,
              label: 'وصف الطلب والتعليمات',
              hint: 'ضع الشعار في المنتصف وأضف رقم الهاتف أسفله',
              maxLines: 6,
              validator: Validators.required,
            ),
            if (mayRoute) ...[
              SizedBox(height: 14.h),
              _DesignerRow(
                value: _designerName ?? 'بلا مصمم — تظهر لكل المصممين',
                onTap: _pickDesigner,
              ),
            ],
            SizedBox(height: 18.h),
            Text(
              'المرفقات (${_files.length} من ${DesignTicketFormPage.maxFiles})',
              style: context.textTheme.labelLarge,
            ),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                for (final file in _files)
                  _PickedFileTile(file: file, onRemove: () => setState(() => _files.remove(file))),
                if (_files.length < DesignTicketFormPage.maxFiles)
                  _AddFileTile(onTap: () => unawaited(_addFile())),
              ],
            ),
            SizedBox(height: 24.h),
            AppButton(
              label: 'إرسال الطلب',
              isLoading: _isSaving,
              onPressed: mayManage ? _save : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// The row that opens the designers' list.
///
/// Not an [AppDropdown]: the list is paginated and searched on the server, so it does not fit a
/// dropdown's fixed set. Drawn in the same box every field on this form wears, copied from
/// `AppTextField`'s own decoration so the two cannot drift.
class _DesignerRow extends StatelessWidget {
  const _DesignerRow({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'المصمم',
          filled: true,
          fillColor: scheme.surfaceContainerLow,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          suffixIcon: const Icon(Icons.expand_more_rounded),
        ),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
        ),
      ),
    );
  }
}

/// مرفقٌ اختير ولم يُرسل بعد: الصورةُ نفسها، أو PDF باسمه — وعليه ما يُزيله.
class _PickedFileTile extends StatelessWidget {
  const _PickedFileTile({required this.file, required this.onRemove});

  final PickedFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isPdf = file.name.toLowerCase().endsWith('.pdf');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: isPdf
              ? Container(
                  width: 76.w,
                  height: 76.w,
                  padding: EdgeInsets.all(6.w),
                  color: scheme.surfaceContainerLow,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(AppIcons.pdf, color: scheme.onSurfaceVariant),
                      SizedBox(height: 4.h),
                      Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall,
                      ),
                    ],
                  ),
                )
              : Image(
                  image: LocalFiles.image(file.path),
                  width: 76.w,
                  height: 76.w,
                  fit: BoxFit.cover,
                ),
        ),
        PositionedDirectional(
          top: -8.h,
          end: -8.w,
          child: Material(
            color: scheme.surface,
            shape: CircleBorder(side: BorderSide(color: scheme.outlineVariant)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Icon(AppIcons.close, size: 16.sp, semanticLabel: 'إزالة المرفق'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddFileTile extends StatelessWidget {
  const _AddFileTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Semantics(
      button: true,
      label: 'إضافة مرفق',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: 76.w,
          height: 76.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Icon(AppIcons.attach, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
