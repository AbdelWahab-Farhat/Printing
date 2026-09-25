import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/theme/theme_mode_cubit.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «مظهر التطبيق» — the three answers, and which one is in force.
///
/// **Rows rather than the three circles of `attachment_sheet.dart`**, and the difference is the
/// thing being chosen. There, the glyph *is* the answer: a camera says camera before the word
/// under it is read. Here the difference between «حسب النظام» and «داكن» on a phone that is
/// already dark is not a picture, it is a sentence — so each option gets a line to say what it
/// does, which a circle has nowhere to put.
///
/// **It closes on the tap.** The choice takes effect under the sheet as it goes, so there is no
/// «حفظ» to press and nothing to confirm: the app repainting *is* the confirmation.
///
/// Returns nothing. The cubit is the answer, and a caller that wanted one back would be a second
/// place deciding what the app looks like.
Future<void> showThemeModeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    // The rounded top, as everywhere: a square-cornered sheet under an app whose every card is
    // rounded reads as another app.
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (context) => const _ThemeModeSheet(),
  );
}

class _ThemeModeSheet extends StatelessWidget {
  const _ThemeModeSheet();

  @override
  Widget build(BuildContext context) {
    final cubit = sl<ThemeModeCubit>();

    return SafeArea(
      // The home indicator sits exactly where the bottom row of a sheet does.
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: context.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'مظهر التطبيق',
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 10.h),
            BlocBuilder<ThemeModeCubit, ThemeMode>(
              bloc: cubit,
              builder: (context, current) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final mode in ThemeMode.values)
                    _ModeRow(
                      mode: mode,
                      isSelected: mode == current,
                      onTap: () {
                        // Not awaited: the palette changes on this frame and the disk write
                        // follows. See [ThemeModeCubit.choose].
                        cubit.choose(mode).ignore();
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  const _ModeRow({required this.mode, required this.isSelected, required this.onTap});

  final ThemeMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 12.h),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    mode.label,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? scheme.primary : scheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    mode.description,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // The tick is the only mark of the current choice — a radio circle beside three rows
            // that are already a list is a second control saying the same thing.
            if (isSelected) Icon(AppIcons.check, size: 20.sp, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}
