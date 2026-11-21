// A tool, not a test: draws the three house ads in `assets/billboards/` in the Daaya identity.
// It lives outside `test/` so `flutter test` does not collect it.
//
//   BILLBOARDS_OUT=<folder> flutter test tool/make_billboards.dart
//   for f in printed_bags volume_pricing bag_preview; do
//     sips -s format jpeg -s formatOptions 88 <folder>/$f.png --out assets/billboards/$f.jpg
//   done
//
// **Drawn by Flutter, not by an image script**, because the text is Arabic: PIL cannot shape it
// without a shaping library, and Flutter shapes it with the app's own Cairo. The two bag photos
// are the only raster inputs, kept in `tool/billboards/`; everything else is drawn here, so a
// change of palette is a change to `theme.dart` and `app_tones.dart` and one run of this tool.
//
// 1164×528 at a pixel ratio of 1: the size the carousel was designed for (`house_ad.dart`).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dayaa_client/core/theme/app_tones.dart';
import 'package:dayaa_client/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = Size(1164, 528);

/// Decoded once, off the fake clock, and drawn with `RawImage`: an `Image.file` or `Image.asset`
/// resolves through an image stream that a widget test never lets finish.
final _images = <String, ui.Image>{};

Future<ui.Image> _decode(String path) async {
  final codec = await ui.instantiateImageCodec(await File(path).readAsBytes());

  return (await codec.getNextFrame()).image;
}

/// Every colour comes out of the palette, never a hex here.
const _light = MaterialTheme.lightScheme;

Future<void> _loadCairo() async {
  final loader = FontLoader('Cairo');
  for (final face in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold', 'Black']) {
    final bytes = await File('assets/fonts/Cairo-$face.ttf').readAsBytes();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  final out = Platform.environment['BILLBOARDS_OUT'] ?? 'build/billboards';
  setUpAll(() async {
    await _loadCairo();
    await Directory(out).create(recursive: true);
  });

  Future<void> draw(WidgetTester tester, String name, Widget ad) async {
    if (_images.isEmpty) {
      await tester.runAsync(() async {
        _images['logo'] = await _decode('assets/images/logo.png');
        for (final photo in ['mailer_bag', 'paper_bag']) {
          _images[photo] = await _decode('tool/billboards/$photo.jpg');
        }
      });
    }

    tester.view.physicalSize = _size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: DefaultTextStyle(
          style: const TextStyle(fontFamily: 'Cairo'),
          child: RepaintBoundary(
            key: key,
            child: SizedBox.fromSize(size: _size, child: ad),
          ),
        ),
      ),
    );

    await tester.pump();

    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('$out/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    });
  }

  testWidgets('printed_bags: «أكياس شحن بشعارك»', (tester) async {
    await draw(
      tester,
      'printed_bags',
      _Split(
        photo: 'mailer_bag',
        photoWidth: 480,
        panel: _light.brandYellow,
        child: _Copy(
          top: const _Lockup(),
          title: 'أكياس شحن\nبشعارك',
          ink: _light.onPrimaryContainer,
          action: 'اطلب الآن',
          actionFill: _light.header,
          actionInk: _light.onHeader,
        ),
      ),
    );
  });

  testWidgets('volume_pricing: «كلما زادت الكمية قلّ السعر»', (tester) async {
    await draw(
      tester,
      'volume_pricing',
      ColoredBox(
        color: _light.header,
        child: Row(
          children: [
            Expanded(
              child: _Copy(
                top: _Label('أسعار الجملة', color: _light.brandYellow),
                title: 'كلما زادت الكمية\nقلّ السعر',
                ink: _light.onHeader,
                action: 'شاهد الأسعار',
                actionFill: _light.brandYellow,
                actionInk: _light.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 440, child: _Bars()),
          ],
        ),
      ),
    );
  });

  testWidgets('bag_preview: «شاهد تصميمك على الكيس»', (tester) async {
    await draw(
      tester,
      'bag_preview',
      _Split(
        photo: 'paper_bag',
        photoWidth: 468,
        panel: _light.outgoingBubble,
        // The Daaya mark printed on the bag, over the sticker the photo was taken with.
        onPhoto: const Positioned(left: 172, top: 244, child: _PrintedMark(side: 124)),
        child: _Copy(
          top: _Label('معاينة قبل الطباعة', color: _light.brand),
          title: 'شاهد تصميمك\nعلى الكيس',
          ink: _light.onSurface,
          action: 'جرّب المعاينة',
          actionFill: _light.header,
          actionInk: _light.onHeader,
        ),
      ),
    );
  });
}

/// A photo on the left, the copy on a flat panel on the right.
class _Split extends StatelessWidget {
  const _Split({
    required this.photo,
    required this.photoWidth,
    required this.panel,
    required this.child,
    this.onPhoto,
  });

  final String photo;
  final double photoWidth;
  final Color panel;
  final Widget child;
  final Widget? onPhoto;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.ltr,
      children: [
        SizedBox(
          width: photoWidth,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RawImage(image: _images[photo], fit: BoxFit.cover),
              ?onPhoto,
            ],
          ),
        ),
        Expanded(
          child: ColoredBox(color: panel, child: child),
        ),
      ],
    );
  }
}

/// The right-hand copy: a small line on top, a two-line title, and a pill-shaped action.
class _Copy extends StatelessWidget {
  const _Copy({
    required this.top,
    required this.title,
    required this.ink,
    required this.action,
    required this.actionFill,
    required this.actionInk,
  });

  final Widget top;
  final String title;
  final Color ink;
  final String action;
  final Color actionFill;
  final Color actionInk;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(64, 56, 48, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          top,
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 66,
              fontWeight: FontWeight.w900,
              height: 1.15,
              color: ink,
            ),
          ),
          Container(
            height: 104,
            padding: const EdgeInsets.symmetric(horizontal: 52),
            decoration: BoxDecoration(color: actionFill, borderRadius: BorderRadius.circular(52)),
            // `widthFactor: 1`: the pill is as wide as its words, not the panel.
            child: Center(
              widthFactor: 1,
              child: Text(
                action,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: actionInk,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: color,
      ),
    );
  }
}

/// The mark on its white plate beside «دعاية», as `BrandMark` draws it in the app.
class _Lockup extends StatelessWidget {
  const _Lockup();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: _light.logoPlate,
            borderRadius: BorderRadius.circular(14),
          ),
          child: RawImage(image: _images['logo'], fit: BoxFit.contain),
        ),
        const SizedBox(width: 14),
        Text(
          'دعاية',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 38,
            fontWeight: FontWeight.w900,
            height: 1.2,
            color: _light.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}

/// The logo as a printed square on the bag: a white label, faintly edged so it reads as print on
/// paper rather than a hole in the photo. The logo file itself, not `DaayaMarkPainter`: at this
/// size the raster is sharp, and it is exact.
class _PrintedMark extends StatelessWidget {
  const _PrintedMark({required this.side});

  final double side;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: side,
      height: side,
      padding: EdgeInsets.all(side * 0.1),
      decoration: BoxDecoration(
        color: _light.logoPlate,
        borderRadius: BorderRadius.circular(side * 0.22),
        border: Border.all(color: _light.outlineVariant),
      ),
      child: RawImage(image: _images['logo'], fit: BoxFit.contain),
    );
  }
}

/// Three bars, each shorter than the last, under 100, 500 and 1000: the price per piece falling
/// as the quantity grows. The brand yellow, fading toward the band as the price drops.
class _Bars extends StatelessWidget {
  const _Bars();

  @override
  Widget build(BuildContext context) {
    const quantities = [100, 500, 1000];
    const heights = [300.0, 198.0, 114.0];

    return Padding(
      padding: const EdgeInsets.fromLTRB(54, 86, 54, 60),
      child: Row(
        textDirection: TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final (index, quantity) in quantities.indexed)
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 90,
                  height: heights[index],
                  decoration: BoxDecoration(
                    color: Color.lerp(_light.brandYellow, _light.header, index * 0.28),
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  '$quantity',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: _light.onHeaderVariant,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
