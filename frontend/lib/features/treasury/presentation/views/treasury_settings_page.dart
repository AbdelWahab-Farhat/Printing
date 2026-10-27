import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/router/pop_result.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/viewmodel/treasury_settings_cubit.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_settings_explain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «إعدادات المالية» — كلُّ ما يقرّره المالك في الخزينة، في مكانٍ واحد. TREASURY-DESIGN §١٦.
///
/// أربعُ بطاقات بحسب اللحظة التي يعمل فيها الإعداد، وكلُّ تغييرٍ يُحفظ لحظتَه:
///
/// 1. **الدفعة** — كاشُ كل مكتب استلام (§١٩)، والافتراضيُّ لكل طريقة، و«الحساب الشخصي أولاً».
/// 2. **التسوية** — الاختيار على الشاشة (§٢٤)، ثم حساب المسوّي (§٢٢)، ثم «اجمع» (§١٨) — مرقّمةً
///    بترتيب غلبتها — ثم أين تُسوّى كلُّ عهدة.
/// 3. **الحماية** — الرصيد السالب، وسبب السحب، والقفل.
/// 4. **الدفع الإلكتروني** — على من عمولة EzonePay.
///
/// لا جملَ تحت المفاتيح: زرُّ ⓘ يفتح الشرح لمن يسأل. و«سؤال احتفظ به الناقل» لا يظهر هنا بطلب
/// المالك (2026-10-27)؛ قيمتُه على الخادم كما هي.
///
/// الحساباتُ تُفتح وتُعدَّل وتُضاف في «الحسابات والكاش» وحدها، والتصنيفاتُ شاشةٌ تحت «المالية».
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
        body: BlocConsumer<TreasurySettingsCubit, TreasurySettingsState>(
          listener: (context, state) {
            // تعيد لمن فتحها `true` إن حُفظ فيها شيء، فتقرأ اللوحة حساباتها مرةً واحدة.
            context.handBack(context.read<TreasurySettingsCubit>().changed ? true : null);

            if (state case TreasurySettingsLoaded(:final refreshFailure?)) {
              context.showFailure(refreshFailure);
            }
          },
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
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 48.h),
        children: [
          _Section(
            title: 'الدفعة',
            explain: TreasuryExplain.payment,
            children: [
              if (settings.pickupOffices.isNotEmpty) ...[
                const _Overline('كاش المكتب عندما تكون الطلبية استلام مكتب'),
                for (final office in settings.pickupOffices)
                  _ChoiceTile(
                    key: ValueKey('office-${office.cityId}'),
                    title: _officeName(office.name),
                    value: office.accountName ?? 'القاعدة العادية',
                    onTap: () async {
                      final boxes = [
                        for (final a in active)
                          if (a.kind == AccountKind.cash) a,
                      ];
                      final picked = await _pick<int>(
                        context,
                        title: 'كاش «${_officeName(office.name)}»',
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
              const _Overline('الافتراضي'),
              for (final (label, kind) in const [
                ('كاش', AccountKind.cash),
                ('حوالة وبطاقة', AccountKind.bank),
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
                    // حسابُ النظام — «Ezone» محفظةٌ أيضاً — لا يكون افتراضياً: يملؤه EzonePay وحده.
                    final choices = [
                      for (final a in active)
                        if (a.kind == kind && !a.isSystem) a,
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
              // آخرُ البطاقة بطلب المالك، والسطرُ الرماديّ تحته بطلبه أيضاً (2026-10-27).
              _Switch(
                title: 'الحساب الشخصي أولاً',
                subtitle: 'تنزل الدفعة في حساب من سجّلها بدل الافتراضي، إن كان له حساب من نوعها',
                value: settings.ownAccountFirst,
                onChanged: (v) => _run(context, () => cubit.saveSettings(ownAccountFirst: v)),
              ),
            ],
          ),

          _Section(
            title: 'التسوية',
            explain: TreasuryExplain.settlement,
            children: [
              // §٢٤ — يغلب ما تحته كلَّه.
              _Switch(
                key: const ValueKey('pick-settlement-accounts'),
                step: '1',
                title: 'اختيار الحساب عند التغيير لحالة التسوية',
                explain: TreasuryExplain.pick,
                value: settings.pickSettlementAccounts,
                onChanged: (v) =>
                    _run(context, () => cubit.saveSettings(pickSettlementAccounts: v)),
              ),
              // §٢٢ — قبل «اجمع»: نوعٌ ليس للمسوّي فيه حسابٌ يتبعه.
              _Switch(
                key: const ValueKey('settle-into-settler'),
                step: '2',
                title: 'إلى حساب المسوّي تلقائياً',
                explain: TreasuryExplain.settler,
                value: settings.settleIntoSettler,
                onChanged: (v) => _run(context, () => cubit.saveSettings(settleIntoSettler: v)),
              ),
              const _Overline('التجميع', step: '3', explain: TreasuryExplain.collect),
              for (final (label, kind) in const [
                ('اجمع الكاش', AccountKind.cash),
                ('اجمع الحوالات والبطاقات', AccountKind.bank),
                ('اجمع ليبيانا', AccountKind.wallet),
              ])
                _CollectionTile(
                  key: ValueKey('collect-${kind.wire}'),
                  label: label,
                  kind: kind,
                  state: state,
                ),
              if (custody.isNotEmpty) ...[
                const _Overline('العهدة'),
                for (final account in custody)
                  _ChoiceTile(
                    title: account.name,
                    value: account.settlesIntoName ?? 'تلقائي',
                    onTap: () async {
                      final picked = await _pick<int>(
                        context,
                        title: 'تُسوّى «${account.name}» إلى',
                        options: [(0, 'تلقائي'), for (final a in spendable) (a.id, a.name)],
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
            ],
          ),

          _Section(
            title: 'الحماية',
            children: [
              _Switch(
                title: 'منع الرصيد السالب',
                value: settings.blockOverdraft,
                onChanged: (v) => _run(context, () => cubit.saveSettings(blockOverdraft: v)),
              ),
              _Switch(
                title: 'السبب إجباري عند السحب',
                value: settings.withdrawalNeedsReason,
                onChanged: (v) =>
                    _run(context, () => cubit.saveSettings(withdrawalNeedsReason: v)),
              ),
              _LockTile(lockedUntil: settings.lockedUntil),
            ],
          ),

          if (settings.onlineFeePayer case final payer?)
            _Section(title: 'الدفع الإلكتروني', children: [_FeePayerTile(payer: payer)]),
        ],
      ),
    );
  }
}

/// اسمُ المكتب بلا «إستلام مكتب(…)» حوله: المدنُ مسمّاةٌ هكذا في خريطة التوصيل، والعنوانُ فوقها
/// يقول إنها مكاتب استلام.
String _officeName(String name) =>
    RegExp(r'\(([^)]+)\)').firstMatch(name)?.group(1)?.trim() ?? name;

/// عنوانُ القسم، وزرُّ ⓘ لشرحه إن كان له شرح، ثم بطاقتُه بخطٍّ رفيع بين صفوفها.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.explain});

  final String title;
  final TreasuryExplain? explain;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final hairline = scheme.outlineVariant.withValues(alpha: 0.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: 4.w, top: 16.h, bottom: 4.h),
          child: SizedBox(
            height: 44.h,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ),
                if (explain case final explain?)
                  _ExplainButton(tooltip: 'شرح: $title', topic: explain),
              ],
            ),
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: hairline),
          ),
          // شفّافةٌ فوق لون البطاقة: بلاها يُرسم أثرُ اللمس تحت اللون فلا يُرى.
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, child) in children.indexed) ...[
                  // العنوانُ الصغير يلتصق بصفوفه، فلا خطَّ تحته.
                  if (i > 0 && children[i - 1] is! _Overline)
                    Divider(height: 1, thickness: 1, color: hairline),
                  child,
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// عنوانٌ صغير داخل البطاقة لمجموعة صفوف: «الافتراضي»، «التجميع»، «العهدة».
class _Overline extends StatelessWidget {
  const _Overline(this.text, {this.step, this.explain});

  final String text;
  final String? step;
  final TreasuryExplain? explain;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsetsDirectional.fromSTEB(16.w, 14.h, 8.w, 2.h),
    child: Row(
      children: [
        if (step case final step?) ...[TreasuryStepMark(step), SizedBox(width: 12.w)],
        Flexible(
          child: Text(
            text,
            style: context.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (explain case final explain?) _ExplainButton(tooltip: 'ما معنى: $text', topic: explain),
      ],
    ),
  );
}

class _ExplainButton extends StatelessWidget {
  const _ExplainButton({required this.tooltip, required this.topic});

  final String tooltip;
  final TreasuryExplain topic;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    visualDensity: VisualDensity.compact,
    iconSize: 20.r,
    color: context.colorScheme.onSurfaceVariant,
    icon: Icon(AppIcons.explain),
    onPressed: () => showTreasuryExplain(context, topic),
  );
}

class _Switch extends StatelessWidget {
  const _Switch({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.step,
    this.explain,
    super.key,
  });

  final String title;
  final String? subtitle;

  /// ترتيبُ القاعدة بين أخواتها، حين يكون لترتيبها معنى.
  final String? step;

  final TreasuryExplain? explain;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: EdgeInsetsDirectional.only(start: 16.w, end: 12.w),
    secondary: step == null ? null : TreasuryStepMark(step!),
    title: explain == null
        ? Text(title)
        : Row(
            children: [
              Flexible(child: Text(title)),
              _ExplainButton(tooltip: 'ما معنى: $title', topic: explain!),
            ],
          ),
    subtitle: subtitle == null ? null : Text(subtitle!),
    value: value,
    onChanged: onChanged,
  );
}

/// صفٌّ يُضغط فيفتح خياراته: الاسمُ عند البداية، والقيمةُ وسهمٌ عند النهاية.
class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({required this.title, required this.value, required this.onTap, super.key});

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsetsDirectional.only(start: 16.w, end: 12.w),
    title: Text(title),
    trailing: _Value(value, end: Icon(AppIcons.forward, color: context.colorScheme.outline)),
    onTap: onTap,
  );
}

/// القيمةُ الرمادية في آخر الصف، وما بعدها: سهمٌ، أو زرّ.
class _Value extends StatelessWidget {
  const _Value(this.value, {required this.end});

  final String value;
  final Widget end;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 180.w),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      SizedBox(width: 4.w),
      end,
    ],
  );
}

/// حساباتُ نوعٍ في «اجمع»: حساباتُه النشطة بلا حساب النظام، وما يُجمع فيه — المسمّى، وإلا
/// الافتراضي — وما سواه، وهو ما يُختار في «من:».
({
  List<TreasuryAccount> all,
  TreasuryAccount? named,
  TreasuryAccount? fallback,
  List<TreasuryAccount> others,
})
_collecting(TreasurySettingsLoaded state, AccountKind kind) {
  final setting = state.settings.collectionOf(kind);
  final all = [
    for (final a in state.accounts)
      if (a.isActive && a.kind == kind && !a.isSystem) a,
  ];
  final fallback = all.where((a) => a.isDefault).firstOrNull;
  final named = all.where((a) => a.id == setting.intoId).firstOrNull;
  final target = named ?? fallback;

  return (
    all: all,
    named: named,
    fallback: fallback,
    others: [
      for (final a in all)
        if (a.id != target?.id) a,
    ],
  );
}

/// «اجمع» لنوعٍ واحد: المفتاح، وتحته «في:» و«من:». مطفأً يبقيان ظاهرين ولا يُفتحان، فيُعرف
/// أين سيُجمع المال قبل التشغيل. TREASURY-DESIGN §١٨.
class _CollectionTile extends StatelessWidget {
  const _CollectionTile({
    super.key,
    required this.label,
    required this.kind,
    required this.state,
  });

  final String label;
  final AccountKind kind;
  final TreasurySettingsLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TreasurySettingsCubit>();
    final setting = state.settings.collectionOf(kind);
    final (:all, :named, :fallback, :others) = _collecting(state, kind);
    final collected = others.where((a) => a.isCollected).length;
    final fallbackLabel = 'الافتراضي (${fallback?.name ?? '—'})';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsetsDirectional.only(start: 16.w, end: 12.w),
          title: Text(label),
          value: setting.on,
          onChanged: (v) => _run(context, () => cubit.saveCollection(kind, on: v)),
        ),
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(16.w, 0, 16.w, 12.h),
          child: Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _PickChip(
                key: ValueKey('collect-into-${kind.wire}'),
                prefix: 'في:',
                value: (named ?? fallback)?.name ?? '—',
                onTap: !setting.on
                    ? null
                    : () async {
                        final picked = await _pick<int>(
                          context,
                          title: '$label في',
                          options: [(0, fallbackLabel), for (final a in all) (a.id, a.name)],
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
              if (others.isNotEmpty)
                _PickChip(
                  key: ValueKey('collect-from-${kind.wire}'),
                  prefix: 'من:',
                  value: switch (collected) {
                    _ when collected == others.length => 'الكل',
                    0 => 'لا شيء',
                    _ => '$collected من ${others.length}',
                  },
                  onTap: !setting.on
                      ? null
                      : () => _collectFrom(context, title: '$label من', kind: kind),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// «في: …» و«من: …» تحت «اجمع» — رقاقةٌ تفتح خياراتها، ومعطّلةٌ والمفتاحُ مطفأ.
class _PickChip extends StatelessWidget {
  const _PickChip({required this.prefix, required this.value, required this.onTap, super.key});

  final String prefix;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
    onPressed: onTap,
    label: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          prefix,
          style: TextStyle(color: context.colorScheme.onSurfaceVariant),
        ),
        SizedBox(width: 4.w),
        Text(value),
        SizedBox(width: 2.w),
        Icon(AppIcons.expand, size: 18.r),
      ],
    ),
  );
}

/// «من:» — حساباتُ النوع غيرُ حساب التجميع، كلٌّ بمربّعه. المحذوفُ منها يبقى مالُه مكانه.
/// الورقةُ تقرأ الحالة حيّةً، فيتبدّل المربّع حين يُحفظ.
Future<void> _collectFrom(
  BuildContext context, {
  required String title,
  required AccountKind kind,
}) {
  final cubit = context.read<TreasurySettingsCubit>();

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => BlocBuilder<TreasurySettingsCubit, TreasurySettingsState>(
      bloc: cubit,
      builder: (context, state) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            _SheetTitle(title),
            if (state case final TreasurySettingsLoaded loaded)
              for (final account in _collecting(loaded, kind).others)
                CheckboxListTile(
                  key: ValueKey('collected-${account.id}'),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(account.name),
                  value: account.isCollected,
                  onChanged: (v) => _run(context, () => cubit.setCollected(account, v ?? true)),
                ),
          ],
        ),
      ),
    ),
  );
}

/// «مقفل حتى» — يومٌ يُقفل كلُّ ما قبله من عمليات يدوية، أو «لا شيء».
class _LockTile extends StatelessWidget {
  const _LockTile({required this.lockedUntil});

  final String? lockedUntil;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TreasurySettingsCubit>();

    return ListTile(
      contentPadding: EdgeInsetsDirectional.only(start: 16.w, end: 12.w),
      leading: Icon(AppIcons.locked, color: context.colorScheme.onSurfaceVariant),
      title: const Text('مقفل حتى'),
      trailing: switch (lockedUntil) {
        null => _Value('لا شيء', end: Icon(AppIcons.forward, color: context.colorScheme.outline)),
        final day => _Value(
          day,
          end: IconButton(
            tooltip: 'فتح القفل',
            icon: Icon(AppIcons.unlocked),
            onPressed: () => _run(context, () => cubit.saveSettings(clearLock: true)),
          ),
        ),
      },
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

/// «العمولة على» — الزبون أو المحلّ بضغطةٍ واحدة. ما ليس «shop» يُقرأ «customer» كما كان.
class _FeePayerTile extends StatelessWidget {
  const _FeePayerTile({required this.payer});

  final String payer;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TreasurySettingsCubit>();
    final current = payer == 'shop' ? 'shop' : 'customer';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Expanded(child: Text('العمولة على', style: context.textTheme.bodyLarge)),
          SegmentedButton<String>(
            key: const ValueKey('online-fee-payer'),
            segments: const [
              ButtonSegment(value: 'customer', label: Text('الزبون')),
              ButtonSegment(value: 'shop', label: Text('المحلّ')),
            ],
            selected: {current},
            onSelectionChanged: (picked) {
              if (picked.first != current) {
                _run(context, () => cubit.saveSettings(onlineFeePayer: picked.first));
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 8.h),
    child: Text(
      text,
      style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    ),
  );
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
          _SheetTitle(title),
          for (final (value, label) in options)
            ListTile(title: Text(label), onTap: () => Navigator.of(context).pop(value)),
        ],
      ),
    ),
  );
}
