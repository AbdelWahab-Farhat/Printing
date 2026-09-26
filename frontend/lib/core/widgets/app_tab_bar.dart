import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The strip of tabs a shell tab hangs under the shell's app bar — الجهات and المخزون.
///
/// **One widget because the two are one shape.** They are both a shell tab split into sibling
/// lists, and they used to be drawn two different ways — a Material tab bar on one and a pill
/// switch on the other — so moving between them read as moving between two apps. Written once,
/// a change to one is a change to both.
///
/// Reads its controller from the nearest [DefaultTabController], as a bare [TabBar] does.
class AppTabBar extends StatelessWidget {
  const AppTabBar({required this.labels, super.key});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return TabBar(
      // Sized to the screen rather than scrolling: short words fit, and a bar that can be
      // scrolled hides the tab at its end from anybody who never drags it.
      isScrollable: false,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: scheme.outlineVariant.withValues(alpha: 0.5),
      labelColor: scheme.primary,
      unselectedLabelColor: scheme.onSurfaceVariant,
      labelStyle: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
      unselectedLabelStyle: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      tabs: [for (final label in labels) Tab(height: 44.h, text: label)],
    );
  }
}
