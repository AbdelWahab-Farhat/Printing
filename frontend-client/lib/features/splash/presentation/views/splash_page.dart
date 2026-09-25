import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/router/app_router.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/features/splash/presentation/viewmodel/splash_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// The first screen: the wordmark, and the decision about where to go next.
///
/// Its reason to exist is the failure case. Without it the app opened home on the strength of a
/// stored token alone, and a phone with no signal got a home screen that looked fine and failed
/// section by section. Here the check happens once, and when the server cannot be reached the
/// customer is told so in one place — and told that their session is intact, so they do not go
/// looking for the login screen to fix it.
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
                  const _Wordmark(),
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

/// «FlyerX» مكتوباً، بحجم شاشةٍ لا شريط.
///
/// **ليس `BrandMark`**: ذاك بلون ترويسة شاشة الدخول الكحلية — «Flyer» أبيض — وهذه الشاشة على
/// السطح الفاتح، فيختفي عليها. والاسم لاتينيٌّ في تطبيقٍ من اليمين، فاتجاهه مثبّت.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'Flyer', style: TextStyle(color: scheme.onSurface)),
          TextSpan(text: 'X', style: TextStyle(color: scheme.primary)),
        ],
      ),
      style: context.textTheme.displaySmall?.copyWith(
        fontSize: 44.sp,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        height: 1.1,
      ),
      textDirection: TextDirection.ltr,
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
