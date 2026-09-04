import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/investor_portal/models/investor_portfolio.dart';
import 'package:flutter/material.dart';

/// One of his deals: what he has in it, what it has earned him, and where it stands.
///
/// No quantities, no unit costs, and nobody else's share — what he financed and what it made him
/// is the whole of his business with us.
class InvestorDealCard extends StatelessWidget {
  const InvestorDealCard({super.key, required this.deal});

  final InvestorDealLine deal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isLoss = deal.profit.startsWith('-');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  deal.name ?? deal.code ?? 'صفقة',
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (deal.statusLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    deal.statusLabel!,
                    style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSecondaryContainer),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${deal.code ?? ''} · حصتي ${trimDecimals(deal.sharePercent)}%',
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Figure(label: 'رأس مالي', amount: deal.capital, color: colors.onSurface),
              ),
              Expanded(
                child: _Figure(
                  label: isLoss ? 'خسارتي' : 'ربحي',
                  amount: deal.profit,
                  color: isLoss ? colors.error : colors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.amount, required this.color});

  final String label;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              '${amount.grouped} د.ل',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
