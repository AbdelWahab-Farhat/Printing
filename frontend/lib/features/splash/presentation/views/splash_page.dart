import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/router/app_router.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/widgets/app_button.dart';
import 'package:printing/features/splash/presentation/viewmodel/splash_cubit.dart';

/// The first screen: the brand, and the decision about where to go next.
///
/// It has a Cubit now, which the previous version of this file said it would earn "the moment it
/// grows a retry button". That moment came from a real complaint: with the connection down, the
/// app dropped the user at the login screen — asking for a password to fix something that was
/// never about their password, at the exact moment the phone could least complete a sign-in.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SplashCubit>(
      create: (_) => sl<SplashCubit>()..check(),
      child: const _SplashView(),
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: SafeArea(
        child: BlocConsumer<SplashCubit, SplashState>(
          listener: (context, state) {
            // `go`, not `push`: there must be nothing behind either destination for the back
            // button to return to — least of all this screen, which would re-run the check.
            switch (state) {
              case SplashSignedIn():
                context.go(Routes.home);

              case SplashSignedOut():
                context.go(Routes.login);

              default:
                break;
            }
          },
          builder: (context, state) => Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _Brand(),
                  SizedBox(height: 36.h),
                  // The two navigating states are already on their way out; keeping the spinner
                  // under them stops the screen flashing empty as it leaves.
                  if (state is SplashUnreachable)
                    _Unreachable(failure: state.failure)
                  else
                    SizedBox(
                      height: 26.h,
                      width: 26.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: context.colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/logo.png', height: 96.w, width: 96.w),
        SizedBox(height: 20.h),
        Text(
          'PrintX',
          // Latin brand mark inside a right-to-left app: forced LTR so the letters are never
          // reordered by the surrounding direction.
          textDirection: TextDirection.ltr,
          style: context.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: context.colorScheme.primary,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          'نطبعوا فكل شيء',
          style: context.textTheme.titleMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// The session could not be checked — and the session is not what is wrong.
///
/// It names which of the two it is, because «لا يوجد اتصال» and a server that answered badly are
/// fixed by different people. Neither is fixed by typing a password, which is why there is no
/// login form here — only a deliberate way out for somebody who wants a different account.
class _Unreachable extends StatelessWidget {
  const _Unreachable({required this.failure});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          failure.isNetwork ? AppIcons.offline : AppIcons.error,
          size: 44.sp,
          color: scheme.error,
        ),
        SizedBox(height: 14.h),
        Text(
          // The server's own words when it managed to say any; the network layer's otherwise.
          failure.message,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        ),
        SizedBox(height: 8.h),
        Text(
          'جلستك لا تزال قائمة — لا حاجة لتسجيل الدخول من جديد.',
          textAlign: TextAlign.center,
          style: context.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
        SizedBox(height: 24.h),
        AppButton(
          label: 'إعادة المحاولة',
          icon: AppIcons.refresh,
          onPressed: context.read<SplashCubit>().check,
        ),
        SizedBox(height: 4.h),
        TextButton(
          // The way out of a retry screen that a broken backend would otherwise trap somebody
          // on. It clears the token deliberately, so the next launch does not land back here.
          onPressed: context.read<SplashCubit>().abandon,
          child: Text(
            'تسجيل الدخول بحساب آخر',
            style: context.textTheme.bodyMedium?.copyWith(color: scheme.primary),
          ),
        ),
      ],
    );
  }
}
