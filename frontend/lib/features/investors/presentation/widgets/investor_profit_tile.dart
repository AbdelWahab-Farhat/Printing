import 'package:dayaa/core/utils/fixed_point.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/features/investors/presentation/widgets/investor_money_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// بوّاباتُ الربح الثلاث — §٠.٨ من مواصفة الصندوق — بالترتيب الذي يمرّ به المال فيها.
enum ProfitGate { awaitingDelivery, pending, available }

/// ربحُ المستثمر في بطاقةٍ واحدة: **المجموعُ أولاً، وزرٌّ لكل بوّابة.**
///
/// كانت ثلاثَ بطاقاتٍ متشابهة يُقرأ فيها الرقمُ ثلاث مرّات قبل أن يُعرف كم ربح. المجموعُ هو
/// سؤالُه الأول؛ والأزرارُ تُبقي الفرقَ بين ما في الطريق وما قُيِّد وما يُسحب على بُعد لمسة —
/// فلا يَعِد الرقمُ الكبير بمالٍ لا يُسحب، لأن «متاحة للسحب» زرٌّ بجانبه.
///
/// **«الكل» زرٌّ أوّلُ ظاهرٌ ومختارٌ عند الفتح**، والأربعةُ اختيارٌ واحد: الرجوعُ إلى المجموع
/// لمسةٌ على اسمه، لا لمسةٌ ثانية على زرٍّ لا يقول إنه يُرجع. والجمعُ على السلاسل بـ
/// [addDecimals] لا بـ `double`.
///
/// **ولا سطرَ شرحٍ تحت الرقم**: رُفض على صفحة المستثمر — الاسمُ فوقه يكفيه.
class InvestorProfitTile extends StatefulWidget {
  const InvestorProfitTile({
    required this.awaitingDelivery,
    required this.pending,
    required this.available,
    super.key,
    this.icon,
  });

  final String awaitingDelivery;
  final String pending;
  final String available;
  final IconData? icon;

  @override
  State<InvestorProfitTile> createState() => _InvestorProfitTileState();
}

class _InvestorProfitTileState extends State<InvestorProfitTile> {
  /// null هو «الكل».
  ProfitGate? _gate;

  @override
  Widget build(BuildContext context) {
    final (label, amount) = switch (_gate) {
      null => (
        'إجمالي الأرباح',
        addDecimals(addDecimals(widget.awaitingDelivery, widget.pending), widget.available),
      ),
      ProfitGate.awaitingDelivery => ('ربح قيد التسليم', widget.awaitingDelivery),
      ProfitGate.pending => ('أرباح معلّقة', widget.pending),
      ProfitGate.available => ('أرباح متاحة للسحب', widget.available),
    };

    return InvestorMoneyTile(
      label: label,
      amount: amount,
      icon: widget.icon,
      footer: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: [
          for (final (gate, word) in const <(ProfitGate?, String)>[
            (null, 'الكل'),
            (ProfitGate.awaitingDelivery, 'قيد التسليم'),
            (ProfitGate.pending, 'معلّقة'),
            (ProfitGate.available, 'متاحة للسحب'),
          ])
            FilterOptionChip(
              label: word,
              isSelected: _gate == gate,
              onTap: () => setState(() => _gate = gate),
            ),
        ],
      ),
    );
  }
}
