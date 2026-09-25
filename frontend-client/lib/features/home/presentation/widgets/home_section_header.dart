import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/widgets/app_text_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// عنوان قسمٍ على الرئيسية، و«عرض الكل» في طرفه إلى التبويب الذي فيه القسم كاملاً.
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({required this.title, required this.onSeeAll, super.key});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          AppTextLink(
            label: 'عرض الكل',
            onPressed: onSeeAll,
            style: context.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
