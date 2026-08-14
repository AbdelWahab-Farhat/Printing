import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A place already chosen, and a tap to change it.
///
/// **A tile, not an `AppButton`.** A button is for doing something; this shows the answer and
/// opens the sheet that changes it — so the value gets the weight, and the caption above it
/// says which question that value is answering. It is the same shape the shop's map field uses
/// on the customer form, for the same reason.
///
/// It exists because the city and the region were two full-width buttons, stacked: one address
/// told as two lines, taking a third of the screen, with the *optional* half arriving as the
/// louder of the two. Two of these fit on one row at half the height, and neither has to shout
/// its own label at 54 pixels tall.
class PlacePickerTile extends StatelessWidget {
  const PlacePickerTile({
    required this.caption,
    required this.value,
    required this.isChosen,
    required this.onTap,
    super.key,
  });

  /// «المدينة» / «المنطقة» — which of the two this is, said once and quietly.
  final String caption;

  final String value;

  /// Whether [value] is an answer or an invitation. Only the colour changes: an unanswered
  /// optional field must not read as an error.
  final bool isChosen;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(12.r);

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(AppIcons.mapPin, size: 17.sp, color: scheme.onSurfaceVariant),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      caption,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      value,
                      maxLines: 1,
                      // Half a row is not wide enough for «إستلام مكتب(قرجي)», and a name cut
                      // mid-word with no mark is a different place.
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isChosen ? scheme.onSurface : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
