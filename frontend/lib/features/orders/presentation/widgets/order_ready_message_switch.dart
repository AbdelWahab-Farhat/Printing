import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «تم إرسال رسالة الجاهزية للزبون» — سؤالٌ بجوابين، فمفتاحٌ لا زرّان.
///
/// **وحده في هذا التطبيق يسجّل شيئاً لم يحدث فيه.** الرسالة تُرسَل على واتساب أو بمكالمة، من
/// هاتف الموظف، فلا حدث يُرصَد ولا قيمة تُشتقّ: الضغطة **هي** السجلّ، والخادم يختم من ضغطها ومتى.
///
/// **الصفّ كلّه يُضغط لا المفتاح وحده**، كما في [OrderUrgentSwitch]: المفتاح على حافة الشاشة
/// هدفٌ صغيرٌ بجانب سطرٍ عريضٍ فارغ، و`SwitchListTile` تجعل الكلمة والمفتاح ضغطةً واحدة كما تفعل
/// كل قائمة إعداداتٍ يعرفها صاحب الهاتف.
///
/// **والاسم والتاريخ تحته حين تكون مضبوطة** — وهذا ليس سطر شرح: الغرض المُعلَن من الخانة أن
/// يُتأكَّد من أنّ الموظف المسؤول أرسل الرسالة، فـ«أرسلها فلان · أمس» هو الجواب نفسه لا حاشيةً
/// عليه. ولا يُرسَم شيء وهي مطفأة، لأنّ لا شيء وقع بعد.
///
/// وملفوفٌ بـ`Material` شفّافة عن قصد: `ListTile` ترسم لمستها على أقرب `Material` فوقها، والقسم
/// الذي يحمله صندوقٌ ملوّن — فبغيرها تُرسم اللمسة تحت الصندوق ولا تُرى.
class OrderReadyMessageSwitch extends StatelessWidget {
  const OrderReadyMessageSwitch({required this.order, required this.onChanged, super.key});

  final Order order;

  /// Null when the mark may not be moved — a reader without `orders.ready_message`, an archived
  /// order, or a write already in flight. `SwitchListTile` greys itself out on a null, which is
  /// the whole of the refusal: the server says it again if anything gets past it.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isEditable = onChanged != null;
    final sent = order.isReadyMessageSent;

    return Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            value: sent,
            onChanged: onChanged,
            contentPadding: EdgeInsets.zero,
            // الأخضر نفسه الذي تلبسه «مدفوعة بالكامل»: لونٌ واحد لمعنى «انتهى هذا» في التطبيق
            // كلّه، حتى لا يتعلّم القارئ لوناً ثانياً للشيء نفسه.
            activeTrackColor: scheme.paid,
            title: Row(
              children: [
                Icon(
                  AppIcons.readyMessage,
                  size: 18.sp,
                  // ورماديّةٌ ما دامت مطفأة: أيقونةٌ خضراء فوق مفتاحٍ لم يُضغط تقول إنّ الرسالة
                  // أُرسلت أصلاً.
                  color: sent ? scheme.paid : scheme.outline,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'تم إرسال رسالة الجاهزية للزبون',
                    style: context.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      // الكلمة تخفت مع المفتاح، فلا يُقرأ الصفّ حيّاً وهو مقفل.
                      color: isEditable ? null : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // **مَن ومتى، وهو الواقعة نفسها لا شرحاً لها.** غائبٌ تماماً ما لم تُضبط، وغائبٌ اسمه
          // وحده لو كان مَن ضغطها قد حُذف من الموظفين — الختم ينجو منه، والطلبية تظلّ تقول إنّ
          // رسالةً أُرسلت.
          if (sent)
            if (_record(order) case final record?)
              Padding(
                padding: EdgeInsetsDirectional.only(start: 26.w, bottom: 4.h),
                child: Text(
                  record,
                  style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
        ],
      ),
    );
  }

  /// «أرسلها أحمد · 14 أغسطس 2026 · 2:00 م», or as much of it as the server sent.
  ///
  /// The day is [AppDates.stamp] rather than «منذ ساعتين»: this is read weeks later when a
  /// customer says nobody called them, and «منذ ساعتين» is true only while the screen is open.
  static String? _record(Order order) {
    final who = order.readyMessageSentBy?.name;
    final when = order.readyMessageSentAt?.stampLabel;

    return switch ((who, when)) {
      (final name?, final stamp?) => 'أرسلها $name · $stamp',
      (final name?, null) => 'أرسلها $name',
      (null, final stamp?) => stamp,
      _ => null,
    };
  }
}
