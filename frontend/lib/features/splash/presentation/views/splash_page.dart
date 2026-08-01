import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/router/app_router.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/features/auth/repositories/auth_repository.dart';

/// The first screen: the brand, and the decision about where to go next.
///
/// No Cubit here on purpose. A Cubit models state a screen moves *between*; this one has a
/// single outcome and no interaction, so a union with one useful case would be ceremony. The
/// moment it grows a retry button it earns one.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  /// Long enough to read the name, short enough not to feel like a delay. The session check
  /// runs *alongside* it, so a slow network makes this longer but a fast one never makes the
  /// logo flash by.
  static const Duration _minimumDisplay = Duration(milliseconds: 1200);

  @override
  void initState() {
    super.initState();
    unawaited(_decideWhereToGo());
  }

  Future<void> _decideWhereToGo() async {
    final auth = sl<AuthRepository>();

    // No token at all: nothing to check, so do not spend a request finding that out.
    if (!auth.hasStoredToken) {
      await Future<void>.delayed(_minimumDisplay);
      if (mounted) context.go(Routes.login);

      return;
    }

    // A stored token is *checked*, not trusted. It may have been revoked from another device,
    // and sending someone to the home screen on a dead token means the first thing they see is
    // an error.
    //
    // The request is started before the delay is awaited, so the two overlap: the wait is the
    // slower of the two rather than their sum.
    final pendingUser = auth.currentUser();
    await Future<void>.delayed(_minimumDisplay);
    final result = await pendingUser;

    if (!mounted) return;

    context.go(result.isRight() ? Routes.home : Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PrintX',
              // Latin brand mark inside a right-to-left app: forced LTR so the letters are
              // never reordered by the surrounding direction.
              textDirection: TextDirection.ltr,
              style: context.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: context.colorScheme.primary,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'نطبعوا فكل شيء',
              style: context.textTheme.titleMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
