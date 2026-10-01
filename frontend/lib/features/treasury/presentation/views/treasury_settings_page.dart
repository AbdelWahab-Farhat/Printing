import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/viewmodel/treasury_settings_cubit.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_account_sheet.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «إعدادات المالية» — everything the owner can decide about the treasury, in one place.
/// TREASURY-DESIGN §١٦.
///
/// Six sections, each saved the moment it changes:
///
/// 1. **القواعد** — own account first, overdrafts, the withdrawal reason, the carrier's cut, and
///    the lock date.
/// 2. **الحساب الافتراضي لكل طريقة** — where «تلقائي» lands for cash, transfer and card, Libyana.
/// 3. **أين تُسوّى العهدة** — where Nawris's and each driver's money goes at «تم التسوية».
/// 4. **خزنة كل مكتب استلام** — the cash box of each branch customers collect from (§١٩).
/// 5. **التجميع عند التسوية** — per kind: on or off, where to, and which accounts keep their money
///    (§١٨).
/// 6. **الحسابات** — every account, including the switched-off ones; tap to edit.
///
/// تصنيفاتُ المصروفات كانت القسمَ السابع، وصارت شاشةً وحدها تحت «المالية» في الدرج.
class TreasurySettingsPage extends StatelessWidget {
  const TreasurySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TreasurySettingsCubit(
        getSettings: sl(),
        saveSettings: sl(),
        getAccounts: sl(),
        saveAccount: sl(),
        setSettlesInto: sl(),
      )..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('إعدادات المالية')),
        body: BlocBuilder<TreasurySettingsCubit, TreasurySettingsState>(
          builder: (context, state) => switch (state) {
            TreasurySettingsLoading() => const Center(child: CircularProgressIndicator()),
            TreasurySettingsFailed(:final failure) => Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(failure.message, textAlign: TextAlign.center),
                    SizedBox(height: 16.h),
                    AppButton.tonal(
                      label: 'إعادة المحاولة',
                      onPressed: context.read<TreasurySettingsCubit>().load,
                    ),
                  ],
                ),
              ),
            ),
            TreasurySettingsLoaded() => _Loaded(state: state),
          },
        ),
      ),
    );
  }
}

/// Shows what a write came back with — a toast on failure, nothing on success (the page redraws).
Future<void> _run(BuildContext context, Future<Failure?> Function() write) async {
  final failure = await write();

  if (failure != null && context.mounted) {
    context.showError(failure.message, details: failure.details);
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.state});

  final TreasurySettingsLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TreasurySettingsCubit>();
    final settings = state.settings;
    final active = [
      for (final a in state.accounts)
        if (a.isActive) a,
    ];
    final spendable = [
      for (final a in active)
        if (a.isSpendable) a,
    ];
    final custody = [
      for (final a in state.accounts)
        if (a.kind == AccountKind.custody) a,
    ];

    return RefreshIndicator(
      onRefresh: cubit.load,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 48.h),
        children: [
          const _Heading('القواعد'),
          _Switch(
            title: 'الحساب الشخصي أولاً',
            subtitle: 'الدفعة تنزل في حساب من يسجّلها إن كان له حساب يناسب الطريقة، قبل الافتراضي',
            value: settings.ownAccountFirst,
            onChanged: (v) => _run(context, () => cubit.saveSettings(ownAccountFirst: v)),
          ),
          _Switch(
            title: 'منع الرصيد السالب في العمليات اليدوية',
            subtitle: 'السحب والمصروف والتحويل ودفعة المورد تُرفض إن لم يكفِ الرصيد',
            value: settings.blockOverdraft,
            onChanged: (v) => _run(context, () => cubit.saveSettings(blockOverdraft: v)),
          ),
          _Switch(
            title: 'السبب إجباري عند السحب',
            subtitle: 'لا يُسجَّل سحبٌ بلا سبب مكتوب',
            value: settings.withdrawalNeedsReason,
            onChanged: (v) => _run(context, () => cubit.saveSettings(withdrawalNeedsReason: v)),
          ),
          _Switch(
            title: 'سؤال «احتفظ به الناقل» عند التسوية',
            subtitle: 'خانة ما خصمه النورس، ويُسجَّل مصروف «رسوم شركة التوصيل»',
            value: settings.askCarrierFee,
            onChanged: (v) => _run(context, () => cubit.saveSettings(askCarrierFee: v)),
          ),
          _LockTile(lockedUntil: settings.lockedUntil),

          const _Heading('الحساب الافتراضي لكل طريقة'),
          const _Hint('حين يُترك «تلقائي» ولا يملك المسجِّل حساباً مناسباً، تنزل الدفعة هنا'),
          for (final (label, kind) in const [
            ('كاش', AccountKind.cash),
            ('حوالة وبطاقة مصرفية', AccountKind.bank),
            ('ليبيانا', AccountKind.wallet),
          ])
            _ChoiceTile(
              title: label,
              value:
                  [
                    for (final a in active)
                      if (a.kind == kind && a.isDefault) a.name,
                  ].firstOrNull ??
                  '—',
              onTap: () async {
                final choices = [
                  for (final a in active)
                    if (a.kind == kind) a,
                ];
                final picked = await _pick<TreasuryAccount>(
                  context,
                  title: 'الافتراضي لـ$label',
                  options: [for (final a in choices) (a, a.name)],
                );

                if (picked != null && context.mounted && !picked.isDefault) {
                  await _run(context, () => cubit.makeDefault(picked));
                }
              },
            ),

          if (custody.isNotEmpty) ...[
            const _Heading('أين تُسوّى العهدة'),
            const _Hint(
              'عند «تم التسوية» ينتقل مال العهدة إلى: ما يُختار على الشاشة، ثم حساب من يسوّي '
              '(إن كانت «الحساب الشخصي أولاً» مفعّلة)، ثم ما يُحدَّد هنا، ثم المصرف للنورس والخزنة للمندوب',
            ),
            for (final account in custody)
              _ChoiceTile(
                title: account.name,
                value: account.settlesIntoName ?? 'القاعدة الافتراضية',
                onTap: () async {
                  final picked = await _pick<int>(
                    context,
                    title: 'تُسوّى «${account.name}» إلى',
                    options: [(0, 'القاعدة الافتراضية'), for (final a in spendable) (a.id, a.name)],
                  );

                  if (picked != null && context.mounted) {
                    await _run(
                      context,
                      () => cubit.setSettlesInto(account, picked == 0 ? null : picked),
                    );
                  }
                },
              ),
          ],

          if (settings.pickupOffices.isNotEmpty) ...[
            const _Heading('خزنة كل مكتب استلام'),
            const _Hint(
              'الكاش المقبوض والطلبية في «استلام مكتب» — عند التسليم أو من شاشة المدفوعات — ينزل '
              'في خزنة ذلك المكتب حين يُترك «تلقائي»، قبل حساب الموظف والخزنة الرئيسية',
            ),
            for (final office in settings.pickupOffices)
              _ChoiceTile(
                key: ValueKey('office-${office.cityId}'),
                title: office.name,
                value: office.accountName ?? 'القاعدة العادية',
                onTap: () async {
                  final boxes = [
                    for (final a in active)
                      if (a.kind == AccountKind.cash) a,
                  ];
                  final picked = await _pick<int>(
                    context,
                    title: 'خزنة «${office.name}»',
                    options: [(0, 'القاعدة العادية'), for (final a in boxes) (a.id, a.name)],
                  );

                  if (picked != null && context.mounted && picked != (office.accountId ?? 0)) {
                    await _run(
                      context,
                      () => cubit.setPickupOfficeBox(
                        office,
                        boxes.where((a) => a.id == picked).firstOrNull,
                        state.accounts,
                      ),
                    );
                  }
                },
              ),
          ],

          const _Heading('التجميع عند التسوية'),
          const _Hint(
            'عند «تم التسوية» ينتقل مال الطلبية من «مصرف علي» أو خزنة الفرع إلى حساب التجميع '
            'لنوعه — ما بقي منه في الحساب فقط، وما اختير يدوياً على شاشة التسوية يبقى مكانه',
          ),
          for (final (label, kind) in const [
            ('النقد', AccountKind.cash),
            ('المصارف', AccountKind.bank),
            ('ليبيانا', AccountKind.wallet),
          ])
            _CollectionTile(
              key: ValueKey('collect-${kind.wire}'),
              label: label,
              kind: kind,
              setting: settings.collectionOf(kind),
              accounts: [
                for (final a in active)
                  if (a.kind == kind) a,
              ],
            ),

          const _Heading('الحسابات'),
          for (final account in state.accounts)
            TreasuryAccountTile(
              key: ValueKey(account.id),
              account: account,
              onTap: () => showTreasuryAccountSheet(
                context: context,
                account: account,
                onSubmit: ({required name, kind, isDefault, isActive, holderUserId, notes}) =>
                    cubit.saveAccount(
                      id: account.id,
                      name: name,
                      isDefault: isDefault,
                      isActive: isActive,
                      holderUserId: holderUserId,
                      notes: notes,
                    ),
              ),
            ),
          SizedBox(height: 8.h),
          AppButton.tonal(
            label: 'حساب جديد',
            icon: AppIcons.add,
            onPressed: () => showTreasuryAccountSheet(
              context: context,
              onSubmit: ({required name, kind, isDefault, isActive, holderUserId, notes}) =>
                  cubit.saveAccount(
                    name: name,
                    kind: kind,
                    isDefault: isDefault,
                    holderUserId: holderUserId,
                    notes: notes,
                  ),
            ),
          ),

        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: 24.h, bottom: 4.h),
    child: Text(
      text,
      style: context.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: context.colorScheme.primary,
      ),
    ),
  );
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 4.h),
    child: Text(
      text,
      style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurfaceVariant),
    ),
  );
}

class _Switch extends StatelessWidget {
  const _Switch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    subtitle: Text(subtitle),
    value: value,
    onChanged: onChanged,
  );
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({required this.title, required this.value, required this.onTap, super.key});

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    subtitle: Text(value),
    trailing: Icon(AppIcons.edit),
    onTap: onTap,
  );
}

/// One kind's «التجميع عند التسوية»: the switch, and while it is on, the account it collects
/// into and which of the kind's other accounts are left alone. TREASURY-DESIGN §١٨.
class _CollectionTile extends StatelessWidget {
  const _CollectionTile({
    super.key,
    required this.label,
    required this.kind,
    required this.setting,
    required this.accounts,
  });

  final String label;
  final AccountKind kind;
  final CollectionSetting setting;

  /// The kind's active accounts.
  final List<TreasuryAccount> accounts;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TreasurySettingsCubit>();
    final defaultAccount = accounts.where((a) => a.isDefault).firstOrNull;
    final named = accounts.where((a) => a.id == setting.intoId).firstOrNull;
    final target = named ?? defaultAccount;
    final others = [
      for (final a in accounts)
        if (a.id != target?.id) a,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Switch(
          title: 'تجميع $label',
          subtitle: setting.on
              ? 'يُجمع مال الطلبية في «${target?.name ?? '—'}» عند التسوية'
              : 'مال الطلبية يبقى حيث سُجِّل',
          value: setting.on,
          onChanged: (v) => _run(context, () => cubit.saveCollection(kind, on: v)),
        ),
        if (setting.on) ...[
          _ChoiceTile(
            title: 'يُجمع في',
            value: named == null ? 'الافتراضي (${defaultAccount?.name ?? '—'})' : named.name,
            onTap: () async {
              final picked = await _pick<int>(
                context,
                title: 'يُجمع $label في',
                options: [
                  (0, 'الافتراضي (${defaultAccount?.name ?? '—'})'),
                  for (final a in accounts) (a.id, a.name),
                ],
              );

              if (picked != null && context.mounted) {
                await _run(
                  context,
                  () => picked == 0
                      ? cubit.saveCollection(kind, toDefault: true)
                      : cubit.saveCollection(kind, intoId: picked),
                );
              }
            },
          ),
          for (final account in others)
            CheckboxListTile(
              key: ValueKey('collected-${account.id}'),
              contentPadding: EdgeInsetsDirectional.only(start: 16.w),
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(account.name),
              subtitle: Text(account.isCollected ? 'يُجمع' : 'يحتفظ بماله'),
              value: account.isCollected,
              onChanged: (v) => _run(context, () => cubit.setCollected(account, v ?? true)),
            ),
        ],
      ],
    );
  }
}

/// «مقفل حتى تاريخ» — pick a day to lock everything by hand up to it, or clear it.
class _LockTile extends StatelessWidget {
  const _LockTile({required this.lockedUntil});

  final String? lockedUntil;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TreasurySettingsCubit>();

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(AppIcons.locked),
      title: const Text('مقفل حتى تاريخ'),
      subtitle: Text(
        lockedUntil == null
            ? 'لا شيء مقفل — بعد جرد الشهر اختر آخر يوم فيه فلا تُسجَّل عملية يدوية بتاريخٍ قبله'
            : 'لا تُسجَّل عملية يدوية ولا دفعة مورد بتاريخ $lockedUntil أو قبله',
      ),
      trailing: lockedUntil == null
          ? null
          : IconButton(
              tooltip: 'فتح القفل',
              icon: Icon(AppIcons.unlocked),
              onPressed: () => _run(context, () => cubit.saveSettings(clearLock: true)),
            ),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: lockedUntil == null ? now : DateTime.tryParse(lockedUntil!) ?? now,
          firstDate: DateTime(2020),
          lastDate: now,
        );

        if (picked != null && context.mounted) {
          await _run(
            context,
            () => cubit.saveSettings(lockedUntil: picked.toIso8601String().substring(0, 10)),
          );
        }
      },
    );
  }
}

/// A short list of choices in a sheet — answers the value picked, or null for a dismissal.
Future<T?> _pick<T>(
  BuildContext context, {
  required String title,
  required List<(T, String)> options,
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 8.h),
            child: Text(
              title,
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          for (final (value, label) in options)
            ListTile(title: Text(label), onTap: () => Navigator.of(context).pop(value)),
        ],
      ),
    ),
  );
}
