import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:latlong2/latlong.dart';

part 'place.freezed.dart';

/// One search result: somewhere with a name and a point on the map.
///
/// Hand-written `fromJson` rather than generated, for one reason: the geocoder sends latitude
/// and longitude as **strings** (`"32.8872"`), and the app wants a [LatLng]. A generated parser
/// would give two `String` fields and push the conversion — and the failure when it does not
/// parse — out to every caller.
@freezed
abstract class Place with _$Place {
  const factory Place({
    /// What the geocoder calls it, already in Arabic where it has an Arabic name.
    required String displayName,

    required LatLng point,
  }) = _Place;

  const Place._();

  /// Returns `null` for a row that cannot be read, rather than throwing.
  ///
  /// One malformed result among six must not empty the list. This is a search, not a record:
  /// there is nothing to be lost by skipping a row nobody could have used.
  static Place? tryFromJson(Map<String, dynamic> json) {
    final latitude = double.tryParse('${json['lat']}');
    final longitude = double.tryParse('${json['lon']}');
    final name = json['display_name'];

    if (latitude == null || longitude == null || name is! String || name.isEmpty) return null;

    return Place(displayName: name, point: LatLng(latitude, longitude));
  }

  /// The first line of the full address — «سوق الجمعة» out of
  /// «سوق الجمعة، طرابلس، ليبيا». The rest is context for the second line.
  String get title => displayName.split('،').first.trim();

  String get subtitle {
    final parts = displayName.split('،').skip(1).map((part) => part.trim());

    return parts.join('، ');
  }
}
