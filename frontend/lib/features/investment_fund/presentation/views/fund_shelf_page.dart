import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/investment_fund/models/fund_breakdown.dart';
import 'package:dayaa/features/investment_fund/presentation/viewmodel/fund_detail_cubit.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/fund_detail_body.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/fund_total_card.dart';
import 'package:dayaa/features/investment_fund/usecases/fund_breakdown_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// بضاعةُ الصندوق على الرفّ — «ما هذه البضاعة».
///
/// الرقمُ في اللوحة لا يقول أهو ألفُ كيسٍ أم طنُّ رول؛ وهذه تقوله مادّةً مادّة: كم منها، وبكم
/// كلّفت. الأغلى أوّلاً، لأنه ما يحمل أكثرَ مال الصندوق.
class FundShelfPage extends StatelessWidget {
  const FundShelfPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FundDetailCubit<FundShelf>(() => sl<GetFundShelf>()())..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('بضاعة على الرفّ')),
        body: FundDetailBody<FundShelf>(
          builder: (context, shelf) => [
            FundTotalCard(label: 'المجموع', amount: shelf.total),
            SizedBox(height: 8.h),
            if (shelf.materials.isEmpty)
              const FundEmptyLine('لا بضاعة للصندوق على الرفّ')
            else
              for (final (index, material) in shelf.materials.indexed) ...[
                if (index > 0) const FundHairline(),
                _MaterialRow(key: ValueKey(material.stockItemId ?? index), material: material),
              ],
          ],
        ),
      ),
    );
  }
}

/// مادّةٌ على الرفّ: رمزُها واسمُها، وكمّيتُها بوحدتها، وتكلفتُها أكبرَ ما في السطر.
class _MaterialRow extends StatelessWidget {
  const _MaterialRow({required this.material, super.key});

  final FundShelfMaterial material;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (material.code case final code? when code.isNotEmpty) ...[
                      Text(
                        code,
                        textDirection: TextDirection.ltr,
                        style: context.textTheme.titleMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 8.w),
                    ],
                    Flexible(
                      child: Text(
                        material.name ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  [material.quantity.grouped, ?material.unitLabel].join(' '),
                  style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            '${material.value.grouped} د.ل',
            textDirection: TextDirection.ltr,
            style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
