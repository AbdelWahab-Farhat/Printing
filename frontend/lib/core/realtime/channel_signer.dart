import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/core/realtime/realtime_client.dart';
import 'package:dio/dio.dart';

/// التوقيعُ من الـ API نفسه، بالـ `Dio` المشترك — فيحمل رمزَ الدخول ومهلَه كأيّ طلبٍ آخر.
///
/// **الجوابُ خارج المغلّف** (`{"auth": "…"}` كما يقرؤه بروتوكول Pusher)، ولهذا
/// `safeForeignRequest` لا `safeRequest`. والرفض — ٤٠١ أو ٤٠٣ أو انقطاع — `null`، فلا تُفتح
/// القناة؛ والـ ٤٠١ يمرّ على `AuthInterceptor` كأيّ طلبٍ فيُخرج الجلسة المنتهية.
ChannelSigner apiChannelSigner(Dio dio, String path) {
  return (socketId, channelName) async {
    final result = await safeForeignRequest<String>(
      () => dio.post<dynamic>(
        path,
        data: {'socket_id': socketId, 'channel_name': channelName},
      ),
      parse: (body) => (body as Map<String, dynamic>)['auth'] as String,
    );

    return result.fold((_) => null, (auth) => auth);
  };
}
