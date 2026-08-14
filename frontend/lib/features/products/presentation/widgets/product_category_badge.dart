import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';

/// The catalogue heading, as the one thing on a product row that is a *kind* rather than a
/// number — أكياس, علب وكراتين, مطبوعة, سادة.
///
/// It is the question a customer opens with, and it used to be the first half of a grey subtitle
/// — read only by somebody already reading the whole card. As a tinted badge at the card's far
/// top corner it is answered before the name is, and the catalogue can be skimmed without
/// reading a word of it.
///
/// **The word is the server's and nothing here decides it.** This badge replaced one that
/// carried «النوع» — مطبوعة/سادة — and that one owned a glyph and a colour per value, which it
/// could only do because the values were two and this app knew both. A heading the business adds
/// tomorrow is a name this build has never seen, so there is one tone and one glyph: a badge
/// that guesses is worse than a badge that does not.
///
/// **Absent, not empty, for a product with no heading.** A handful were recorded before
/// categories existed; an untinted pill saying nothing would read as a category called nothing.
///
/// It is deliberately the only pill on the card. The design once tagged sizes this way too, and
/// two different kinds of data in one visual language meant the eye could not separate them; the
/// sizes are a table now, so nothing here can be mistaken for one.
class ProductCategoryBadge extends StatelessWidget {
  const ProductCategoryBadge({required this.name, super.key});

  /// The heading's Arabic, straight from the server. Null for a product not filed under one.
  final String? name;

  @override
  Widget build(BuildContext context) {
    final heading = name?.trim();
    if (heading == null || heading.isEmpty) return const SizedBox.shrink();

    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        // Not `primary`. On this card primary means money — the code, and the floor price in the
        // grid. Spending it on a badge present on every single row would leave the price column
        // competing with a label that never changes.
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8.r),
      ),
      // A long heading takes what the name column can spare and no more: «ستيكرات ومطبوعات
      // أخرى» must not push the card's own name off its line.
      constraints: BoxConstraints(maxWidth: 120.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.productCategory, size: 13.sp, color: scheme.onSecondaryContainer),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              heading,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelSmall?.copyWith(
                color: scheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
