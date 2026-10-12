import 'dart:async';

import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/widgets/app_dialog.dart';
import 'package:dayaa_client/features/wallet/presentation/viewmodel/top_up_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// «بوابة الدفع» — صفحة البطاقة المصرفية من EzonePay **داخل التطبيق** بملء الشاشة، على نسق بريمولا
/// (`payment_gateway_view.dart`). CUSTOMER-WALLET §٥.
///
/// - **تُغلق نفسها حين يصل المال**: [TopUpCubit] يسأل الخادم كل بضع ثوانٍ، ولحظةَ تخرج المحاولة من
///   الانتظار تُطوى الصفحة وتظهر النهاية تحتها. الزبون لا يبحث عن مخرجٍ بعد أن دفع.
/// - **الخروج بتأكيد**: ✕ أو زرّ الرجوع يسأل الخادم مرّةً أولاً — أرجح لحظةٍ يكون فيها الدفع قد وصل
///   للتوّ — ثم، إن بقيت تنتظر، «لم تكتمل عملية الدفع بعد… هل تريد الخروج؟».
/// - **مقاسٌ ثابت**: لا تتغيّر الصفحة مع لوحة المفاتيح، فلا ترتعش صفحة البطاقة عند كل حقل.
///
/// سكربت بريمولا المحقون (إخفاء علامة EzonePay ودعمها) لم يُنقل: يُضبط على صفحة EzonePay الحقيقية
/// بعد البيئة التجريبية.
class PaymentGatewayPage extends StatefulWidget {
  const PaymentGatewayPage({required this.url, super.key});

  final String url;

  /// تُدفع فوق «اشحن محفظتك» بالـCubit نفسه — هو من يسأل، وهو من يقول إن وصل المال.
  static Future<void> open(BuildContext context, String url) {
    final cubit = context.read<TopUpCubit>();

    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => BlocProvider<TopUpCubit>.value(value: cubit, child: PaymentGatewayPage(url: url)),
      ),
    );
  }

  @override
  State<PaymentGatewayPage> createState() => _PaymentGatewayPageState();
}

class _PaymentGatewayPageState extends State<PaymentGatewayPage> {
  /// null لرابطٍ لا يُقرأ — فلا يُشغَّل متصفحٌ بلا صفحة.
  WebViewController? _controller;

  /// الغطاء الأبيض للتحميل الأول وحده؛ التنقّلات بعده يكفيها الشريط.
  bool _firstLoadDone = false;
  int _progress = 0;
  bool _loading = true;
  bool _canGoBack = false;
  String _host = '';

  /// يُرفع قبل الخروج وحده — `PopScope` يعترض كل `pop`، حتى الذي يأتي من زرّ التأكيد نفسه.
  bool _allowExit = false;

  bool _checking = false;

  static final Set<Factory<OneSequenceGestureRecognizer>> _gestures = {
    const Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
  };

  @override
  void initState() {
    super.initState();

    final uri = widget.url.isEmpty ? null : Uri.tryParse(widget.url);

    if (uri == null || !uri.hasScheme) {
      _loading = false;

      return;
    }

    _host = uri.host;
    _controller = WebViewController()
      ..enableZoom(false)
      ..setBackgroundColor(Colors.white)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (_) {
            if (!mounted) return;

            setState(() {
              _loading = true;
              _progress = 0;
            });
          },
          onPageFinished: (_) {
            unawaited(_refreshHistory());

            if (!mounted) return;

            setState(() {
              _loading = false;
              _firstLoadDone = true;
            });
          },
          onUrlChange: (change) {
            final host = Uri.tryParse(change.url ?? '')?.host ?? '';
            if (mounted && host.isNotEmpty && host != _host) setState(() => _host = host);
          },
        ),
      )
      ..loadRequest(uri);
  }

  Future<void> _refreshHistory() async {
    final canGoBack = await _controller?.canGoBack() ?? false;

    if (mounted) setState(() => _canGoBack = canGoBack);
  }

  /// ✕ أو الرجوع: سؤالٌ أخير للخادم قبل التأكيد.
  Future<void> _confirmExit() async {
    final cubit = context.read<TopUpCubit>();

    if (_checking) return;

    setState(() => _checking = true);
    await cubit.check();

    if (!mounted || _allowExit) return;

    setState(() => _checking = false);

    if (cubit.state is! TopUpWaiting) {
      _exit();

      return;
    }

    final leave = await showCustomDialog(
      context: context,
      title: 'إلغاء عملية الدفع',
      description:
          'لم تكتمل عملية الدفع بعد. هل تريد الخروج من صفحة الدفع؟\n'
          'إن كنت قد أتممت الدفع فستُشحن محفظتك خلال لحظات.',
      severity: DialogSeverity.warning,
      confirmLabel: 'خروج',
      cancelLabel: 'متابعة الدفع',
    );

    if (leave == true && mounted) _exit();
  }

  /// يفتح الباب ثم يُغلق بعد إعادة البناء — `canPop` تُقرأ من الإطار لا من النداء.
  void _exit() {
    if (_allowExit) return;

    setState(() => _allowExit = true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final navigator = Navigator.of(context);
      final route = ModalRoute.of(context);

      // **Only this page, and only while it is still up.** The sheet beneath may have closed it
      // already on the same news — a blind `pop()` here would then close the sheet instead.
      if (route == null || !route.isActive) return;

      // The confirmation, if it is open, is a route above this one.
      navigator.popUntil((r) => r == route);
      navigator.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final scheme = context.colorScheme;

    return BlocListener<TopUpCubit, TopUpState>(
      // وصل المال أو انتهت المحاولة — الصفحة تُطوى بلا سؤال، والنهاية تحتها.
      listenWhen: (_, current) => current is! TopUpWaiting,
      listener: (_, _) => _exit(),
      child: PopScope(
        canPop: _allowExit,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) unawaited(_confirmExit());
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: Column(
              children: [
                _GatewayHeader(
                  host: _host,
                  isChecking: _checking,
                  onClose: () => unawaited(_confirmExit()),
                  onBack: (_canGoBack && controller != null)
                      ? () async {
                          await controller.goBack();
                          await _refreshHistory();
                        }
                      : null,
                  onReload: controller?.reload,
                ),
                const _WatchingBanner(),
                SizedBox(
                  height: 2.h,
                  child: (_loading && _progress > 0 && _progress < 100)
                      ? LinearProgressIndicator(value: _progress / 100, minHeight: 2.h)
                      : null,
                ),
                Expanded(
                  child: controller == null
                      ? Center(
                          child: Text('رابط الدفع غير صالح', style: TextStyle(color: scheme.error)),
                        )
                      : Stack(
                          children: [
                            Positioned.fill(
                              child: WebViewWidget(controller: controller, gestureRecognizers: _gestures),
                            ),
                            if (!_firstLoadDone)
                              const Positioned.fill(
                                child: ColoredBox(
                                  color: Colors.white,
                                  child: Center(child: CircularProgressIndicator()),
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ✕، والعنوان، واسمُ الموقع بقفل — ليطمئن الزبون أين يكتب بطاقته — والرجوع والتحديث داخل الصفحة.
class _GatewayHeader extends StatelessWidget {
  const _GatewayHeader({
    required this.host,
    required this.isChecking,
    required this.onClose,
    required this.onBack,
    required this.onReload,
  });

  final String host;
  final bool isChecking;
  final VoidCallback onClose;
  final Future<void> Function()? onBack;
  final Future<void> Function()? onReload;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final quiet = scheme.onSurface.withValues(alpha: .55);

    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 4.h, 4.w, 8.h),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: .3))),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'إغلاق',
            onPressed: isChecking ? null : onClose,
            icon: isChecking
                ? SizedBox.square(dimension: 18.sp, child: const CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.close_rounded),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'بوابة الدفع',
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (host.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_rounded, size: 12.sp, color: quiet),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          host,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.ltr,
                          style: context.textTheme.bodySmall?.copyWith(color: quiet),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'رجوع في الصفحة',
            onPressed: onBack == null ? null : () => unawaited(onBack!()),
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
          ),
          IconButton(
            tooltip: 'تحديث الصفحة',
            onPressed: onReload == null ? null : () => unawaited(onReload!()),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

/// بدونه يظنّ الزبون — بحقّ — أن عليه أن يفعل شيئاً بعد الإيصال.
class _WatchingBanner extends StatelessWidget {
  const _WatchingBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      color: scheme.primary.withValues(alpha: .06),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_outlined, size: 14.sp, color: scheme.primary),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              'نتابع العملية تلقائياً؛ تُغلق هذه الصفحة بمجرّد وصول المبلغ.',
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: .72),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
