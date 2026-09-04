import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/investors/models/investor.dart';
import 'package:dayaa/features/investors/usecases/investor_usecases.dart';
import 'package:dayaa/features/stock_items/models/stock_item.dart';
import 'package:dayaa/features/stock_items/presentation/widgets/stock_item_picker_sheet.dart';
import 'package:flutter/material.dart';

/// Creating a deal: which shelves it funds, and who is in it.
///
/// **The profit share is left blank on purpose.** Omitted, the server seeds it from the company
/// default — which is the whole point of having a default: one number the business edits once
/// instead of typing it into every deal. Fill the box only to depart from it.
///
/// The deal is born a draft. Nothing may be claimed for it until it is opened, and opening also
/// closes its terms, because they are what the money will be split by.
Future<bool?> showDealFormSheet({required BuildContext context}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _DealForm(),
  );
}

class _DealForm extends StatefulWidget {
  const _DealForm();

  @override
  State<_DealForm> createState() => _DealFormState();
}

class _DealFormState extends State<_DealForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _sharePercent = TextEditingController();

  final _shelves = <StockItem>[];
  final _participants = <({Investor investor, TextEditingController percent})>[];

  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _sharePercent.dispose();
    for (final row in _participants) {
      row.percent.dispose();
    }
    super.dispose();
  }

  Future<void> _addShelf() async {
    final item = await showStockItemPicker(context: context);

    if (item == null || !mounted) return;

    setState(() {
      if (!_shelves.any((shelf) => shelf.id == item.id)) _shelves.add(item);
    });
  }

  Future<void> _addInvestor() async {
    final investor = await showModalBottomSheet<Investor>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _InvestorPicker(),
    );

    if (investor == null || !mounted) return;

    setState(() {
      if (!_participants.any((row) => row.investor.id == investor.id)) {
        _participants.add((investor: investor, percent: TextEditingController()));
      }
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_shelves.isEmpty) {
      context.showError('اختر مادة واحدة على الأقل');

      return;
    }

    if (_participants.isEmpty) {
      context.showError('أضف مستثمراً واحداً على الأقل');

      return;
    }

    setState(() => _saving = true);

    final result = await sl<CreateInvestorDeal>()(<String, dynamic>{
      'name': _name.text.trim(),
      'opened_on': DateTime.now().toIso8601String().substring(0, 10),
      if (_sharePercent.text.trim().isNotEmpty)
        'investor_profit_share_percent': _sharePercent.text.trim(),
      'items': [
        for (final shelf in _shelves) <String, dynamic>{'stock_item_id': shelf.id},
      ],
      'investors': [
        for (final row in _participants)
          <String, dynamic>{
            'investor_id': row.investor.id,
            'share_percent': row.percent.text.trim(),
          },
      ],
    });

    if (!mounted) return;

    setState(() => _saving = false);

    result.fold(
      // The server checks that the percentages sum to exactly 100 under the deal's own lock —
      // a rule this form cannot enforce, because two people filling it at once would each pass
      // their own check.
      (failure) => context.showError(failure.message),
      (_) {
        Navigator.of(context).pop(true);
        context.showSuccess('تم إنشاء الصفقة كمسودة');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('صفقة جديدة', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'اسم الصفقة'),
                validator: (value) =>
                    (value ?? '').trim().length < 2 ? 'اسم الصفقة مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sharePercent,
                decoration: const InputDecoration(
                  labelText: 'نسبة المستثمرين من الربح',
                  helperText: 'اتركه فارغاً لاستعمال النسبة الافتراضية للشركة',
                  suffixText: '%',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 20),

              Text('المواد', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final shelf in _shelves)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(shelf.displayName),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _shelves.remove(shelf)),
                  ),
                ),
              AppButton.outlined(label: 'إضافة مادة', onPressed: _addShelf),

              const SizedBox(height: 20),
              Text('المستثمرون', style: theme.textTheme.titleMedium),
              Text(
                'مجموع النسب يجب أن يساوي 100% — وهي نسب من حصة المستثمرين، لا من كامل الربح',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              for (final row in _participants)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(row.investor.name)),
                      SizedBox(
                        width: 110,
                        child: TextFormField(
                          controller: row.percent,
                          decoration: const InputDecoration(labelText: 'النسبة', suffixText: '%'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            final percent = double.tryParse((value ?? '').trim());

                            return percent == null || percent <= 0 ? 'مطلوب' : null;
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _participants.remove(row)),
                      ),
                    ],
                  ),
                ),
              AppButton.outlined(label: 'إضافة مستثمر', onPressed: _addInvestor),

              const SizedBox(height: 24),
              AppButton(label: 'حفظ', isLoading: _saving, onPressed: _saving ? null : _submit),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Picking one investor to add to a deal.
class _InvestorPicker extends StatefulWidget {
  const _InvestorPicker();

  @override
  State<_InvestorPicker> createState() => _InvestorPickerState();
}

class _InvestorPickerState extends State<_InvestorPicker> {
  List<Investor> _investors = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await sl<GetInvestors>()(isActive: true, perPage: 100);

    if (!mounted) return;

    setState(() {
      _loading = false;
      _investors = result.fold((_) => const [], (page) => page.items);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
    }

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      children: [
        Text('اختر مستثمراً', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final investor in _investors)
          ListTile(
            title: Text(investor.name),
            subtitle: Text(investor.code),
            onTap: () => Navigator.of(context).pop(investor),
          ),
      ],
    );
  }
}
