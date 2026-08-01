import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// One name per idea, two glyphs behind it: Material on Android, Cupertino on iOS.
///
/// An Android user reading a rounded iOS chevron, or an iPhone user reading Material's boxy
/// person icon, both spend a moment deciding what they are looking at. Each platform's own set
/// is the one its owner already knows, so the icon stops being something to read.
///
/// **Screens never name a glyph.** They ask for [AppIcons.customers], and which family answers
/// is settled here — one place to change, and no screen that quietly stayed Material because
/// somebody typed `Icons.` out of habit.
///
/// The decision reads [defaultTargetPlatform] rather than `Platform.isIOS` for two reasons: it
/// compiles on the web, and a test can flip it with `debugDefaultTargetPlatformOverride` to
/// check both families without two devices.
abstract final class AppIcons {
  /// Cupertino for the platforms Apple ships; Material everywhere else.
  static bool get isCupertino =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  static IconData _pick(IconData material, IconData cupertino) =>
      isCupertino ? cupertino : material;

  // ── navigation ─────────────────────────────────────────────────────────────
  static IconData get home => _pick(Icons.home_rounded, CupertinoIcons.house_fill);

  static IconData get customers =>
      _pick(Icons.people_alt_rounded, CupertinoIcons.person_2_fill);

  static IconData get warehouse =>
      _pick(Icons.inventory_2_rounded, CupertinoIcons.cube_box_fill);

  static IconData get products =>
      _pick(Icons.shopping_bag_rounded, CupertinoIcons.bag_fill);

  static IconData get menu =>
      _pick(Icons.menu_rounded, CupertinoIcons.line_horizontal_3);

  static IconData get back =>
      _pick(Icons.arrow_back_rounded, CupertinoIcons.back);

  /// Points the way *forward* in reading order, which in an Arabic layout is to the left.
  static IconData get forward =>
      _pick(Icons.chevron_left_rounded, CupertinoIcons.chevron_left);

  // ── actions ────────────────────────────────────────────────────────────────
  static IconData get addCustomer =>
      _pick(Icons.person_add_alt_1_rounded, CupertinoIcons.person_add_solid);

  /// A pin on a map. The crosshair on the location picker, and the marker beside a shop.
  static IconData get mapPin =>
      _pick(Icons.location_on_rounded, CupertinoIcons.location_solid);

  static IconData get addProduct =>
      _pick(Icons.add_box_outlined, CupertinoIcons.plus_app);

  /// A plain "one more of these" — a size, a price break. Not [addProduct], which names a
  /// specific thing to create.
  static IconData get add => _pick(Icons.add_rounded, CupertinoIcons.add);

  /// Removes a row the user added. Distinct from [clear], which empties a field.
  static IconData get delete =>
      _pick(Icons.delete_outline_rounded, CupertinoIcons.delete);

  /// A machine-readable name — a slug, a code.
  static IconData get tag => _pick(Icons.tag_rounded, CupertinoIcons.tag);

  static IconData get copy => _pick(Icons.copy_rounded, CupertinoIcons.doc_on_doc);

  static IconData get refresh =>
      _pick(Icons.refresh_rounded, CupertinoIcons.refresh);

  static IconData get logout =>
      _pick(Icons.logout_rounded, CupertinoIcons.square_arrow_right);

  // ── the things the numbers count ───────────────────────────────────────────
  static IconData get orders =>
      _pick(Icons.receipt_long_rounded, CupertinoIcons.doc_text_fill);

  static IconData get today => _pick(Icons.today_rounded, CupertinoIcons.calendar_today);

  static IconData get month =>
      _pick(Icons.calendar_month_rounded, CupertinoIcons.calendar);

  static IconData get city =>
      _pick(Icons.location_city_rounded, CupertinoIcons.building_2_fill);

  /// One person, as a form field's prefix — distinct from [customers], which is the group and
  /// belongs to the tab.
  static IconData get person =>
      _pick(Icons.person_outline_rounded, CupertinoIcons.person);

  static IconData get phone => _pick(Icons.phone_outlined, CupertinoIcons.phone);

  static IconData get password => _pick(Icons.lock_outline_rounded, CupertinoIcons.lock);

  static IconData get passwordVisible =>
      _pick(Icons.visibility_outlined, CupertinoIcons.eye);

  static IconData get passwordHidden =>
      _pick(Icons.visibility_off_outlined, CupertinoIcons.eye_slash);

  static IconData get search => _pick(Icons.search_rounded, CupertinoIcons.search);

  /// Empties a field — the small circle inside a search box, not a delete.
  static IconData get clear =>
      _pick(Icons.close_rounded, CupertinoIcons.clear_circled_solid);

  static IconData get error =>
      _pick(Icons.error_outline_rounded, CupertinoIcons.exclamationmark_circle);

  static IconData get empty =>
      _pick(Icons.inbox_rounded, CupertinoIcons.tray);
}
