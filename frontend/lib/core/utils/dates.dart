/// كيف يُكتب التاريخ في هذا التطبيق — في مكان واحد.
///
/// Every screen used to spell its own: `2026-08-14` here, `2026/8/14` there, and a padded
/// `14-08` on the home screen. Three shapes for one idea is three places to change and two of
/// them get forgotten — and none of the three reads like something a person would say.
///
/// **Arabic month names, Latin digits.** «14 أغسطس 2026» is what somebody reads out loud, and
/// the digits match every other number this app draws — a price, a quantity, an order code.
/// Mixing Arabic-Indic digits in here alone would make one screen belong to a different app.
///
/// **A const table rather than `intl`.** `DateFormat('d MMMM y', 'ar')` needs its locale data
/// initialised before first use, and a formatter that throws on a screen because an `await` was
/// missed at startup is a worse trade than twelve strings. It is also what keeps a widget test
/// deterministic without a setup step.
///
/// **What is *not* here: the wire.** `2026-08-14` is what the API filters and stores by, and
/// that shape belongs to whatever builds the request — see `HomeSummaryCubit` and the purchase
/// order form. Nothing in this file is safe to put in a query string.
library;

abstract final class AppDates {
  /// The names Libya uses. Not «كانون الثاني» and the Levantine set — the shop reads these.
  static const List<String> _months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  /// «14 أغسطس 2026» — in the device's own local time.
  static String day(DateTime at) {
    final local = at.toLocal();

    return '${local.day} ${_months[local.month - 1]} ${local.year}';
  }

  /// «14 أغسطس» — the year dropped when it is this one.
  ///
  /// For a list of things that happened recently, where the year is the same on every row and
  /// therefore tells the reader nothing.
  static String shortDay(DateTime at) {
    final local = at.toLocal();

    return local.year == DateTime.now().year
        ? '${local.day} ${_months[local.month - 1]}'
        : day(local);
  }

  /// «2:00 م» — twelve-hour, because that is how the time is said here.
  ///
  /// Midnight reads «12:00 ص» rather than «0:00», which is a clock nobody in the shop owns.
  static String time(DateTime at) {
    final local = at.toLocal();
    final hour = switch (local.hour % 12) {
      0 => 12,
      final int hour => hour,
    };

    return '$hour:${local.minute.toString().padLeft(2, '0')} ${local.hour < 12 ? 'ص' : 'م'}';
  }

  /// «14 أغسطس 2026 · 2:00 م», or the date alone when the time carries nothing.
  ///
  /// A timestamp stored as a date — an expected delivery, a period boundary — arrives as
  /// midnight exactly, and printing «12:00 ص» beside it would invent a precision the column
  /// never had.
  static String stamp(DateTime at) {
    final local = at.toLocal();

    return _isDateOnly(local) ? day(local) : '${day(local)} · ${time(local)}';
  }

  /// «اليوم», «أمس», or the date.
  ///
  /// The two words are worth their special case on any screen somebody opens right after doing
  /// the thing they are looking for.
  static String relativeDay(DateTime at) {
    final local = at.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(local.year, local.month, local.day);

    return switch (today.difference(that).inDays) {
      0 => 'اليوم',
      1 => 'أمس',
      _ => day(local),
    };
  }

  /// Whether the clock on this value says nothing — see [stamp].
  static bool _isDateOnly(DateTime local) =>
      local.hour == 0 && local.minute == 0 && local.second == 0;
}

/// The same four, where a date is already in hand.
extension AppDateFormatting on DateTime {
  /// «14 أغسطس 2026».
  String get dayLabel => AppDates.day(this);

  /// «14 أغسطس» — the year dropped when it is this one.
  String get shortDayLabel => AppDates.shortDay(this);

  /// «2:00 م».
  String get timeLabel => AppDates.time(this);

  /// «14 أغسطس 2026 · 2:00 م», or the date alone at midnight.
  String get stampLabel => AppDates.stamp(this);

  /// «اليوم», «أمس», or the date.
  String get relativeDayLabel => AppDates.relativeDay(this);
}
