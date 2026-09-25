import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/theme/app_tones.dart';
import 'package:dayaa_client/core/utils/bidi.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/dates.dart';
import 'package:dayaa_client/core/utils/fixed_point.dart';
import 'package:dayaa_client/core/widgets/app_text_link.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/presentation/views/stage_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// طلبيةٌ في «طلباتي»، على شكل بطاقة الطلبية في تطبيق الموظفين (طلب المستخدم، 2026-09-25).
///
/// **شريط المرحلة يملأ أعلاها**، ثم ثلاثة صفوفٍ من ثلاث خانات تفصلها مسافاتٌ لا خطوط، بترتيب
/// الأسئلة كما تُسأل: أيّ طلبية ومتى ولمن، ثم بكم، ثم أين وكيف. ثم البنود في ذيلها. الخانات
/// خانات الموظف حيث يعني السؤالُ العميلَ أيضاً؛ وما لا يعنيه — رقمه هو، ووزن الطلبية — بُدّل بما
/// يعنيه: تاريخ الطلب، وطريقة الاستلام.
///
/// **كل رقمٍ كما أرسله الخادم.** المتبقي لا يُطرح هنا من السعر والمدفوع: رقمان لسؤالٍ واحد، واحدٌ
/// من الخادم وآخر من الهاتف، يختلفان يوماً.
///
/// **وخادمٌ أقدم لا يكسرها.** الخانة التي لم يصل جوابها ترسم «—»، والبنود الغائبة يحلّ محلّها
/// سطر الملخّص الذي كان الخادم يرسله قبلها.
///
/// تُفتح بـ`push`: الطلبية مكانٌ يُذهب إليه ويُرجع منه، فوق الشريط السفلي.
class OrderCard extends StatelessWidget {
  const OrderCard({required this.order, super.key});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(18.r);

    String money(String? amount) => amount == null ? '—' : '${amount.asMoney} د.ل';

    // أحمر ما دام شيءٌ مستحقاً، وأخضر حين لا شيء — صفرٌ بأحمر الإنذار يجعل الطلبية المسدّدة
    // تبدو هي المشكلة. والمقارنة بالإشارة وحدها، لا حسابٌ بالمال.
    final balance = order.balance;
    final owesSomething = balance != null && (double.tryParse(balance) ?? 0) > 0;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: radius,
      child: InkWell(
        onTap: () => context.push(Routes.order(order.id)),
        borderRadius: radius,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 18.h),
          // اللون مرسومٌ هنا لا على `Material` وحده: الظل يُرسم مستطيلاً مملوءاً مموّهاً، وزخرفةٌ
          // بظلٍّ بلا لون تغسل وجه البطاقة بسواده. `BoxDecoration` يرسم الظل أولاً ثم اللون فوقه.
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: radius,
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StageBanner(label: order.stageLabel, stage: order.stage),
              SizedBox(height: 22.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _Cell(label: 'رقم الطلبية', value: '#${order.code}')),
                  Expanded(
                    child: _Cell(
                      label: 'تاريخ الطلب',
                      value: order.placedAt?.relativeDayLabel ?? '—',
                    ),
                  ),
                  Expanded(
                    child: _Cell(
                      label: 'رقم الاستلام',
                      value: order.recipientPhone ?? '—',
                      isLtr: true,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 26.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Cell(
                      label: 'سعر الطلبية',
                      // طلبيةٌ بندٌ فيها بلا سعر: جملةٌ مكان الرقم، بخطٍّ خافت لا بلون المال.
                      value: order.total == null ? awaitingQuoteLabel : money(order.total),
                      tone: order.total == null ? scheme.onSurfaceVariant : scheme.primary,
                    ),
                  ),
                  Expanded(
                    child: _Cell(
                      label: 'المدفوع',
                      value: money(order.paidAmount),
                      tone: order.paidAmount == null ? null : scheme.paid,
                    ),
                  ),
                  Expanded(
                    child: _Cell(
                      label: 'المتبقي',
                      value: money(balance),
                      tone: balance == null
                          ? null
                          : owesSomething
                          ? scheme.error
                          : scheme.paid,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 26.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _Cell(label: 'مكان الاستلام', value: order.cityName ?? '—')),
                  Expanded(
                    child: _Cell(
                      label: 'التسليم',
                      value: order.fulfilmentTypeLabel ?? '—',
                    ),
                  ),
                  // الخانة الثالثة فارغةٌ عمداً، كي تستقيم الأعمدة تحت الصفّين فوقها.
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
              _Footer(items: order.items, summary: order.summary),
            ],
          ),
        ),
      ),
    );
  }
}

/// ذيل البطاقة: ما في الطلبية بنداً بنداً — بندان، وما زاد خلف «عرض الكل».
///
/// **بندٌ في سطر، ومعه كميته ووحدتها.** اسم المنتج وحده لا يقول كم منه، والكمية هي ما يُسأل عنه.
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
        SizedBox(height: 20.h),
        Divider(height: 1, thickness: 1, color: scheme.outlineVariant.withValues(alpha: 0.5)),
        SizedBox(height: 10.h),
        if (items.isEmpty)
          Text(
            summary!.bidiSafe,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          )
        else
          for (final item in shown) _Line(item: item),
        if (foldable)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: EdgeInsets.only(top: 6.h),
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

/// سطرٌ واحد: اسمه، ومقاسه بجانبه، وكم منه.
///
/// **والمقاس ليس زينة.** المنتج الواحد قد يُطلب بمقاسين في الطلبية نفسها، فيصير السطران
/// توأمين لا يفرّق بينهما إلا المقاس. وهو أخفت من الاسم، يقود الاسمُ العينَ إليه.
class _Line extends StatelessWidget {
  const _Line({required this.item});

  final OrderLine item;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final unit = item.pricingUnitLabel;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
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
                    style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (item.variantLabel case final variant?) ...[
                  SizedBox(width: 8.w),
                  Text(
                    variant,
                    // «25*35» يُقرأ من اليسار كما يُكتب على الكيس.
                    textDirection: TextDirection.ltr,
                    maxLines: 1,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            unit == null ? item.quantity.asQuantity : '${item.quantity.asQuantity} $unit',
            style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// خانةٌ واحدة: اسمها فوقها عريضاً، وقيمتها تحته.
///
/// **الاسم هو النصف العريض لا القيمة**، كما في بطاقة الموظفين: في شبكةٍ من تسع خانات، أرقامٌ
/// عريضة وحدها لا يُعرف أيّها أيّ إلا بقراءة ما فوقها؛ والاسم العريض يقود العين إلى قيمته.
class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.value, this.isLtr = false, this.tone});

  final String label;
  final String value;

  /// رقم هاتف: يُقرأ من اليسار حتى داخل بطاقةٍ من اليمين.
  final bool isLtr;

  /// لون القيمة. يُصرف على خانات المال وحدها، فاللون على هذه البطاقة يعني دائماً «هذا مال».
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 2.w),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            textAlign: TextAlign.center,
            textDirection: isLtr ? TextDirection.ltr : null,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodyMedium?.copyWith(color: tone ?? scheme.onSurface),
          ),
        ],
      ),
    );
  }
}
