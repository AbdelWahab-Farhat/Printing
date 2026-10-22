import 'dart:async';
import 'dart:io';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/core/widgets/attachment_sheet.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/features/customers/presentation/widgets/customer_picker_sheet.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket_query.dart';
import 'package:dayaa/features/internal_tickets/presentation/viewmodel/new_internal_ticket_cubit.dart';
import 'package:dayaa/features/internal_tickets/presentation/widgets/colleague_picker_sheet.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// «تذكرة جديدة» — حقولُ نموذج بريمولا بترتيبها: مع مَن، والعنوان، والتفاصيل، ونوعُ المشكلة،
/// والأولوية، والعميلُ وبجانبه الطلبية، وحتى أربع صور. الصوتُ يُرسل من المحادثة.
///
/// **العميلُ والطلبيةُ يُختاران من النموذج نفسه** (طلبُ المالك ٢٠٢٦-١٠-٢٣)، وتملؤهما صفحتُهما حين
/// تُفتح منها. كلٌّ منهما لمن يقرأ قائمته وحده — `customers.view` و`orders.view` — فلا يُعرض حقلٌ
/// تُرفض ورقتُه. ومع العميل لا تُعرض إلا طلبياته، واختيارُ عميلٍ ليست الطلبيةُ له يُسقطها، كبريمولا.
///
/// **بعد الفتح تُستبدل بالمحادثة نفسها**، فالرجوعُ منها يعود إلى حيث فُتحت لا إلى نموذجٍ فارغ.
class NewInternalTicketPage extends StatelessWidget {
  const NewInternalTicketPage({this.subject, super.key});

  final InternalTicketSubject? subject;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NewInternalTicketCubit>(
      create: (_) => sl<NewInternalTicketCubit>()..load(),
      child: _NewTicketView(subject: subject),
    );
  }
}

class _NewTicketView extends StatefulWidget {
  const _NewTicketView({required this.subject});

  final InternalTicketSubject? subject;

  @override
  State<_NewTicketView> createState() => _NewTicketViewState();
}

class _NewTicketViewState extends State<_NewTicketView> {
  final _title = TextEditingController();
  final _details = TextEditingController();

  /// اسمُ الزميل المختار في حقلٍ للقراءة — يُكتب فيه عند الاختيار، لا يُكتب فيه أحد.
  final _colleagueName = TextEditingController();
  final _customerName = TextEditingController();
  final _orderCode = TextEditingController();
  final _form = GlobalKey<FormState>();

  // ما يملؤه الموظف — حالةُ نموذجٍ بحتة، تُرسل كاملةً عند «فتح التذكرة».
  Colleague? _colleague;
  InternalCategory? _category;
  InternalTicketPriority _priority = InternalTicketPriority.medium;
  final List<PickedFile> _images = [];

  /// ما تُربط به التذكرة — من صفحة الطلبية أو العميل، أو مختارٌ هنا.
  ({int id, String name})? _customer;

  /// وعميلُها إن عُرف، كي يُسقطها اختيارُ عميلٍ غيره. من صفحة الطلبية لا يُعرف، فلا تسقط.
  ({int id, String code, int? customerId})? _order;

  @override
  void initState() {
    super.initState();

    final subject = widget.subject;
    if (subject?.customerId case final id?) _setCustomer((id: id, name: subject?.customerName ?? ''));
    if (subject?.orderId case final id?) {
      _setOrder((id: id, code: subject?.orderCode ?? '', customerId: null));
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    _colleagueName.dispose();
    _customerName.dispose();
    _orderCode.dispose();
    super.dispose();
  }

  void _setCustomer(({int id, String name})? customer) {
    _customer = customer;
    _customerName.text = customer?.name ?? '';
  }

  void _setOrder(({int id, String code, int? customerId})? order) {
    _order = order;
    _orderCode.text = order?.code ?? '';
  }

  Future<void> _pickCustomer() async {
    final chosen = await showCustomerPicker(context: context, title: 'عن أيّ عميل؟');

    if (chosen == null || !mounted) return;

    setState(() {
      _setCustomer((id: chosen.id, name: chosen.name));

      // طلبيةُ عميلٍ آخر لا تبقى مع هذا العميل.
      final owner = _order?.customerId;
      if (owner != null && owner != chosen.id) _setOrder(null);
    });
  }

  Future<void> _pickOrder() async {
    final chosen = await showOrderPicker(
      context: context,
      customerId: _customer?.id,
      title: 'عن أيّ طلبية؟',
    );

    if (chosen == null || !mounted) return;

    setState(() => _setOrder((id: chosen.id, code: chosen.code, customerId: chosen.customerId)));
  }

  Future<void> _pickColleague(List<Colleague> colleagues) async {
    final chosen = await showColleaguePicker(context: context, colleagues: colleagues);

    if (chosen == null || !mounted) return;

    _colleagueName.text = chosen.name;
    setState(() => _colleague = chosen);
  }

  Future<void> _addImage() async {
    final source = await showAttachmentSheet(
      context: context,
      title: 'إرفاق صورة',
      sources: const [AttachmentSource.photos, AttachmentSource.camera],
    );
    if (source == null || !mounted) return;

    final picked = await sl<AttachmentPicker>().pick(
      source,
      extensions: const ['jpg', 'jpeg', 'png', 'webp'],
    );
    if (picked.isEmpty || !mounted) return;

    setState(() {
      _images.addAll(picked.take(NewInternalTicketCubit.maxImages - _images.length));
    });
  }

  Future<void> _submit() async {
    final colleague = _colleague;

    if (colleague == null) {
      context.showError('اختر الزميل الذي تفتح التذكرة معه');

      return;
    }

    if (!(_form.currentState?.validate() ?? false)) return;

    await context.read<NewInternalTicketCubit>().submit(
      InternalTicketDraft(
        assigneeId: colleague.id,
        title: _title.text,
        description: _details.text,
        priority: _priority,
        categoryId: _category?.id,
        orderId: _order?.id,
        customerId: _customer?.id,
      ),
      images: List<PickedFile>.of(_images),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NewInternalTicketCubit, NewInternalTicketState>(
      listener: (context, state) {
        if (state case NewInternalTicketReady(:final created?)) {
          context.pushReplacement(Routes.internalTicket(created.id));
        } else if (state case NewInternalTicketReady(:final lastFailure?)) {
          // ما له حقلٌ يُعلَّق تحته، والباقي في الرسالة — RULES §٥.
          if (lastFailure.fieldError('title') == null &&
              lastFailure.fieldError('description') == null) {
            context.showFailure(lastFailure);
          }
        }
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('تذكرة جديدة')),
        body: switch (state) {
          NewInternalTicketLoading() => const Center(child: CircularProgressIndicator()),
          NewInternalTicketFailure(:final failure) => Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(failure.message, textAlign: TextAlign.center),
                  SizedBox(height: 16.h),
                  AppButton.outlined(
                    label: 'أعد المحاولة',
                    icon: AppIcons.refresh,
                    onPressed: () => unawaited(context.read<NewInternalTicketCubit>().load()),
                  ),
                ],
              ),
            ),
          ),
          final NewInternalTicketReady ready => _fields(context, ready),
        },
      ),
    );
  }

  Widget _fields(BuildContext context, NewInternalTicketReady state) {
    final failure = state.lastFailure;
    final session = sl<Session>();
    final mayPickCustomer = session.can(AppPermission.viewCustomers);
    final mayPickOrder = session.can(AppPermission.viewOrders);

    // ما لا يُقرأ لا يُعرض — إلا ما ملأته صفحةُ الطلبية أو العميل.
    final customerField = mayPickCustomer || _customer != null
        ? _SubjectField(
            controller: _customerName,
            label: 'العميل',
            hint: 'بلا عميل',
            icon: AppIcons.customers,
            clearLabel: 'إزالة العميل',
            errorText: failure?.fieldError('customer_id'),
            onTap: mayPickCustomer ? () => unawaited(_pickCustomer()) : null,
            onClear: _customer == null ? null : () => setState(() => _setCustomer(null)),
          )
        : null;
    final orderField = mayPickOrder || _order != null
        ? _SubjectField(
            controller: _orderCode,
            label: 'الطلبية',
            hint: 'بلا طلبية',
            icon: AppIcons.orders,
            clearLabel: 'إزالة الطلبية',
            errorText: failure?.fieldError('order_id'),
            onTap: mayPickOrder ? () => unawaited(_pickOrder()) : null,
            onClear: _order == null ? null : () => setState(() => _setOrder(null)),
          )
        : null;

    return Form(
      key: _form,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
        children: [
          AppTextField(
            readOnly: true,
            label: 'مع مَن؟',
            hint: 'اختر الزميل',
            prefixIcon: AppIcons.person,
            controller: _colleagueName,
            errorText: failure?.fieldError('assignee_id'),
            onTap: () => unawaited(_pickColleague(state.colleagues)),
          ),
          SizedBox(height: 14.h),
          AppTextField(
            controller: _title,
            label: 'العنوان',
            maxLength: 255,
            errorText: failure?.fieldError('title'),
            validator: (value) => (value ?? '').trim().isEmpty ? 'عنوان التذكرة مطلوب' : null,
          ),
          SizedBox(height: 14.h),
          AppTextField(
            controller: _details,
            label: 'التفاصيل',
            minLines: 4,
            maxLines: 8,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            errorText: failure?.fieldError('description'),
            validator: (value) => (value ?? '').trim().length < 3 ? 'اكتب تفاصيل التذكرة' : null,
          ),
          if (state.categories.isNotEmpty) ...[
            SizedBox(height: 14.h),
            AppDropdown<InternalCategory>(
              label: 'نوع المشكلة',
              items: state.categories,
              value: _category,
              keyOf: (category) => category.id,
              labelOf: (category) => category.name,
              placeholder: 'بلا نوع',
              errorText: failure?.fieldError('category_id'),
              onChanged: (category) => setState(() => _category = category),
            ),
          ],
          SizedBox(height: 16.h),
          Text('الأولوية', style: context.textTheme.labelLarge),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            children: [
              for (final priority in const [
                InternalTicketPriority.low,
                InternalTicketPriority.medium,
                InternalTicketPriority.high,
              ])
                FilterOptionChip(
                  label: priority.label,
                  isSelected: _priority == priority,
                  onTap: () => setState(() => _priority = priority),
                ),
            ],
          ),
          if (customerField != null || orderField != null) ...[
            SizedBox(height: 16.h),
            // العميلُ وبجانبه الطلبية، كنموذج بريمولا — وأحدُهما وحده يأخذ السطر.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (customerField != null) Expanded(flex: 3, child: customerField),
                if (customerField != null && orderField != null) SizedBox(width: 10.w),
                if (orderField != null) Expanded(flex: 2, child: orderField),
              ],
            ),
          ],
          SizedBox(height: 18.h),
          Text(
            'الصور (${_images.length} من ${NewInternalTicketCubit.maxImages})',
            style: context.textTheme.labelLarge,
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (final image in _images)
                _Thumbnail(image: image, onRemove: () => setState(() => _images.remove(image))),
              if (_images.length < NewInternalTicketCubit.maxImages)
                _AddImageTile(onTap: () => unawaited(_addImage())),
            ],
          ),
          SizedBox(height: 28.h),
          AppButton(
            label: 'فتح التذكرة',
            icon: AppIcons.send,
            isLoading: state.isSubmitting,
            onPressed: () => unawaited(_submit()),
          ),
        ],
      ),
    );
  }
}

/// حقلٌ للقراءة يفتح ورقةَ اختيار، وبزرٍّ يمسح ما اختير.
class _SubjectField extends StatelessWidget {
  const _SubjectField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.clearLabel,
    this.errorText,
    this.onTap,
    this.onClear,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String clearLabel;
  final String? errorText;

  /// `null` لمن لا يقرأ القائمة — الحقلُ يعرض ما ملأته الصفحةُ ولا يفتح ورقة.
  final VoidCallback? onTap;

  /// `null` حين لا شيء مختار.
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      readOnly: true,
      label: label,
      hint: hint,
      prefixIcon: icon,
      controller: controller,
      errorText: errorText,
      onTap: onTap,
      suffix: onClear == null
          ? null
          : IconButton(
              tooltip: clearLabel,
              onPressed: onClear,
              icon: Icon(AppIcons.close, size: 18.sp),
            ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.image, required this.onRemove});

  final PickedFile image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Image.file(File(image.path), width: 76.w, height: 76.w, fit: BoxFit.cover),
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
                child: Icon(AppIcons.close, size: 16.sp, semanticLabel: 'إزالة الصورة'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddImageTile extends StatelessWidget {
  const _AddImageTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Semantics(
      button: true,
      label: 'إضافة صورة',
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
          child: Icon(AppIcons.camera, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
