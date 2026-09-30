import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/bidi.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/dates.dart';
import 'package:dayaa_client/core/utils/fixed_point.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:dayaa_client/core/widgets/app_text_link.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/models/order_progress.dart';
import 'package:dayaa_client/features/orders/presentation/views/order_progress_bar.dart';
import 'package:dayaa_client/features/orders/presentation/views/stage_pill.dart';
import 'package:dayaa_client/features/orders/presentation/widgets/order_money_cells.dart';
import 'package:dayaa_client/features/orders/presentation/widgets/size_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// طلبيةٌ في «طلباتي»، بلغة تطبيق العميل لا بطاقة الموظفين (اتجاه «أ · الخطوات»، اختاره
/// المستخدم، 2026-09-25).
///
/// **من عائلة الرئيسية والطلبية المفتوحة**: المرحلة في مربّعٍ بلونها ورقم الطلبية في آخر السطر،
/// ثم الخطوات الخمس كما على بطاقة الرئيسية ([OrderProgressBar])، ثم المال بخانات الطلبية
/// المفتوحة نفسها ([OrderMoneyCells]) في صندوقٍ غائر، ثم المدينة والهاتف، ثم البنود.
///
/// **ولا «التسليم»**: قال المستخدم إنه غير ضروري. وذهبت معه أسماء خانات الموظف فوق الرقم
/// والمدينة والهاتف: الأيقونة بجانب كلٍّ منها تقول ما هو.
///
/// **وخادمٌ أقدم لا يكسرها.** المال الذي لم يصل جوابه يُرسم «—»، والمدينة والهاتف يغيبان،
/// والبنود الغائبة يحلّ محلّها سطر الملخّص الذي كان الخادم يرسله قبلها.
///
/// تُفتح بـ`push`: الطلبية مكانٌ يُذهب إليه ويُرجع منه، فوق الشريط السفلي.
class OrderCard extends StatelessWidget {
  const OrderCard({required this.order, super.key});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final step = order.stage.step;

    return AppCard.raised(
      onTap: () => context.push(Routes.order(order.id)),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(order: order),
          // طلبيةٌ انتهت — وصلت أو رجعت أو أُلغيت — لا خطوات أمامها، كبطاقة الرئيسية.
          if (step != null) ...[
            SizedBox(height: 14.h),
            OrderProgressBar(step: step),
          ],
          SizedBox(height: 14.h),
          // غائرٌ خطوةً عن البطاقة: لون الصفحة تحت الأرقام، فيُقرأ المال كتلةً واحدة.
          Container(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: scheme.surfaceContainerHigh),
            ),
            child: OrderMoneyCells(
              total: order.total,
              paidAmount: order.paidAmount,
              balance: order.balance,
              isAwaitingQuote: order.isAwaitingQuote,
            ),
          ),
          if (order.cityName != null || order.recipientPhone != null) ...[
            SizedBox(height: 14.h),
            _Destination(city: order.cityName, phone: order.recipientPhone),
          ],
          _Footer(items: order.items, summary: order.summary),
        ],
      ),
    );
  }
}

/// رأس البطاقة: مربّع المرحلة، وكلمتها ويوم الطلب تحتها، ورقم الطلبية في آخر السطر وسهمٌ يقول
/// إن البطاقة تُفتح.
class _Header extends StatelessWidget {
  const _Header({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tone = stageTone(scheme, order.stage);

    return Row(
      children: [
        StageTile(stage: order.stage),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                // كلمة الخادم كما هي، بحبر مرحلتها.
                order.stageLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleMedium?.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                  color: tone.foreground,
                ),
              ),
              if (order.placedAt case final placedAt?)
                Text(
                  placedAt.relativeDayLabel,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          // الرقم وحده بلا «#» ولا «طلبية»، كعنوان الطلبية حين تُفتح.
          order.code,
          style: context.textTheme.titleLarge?.copyWith(
            fontSize: 20.sp,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
        ),
        SizedBox(width: 2.w),
        Icon(AppIcons.forward, size: 18.sp, color: scheme.outline),
      ],
    );
  }
}

/// إلى أين ولمن: المدينة بجانب دبّوس، ورقم الاستلام بجانب سمّاعة. ما لم يصل منهما يغيب.
class _Destination extends StatelessWidget {
  const _Destination({required this.city, required this.phone});

  final String? city;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final style = context.textTheme.bodyMedium?.copyWith(
      fontSize: 14.sp,
      fontWeight: FontWeight.w600,
      height: 1.45,
      color: scheme.onSurfaceVariant,
    );

    return Row(
      children: [
        if (city case final city?) ...[
          Icon(AppIcons.mapPin, size: 17.sp, color: scheme.onSurfaceVariant),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(city, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
          ),
        ],
        if (city != null && phone != null) SizedBox(width: 20.w),
        if (phone case final phone?) ...[
          Icon(AppIcons.phone, size: 16.sp, color: scheme.onSurfaceVariant),
          SizedBox(width: 6.w),
          // رقمٌ ليبي يُقرأ من اليسار حتى في سطرٍ من اليمين.
          Text(phone, textDirection: TextDirection.ltr, style: style),
        ],
      ],
    );
  }
}

/// ذيل البطاقة: ما في الطلبية بنداً بنداً — بندان، وما زاد خلف «عرض الكل».
///
/// **بندٌ في سطر، ومعه مقاسه وكميته بوحدتها.** اسم المنتج وحده لا يقول كم منه، والكمية هي ما
/// يُسأل عنه.
///
/// **ولا حركة في الفتح والطيّ.** يطول الذيل في الإطار نفسه: ذيلٌ يتمدّد بالتدريج عنصرٌ يغيّر
/// مقاسه، وقواعد الحركة لا تسمح إلا بالإزاحة والشفافية (RULES §7).
///
/// ويغيب كلّه، خطُّه الفاصل معه، عن طلبيةٍ لا بنود فيها ولا ملخّص.
class _Footer extends StatefulWidget {
  const _Footer({required this.items, required this.summary});

  final List<OrderLine> items;

  /// سطر الخادم «كيس شحن ٣٠×٤٠ و٢ أخرى»، لخادمٍ أقدم لا يرسل البنود.
  final String? summary;

  static const int _collapsedCount = 2;

  @override
  State<_Footer> createState() => _FooterState();
}

class _FooterState extends State<_Footer> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final items = widget.items;
    final summary = widget.summary;

    if (items.isEmpty && summary == null) return const SizedBox.shrink();

    final foldable = items.length > _Footer._collapsedCount;
    final shown = _expanded || !foldable ? items : items.take(_Footer._collapsedCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 14.h),
        Divider(height: 1, thickness: 1, color: scheme.surfaceContainerHigh),
        SizedBox(height: 4.h),
        if (items.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Text(
              summary!.bidiSafe,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.copyWith(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          for (final item in shown) _Line(item: item),
        if (foldable)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: EdgeInsets.only(top: 2.h, bottom: 4.h),
              // ضغطته له وحده: البطاقة كلها ضغطةٌ تفتح الطلبية، وهذا الرابط أعمق منها.
              child: AppTextLink(
                label: _expanded ? 'إخفاء' : 'عرض الكل (${items.length})',
                onPressed: () => setState(() => _expanded = !_expanded),
                style: context.textTheme.bodyMedium,
              ),
            ),
          ),
      ],
    );
  }
}

/// سطرٌ واحد: اسمه، ومقاسه في شارةٍ بجانبه، وكم منه في آخر السطر.
///
/// **والمقاس ليس زينة.** المنتج الواحد قد يُطلب بمقاسين في الطلبية نفسها، فيصير السطران
/// توأمين لا يفرّق بينهما إلا المقاس.
class _Line extends StatelessWidget {
  const _Line({required this.item});

  final OrderLine item;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final unit = item.pricingUnitLabel;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    item.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                ),
                if (item.variantLabel case final size?) ...[
                  SizedBox(width: 8.w),
                  SizeChip(size),
                ],
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            unit == null ? item.quantity.asQuantity : '${item.quantity.asQuantity} $unit',
            style: context.textTheme.bodyMedium?.copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              height: 1.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
