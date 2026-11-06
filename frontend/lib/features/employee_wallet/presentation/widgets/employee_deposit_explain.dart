import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// زرُّ ⓘ في «إيداع»: الفرقُ بين الاثنين لمن يسأل، والورقةُ نفسها بلا جملٍ تحت خياراتها — كزرّ ⓘ في
/// «إعدادات المالية».
class EmployeeDepositExplainButton extends StatelessWidget {
  const EmployeeDepositExplainButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'الفرق بين مال مستلم ومال مستحق',
    visualDensity: VisualDensity.compact,
    iconSize: 20.r,
    color: context.colorScheme.onSurfaceVariant,
    icon: Icon(AppIcons.explain),
    onPressed: () => _show(context),
  );

  Future<void> _show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Kind(
                'مال مستلم',
                'مال استلمته الشركة من الموظف. يدخل الحساب الذي تختاره، ويزيد رصيد محفظته.',
              ),
              _Kind(
                'مال مستحق',
                'مبلغ له على الشركة، كالراتب. لا يدخل به مال، ويُسجَّل مصروفاً ويزيد رصيد محفظته.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Kind extends StatelessWidget {
  const _Kind(this.name, this.meaning);

  final String name;
  final String meaning;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 8.h),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(name, style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        SizedBox(height: 4.h),
        Text(meaning, style: context.textTheme.bodyLarge),
      ],
    ),
  );
}
