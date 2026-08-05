import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/features/business_fields/models/business_field.dart';
import 'package:printing/features/business_fields/presentation/viewmodel/business_fields_cubit.dart';

/// «مجال العمل» on a shop row — pick a trade, or leave it unanswered.
///
/// **Optional on purpose, and it says so.** The first entry is «غير محدد», because a shop
/// recorded at speed with no trade is a real shop and this field must never be the thing that
/// stops it being saved. A required picker would be answered at random, which is worse than
/// nothing for the reports this list exists to make possible.
///
/// It reads the list from a [BusinessFieldsCubit] provided *above the whole form*, not one per
/// row: three shops must not be three identical requests, and every row offers the same list.
///
/// A field that is no longer offered but is already on this shop stays selectable — it is
/// merged into the options below. Otherwise opening an old customer would silently blank a
/// trade that was recorded years ago, which is the one thing a form must never do to data it
/// was only asked to display.
class BusinessFieldPicker extends StatelessWidget {
  const BusinessFieldPicker({
    required this.value,
    required this.onChanged,
    this.current,
    this.errorText,
    super.key,
  });

  /// The id currently on the shop, or null for «غير محدد».
  final int? value;

  final ValueChanged<int?> onChanged;

  /// The trade already recorded on this shop, when the form was opened on an existing one. It
  /// is what keeps a stopped field selectable rather than blanked.
  final BusinessField? current;

  /// The server's complaint about `shops.N.business_field_id`, if it made one.
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BusinessFieldsCubit, BusinessFieldsState>(
      builder: (context, state) {
        final fields = _options(state, current);

        return DropdownButtonFormField<int?>(
          initialValue: fields.any((field) => field.id == value) ? value : null,
          decoration: InputDecoration(
            labelText: 'مجال العمل',
            prefixIcon: Icon(AppIcons.businessField),
            errorText: errorText,
            // The list may still be arriving, or the account may have no fields to offer. Both
            // are said out loud rather than left as an empty dropdown the user taps twice.
            helperText: switch (state) {
              BusinessFieldsLoading() => 'جارٍ تحميل المجالات…',
              BusinessFieldsLoaded() when fields.isEmpty => 'لا توجد مجالات عمل بعد',
              BusinessFieldsFailure() => 'تعذّر تحميل المجالات',
              _ => null,
            },
          ),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text(
                'غير محدد',
                style: TextStyle(color: context.colorScheme.onSurfaceVariant),
              ),
            ),
            for (final field in fields)
              DropdownMenuItem<int?>(
                value: field.id,
                child: Text(
                  field.isActive ? field.name : '${field.name} (موقوف)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: onChanged,
          borderRadius: BorderRadius.circular(12.r),
          isExpanded: true,
        );
      },
    );
  }
}

/// What the dropdown offers: the fields on offer, plus this shop's own if it is not among them.
List<BusinessField> _options(BusinessFieldsState state, BusinessField? current) {
  final loaded = switch (state) {
    BusinessFieldsLoaded(:final page) => page.items,
    _ => const <BusinessField>[],
  };

  if (current == null || loaded.any((field) => field.id == current.id)) return loaded;

  return [...loaded, current];
}
