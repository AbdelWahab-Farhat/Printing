import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/investors/models/profit_sources.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/profit_sources_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// «من أين جاء هذا الرقم؟» — بوّابةٌ من بطاقة أرباحه، مفتوحةً صفحةً.
///
/// **في الأعلى الرقمُ مقسوماً على فتراته** — شريطٌ بحصّة كلِّ فترة، ثم اسمُها ومجموعُها — فيُقرأ
/// من أين جاء قبل النزول في القائمة، ولا تحتاج الصفحةُ جملةً تشرح أن المجموعَ رقمُ البطاقة.
/// **ثم بطاقةٌ لكل فترة**: ما تنتظره طلبياتُها يُقال مرّةً في رأسها، لا شارةً تتكرّر على كل سطر.
///
/// كانت ورقةً سفلية، وصارت صفحةً: القائمةُ تطول، والطلبيةُ تُفتح فوقها ويُرجع منها إليها.
class ProfitSourcesPage extends StatelessWidget {
  const ProfitSourcesPage({required this.investorId, required this.gate, super.key});

  final int investorId;
  final ProfitGate gate;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfitSourcesCubit>(
      create: (_) => sl<ProfitSourcesCubit>()..load(investorId, gate),
      child: Scaffold(
        appBar: AppBar(title: Text(gate.title)),
        body: BlocBuilder<ProfitSourcesCubit, ProfitSourcesState>(
          builder: (context, state) => switch (state) {
            ProfitSourcesLoading() => const Center(child: CircularProgressIndicator()),
            ProfitSourcesFailure(:final failure) => _Retry(
              message: failure.message,
              onRetry: () => context.read<ProfitSourcesCubit>().load(investorId, gate),
            ),
            ProfitSourcesLoaded(:final sources) when sources.groups.isEmpty => Center(
              child: Text(
                'لا شيء خلف هذا الرقم',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ProfitSourcesLoaded(:final sources) => _Sources(sources: sources),
          },
        ),
      ),
    );
  }
}

/// الملخّصُ ثم بطاقاتُ الفترات.
///
/// **لونُ الفترة يربط سطرَها في الملخّص ببطاقتها**، ولا يُرسم إلا حين يُقسم الرقمُ على أكثر من
/// فترة: قائمةٌ واحدة لا شيءَ تُربط به. والألوانُ أدوارٌ من اللوحة بترتيب الفترات، تدور إن زادت.
class _Sources extends StatelessWidget {
  const _Sources({required this.sources});

  final ProfitSources sources;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final palette = [scheme.primary, scheme.tertiary, scheme.secondary, scheme.outline];

    final named = [
      for (final group in sources.groups)
        if (group.title != null) group,
    ];
    final split = named.length > 1;
    final tones = <String, Color>{
      if (split)
        for (final (index, group) in named.indexed) group.key: palette[index % palette.length],
    };

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
      children: [
        _Summary(total: sources.total, groups: split ? named : const [], tones: tones),
        for (final group in sources.groups) ...[
          SizedBox(height: 12.h),
          _GroupCard(group: group, tone: tones[group.key]),
        ],
      ],
    );
  }
}

/// رقمُ البوّابة، وتحته فتراتُه: شريطُ حصصها، ثم كلُّ فترةٍ بلونها واسمها ومجموعها.
class _Summary extends StatelessWidget {
  const _Summary({required this.total, required this.groups, required this.tones});

  final String total;

  /// فارغةٌ حين لا يُقسم الرقم — فترةٌ واحدة أو قائمةٌ بلا عنوان.
  final List<ProfitSourceGroup> groups;
  final Map<String, Color> tones;

  @override
  Widget build(BuildContext context) {
    // الشريطُ حصصٌ من كلٍّ، والحصّةُ لا تكون سالبة: فترةٌ بخسارةٍ تُبقي السطورَ وتُسقط الشريط.
    final positive = groups.every((group) => _cents(group.total) > 0);

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 20.h),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: _Amount(
                total,
                style: context.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          if (groups.isNotEmpty) ...[
            if (positive) ...[
              SizedBox(height: 16.h),
              _ShareBar(groups: groups, tones: tones),
            ],
            SizedBox(height: 10.h),
            for (final group in groups)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 3.h),
                child: Row(
                  children: [
                    _Dot(color: tones[group.key]!),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        _titleOf(group)!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    _Amount(
                      group.total,
                      style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// حصّةُ كلِّ فترةٍ من الرقم، عرضاً — صورةٌ لما تقوله السطورُ تحتها، فلا يقرؤها قارئُ الشاشة.
class _ShareBar extends StatelessWidget {
  const _ShareBar({required this.groups, required this.tones});

  final List<ProfitSourceGroup> groups;
  final Map<String, Color> tones;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        key: const ValueKey('profit-share-bar'),
        height: 10.h,
        // ممدودةً على ارتفاع الشريط: قطعةٌ بلا ابنٍ تأخذ في الصفّ ارتفاعَ صفر.
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, group) in groups.indexed) ...[
              if (index > 0) SizedBox(width: 3.w),
              Expanded(
                flex: _cents(group.total),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tones[group.key],
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// فترةٌ واحدة — أو القائمةُ كلُّها حين لا فترات: رأسُها ثم سطورُها.
///
/// **ما تنتظره طلبياتُها يُقال مرّةً.** في الفترة المفتوحة كلُّها «بانتظار انتهاء الفترة»، وفي
/// الصفقة القديمة كلُّها «بانتظار إقفال الصفقة» — فيُكتب في الرأس بجانب أيامها. وفترةٌ قيد
/// الإغلاق قد تجمع طلبيةً استُلم ربحُها وأخرى تنتظر التحصيل: حينها يقول الرأسُ حالَ الفترة،
/// وكلُّ انتظارٍ عنوانٌ فوق طلبياته (الخادمُ يرتّبها بحالها، فتأتي متجاورة).
class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, this.tone});

  final ProfitSourceGroup group;

  /// لونُها في الملخّص — `null` حين لا ملخّصَ يقسم.
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final hairline = scheme.outlineVariant.withValues(alpha: 0.5);
    final title = _titleOf(group);

    final waits = <String>{
      for (final line in group.lines)
        if (line.kind == 'order' && line.stateLabel != null) line.stateLabel!,
    };
    final mixed = waits.length > 1;

    final starts = DateTime.tryParse(group.startsOn ?? '');
    final ends = DateTime.tryParse(group.endsOn ?? '');
    final subtitle = [
      if (waits.length == 1) waits.single else ?group.statusLabel,
      if (starts != null && ends != null) AppDates.span(starts, ends),
    ].join(' · ');

    final rows = <Widget>[];
    String? wait;
    var pastOrders = false;

    for (final line in group.lines) {
      final isOrder = line.kind == 'order';
      final opensWait = mixed && isOrder && line.stateLabel != wait;
      // ما ليس طلبيةً بعد عناوين الانتظار يُفصل عنها، فلا يُقرأ تحت آخرها.
      final opensOthers = mixed && !isOrder && !pastOrders;

      if (rows.isNotEmpty) {
        final inset = opensWait || opensOthers ? 0.0 : 16.w;
        rows.add(Divider(height: 1, indent: inset, endIndent: inset, color: hairline));
      }

      if (opensWait) {
        wait = line.stateLabel;
        rows.add(_WaitHeader(label: line.stateLabel ?? ''));
      }

      if (!isOrder) pastOrders = true;

      rows.add(_Line(line: line));
    }

    return Container(
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
            if (title != null) ...[
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
                child: Row(
                  children: [
                    if (tone case final tone?) ...[
                      _Dot(color: tone),
                      SizedBox(width: 10.w),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (subtitle.isNotEmpty)
                            Text(
                              subtitle,
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    _Amount(
                      group.total,
                      style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: hairline),
            ],
            ...rows,
          ],
        ),
      ),
    );
  }
}

/// ما تنتظره الطلبياتُ تحته — في فترةٍ تختلف طلبياتُها فيه وحدها.
class _WaitHeader extends StatelessWidget {
  const _WaitHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
      child: Text(
        label,
        style: context.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.line});

  final ProfitSourceLine line;

  @override
  Widget build(BuildContext context) {
    return switch (line.kind) {
      'order' => _OrderLine(line: line),
      'release' => _ReleaseLine(line: line),
      _ => _EntryLine(line: line),
    };
  }
}

/// طلبيةٌ ونصيبُه منها — تُفتح فوق هذه الصفحة، ويُرجع منها إليها.
class _OrderLine extends StatelessWidget {
  const _OrderLine({required this.line});

  final ProfitSourceLine line;

  @override
  Widget build(BuildContext context) {
    final orderId = line.orderId;
    final subtitle = [line.customerName, line.orderStatusLabel].whereType<String>().join(' · ');

    return InkWell(
      onTap: orderId == null ? null : () => context.push(Routes.order(orderId)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.code ?? '#$orderId',
                    textDirection: TextDirection.ltr,
                    style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            _Amount(line.amount, style: _rowFigure(context)),
          ],
        ),
      ),
    );
  }
}

/// ما وضعه إقفالُ فترةٍ في محفظته — يُفتح على الطلبيات التي صُنع منها.
class _ReleaseLine extends StatelessWidget {
  const _ReleaseLine({required this.line});

  final ProfitSourceLine line;

  @override
  Widget build(BuildContext context) {
    final at = DateTime.tryParse(line.occurredAt ?? '');
    final muted = context.colorScheme.onSurfaceVariant;

    return Theme(
      // بلا خطَّي الحدود اللذين يرسمهما ExpansionTile مفتوحاً — البطاقةُ مسطّرةٌ بفواصلها.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16.w),
        childrenPadding: EdgeInsetsDirectional.only(start: 12.w),
        title: Text(
          line.label ?? '',
          style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: at == null
            ? null
            : Text(
                AppDates.day(at),
                style: context.textTheme.bodyMedium?.copyWith(color: muted),
              ),
        trailing: _Amount(line.amount, style: _rowFigure(context)),
        children: [
          if (line.children.isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Text(
                'لا تفصيل لهذا الإفراج',
                style: context.textTheme.bodyMedium?.copyWith(color: muted),
              ),
            ),
          for (final child in line.children) _Line(line: child),
        ],
      ),
    );
  }
}

/// ما ليس طلبية: نصيبُه من المصاريف، سحبٌ، ما أخذه الإقفال.
class _EntryLine extends StatelessWidget {
  const _EntryLine({required this.line});

  final ProfitSourceLine line;

  @override
  Widget build(BuildContext context) {
    final at = DateTime.tryParse(line.occurredAt ?? '');

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.label ?? '',
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (at != null)
                  Text(
                    AppDates.day(at),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          _Amount(line.amount, style: _rowFigure(context)),
        ],
      ),
    );
  }
}

/// رقمُ السطر أكبرُ ما فيه.
TextStyle? _rowFigure(BuildContext context) =>
    context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800);

/// رقمٌ بإشارته ووحدته: ما يُطرح أحمرُ ويحمل سالبَه.
class _Amount extends StatelessWidget {
  const _Amount(this.amount, {required this.style});

  final String amount;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${amount.grouped} د.ل',
      textDirection: TextDirection.ltr,
      style: style?.copyWith(color: amount.startsWith('-') ? context.colorScheme.error : null),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10.w,
      height: 10.w,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          SizedBox(height: 8.h),
          TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }
}

/// اسمُ المجموعة كما يُكتب: `null` للقائمة الواحدة بلا عنوان، و«صفقة سابقة» لصفقةٍ قديمة جاء
/// اسمُها فارغاً — كان رأسُها رقماً وحده بلا اسم.
String? _titleOf(ProfitSourceGroup group) => switch (group.title) {
  null => null,
  '' => 'صفقة سابقة',
  final String title => title,
};

/// المبلغُ بالقروش — وزنُ الفترة في الشريط، لا رقمٌ يُعرض.
int _cents(String amount) => ((double.tryParse(amount) ?? 0) * 100).round();
