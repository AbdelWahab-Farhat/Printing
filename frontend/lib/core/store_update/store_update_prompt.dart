import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/store_update/store_update.dart';
import 'package:dayaa/core/widgets/app_dialog.dart';
import 'package:flutter/material.dart';

/// يعلن «تحديث جديد» فوق [child] حين تكون على App Store نسخةٌ أحدث — على آيفون وحده.
///
/// يلفّه الموجّه حول الشاشتين اللتين يبدأ منهما من دخل: إطارُ الموظفين وبوّابةُ المستثمر. لا
/// حولَ شاشة البداية أو الدخول: كلتاهما تُستبدل بـ`go`، فتذهب معها النافذة قبل أن تُقرأ.
///
/// يسأل عند فتح الشاشة وكلما عاد التطبيق من الخلفية — و[StoreUpdate] نفسه يمنع التكرار.
class StoreUpdatePrompt extends StatefulWidget {
  const StoreUpdatePrompt({required this.child, this.update, super.key});

  final Widget child;

  /// للاختبار. وفي التطبيق: من الحاوية على آيفون، ولا شيء على غيره.
  final StoreUpdate? update;

  @override
  State<StoreUpdatePrompt> createState() => _StoreUpdatePromptState();
}

class _StoreUpdatePromptState extends State<StoreUpdatePrompt> with WidgetsBindingObserver {
  bool _showing = false;

  StoreUpdate? get _update =>
      widget.update ?? (StoreUpdate.appliesHere ? sl<StoreUpdate>() : null);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_check()));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_check());
  }

  Future<void> _check() async {
    final update = _update;
    if (update == null || _showing) return;

    final release = await update.pending();
    if (release == null || !mounted || _showing) return;

    _showing = true;
    final confirmed = await showCustomDialog(
      context: context,
      title: 'تحديث جديد',
      description: 'النسخة ${release.version} متاحة على App Store',
      confirmLabel: 'تحديث',
      cancelLabel: 'لاحقاً',
    );
    _showing = false;

    // الضغطُ خارج النافذة «لاحقاً» أيضاً: لم يُرِد التحديث الآن.
    if (confirmed ?? false) {
      await update.open(release);
    } else {
      await update.snooze(release);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
