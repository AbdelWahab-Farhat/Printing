import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// سببُ عكسٍ يُكتب على صفّ العكس — إجباريٌّ، ويعود مقصوصاً، أو null لمن تراجع.
///
/// **على شكل حوار «إلغاء الدفعة» في الطلبيات** (`order_payments_page.dart`) وحوار عكس التوفير:
/// `AppTextField` بمدقّقه، وزرّان من أزرار الحوار نفسه — والفعلُ بلون الخطأ لأنه يكتب عكساً. بلا
/// سطر شرحٍ فوق الحقل: العنوان يقول ماذا يُعكس.
Future<String?> askForReason(
  BuildContext context, {
  required String title,
  required String confirmLabel,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TextPrompt(
      title: title,
      label: 'السبب',
      confirmLabel: confirmLabel,
      icon: AppIcons.notes,
      isDestructive: true,
      // ثلاثة أحرف لا «غير فارغ»، كحوار إلغاء الدفعة: «خطأ» جواب، وحرفٌ شارد ليس جواباً.
      minLength: 3,
      emptyMessage: 'السبب مطلوب',
    ),
  );
}

/// اسمٌ جديد أو معدَّل — تصنيف مصروف، مثلاً. يعود مقصوصاً، أو null لمن تراجع.
Future<String?> askForName(BuildContext context, {required String title, String initial = ''}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TextPrompt(
      title: title,
      label: 'الاسم',
      confirmLabel: 'حفظ',
      icon: AppIcons.tag,
      initial: initial,
      emptyMessage: 'الاسم مطلوب',
    ),
  );
}

/// **ويدجت يملك متحكّمه**، لا متحكّمٌ يُنشأ بجانب `showDialog` ويُتلف بعد عودته: الحوار ما
/// زال يتلاشى ويقرؤه بعد أن تعود — الدرسُ الذي كتبه حوار إلغاء الدفعة.
class _TextPrompt extends StatefulWidget {
  const _TextPrompt({
    required this.title,
    required this.label,
    required this.confirmLabel,
    required this.icon,
    required this.emptyMessage,
    this.initial = '',
    this.minLength = 1,
    this.isDestructive = false,
  });

  final String title;
  final String label;
  final String confirmLabel;
  final IconData icon;
  final String emptyMessage;
  final String initial;
  final int minLength;
  final bool isDestructive;

  @override
  State<_TextPrompt> createState() => _TextPromptState();
}

class _TextPromptState extends State<_TextPrompt> {
  final _formKey = GlobalKey<FormState>();
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(_text.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.only(top: 8.h),
          child: AppTextField(
            controller: _text,
            label: widget.label,
            prefixIcon: widget.icon,
            autofocus: true,
            maxLines: widget.isDestructive ? 2 : 1,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            validator: (value) =>
                (value ?? '').trim().length < widget.minLength ? widget.emptyMessage : null,
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('تراجع')),
        TextButton(
          onPressed: _submit,
          child: Text(
            widget.confirmLabel,
            style: widget.isDestructive ? TextStyle(color: scheme.error) : null,
          ),
        ),
      ],
    );
  }
}
