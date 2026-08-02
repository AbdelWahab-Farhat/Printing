import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/core/config/app_config.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/router/app_router.dart';
import 'package:printing/core/session/session.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/widgets/app_dialog.dart';
import 'package:printing/features/auth/presentation/viewmodel/logout_cubit.dart';
import 'package:printing/features/settings/presentation/viewmodel/settings_cubit.dart';

/// الإعدادات — the device's preferences, what this app is, and the way out.
///
/// Its own screen rather than a longer drawer: a drawer is for going somewhere, and a switch is
/// not a destination. Putting the toggle in the sidebar would also mean flipping it under a
/// panel that closes the moment a thumb lands anywhere else.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsCubit>(create: (_) => sl<SettingsCubit>()),
        BlocProvider<LogoutCubit>(create: (_) => sl<LogoutCubit>()),
      ],
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
          children: [
            const _SectionTitle('التنبيهات'),
            SizedBox(height: 8.h),
            const _NotificationsCard(),
            SizedBox(height: 24.h),

            const _SectionTitle('عن التطبيق'),
            SizedBox(height: 8.h),
            const _AboutCard(),
            SizedBox(height: 24.h),

            const _SectionTitle('الحساب'),
            SizedBox(height: 8.h),
            const _LogoutCard(),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 4.w),
      child: Text(
        title,
        style: context.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: context.colorScheme.primary,
        ),
      ),
    );
  }
}

/// A white block with the same corners, border and shadow as every card in the app.
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _NotificationsCard extends StatelessWidget {
  const _NotificationsCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) => SwitchListTile.adaptive(
          value: state.notificationsEnabled,
          onChanged: (isEnabled) => unawaited(
            context.read<SettingsCubit>().toggleNotifications(isEnabled: isEnabled),
          ),
          title: Text(
            'تفعيل الإشعارات',
            style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            // Says what it is for, not what it does today. The honest note about the service
            // not existing yet lives in [SetNotificationsEnabled], where a developer reads it —
            // telling the shop "this does nothing yet" is an apology, not information.
            'إشعارات الطلبات الجديدة والتحديثات على هذا الجهاز',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          secondary: Icon(AppIcons.notifications, color: context.colorScheme.primary),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        ),
      ),
    );
  }
}

/// What this app is, and — the part that earns its place — **which server it is talking to**.
///
/// An About screen listing a name and a version answers nothing anybody asks. "لماذا لا تظهر
/// الطلبات؟" is answered by the environment and the host, which is why they are here, and why
/// the host is shown only outside a production build: on a real phone it is noise, and in
/// development it is the first question.
class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    final user = sl<Session>().user;

    return _Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Image.asset('assets/images/logo.png', height: 48.w, width: 48.w),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'PrintX',
                        textDirection: TextDirection.ltr,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: context.colorScheme.primary,
                        ),
                      ),
                      Text(
                        'إدارة أكياس الطباعة والطلبات',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            const Divider(height: 1),
            SizedBox(height: 12.h),

            if (user != null) ...[
              _AboutRow(label: 'الموظف', value: user.name),
              if (user.employeeCode != null)
                _AboutRow(label: 'كود الموظف', value: '#${user.employeeCode}', isLatin: true),
            ],
            _AboutRow(
              label: 'البيئة',
              value: AppConfig.isDev ? 'تطوير' : 'إنتاج',
            ),
            // Development only: on a shop's phone the API host is noise, and here it is the
            // first thing anybody needs when the app "does not work".
            if (AppConfig.isDev)
              _AboutRow(label: 'الخادم', value: AppConfig.baseUrl, isLatin: true),
          ],
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.value, this.isLatin = false});

  final String label;
  final String value;
  final bool isLatin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              textDirection: isLatin ? TextDirection.ltr : null,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The way out, in the error colour, behind a confirmation.
///
/// Signing out is one tap from losing a half-finished screen and needing a password to get back
/// in — cheap to confirm, expensive to do by accident with a thumb.
class _LogoutCard extends StatelessWidget {
  const _LogoutCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: BlocConsumer<LogoutCubit, LogoutState>(
        listener: (context, state) {
          if (state is! LogoutSignedOut) return;

          // `go`, not `push`: the session is over, so there must be nothing behind the login
          // screen for the back button to return to.
          context.go(Routes.login);
          // Said the same way whether or not the server was reached, because from here it is
          // the same thing: the token is off this device. `state.failure` records the
          // difference for anyone who needs it, and nobody signing out needs to read about it.
          context.showSuccess('تم تسجيل الخروج');
        },
        builder: (context, state) {
          final isSubmitting = state is LogoutSubmitting;
          final scheme = context.colorScheme;

          return ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            leading: isSubmitting
                ? SizedBox(
                    height: 22.w,
                    width: 22.w,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: scheme.error),
                  )
                : Icon(AppIcons.logout, color: scheme.error),
            title: Text(
              'تسجيل الخروج',
              style: context.textTheme.titleSmall?.copyWith(
                color: scheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              'إنهاء الجلسة على هذا الجهاز',
              style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            onTap: isSubmitting ? null : () => unawaited(_confirmAndSubmit(context)),
          );
        },
      ),
    );
  }

  Future<void> _confirmAndSubmit(BuildContext context) async {
    final cubit = context.read<LogoutCubit>();

    final confirmed = await showCustomDialog(
      context: context,
      title: 'تسجيل الخروج',
      description: 'سيتم إنهاء جلستك على هذا الجهاز، وستحتاج إلى إدخال كلمة المرور مرة أخرى.',
      confirmLabel: 'خروج',
      severity: DialogSeverity.warning,
    );

    if (confirmed ?? false) await cubit.submit();
  }
}
