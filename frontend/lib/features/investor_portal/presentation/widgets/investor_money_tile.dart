import 'package:dayaa/core/utils/digits.dart';
import 'package:flutter/material.dart';

/// One figure on the investor's screen, with the sentence that says what it means.
///
/// The number is the biggest thing on the tile and carries its unit, because an amount without
/// «د.ل» beside it is a figure somebody has to guess at. Body-size type throughout — a caption
/// small enough to squint at is a caption nobody reads.
class InvestorMoneyTile extends StatelessWidget {
  const InvestorMoneyTile({
    super.key,
    required this.label,
    required this.amount,
    this.caption,
    this.emphasis = false,
  });

  final String label;

  /// A decimal string exactly as the server sent it — `'43500.00'`.
  final String amount;

  final String? caption;

  /// Whether this is one of the two figures he opens the app for.
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isNegative = amount.startsWith('-');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: emphasis ? colors.primaryContainer : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: emphasis ? colors.onPrimaryContainer : colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          // Forced left-to-right inside the RTL tree: a grouped number laid out right-to-left
          // can land its separator on the wrong side of the digits.
          Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                '${amount.grouped} د.ل',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isNegative
                      ? colors.error
                      : (emphasis ? colors.onPrimaryContainer : colors.onSurface),
                ),
              ),
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 6),
            Text(
              caption!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: emphasis ? colors.onPrimaryContainer : colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
