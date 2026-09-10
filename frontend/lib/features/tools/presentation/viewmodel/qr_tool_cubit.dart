import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/tools/models/qr_code_art.dart';
import 'package:dayaa/features/tools/usecases/generate_qr_code.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'qr_tool_cubit.freezed.dart';
part 'qr_tool_state.dart';

/// الرمز المعروض على شاشة أداة QR — لا أكثر.
///
/// **اللون وشفافية الخلفية ليسا هنا، وهذا ليس سهواً.** ما يملكه هذا الـ Cubit هو ناتج
/// «إنشاء الرمز»، وهو الترميز؛ واللون طلاءٌ فوقه ترسمه الشاشة و[SaveQrCodeImage] من نفس
/// المصدر. §4 تسمح بحالة بصرية بحتة داخل ويدجت واحد، وهذا هو تعريفها: تغيير الحبر لا يسأل
/// أحداً ولا يفشل ولا ينتظر شيئاً — يُعاد الطلاء في الإطار التالي.
///
/// وأثرُ ذلك على ما يراه الموظف مقصود أيضاً: بعد إنشاء الرمز، تبديلُ اللون يُبدّله في المعاينة
/// فوراً بلا ضغطة ثانية — لأنه **نفس الرمز** بحبر آخر. أما تعديل النص فيترك المعروض كما هو حتى
/// يُضغط «إنشاء الرمز»، تماماً كما في `qr.html`: النص الجديد رمزٌ آخر، ورمزٌ يتبدّل تحت الإصبع
/// مع كل حرف يُكتب هو رمزٌ لا يعرف الموظف أيَّ نسخةٍ منه حمَّل.
class QrToolCubit extends Cubit<QrToolState> {
  QrToolCubit({required GenerateQrCode generate})
    : _generate = generate,
      super(const QrToolState.blank());

  final GenerateQrCode _generate;

  /// يرمّز [data] ويعرضه.
  ///
  /// لا `isClosed` هنا لأن لا `await` قبل الـ `emit`: الترميز حسابٌ متزامن، والشاشة لا تستطيع
  /// أن تُغلق في منتصفه.
  void generate(String data) {
    final text = data.trim();

    // الفراغ ليس فشلاً يُعرض، بل شرطٌ لا يصل إلى هنا: `Validators.required` على الحقل هو ما
    // يمنعه، والرسالة تُعلَّق تحت الحقل حيث وقع النقص. (`qr.html` يفتح نافذة بدلها.)
    if (text.isEmpty) return;

    emit(
      _generate(text).fold(
        (failure) => QrToolState.failure(failure),
        (art) => QrToolState.ready(art: art),
      ),
    );
  }
}
