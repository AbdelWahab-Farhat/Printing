import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/features/access/models/role.dart';

/// One section of permissions — a heading, a count, and the permissions under it.
///
/// **Twenty-five checkboxes in one column is a list nobody reads to the end.** The catalogue
/// arrives from the server already cut into the parts of the business it belongs to — «العملاء»,
/// «الطلبيات», «حالات الطلبيات» — and this draws one of those, in the same shape whether the
/// permissions are being *chosen* or merely *read*.
///
/// That sameness is the point. Somebody who ticked six boxes under «حالات الطلبيات» should find
/// those six under a heading of the same name, in the same order, on the screen that tells them
/// what the role ended up with. A read-only view laid out differently from the editor makes the
/// reader do the matching by hand.
///
/// Two modes, one widget:
///   * **[PermissionSection.editable]** — a checkbox per permission and a header that ticks the
///     whole section, for the form.
///   * **[PermissionSection.readOnly]** — the same rows without the boxes, for the role screen.
class PermissionSection extends StatelessWidget {
  const PermissionSection.editable({
    required this.group,
    required this.isSelected,
    required this.onToggle,
    required this.onToggleGroup,
    required this.selectedCount,
    super.key,
  }) : _isEditable = true;

  /// The granted subset of a section, drawn without any way to change it.
  const PermissionSection.readOnly({required this.group, super.key})
    : _isEditable = false,
      isSelected = null,
      onToggle = null,
      onToggleGroup = null,
      selectedCount = null;

  final PermissionGroup group;
  final bool _isEditable;

  /// Whether one permission is ticked. Editable mode only.
  final bool Function(String permissionName)? isSelected;

  final ValueChanged<String>? onToggle;
  final VoidCallback? onToggleGroup;

  /// How many of this section are ticked — what the header counts. Editable mode only.
  final int? selectedCount;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final radius = BorderRadius.circular(16.r);

    // A `Material` for the surface, not a coloured `Container`: the rows below are
    // `CheckboxListTile`s, and they paint their ink on the nearest `Material` ancestor. A
    // `DecoratedBox` carrying the colour would sit in front of that and swallow every splash —
    // the boxes would still tick, and the taps would look like they did nothing.
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      // Border only, no colour: the colour is the Material's below.
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Material(
        color: scheme.surfaceContainerLowest,
        borderRadius: radius,
        // So the first and last rows' ink does not paint over the rounded corners.
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              title: group.title,
              // In the editor the count is «٤ من ٦», because what matters is how much of this
              // section is granted. Reading a role, every row shown *is* granted, so the count is
              // simply how many.
              trailing: _isEditable
                  ? '${selectedCount ?? 0} من ${group.permissions.length}'
                  : '${group.permissions.length}',
              isEditable: _isEditable,
              isWholeGroupSelected:
                  _isEditable && (selectedCount ?? 0) == group.permissions.length,
              onToggleGroup: onToggleGroup,
            ),
            Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.45)),
            for (final permission in group.permissions)
              _isEditable
                  ? _PermissionCheckbox(
                      permission: permission,
                      isSelected: isSelected?.call(permission.name) ?? false,
                      onToggle: () => onToggle?.call(permission.name),
                    )
                  : _GrantedRow(permission: permission),
          ],
        ),
      ),
    );
  }
}

/// The section's name, what it holds, and — when editing — one tap for all of it.
class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.trailing,
    required this.isEditable,
    required this.isWholeGroupSelected,
    required this.onToggleGroup,
  });

  final String title;
  final String trailing;
  final bool isEditable;
  final bool isWholeGroupSelected;
  final VoidCallback? onToggleGroup;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 12.w, 12.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(100.r),
            ),
            child: Text(
              trailing,
              style: context.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          if (isEditable) ...[
            SizedBox(width: 4.w),
            // A "select all" that is a text button, not a third checkbox: a checkbox in the
            // header of a list of checkboxes reads as one more permission to grant.
            TextButton(
              onPressed: onToggleGroup,
              child: Text(isWholeGroupSelected ? 'إلغاء الكل' : 'تحديد الكل'),
            ),
          ],
        ],
      ),
    );
  }
}

/// One permission, with a box.
class _PermissionCheckbox extends StatelessWidget {
  const _PermissionCheckbox({
    required this.permission,
    required this.isSelected,
    required this.onToggle,
  });

  final PermissionOption permission;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: isSelected,
      onChanged: (_) => onToggle(),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      visualDensity: VisualDensity.compact,
      title: Text(
        permission.label,
        style: context.textTheme.bodyMedium?.copyWith(color: context.colorScheme.onSurface),
      ),
      // The machine name under the Arabic: it is what a route's `can:` names, so it is what
      // somebody reads out when a permission is not doing what they expect.
      subtitle: Text(
        permission.name,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
        style: context.textTheme.labelSmall?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// One permission the role holds, on the screen that only reports.
class _GrantedRow extends StatelessWidget {
  const _GrantedRow({required this.permission});

  final PermissionOption permission;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 9.h, 16.w, 9.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Icon(AppIcons.activate, size: 16.sp, color: scheme.primary),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  permission.label,
                  style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
                ),
                Text(
                  permission.name,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                  style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
