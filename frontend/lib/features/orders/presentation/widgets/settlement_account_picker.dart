import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/search_field.dart';
import 'package:dayaa/features/orders/models/payment_settlement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// What the account picker answered. A record rather than a bare id, so «كل الحسابات» (a null id)
/// and closing the sheet (no answer at all) are two different things.
typedef AccountChoice = ({int? accountId});

/// «الحساب» on «تسوية الدفعات» — where the money waits: Nawris, a driver, «مصرف علي».
///
/// **A search box over the list rather than a row of buttons** — the owner's choice, 2026-10-07:
/// a shop with a box per pickup office and an account per employee outgrows a row of chips. The
/// list is the one the page already holds, so the search filters it as typed, with no request.
Future<AccountChoice?> showSettlementAccountPicker({
  required BuildContext context,
  required List<SettlementAccount> accounts,
  required int? selectedId,
}) {
  return showModalBottomSheet<AccountChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _AccountPicker(accounts: accounts, selectedId: selectedId),
  );
}

class _AccountPicker extends StatefulWidget {
  const _AccountPicker({required this.accounts, required this.selectedId});

  final List<SettlementAccount> accounts;
  final int? selectedId;

  @override
  State<_AccountPicker> createState() => _AccountPickerState();
}

class _AccountPickerState extends State<_AccountPicker> {
  String _term = '';

  List<SettlementAccount> get _shown {
    final term = _term.trim();

    if (term.isEmpty) return widget.accounts;

    return [
      for (final account in widget.accounts)
        if (account.name.contains(term)) account,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 8.h),
            child: Text(
              'اختر الحساب',
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
            child: SearchField(
              key: const ValueKey('account-picker-search'),
              hint: 'ابحث عن حساب',
              onChanged: (value) => setState(() => _term = value),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                // Only while nothing is typed: «كل الحسابات» is not an answer to a search.
                if (_term.trim().isEmpty)
                  _Option(
                    label: 'كل الحسابات',
                    isSelected: widget.selectedId == null,
                    onTap: () => Navigator.of(context).pop((accountId: null)),
                  ),
                for (final account in shown)
                  _Option(
                    key: ValueKey('account-option-${account.id}'),
                    label: account.name,
                    isSelected: widget.selectedId == account.id,
                    onTap: () => Navigator.of(context).pop((accountId: account.id)),
                  ),
                if (shown.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Text(
                      'لا حساب بهذا الاسم',
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.label, required this.isSelected, required this.onTap, super.key});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return ListTile(
      leading: Icon(AppIcons.treasury, color: isSelected ? scheme.primary : scheme.onSurfaceVariant),
      title: Text(
        label,
        style: TextStyle(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500),
      ),
      trailing: isSelected ? Icon(AppIcons.sentMark, color: scheme.primary) : null,
      onTap: onTap,
    );
  }
}
