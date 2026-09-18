import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
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
class DesignTicketFormPage extends StatefulWidget {
  const DesignTicketFormPage({required this.customer, super.key});

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

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final result = await sl<CreateDesignTicket>()(
      customerId: widget.customer.id,
      title: _title.text,
      description: _description.text,
      assignedDesignerId: _designerId,
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
