import 'dart:async';
import 'dart:io';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/core/widgets/attachment_sheet.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket.dart';
import 'package:dayaa/features/internal_tickets/models/internal_ticket_query.dart';
import 'package:dayaa/features/internal_tickets/presentation/viewmodel/new_internal_ticket_cubit.dart';
import 'package:dayaa/features/internal_tickets/presentation/widgets/colleague_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// «تذكرة جديدة» — حقولُ نموذج بريمولا بترتيبها: مع مَن، والعنوان، والتفاصيل، ونوعُ المشكلة،
/// والأولوية، والطلبيةُ أو العميل حين تُفتح من صفحتهما، وحتى أربع صور. الصوتُ يُرسل من المحادثة.
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
  final _form = GlobalKey<FormState>();

  // ما يملؤه الموظف — حالةُ نموذجٍ بحتة، تُرسل كاملةً عند «فتح التذكرة».
  Colleague? _colleague;
  InternalCategory? _category;
  InternalTicketPriority _priority = InternalTicketPriority.medium;
  final List<PickedFile> _images = [];

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    _colleagueName.dispose();
    super.dispose();
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
        orderId: widget.subject?.orderId,
        customerId: widget.subject?.customerId,
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
    final scheme = context.colorScheme;
    final failure = state.lastFailure;
    final subject = widget.subject?.label;

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
          if (subject != null) ...[
            SizedBox(height: 16.h),
            Row(
              children: [
                Icon(AppIcons.orders, size: 18.sp, color: scheme.onSurfaceVariant),
                SizedBox(width: 6.w),
                Text(subject, style: context.textTheme.bodyMedium),
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
