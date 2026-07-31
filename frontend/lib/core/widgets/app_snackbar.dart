/// A toast that slides up over everything, including dialogs and sheets.
///
/// An `Overlay` entry rather than `ScaffoldMessenger`: a message raised from inside a dialog
/// or a bottom sheet would otherwise be drawn behind it, and the user never sees the reason
/// their action failed.
///
/// **Only one is on screen at a time.** The state below is deliberately library-level, because
/// "only one" has to hold across every widget in the app — a Cubit failing three requests at
/// once would otherwise stack three identical toasts. A repeat of the message already showing
/// extends it instead of queueing.
///
/// Colours come from the theme's `ColorScheme`, so the toast follows the palette rather than
/// hard-coding greens and reds that clash with it.
library;

import 'dart:async';

import 'package:flutter/material.dart';

enum SnackType { success, error, warning, info }

OverlayEntry? _entry;
AnimationController? _controller;
Timer? _timer;
String? _signature;

Future<void> showCustomSnackBar({
  required BuildContext context,
  required String title,
  String? subtitle,
  SnackType type = SnackType.info,
  Duration duration = const Duration(seconds: 3),
  IconData? icon,

  /// When false, a *different* message replaces the one on screen instead of being dropped.
  /// The default protects a burst of errors from flickering past unread.
  bool keepCurrent = true,
}) async {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  final signature = '${type.name}|$title|${subtitle ?? ''}';

  if (_entry != null) {
    // The same message again: keep it up longer rather than restart it.
    if (_signature == signature) {
      _scheduleDismiss(duration);

      return;
    }

    if (keepCurrent) return;

    await _dismissNow();
  }

  if (!context.mounted) return;

  final scheme = Theme.of(context).colorScheme;
  final (background, foreground) = switch (type) {
    SnackType.success => (scheme.primaryContainer, scheme.onPrimaryContainer),
    SnackType.error => (scheme.errorContainer, scheme.onErrorContainer),
    SnackType.warning => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
    SnackType.info => (scheme.secondaryContainer, scheme.onSecondaryContainer),
  };

  final leading = icon ?? switch (type) {
    SnackType.success => Icons.check_circle_outline_rounded,
    SnackType.error => Icons.error_outline_rounded,
    SnackType.warning => Icons.warning_amber_rounded,
    SnackType.info => Icons.info_outline_rounded,
  };

  final controller = AnimationController(
    vsync: Navigator.of(context),
    duration: const Duration(milliseconds: 250),
    reverseDuration: const Duration(milliseconds: 200),
  );

  final offset = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
    CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ),
  );

  final entry = OverlayEntry(
    builder: (context) => Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 24,
      child: SlideTransition(
        position: offset,
        child: FadeTransition(
          opacity: controller,
          child: _SnackCard(
            title: title,
            subtitle: subtitle,
            icon: leading,
            background: background,
            foreground: foreground,
            onDismiss: _dismissNow,
          ),
        ),
      ),
    ),
  );

  _entry = entry;
  _controller = controller;
  _signature = signature;

  overlay.insert(entry);
  unawaited(controller.forward());

  _scheduleDismiss(duration);
}

void _scheduleDismiss(Duration duration) {
  _timer?.cancel();
  _timer = Timer(duration, _dismissNow);
}

Future<void> _dismissNow() async {
  final entry = _entry;
  final controller = _controller;
  if (entry == null || controller == null) return;

  // Cleared up front so a second call while the reverse animation runs cannot remove the
  // same entry twice — which throws.
  _entry = null;
  _controller = null;
  _signature = null;
  _timer?.cancel();
  _timer = null;

  try {
    await controller.reverse();
  } finally {
    controller.dispose();
    entry.remove();
  }
}

class _SnackCard extends StatelessWidget {
  const _SnackCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onDismiss,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Future<void> Function() onDismiss;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: Dismissible(
        key: ValueKey(title),
        direction: DismissDirection.down,
        onDismissed: (_) => onDismiss(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: foreground),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: textTheme.bodySmall?.copyWith(
                          color: foreground.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
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
