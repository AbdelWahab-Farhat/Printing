import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// المقاس في شارةٍ صغيرة، من اليسار كما يُكتب على الكيس: «25*35» لا «35*25».
///
/// **واحدةٌ للقائمة والطلبية المفتوحة**: بند «طلباتي» وبند الطلبية حين تُفتح بالشارة نفسها، فلا
/// يتبدّل شكل المقاس بين ما يُمسح وما يُفتح منه.
class SizeChip extends StatelessWidget {
  const SizeChip(this.size, {super.key});

  final String size;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      height: 24.h,
      padding: EdgeInsets.symmetric(horizontal: 7.w),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: scheme.surfaceContainerHigh),
      ),
      child: Text(
        size,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        style: context.textTheme.labelMedium?.copyWith(
          fontSize: 12.5.sp,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
