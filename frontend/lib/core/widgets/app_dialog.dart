import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum DialogSeverity { info, success, warning, danger }

/// The app's one confirmation dialog.
///
/// Returns `true` when confirmed, `false` when cancelled, and `null` when dismissed by tapping
/// outside — three outcomes, because "dismissed" is not the same as "no" for a destructive
/// action and the caller may want to treat it differently.
///
/// ```dart
/// final confirmed = await showCustomDialog(
///   context: context,
///   title: 'حذف المدينة',
///   description: 'سيتم حذف كل المناطق داخلها. لا يمكن التراجع.',
///   severity: DialogSeverity.danger,
///   confirmLabel: 'حذف',
/// );
/// if (confirmed ?? false) { … }
/// ```
Future<bool?> showCustomDialog({
  required BuildContext context,
  required String title,
  required String description,
  String confirmLabel = 'تأكيد',
  String? cancelLabel = 'إلغاء',
  DialogSeverity severity = DialogSeverity.info,
  bool barrierDismissible = true,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) => _AppDialog(
      title: title,
      description: description,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      severity: severity,
    ),
  );
}

/// Confirmation for something that cannot be undone. Same dialog, but the confirm button is
/// the error colour and dismissing by tapping outside is off — a destructive action should
/// take a deliberate tap.
Future<bool?> showDestructiveDialog({
  required BuildContext context,
  required String title,
  required String description,
  String confirmLabel = 'حذف',
}) {
  return showCustomDialog(
    context: context,
    title: title,
    description: description,
    confirmLabel: confirmLabel,
    severity: DialogSeverity.danger,
    barrierDismissible: false,
  );
}

class _AppDialog extends StatelessWidget {
  const _AppDialog({
    required this.title,
    required this.description,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.severity,
  });

  final String title;
  final String description;
  final String confirmLabel;
  final String? cancelLabel;
  final DialogSeverity severity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (badgeBackground, badgeForeground) = switch (severity) {
      DialogSeverity.success => (scheme.primaryContainer, scheme.onPrimaryContainer),
      DialogSeverity.warning => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      DialogSeverity.danger => (scheme.errorContainer, scheme.onErrorContainer),
      DialogSeverity.info => (scheme.secondaryContainer, scheme.onSecondaryContainer),
    };

    final icon = switch (severity) {
      DialogSeverity.success => Icons.check_circle_rounded,
      DialogSeverity.warning => Icons.warning_amber_rounded,
      DialogSeverity.danger => Icons.delete_forever_rounded,
      DialogSeverity.info => Icons.info_rounded,
    };

    return AlertDialog(
      // The dialog's own shape, not a bespoke Material + BackdropFilter: AlertDialog already
      // handles the barrier, focus trapping, the back button and screen readers, and every
      // one of those is a thing a hand-rolled dialog quietly loses.
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      icon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: badgeBackground, shape: BoxShape.circle),
        child: Icon(icon, color: badgeForeground, size: 28),
      ),
      title: Text(title, textAlign: TextAlign.center),
      titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      content: ConstrainedBox(
        // A long message scrolls inside the dialog instead of pushing the buttons off-screen.
        constraints: const BoxConstraints(maxHeight: 260),
        child: SingleChildScrollView(
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: scheme.onSurface.withValues(alpha: 0.86),
            ),
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        if (cancelLabel != null)
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel!),
          ),
        FilledButton(
          style: severity == DialogSeverity.danger
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                )
              : null,
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop(true);
          },
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
