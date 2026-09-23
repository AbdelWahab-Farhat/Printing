import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/features/investment_fund/models/fund_breakdown.dart';
import 'package:dayaa/features/investment_fund/presentation/viewmodel/fund_detail_cubit.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/fund_detail_body.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/fund_goods_order_card.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/fund_total_card.dart';
import 'package:dayaa/features/investment_fund/usecases/fund_breakdown_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// بضاعةُ الصندوق خارج الرفّ — «ما هذه البضاعة، وأيُّ طلبياتٍ تحملها».
///
/// شاشةٌ واحدة لبندَي اللوحة، يفرّقها [stage]: **خرجت ولم تُسلَّم** — عالقةٌ في الطريق — أو
/// **سُلِّمت ولم تُحصَّل** — عند عميلٍ لم يدفع. والأقدمُ أوّلاً: ما طال انتظارُه هو ما فُتحت
/// الشاشةُ لأجله.
class FundGoodsOutPage extends StatelessWidget {
  const FundGoodsOutPage({required this.stage, super.key});

  final FundGoodsStage stage;

  /// اسمُ البند كما في اللوحة، فيعرف من ضغطه أنه وصل إلى ما ضغط.
  String get _title => switch (stage) {
    FundGoodsStage.inFlight => 'بضاعة خرجت ولم تُسلَّم',
    FundGoodsStage.uncollected => 'سُلِّمت ولم تُحصَّل',
  };

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FundDetailCubit<FundGoodsOut>(() => sl<GetFundGoodsOut>()(stage))..load(),
      child: Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: FundDetailBody<FundGoodsOut>(
          builder: (context, held) => [
            FundTotalCard(label: 'المجموع', amount: held.total),
            SizedBox(height: 16.h),
            if (held.orders.isEmpty)
              const FundEmptyLine('لا طلبيات تحمل بضاعة الصندوق هنا')
            else
              // البابُ إلى الطلبية نفسها، ولا يعود منه شيء: ما هنا يُقرأ من الرفوف لا من الطلبية.
              for (final order in held.orders)
                FundGoodsOrderCard(
                  key: ValueKey(order.orderId),
                  order: order,
                  stage: stage,
                  onTap: () => context.push(Routes.order(order.orderId)),
                ),
          ],
        ),
      ),
    );
  }
}
