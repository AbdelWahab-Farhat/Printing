import 'package:dayaa_client/features/tools/models/qr_code_art.dart';
import 'package:dayaa_client/features/tools/models/qr_code_painter.dart';
import 'package:flutter/material.dart';

/// الرمز كما سيخرج في الملف، مربّعاً.
///
/// `AspectRatio` لا مقاسٌ ثابت: المعاينة تأخذ عرض الشاشة مهما كان، والرمز مربّع دائماً — ورمزٌ
/// مطّاط في اتجاه واحد لا يُقرأ.
class QrCodeView extends StatelessWidget {
  const QrCodeView({
    required this.art,
    required this.color,
    required this.transparentBackground,
    super.key,
  });

  final QrCodeArt art;
  final Color color;
  final bool transparentBackground;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: QrCodePainter(
          art: art,
          color: color,
          transparentBackground: transparentBackground,
        ),
        // `CustomPaint` بلا ابن يأخذ مقاس ابنه — أي صفراً. هذا ما يعطيه القيود التي حدّدها
        // `AspectRatio` فوقه.
        child: const SizedBox.expand(),
      ),
    );
  }
}
