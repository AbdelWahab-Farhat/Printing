import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/investment_pools/models/investment_pool.dart';
import 'package:dayaa/features/investment_pools/usecases/investment_pool_usecases.dart';
import 'package:dayaa/features/stock_items/models/stock_item.dart';
import 'package:dayaa/features/stock_items/presentation/widgets/stock_item_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Opening a صندوق, or renaming one and changing which shelves it buys.
///
/// **A pool is born empty.** It names the material and nothing else — no partners, no amounts, no
/// purchase order. Money arrives afterwards through the capital form, gated by the grace window,
/// and ownership is recomputed from that capital at every close. That is the whole difference from
/// the صفقة, which was struck around one lorry with its partners and their percentages frozen the
/// day it was funded.
///
/// **حصة المستثمرين is offered once, on creation, and never again.** It is the term the partners
/// were shown; editing it later would re-cut a pool people are already in. So the field is absent
/// when this sheet is opened to edit.
Future<InvestmentPool?> showPoolFormSheet({
  required BuildContext context,

  /// Null opens a new pool; a pool edits that one.
  InvestmentPool? pool,
}) {
  return showModalBottomSheet<InvestmentPool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PoolForm(pool: pool),
  );
}

class _PoolForm extends StatefulWidget {
  const _PoolForm({this.pool});

  final InvestmentPool? pool;

  @override
  State<_PoolForm> createState() => _PoolFormState();
}

class _PoolFormState extends State<_PoolForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _share;
  late final TextEditingController _notes;

  /// Kept as whole objects, not ids: the chips need the display name, and rebuilding that string
  /// from width and height is exactly what the server composes it to prevent.
  late final List<StockItem> _shelves;

  /// Shelves an edit started with but whose objects we never had — an edit loads names from the
  /// pool itself, which carries no `StockItem`.
  late final List<PoolStockItem> _existing;

  bool _saving = false;

  bool get _isNew => widget.pool == null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.pool?.name ?? '');
    _share = TextEditingController(
      text: widget.pool?.investorProfitSharePercent ?? '',
    );
    _notes = TextEditingController(text: widget.pool?.notes ?? '');
    _shelves = [];
    _existing = List.of(widget.pool?.stockItems ?? const <PoolStockItem>[]);
  }

  @override
  void dispose() {
    _name.dispose();
    _share.dispose();
    _notes.dispose();
    super.dispose();
  }

  /// Every shelf this pool will own — the ones it already had, plus the ones just picked.
  List<int> get _stockItemIds => [
    ..._existing.map((item) => item.stockItemId),
    ..._shelves.map((item) => item.id),
  ];

  Future<void> _addShelf() async {
    final chosen = await showStockItemPicker(context: context);

    if (chosen == null) return;

    if (_stockItemIds.contains(chosen.id)) {
      if (mounted) context.showError('هذه المادة مضافة بالفعل');

      return;
    }

    setState(() => _shelves.add(chosen));
  }

  String? _validateShare(String? value) {
    final text = (value ?? '').trim();

    // Blank is legitimate on a new pool: the server seeds it from the company default, which is
    // the right answer almost always and one less number to think about.
    if (text.isEmpty) return null;

    final percent = double.tryParse(Validators.toWesternDigits(text));

    if (percent == null) return 'النسبة يجب أن تكون رقماً';
    if (percent < 0 || percent > 100) return 'النسبة بين صفر ومئة';

    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_stockItemIds.isEmpty) {
      context.showError('أضف مادة واحدة على الأقل');

      return;
    }

    setState(() => _saving = true);

    final share = _share.text.trim();

    final result = _isNew
        ? await sl<CreateInvestmentPool>()(
            name: _name.text,
            stockItemIds: _stockItemIds,
            investorProfitSharePercent: share.isEmpty
                ? null
                : Validators.toWesternDigits(share),
            notes: _notes.text,
          )
        : await sl<UpdateInvestmentPool>()(
            id: widget.pool!.id,
            name: _name.text,
            stockItemIds: _stockItemIds,
            notes: _notes.text,
          );

    if (!mounted) return;

    setState(() => _saving = false);

    result.fold(
      // The server's own words. It refuses a shelf that belongs to another pool and a product
      // outside the investable headings, and its message names which — restating either rule here
      // would be a second copy to keep in step.
      (failure) => context.showError(failure.message),
      (pool) {
        Navigator.of(context).pop(pool);
        context.showSuccess(_isNew ? 'تم فتح الصندوق' : 'تم تحديث الصندوق');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 8.h,
        bottom: context.keyboardInset + 16.h,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                _isNew ? 'صندوق جديد' : 'تعديل الصندوق',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'الصندوق يُفتح فارغاً — رأس المال يدخل بعد ذلك من شاشة الصندوق',
                style: context.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 20.h),

              AppTextField(
                controller: _name,
                label: 'اسم الصندوق',
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'اسم الصندوق مطلوب'
                    : null,
              ),
              SizedBox(height: 16.h),

              _Shelves(
                existing: _existing,
                picked: _shelves,
                onAdd: _addShelf,
                onRemoveExisting: (item) =>
                    setState(() => _existing.remove(item)),
                onRemovePicked: (item) => setState(() => _shelves.remove(item)),
              ),
              SizedBox(height: 16.h),

              // Only when opening one. After that it is the term the partners were shown, and a
              // field that could change it would re-cut a pool they are already in.
              if (_isNew) ...[
                AppTextField(
                  controller: _share,
                  label: 'حصة المستثمرين من الربح (٪) — اختياري',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _validateShare,
                ),
                Padding(
                  padding: EdgeInsets.only(top: 6.h, right: 4.w, left: 4.w),
                  child: Text(
                    'اتركها فارغة لتأخذ النسبة الافتراضية من إعدادات الاستثمار. '
                    'تُجمَّد في الصندوق ولا تتغيّر بعد فتحه.',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
              ],

              AppTextField(controller: _notes, label: 'ملاحظات', maxLines: 2),
              SizedBox(height: 20.h),

              AppButton(
                label: _isNew ? 'افتح الصندوق' : 'احفظ',
                isLoading: _saving,
                onPressed: _saving ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The shelves this pool buys, as removable chips and one button.
///
/// **Each shelf belongs to exactly one pool**, and the server holds that with a unique index. This
/// does not try to filter the picker to free shelves: the list would have to be recomputed every
/// time somebody else opened a pool, and a stale filter that hides a legitimate choice is worse
/// than a refusal that names the pool already holding it.
class _Shelves extends StatelessWidget {
  const _Shelves({
    required this.existing,
    required this.picked,
    required this.onAdd,
    required this.onRemoveExisting,
    required this.onRemovePicked,
  });

  final List<PoolStockItem> existing;
  final List<StockItem> picked;
  final VoidCallback onAdd;
  final ValueChanged<PoolStockItem> onRemoveExisting;
  final ValueChanged<StockItem> onRemovePicked;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isEmpty = existing.isEmpty && picked.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'المواد',
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'كل مادة تتبع صندوقاً واحداً فقط',
          style: context.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 8.h),
        if (isEmpty)
          Text(
            'لم تُضف مواد بعد',
            style: context.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          )
        else
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (final item in existing)
                Chip(
                  label: Text(item.name ?? 'مادة ${item.stockItemId}'),
                  onDeleted: () => onRemoveExisting(item),
                ),
              for (final item in picked)
                Chip(
                  label: Text(item.displayName),
                  onDeleted: () => onRemovePicked(item),
                ),
            ],
          ),
        SizedBox(height: 10.h),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('أضف مادة'),
        ),
      ],
    );
  }
}
