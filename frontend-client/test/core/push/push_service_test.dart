import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/push/push_service.dart';
import 'package:dayaa_client/features/notifications/usecases/register_device_token.dart';
import 'package:dayaa_client/features/notifications/usecases/release_device_token.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockMessaging extends Mock implements FirebaseMessaging {}

class _MockSettings extends Mock implements NotificationSettings {}

class _MockRegister extends Mock implements RegisterDeviceToken {}

class _MockRelease extends Mock implements ReleaseDeviceToken {}

/// كلُّ ما يفعله الهاتف مع FCM، بلا Firebase حقيقيّ: الإذن، والتوكن، ودورانُه، والضغطُ على إشعار.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockMessaging messaging;
  late _MockRegister registerToken;
  late _MockRelease releaseToken;
  late StreamController<String> refresh;
  late StreamController<RemoteMessage> opened;

  NotificationSettings settingsOf(AuthorizationStatus status) {
    final settings = _MockSettings();
    when(() => settings.authorizationStatus).thenReturn(status);

    return settings;
  }

  PushService build({bool firebaseIsUp = true}) => PushService(
    registerToken: registerToken,
    releaseToken: releaseToken,
    messaging: firebaseIsUp ? messaging : null,
    openedApp: firebaseIsUp ? opened.stream : null,
  );

  setUp(() {
    messaging = _MockMessaging();
    registerToken = _MockRegister();
    releaseToken = _MockRelease();
    refresh = StreamController<String>.broadcast();
    opened = StreamController<RemoteMessage>.broadcast();

    when(() => messaging.onTokenRefresh).thenAnswer((_) => refresh.stream);
    when(() => messaging.getToken()).thenAnswer((_) async => 'fcm-token-1');
    when(() => messaging.requestPermission())
        .thenAnswer((_) async => settingsOf(AuthorizationStatus.authorized));
    when(() => messaging.getNotificationSettings())
        .thenAnswer((_) async => settingsOf(AuthorizationStatus.authorized));
    when(
      () => registerToken(token: any(named: 'token'), platform: any(named: 'platform')),
    ).thenAnswer((_) async => const Right('تم تسجيل الجهاز'));
    when(() => releaseToken(token: any(named: 'token')))
        .thenAnswer((_) async => const Right('تم إلغاء تسجيل الجهاز'));
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    await refresh.close();
    await opened.close();
  });

  group('register', () {
    test('asks the OS, then hands the token to the server', () async {
      // Arrange
      final push = build();

      // Act
      final registered = await push.register();

      // Assert
      expect(registered, isTrue);
      verify(() => messaging.requestPermission()).called(1);
      verify(() => registerToken(token: 'fcm-token-1', platform: 'android')).called(1);
    });

    test('names the platform the server expects for an iPhone', () async {
      // Arrange — قيمةٌ خارج android|ios|web يرفضها تحقّقُ الخادم، فلا يُخترع اسم.
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final push = build();

      // Act
      await push.register();

      // Assert
      verify(() => registerToken(token: 'fcm-token-1', platform: 'ios')).called(1);
    });

    test('sends nothing when the customer refuses the prompt', () async {
      // Arrange
      when(() => messaging.requestPermission())
          .thenAnswer((_) async => settingsOf(AuthorizationStatus.denied));
      final push = build();

      // Act
      final registered = await push.register();

      // Assert
      expect(registered, isFalse);
      verifyNever(() => messaging.getToken());
      verifyNever(
        () => registerToken(token: any(named: 'token'), platform: any(named: 'platform')),
      );
    });

    test('without asking, reads the OS answer and never prompts', () async {
      // Arrange — the launch path: a prompt on the splash earns a permanent «لا».
      final push = build();

      // Act
      final registered = await push.register(askPermission: false);

      // Assert
      expect(registered, isTrue);
      verifyNever(() => messaging.requestPermission());
      verify(() => messaging.getNotificationSettings()).called(1);
    });

    test('without asking, stays quiet on a phone that has not allowed it', () async {
      // Arrange
      when(() => messaging.getNotificationSettings())
          .thenAnswer((_) async => settingsOf(AuthorizationStatus.notDetermined));
      final push = build();

      // Act
      final registered = await push.register(askPermission: false);

      // Assert
      expect(registered, isFalse);
      verifyNever(() => messaging.getToken());
    });

    test('an iPhone whose APNs token has not arrived yet is a quiet no, not a crash', () async {
      // Arrange — `getToken` throws on iOS until APNs answers; the call is unawaited at sign-in,
      // so a throw here would surface as an unhandled error with nobody to catch it.
      when(() => messaging.getToken()).thenThrow(
        FirebaseException(plugin: 'firebase_messaging', code: 'apns-token-not-set'),
      );
      final push = build();

      // Act
      final registered = await push.register();

      // Assert
      expect(registered, isFalse);
      verifyNever(
        () => registerToken(token: any(named: 'token'), platform: any(named: 'platform')),
      );
    });

    test('a server that refuses leaves nothing marked as registered', () async {
      // Arrange
      when(
        () => registerToken(token: any(named: 'token'), platform: any(named: 'platform')),
      ).thenAnswer((_) async => const Left(Failure.network(message: 'لا اتصال')));
      final push = build();
      await push.start();

      // Act
      final registered = await push.register();
      refresh.add('fcm-token-2');
      await pumpEventQueue();

      // Assert — نفسُ الطلب مرّةً واحدة، ولا تُلاحَق الدورةُ لجهازٍ لم يُسجَّل.
      expect(registered, isFalse);
      verify(
        () => registerToken(token: any(named: 'token'), platform: any(named: 'platform')),
      ).called(1);
    });
  });

  group('release', () {
    test('releases the token that was registered', () async {
      // Arrange
      final push = build();
      await push.register();
      when(() => messaging.getToken()).thenAnswer((_) async => 'fcm-token-rotated');

      // Act
      await push.release();

      // Assert — the one the server holds, not whatever the phone would say now.
      verify(() => releaseToken(token: 'fcm-token-1')).called(1);
    });

    test('asks the phone for its token when nothing was registered in this run', () async {
      // Arrange
      final push = build();

      // Act
      await push.release();

      // Assert
      verify(() => releaseToken(token: 'fcm-token-1')).called(1);
    });
  });

  group('token rotation', () {
    test('a rotated token reaches the server while registered', () async {
      // Arrange
      final push = build();
      await push.start();
      await push.register();

      // Act
      refresh.add('fcm-token-2');
      await pumpEventQueue();

      // Assert
      verify(() => registerToken(token: 'fcm-token-2', platform: 'android')).called(1);
    });

    test('a rotation after sign-out is ignored', () async {
      // Arrange
      final push = build();
      await push.start();
      await push.register();
      await push.release();

      // Act
      refresh.add('fcm-token-2');
      await pumpEventQueue();

      // Assert
      verifyNever(() => registerToken(token: 'fcm-token-2', platform: any(named: 'platform')));
    });
  });

  group('opening a notification', () {
    test('a tap while the app is in the background opens its route', () async {
      // Arrange
      final routes = <String>[];
      final push = build()..onOpenRoute = routes.add;
      await push.start();

      // Act
      opened.add(const RemoteMessage(data: {'route': '/orders/42'}));
      await pumpEventQueue();

      // Assert
      expect(routes, ['/orders/42']);
    });

    test('a message with no route, or an empty one, opens nothing', () async {
      // Arrange
      final routes = <String>[];
      final push = build()..onOpenRoute = routes.add;
      await push.start();

      // Act
      opened
        ..add(const RemoteMessage())
        ..add(const RemoteMessage(data: {'route': ''}));
      await pumpEventQueue();

      // Assert
      expect(routes, isEmpty);
    });

    test('a cold start hands back the route it was launched from', () async {
      // Arrange
      when(() => messaging.getInitialMessage())
          .thenAnswer((_) async => const RemoteMessage(data: {'route': '/support/7'}));
      final push = build();

      // Act
      final route = await push.initialRoute();

      // Assert
      expect(route, '/support/7');
    });
  });

  group('when Firebase never started', () {
    test('every call is a quiet no-op', () async {
      // Arrange — ملفُّ إعداداتٍ ناقص يكلّف الإشعاراتِ لا التطبيق.
      final push = build(firebaseIsUp: false);

      // Act
      await push.start();
      final registered = await push.register();
      await push.release();
      final route = await push.initialRoute();

      // Assert
      expect(registered, isFalse);
      expect(route, isNull);
      verifyNever(
        () => registerToken(token: any(named: 'token'), platform: any(named: 'platform')),
      );
      verifyNever(() => releaseToken(token: any(named: 'token')));
    });
  });
}
