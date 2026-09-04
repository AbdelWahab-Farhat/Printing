import 'package:dayaa/features/investors/models/investor.dart';
import 'package:flutter/material.dart';

/// One row of the investors list.
///
/// Body-size type throughout, and the name is the biggest thing on it: a list is scanned for a
/// person, not for a figure.
class InvestorCard extends StatelessWidget {
  const InvestorCard({super.key, required this.investor, required this.onTap});

  final Investor investor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    investor.name,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [investor.code, if (investor.phone != null) investor.phone!].join(' · '),
                    style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (!investor.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('موقوف', style: theme.textTheme.bodyMedium),
              ),
          ],
        ),
      ),
    );
  }
}
