import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/support/presentation/widgets/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// صورةُ المتكلّم بجانب آخر فقاعةٍ من سلسلته، كما في بريمولا.
///
/// **العميلُ شخصٌ رماديٌّ بلا اسم**، كصورة بريمولا الافتراضية: اسمُه في الشريط فوق المحادثة.
/// **والزميلُ أوّلُ حرفٍ من اسمه** على لون فقاعة المحل — يُعرف من صاحبُ الرد بلا قراءة الاسم.
class ChatAvatar extends StatelessWidget {
  const ChatAvatar.customer({super.key}) : name = null, fromDesk = false;

  const ChatAvatar.desk({required this.name, super.key}) : fromDesk = true;

  final String? name;
  final bool fromDesk;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final letter = name?.trim().characters.firstOrNull;

    return ExcludeSemantics(
      child: Container(
        width: chatAvatarSize,
        height: chatAvatarSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fromDesk ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: !fromDesk || letter == null
            ? Icon(AppIcons.person, size: 17.sp, color: scheme.onSurfaceVariant)
            : Text(
                letter,
                style: context.textTheme.labelLarge?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
      ),
    );
  }
}
