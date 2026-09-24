import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:dayaa/features/investment_fund/presentation/viewmodel/investment_fund_cubit.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/fund_partner_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// شركاءُ الصندوق في فترتين — **من يقتسم ربحَ هذه الفترة، ومن يقتسم ربحَ التي تليها.**
///
/// قرارُ المالك 2026-09-23: «اريد عبدالرحمن فقط شريك هذه الفترة وينضمون للفترة التي تليها …
/// صفحة كاملة فيها خانتان: مستثمرين الفترة الحالية، مستثمرين الفترة القادمة». فمن اكتتب في
/// نافذة فترةٍ مالُه يعمل فيها ونصيبُه يبدأ من التالية — وسطرٌ واحد بـ«٠٫٠٠٪» كان يُقرأ عطباً.
///
/// **والقسمان من الخادم لا من الشاشة**: نسبةُ هذه الفترة `share_percent`، ونسبةُ التالية
/// `next_share_percent` — بكلّ الوحدات القائمة اليوم. الشاشةُ تفرز ولا تحسب.
///
/// **تبويبان لا قسمان في عمود واحد** — قرارُ المالك 2026-09-23. القسمُ الثاني كان يقع تحت
/// الأوّل، فمن جاء يسأل عن القادمة يمرّر فوق الحالية كلِّها ليصلها.
class InvestmentPartnersPage extends StatelessWidget {
  const InvestmentPartnersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InvestmentFundCubit(
        getStanding: sl(),
        openPeriod: sl(),
        closePeriod: sl(),
        deposit: sl(),
        withdraw: sl(),
        recordExpense: sl(),
      )..load(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(title: const Text('المستثمرون')),
          body: Column(
            children: [
              const _Tabs(),
              Expanded(
                child: BlocBuilder<InvestmentFundCubit, InvestmentFundState>(
                  builder: (context, state) => switch (state) {
                    InvestmentFundLoading() => const Center(child: CircularProgressIndicator()),
                    InvestmentFundFailure(:final failure) => _Retry(message: failure.message),
                    InvestmentFundLoaded(:final standing) => _Partners(standing: standing),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// شريطُ التبويبين — بزيّ «العملاء / الموردون / المستثمرون» في `PartiesPage` لا بزيٍّ خاصّ.
///
/// **في الجسم لا في `AppBar.bottom`**، كما هناك: الشريطُ يبقى فوق التحميل والخطأ، ولا يُحسب له
/// ارتفاعٌ يدويّ يختلف عمّا يرسمه `TabBar` فعلاً.
class _Tabs extends StatelessWidget {
  const _Tabs();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return TabBar(
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: scheme.outlineVariant.withValues(alpha: 0.5),
      labelColor: scheme.primary,
      unselectedLabelColor: scheme.onSurfaceVariant,
      labelStyle: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
      unselectedLabelStyle: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      tabs: [
        Tab(height: 44.h, text: 'الفترة الحالية'),
        Tab(height: 44.h, text: 'الفترة القادمة'),
      ],
    );
  }
}

class _Partners extends StatelessWidget {
  const _Partners({required this.standing});

  final FundStanding standing;

  @override
  Widget build(BuildContext context) {
    final period = standing.period;

    final current = standing.investors
        .where((h) => !h.shareStartsNextPeriod && (double.tryParse(h.sharePercent) ?? 0) > 0)
        .toList();

    final next = standing.investors
        .where((h) => (double.tryParse(h.nextSharePercent) ?? 0) > 0)
        .toList()
      ..sort(
        (a, b) => (double.tryParse(b.nextSharePercent) ?? 0)
            .compareTo(double.tryParse(a.nextSharePercent) ?? 0),
      );

    return TabBarView(
      children: [
        _Tab(
          // بلا سطرٍ فوق البطاقات — قرارُ المالك 2026-09-25: «انزع هذه الجملة كذلك».
          empty: period == null ? 'لا فترة مفتوحة' : 'لا شريك في هذه الفترة',
          children: [
            for (final holder in current)
              FundPartnerCard(holder: holder, percent: holder.sharePercent),
          ],
        ),
        _Tab(
          // بلا سطرٍ فوق البطاقات — قرارُ المالك 2026-09-24: «انزع الملاحظة التي بالأعلى».
          empty: 'لا أحد بعد',
          children: [
            for (final holder in next)
              FundPartnerCard(
                holder: holder,
                percent: holder.nextSharePercent,
                badge: holder.shareStartsNextPeriod ? 'ينضمّ' : null,
              ),
          ],
        ),
      ],
    );
  }
}

/// تبويبٌ واحد — شركاؤه، ولا شيءَ فوقهم.
///
/// **يُسحب ليُحدَّث في كلٍّ منهما**، لأن كلَّ تبويبٍ قائمتُه، والسحبُ يُعيد قراءة الاثنين معاً.
class _Tab extends StatelessWidget {
  const _Tab({required this.empty, required this.children});

  final String empty;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<InvestmentFundCubit>().load(),
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
        children: [
          if (children.isEmpty)
            Text(empty, style: context.textTheme.bodyMedium)
          else
            ...children,
        ],
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center, style: context.textTheme.bodyMedium),
            SizedBox(height: 16.h),
            AppButton(
              label: 'إعادة المحاولة',
              onPressed: () => context.read<InvestmentFundCubit>().load(),
            ),
          ],
        ),
      ),
    );
  }
}
