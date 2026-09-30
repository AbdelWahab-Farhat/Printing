import 'dart:async';
import 'dart:io' show Platform;

import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/network/api_endpoints.dart';
import 'package:dayaa_client/core/network/safe_request.dart';
import 'package:dayaa_client/core/push/push_service.dart';
import 'package:dayaa_client/core/storage/token_storage.dart';
import 'package:dayaa_client/features/auth/models/customer_account.dart';
import 'package:dayaa_client/features/auth/repositories/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Fulfils [AuthRepository] over HTTP, and owns where the token is kept.
///
/// **أقصرُ من نظيره في تطبيق الموظفين باعتماديَّتين، وكلُّ غيابٍ قرارٌ مسجَّل في BACKLOG.md.** لا
/// `Session` يُتبنّى فيها الحساب، لأنّ العميل لا يحمل صلاحياتٍ يقرؤها شيء. ولا `SettingsRepository`:
/// ليس للعميل مفتاحُ «الإشعارات»، وإعدادُ الإشعارات في الهاتف نفسه هو المفتاح.
///
/// **و[PushService] هنا للسبب الذي جعل الرمزَ هنا**: لو كان على الشاشة أن تتذكّر تسجيلَ الجهاز أو
/// تحريرَه، لتركت الشاشةُ التي تنسى هاتفاً تصله طلبياتُ العميل السابق. يُسأل النظامُ عند الدخول
/// وإنشاء الحساب — اللحظةُ التي يستحقّ فيها الطلبُ جواباً — والفتحُ بجلسةٍ محفوظة يعيد التسجيل بلا
/// سؤال. والتحريرُ في [logout] *قبل* الطلب، لأنّ التحرير نفسه طلبٌ موثَّق.
///
/// Storing the token here rather than in the Cubit is deliberate: persistence is a data concern,
/// and if the ViewModel had to remember to save it, the one screen that forgot would produce a
/// session that works until the app restarts and then mysteriously does not.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._dio, this._tokens, this._push);

  final Dio _dio;
  final TokenStorage _tokens;
  final PushService _push;

  @override
  Future<Either<Failure, AuthSession>> register({
    required String name,
    required String phone,
    required String password,
  }) async {
    final result = await safeRequest<AuthSession>(
      () => _dio.post(
        AuthEndpoints.register,
        data: <String, dynamic>{
          'name': name,
          'phone': phone,
          'password': password,
          // The server asks for it confirmed. The same value is sent rather than a second field
          // being carried down here: the screen already compares the two before it calls, and a
          // mismatch should be a message beside the field rather than a round trip.
          'password_confirmation': password,
          'device_name': _deviceName(),
        },
      ),
      parse: (data) => AuthSession.fromJson(data as Map<String, dynamic>),
    );

    return _persist(result);
  }

  @override
  Future<Either<Failure, AuthSession>> login({
    required String phone,
    required String password,
  }) async {
    final result = await safeRequest<AuthSession>(
      () => _dio.post(
        AuthEndpoints.login,
        data: <String, dynamic>{
          // The field is `phone`, not `login`. The staff endpoint accepts an email *or* a phone
          // and so calls its field `login`; a customer account has only ever had one
          // identifier, so the customer endpoint names it plainly and no translation is needed.
          'phone': phone,
          'password': password,

          // Names the token so a person can see their devices and revoke one of them.
          'device_name': _deviceName(),
        },
      ),
      parse: (data) => AuthSession.fromJson(data as Map<String, dynamic>),
    );

    return _persist(result);
  }

  @override
  Future<Either<Failure, CustomerAccount>> currentCustomer() async {
    final result = await safeRequest<CustomerAccount>(
      () => _dio.get(AuthEndpoints.me),
      parse: (data) => CustomerAccount.fromJson(data as Map<String, dynamic>),
    );

    return result.fold(
      (failure) async {
        // The server has disowned this token, so keeping it would send the customer in a loop:
        // start-up trusts it, the first request 401s, and they land back at the login screen
        // still holding the dead token.
        if (failure is UnauthorizedFailure) await _tokens.clear();

        return Left(failure);
      },
      (customer) async {
        // الفتحُ بجلسةٍ محفوظة: قد يكون التوكن دار والتطبيق مغلق، أو سمح العميلُ بالإشعارات من
        // إعدادات الهاتف منذ آخر مرّة. **بلا سؤال** — طلبُ الإذن على شاشة البداية يكسب «لا»
        // دائمة، وiOS لا يسأل مرّتين. ودون انتظار: شاشةُ البداية لا تنتظر FCM.
        unawaited(_push.register(askPermission: false));

        return Right(customer);
      },
    );
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    // **قبل الطلب وقبل مسح الرمز**: التحريرُ نفسه طلبٌ موثَّق، وبعد أيٍّ منهما يُرفض بـ401 فيبقى
    // الجهاز مسجَّلاً للعميل الذي خرج.
    await _push.release();

    final result = await safeCommand(() => _dio.post(AuthEndpoints.logout));

    // Cleared whatever the server said. If the request failed because the phone is offline, the
    // person still asked to sign out and must not be left signed in — the worst case is a token
    // that stays valid server-side until it expires, which is far better than a shared phone
    // that never logs out.
    await _tokens.clear();

    return result.map((_) => unit);
  }

  @override
  bool get hasStoredToken => _tokens.hasTokenInMemory;

  /// Writes the token before handing the session back, so the next request is authenticated
  /// without the caller having to sequence anything.
  ///
  /// Both branches are async on purpose: mixing a sync one with an async one makes `fold` infer
  /// a useless common supertype instead of `Future<Either<…>>`.
  Future<Either<Failure, AuthSession>> _persist(
    Either<Failure, AuthSession> result,
  ) async {
    return result.fold(
      (failure) async => Left(failure),
      (session) async {
        await _tokens.write(session.token);

        // **الإذنُ يُطلب هنا، عند الدخول وإنشاء الحساب، ولا يُطلب على شاشة البداية.** بعد أن
        // صار للعميل ما يُخطَر به؛ وقبلها يكسب الطلبُ «لا» دائمة. بعد كتابة الرمز لأنّ التسجيل
        // طلبٌ موثَّق، ودون انتظار: رحلةٌ بطيئة إلى FCM لا تؤخّر ما خلف زرّ الدخول.
        unawaited(_push.register());

        return Right(session);
      },
    );
  }

  /// A label for the token, not an identifier — it only has to be readable in a device list.
  String _deviceName() {
    if (kIsWeb) return 'web';

    return Platform.operatingSystem;
  }
}
