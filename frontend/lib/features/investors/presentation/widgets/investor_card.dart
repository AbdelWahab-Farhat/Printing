import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/register_card.dart';
import 'package:dayaa/features/investors/models/investor.dart';
import 'package:flutter/material.dart';

/// One investor in the list.
///
/// The same [RegisterCard] the customers and the suppliers are drawn in; what belongs to an
/// investor is his money — **what he has with us, and what he has earned** — because that is what
/// he is in the register for, and it was previously a tap away on his own screen.
///
/// The whole page's figures come back in one query with the list, so the register costs what it
/// always did. `capital` is both places his capital can be, his wallet and the deals it is
/// committed to; the two are told apart on his own screen, where the distinction is the point.
/// «12,500 د.ل», or a dash where the list came back without figures — never a zero invented
/// here, which would read as «لا شيء عنده» about a man whose ledger simply was not sent.
String _money(String? amount) =>
    amount == null ? '–' : '${groupedDecimal(amount)} د.ل';

class InvestorCard extends StatelessWidget {
  const InvestorCard({required this.investor, required this.onTap, super.key});

  final Investor investor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RegisterCard(
      title: investor.name,
      code: investor.code,
      icon: AppIcons.investors,
      tone: investor.isActive ? RegisterTone.investors : RegisterTone.muted,
      badge: investor.isActive ? null : 'موقوف',
      onTap: onTap,
      fields: [
        RegisterField(
          label: 'رأس المال',
          value: _money(investor.totals?.capital),
        ),
        RegisterField(
          label: 'الأرباح',
          value: _money(investor.totals?.profit),
        ),
        RegisterField(
          label: 'رقم الهاتف',
          value: investor.phone ?? '–',
          valueDirection: TextDirection.ltr,
        ),
      ],
    );
  }
}
