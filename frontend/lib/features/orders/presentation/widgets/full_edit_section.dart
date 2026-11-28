import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/usecases/update_order_invoice.dart';
import 'package:dayaa/features/shipping_companies/models/shipping_company.dart';
import 'package:dayaa/features/shipping_companies/repositories/shipping_company_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// What the «حقول الأدمن» section holds while the screen is open.
///
/// **Owned by the screen, not by `OrderInvoiceCubit`.** These are text boxes and two pickers
/// whose controllers have to be disposed with the widget; the Cubit only takes the finished
/// [OrderFullEdit] on «حفظ التعديلات». A [ChangeNotifier] so the save button can light up for a
/// change made here alone.
class FullEditDraft extends ChangeNotifier {
  FullEditDraft(Order order)
    : _openingDeliveryPrice = order.deliveryPrice,
      _openingPlacedAt = order.placedAt,
      deliveryPrice = TextEditingController(text: order.deliveryPrice),
      deliveryCost = TextEditingController(
        text: order.deliveryCostOverride ?? '',
      ),
      courierName = TextEditingController(text: order.courierName ?? ''),
      courierPhone = TextEditingController(text: order.courierPhone ?? ''),
      depositExpected = TextEditingController(
        text: order.depositExpectedAmount ?? '',
      ),
      shippingCompanyId = order.shippingCompanyId,
      shippingCompanyName = order.shippingCompany,
      placedAt = order.placedAt?.toLocal() ?? DateTime.now() {
    for (final controller in _controllers) {
      controller.addListener(_touch);
    }
  }

  final String _openingDeliveryPrice;
  final DateTime? _openingPlacedAt;

  final TextEditingController deliveryPrice;
  final TextEditingController deliveryCost;
  final TextEditingController courierName;
  final TextEditingController courierPhone;
  final TextEditingController depositExpected;
  int? shippingCompanyId;
  String? shippingCompanyName;
  DateTime placedAt;

  bool _isDirty = false;

  /// Whether anything in this section moved since the screen opened.
  bool get isDirty => _isDirty;

  List<TextEditingController> get _controllers => [
    deliveryPrice,
    deliveryCost,
    courierName,
    courierPhone,
    depositExpected,
  ];

  /// Whether the delivery price typed differs from the one the order opened with.
  bool get deliveryPriceMoved =>
      _number(deliveryPrice.text) != _number(_openingDeliveryPrice);

  /// Whether the order date was moved to another day.
  bool get dateMoved {
    final opening = _openingPlacedAt?.toLocal();
    if (opening == null) return true;

    return !DateUtils.isSameDay(opening, placedAt);
  }

  void pickCompany(ShippingCompany? company) {
    shippingCompanyId = company?.id;
    shippingCompanyName = company?.name;
    _touch();
  }

  void pickDate(DateTime date) {
    // Keeps the time of day the order was placed at; only the day is being corrected.
    placedAt = DateTime(
      date.year,
      date.month,
      date.day,
      placedAt.hour,
      placedAt.minute,
    );
    _touch();
  }

  OrderFullEdit toOrderFullEdit() => OrderFullEdit(
    deliveryPrice: deliveryPrice.text,
    deliveryCost: deliveryCost.text,
    shippingCompanyId: shippingCompanyId,
    courierName: courierName.text,
    courierPhone: courierPhone.text,
    depositExpectedAmount: depositExpected.text,
    placedAt: placedAt,
  );

  void _touch() {
    if (_isDirty) {
      notifyListeners();
      return;
    }

    _isDirty = true;
    notifyListeners();
  }

  static double _number(String input) =>
      double.tryParse(
        Validators.toWesternDigits(input.trim()).replaceAll(',', '.'),
      ) ??
      0;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}

/// The fields nothing else edits once they are set. Shown only to `orders.edit_fully`.
class FullEditSection extends StatelessWidget {
  const FullEditSection({required this.draft, super.key});

  final FullEditDraft draft;

  Future<void> _pickCompany(BuildContext context) async {
    final picked = await showModalBottomSheet<_CompanyChoice>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const _CompanySheet(),
    );

    if (picked == null) return;
    draft.pickCompany(picked.company);
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: draft.placedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) draft.pickDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final money = [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.,٫]'))];
    final scheme = context.colorScheme;

    return ListenableBuilder(
      listenable: draft,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'تظهر لك لأن عندك صلاحية «تعديل الطلبية بالكامل».',
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: draft.deliveryPrice,
                  label: 'سعر التوصيل',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: money,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: AppTextField(
                  controller: draft.deliveryCost,
                  label: 'تكلفة التوصيل',
                  hint: 'تلقائي',
                  helperText: 'فارغ = تلقائي',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: money,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _PickerTile(
            label: 'شركة الشحن',
            value: draft.shippingCompanyName ?? 'بدون',
            icon: Icons.local_shipping_outlined,
            onTap: () => _pickCompany(context),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: draft.courierName,
                  label: 'اسم المندوب',
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: AppTextField(
                  controller: draft.courierPhone,
                  label: 'هاتف المندوب',
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  maxLength: 20,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          AppTextField(
            controller: draft.depositExpected,
            label: 'العربون المتوقع',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: money,
          ),
          SizedBox(height: 12.h),
          _PickerTile(
            label: 'تاريخ الطلبية',
            value: MaterialLocalizations.of(
              context,
            ).formatMediumDate(draft.placedAt),
            icon: Icons.event_outlined,
            onTap: () => _pickDate(context),
          ),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.r),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: scheme.onSurfaceVariant),
        title: Text(label, style: context.textTheme.bodySmall),
        subtitle: Text(
          value,
          style: context.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(Icons.chevron_left),
      ),
    );
  }
}

/// A pick from the companies sheet; [company] null is «بدون».
class _CompanyChoice {
  const _CompanyChoice(this.company);

  final ShippingCompany? company;
}

class _CompanySheet extends StatelessWidget {
  const _CompanySheet();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: sl<ShippingCompanyRepository>().companies(
        isActive: true,
        perPage: 100,
      ),
      builder: (context, snapshot) {
        final result = snapshot.data;
        if (result == null) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return result.fold(
          (failure) => Padding(
            padding: EdgeInsets.all(24.w),
            child: Text(failure.message, textAlign: TextAlign.center),
          ),
          (page) => ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('بدون شركة شحن'),
                onTap: () =>
                    Navigator.of(context).pop(const _CompanyChoice(null)),
              ),
              for (final company in page.items)
                ListTile(
                  title: Text(company.name),
                  subtitle: Text(company.subtitle),
                  onTap: () =>
                      Navigator.of(context).pop(_CompanyChoice(company)),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Asks once before a full edit is saved, listing every consequence that applies to *this*
/// save. Returns true straight away when none does.
///
/// One dialog rather than one per warning: the reader agrees to the save, not to each line.
Future<bool> confirmFullEdit({
  required BuildContext context,
  required Order order,
  required FullEditDraft? draft,
  required bool linesChanged,
  required bool linesMoveStock,
  required bool anythingChanged,
}) async {
  final warnings = [
    if (draft != null && draft.dateMoved)
      'تغيير تاريخ الطلبية ممكن ينقلها لفترة أرباح مستثمرين ثانية. '
          'لو الفترة مقفولة، التصحيح يجي في الفترة المفتوحة تواً.',
    if (linesChanged && linesMoveStock)
      'البضاعة خرجت من المخزن: تعديل البنود بيحرّك المخزن '
          '(زيادة الكمية تسحب، ونقصانها يرجّع).',
    if (anythingChanged && order.nawrisParcel != null)
      'الطلبية عند نورس: المندوب بيحصّل المبلغ القديم، والتعديل ما يوصلهمش.',
    if (draft != null && draft.deliveryPriceMoved)
      'سعر التوصيل اليدوي يثبت، وما يرجعش لسعر المدينة إلا لو تغيّرت المدينة أو المنطقة.',
    if (anythingChanged && order.isClosed && order.discountIsEditable)
      'الطلبية مستلمة أو مسوّاة: أرباح المستثمرين وكاش الصندوق بيتعاودوا ينحسبوا.',
  ];

  if (warnings.isEmpty) return true;

  final confirmed = await showCustomDialog(
    context: context,
    title: 'قبل ما نحفظ',
    description: warnings.map((line) => '• $line').join('\n\n'),
    confirmLabel: 'حفظ',
    severity: DialogSeverity.warning,
    barrierDismissible: false,
  );

  return confirmed ?? false;
}
