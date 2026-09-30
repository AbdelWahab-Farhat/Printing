import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/features/badges/presentation/views/badge_count.dart';
import 'package:flutter/material.dart';

/// «الملاحظات» تحت بطاقة الحالة: زرٌّ بعرض الشاشة، وبجانب كلمته عدد ما لم يُقرأ (طلب المستخدم،
/// 2026-09-25).
///
/// **حاضرٌ دائماً**، وإن لم يُكتب شيء: الشارة وحدها تغيب عند الصفر. والحبّة هي [CountPill]
/// نفسها التي على بقية شارات التطبيق.
class OrderNotesButton extends StatelessWidget {
  const OrderNotesButton({required this.unread, required this.onPressed, super.key});

  final int unread;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppButton.tonal(
      label: 'الملاحظات',
      icon: AppIcons.notes,
      trailing: unread > 0 ? CountPill(count: unread) : null,
      onPressed: onPressed,
    );
  }
}
