import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/orders/models/orders_sort.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ترتيب القائمة: ضغطةٌ واحدة تقلبها.
///
/// **زرٌّ لا شريحةً في ورقة التصفية**، وقد كانت هناك أولَ الأمر ونُزعت: الشرائح كلّها تُنقص من
/// القائمة — حالةٌ أو حالةُ دفعٍ أو استعجال — والترتيب لا يُنقص شيئاً، فشريحةٌ لا تصغّر النتيجة
/// بين شرائحَ تصغّرها تُقرأ كفلترٍ لا يعمل. وهو فوق ذلك سؤالٌ بجوابين اثنين: فتحُ ورقةٍ واختيارُ
/// شريحةٍ وضغطُ «تطبيق» ثلاث ضغطاتٍ لما يستحقّ واحدة.
///
/// **والسهم يقول الترتيب القائم، لا ما ستصير إليه الضغطة.** زرٌّ يعرض جوابه المقابل يجعل القارئ
/// يحسب قبل كل ضغطة؛ وهذا يُقرأ كما تُقرأ أيّ لافتة: هكذا القائمة الآن.
///
/// **ويُملأ في «الأقدم أولاً» وحده**، تماماً كما يمتلئ زرّ الفلتر بجانبه: قائمةٌ تعمل بالمقلوب
/// حالةٌ يجب أن تُرى دون فتح شيء، والافتراضيّ لا شيء فيه يُعلَن.
///
/// الألوان من `ColorScheme` لا من قيم التصميم: السمة مولَّدة وتُستبدل كاملةً، وقيمةٌ مكتوبةٌ هنا
/// تنجو من الاستبدال وتكفّ بصمتٍ عن مطابقة ما حولها.
class OrderSortButton extends StatelessWidget {
  const OrderSortButton({required this.sort, required this.onToggled, super.key});

  final OrdersSort sort;

  /// The other one. A callback that hands back the *next* sort rather than a bare
  /// `VoidCallback`, so the screen never has to know which of the two follows which.
  final ValueChanged<OrdersSort> onToggled;

  /// The one that is not on screen.
  OrdersSort get _next =>
      sort == OrdersSort.oldest ? OrdersSort.newest : OrdersSort.oldest;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isReversed = sort != OrdersSort.fallback;

    return Tooltip(
      // The word behind the arrow, for a long press and for a screen reader: the glyph alone
      // says «up» to somebody who has not tapped it yet.
      message: sort.label,
      child: Material(
        color: isReversed ? scheme.primaryContainer : scheme.surfaceContainerLowest,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () => onToggled(_next),
          customBorder: const CircleBorder(),
          child: Padding(
            padding: EdgeInsets.all(13.w),
            child: Icon(
              sort == OrdersSort.oldest ? AppIcons.sortOldest : AppIcons.sortNewest,
              size: 22.sp,
              color: isReversed ? scheme.onPrimaryContainer : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
