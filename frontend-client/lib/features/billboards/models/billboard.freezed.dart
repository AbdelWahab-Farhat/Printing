// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'billboard.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
BillboardTarget _$BillboardTargetFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'product':
          return BillboardProductTarget.fromJson(
            json
          );
                case 'url':
          return BillboardUrlTarget.fromJson(
            json
          );
        
          default:
            return BillboardNoTarget.fromJson(
  json
);
        }
      
}

/// @nodoc
mixin _$BillboardTarget {



  /// Serializes this BillboardTarget to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BillboardTarget);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BillboardTarget()';
}


}

/// @nodoc
class $BillboardTargetCopyWith<$Res>  {
$BillboardTargetCopyWith(BillboardTarget _, $Res Function(BillboardTarget) __);
}


/// Adds pattern-matching-related methods to [BillboardTarget].
extension BillboardTargetPatterns on BillboardTarget {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( BillboardProductTarget value)?  product,TResult Function( BillboardUrlTarget value)?  url,TResult Function( BillboardNoTarget value)?  none,required TResult orElse(),}){
final _that = this;
switch (_that) {
case BillboardProductTarget() when product != null:
return product(_that);case BillboardUrlTarget() when url != null:
return url(_that);case BillboardNoTarget() when none != null:
return none(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( BillboardProductTarget value)  product,required TResult Function( BillboardUrlTarget value)  url,required TResult Function( BillboardNoTarget value)  none,}){
final _that = this;
switch (_that) {
case BillboardProductTarget():
return product(_that);case BillboardUrlTarget():
return url(_that);case BillboardNoTarget():
return none(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( BillboardProductTarget value)?  product,TResult? Function( BillboardUrlTarget value)?  url,TResult? Function( BillboardNoTarget value)?  none,}){
final _that = this;
switch (_that) {
case BillboardProductTarget() when product != null:
return product(_that);case BillboardUrlTarget() when url != null:
return url(_that);case BillboardNoTarget() when none != null:
return none(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function(@JsonKey(name: 'product_id')  int productId)?  product,TResult Function( String url)?  url,TResult Function()?  none,required TResult orElse(),}) {final _that = this;
switch (_that) {
case BillboardProductTarget() when product != null:
return product(_that.productId);case BillboardUrlTarget() when url != null:
return url(_that.url);case BillboardNoTarget() when none != null:
return none();case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function(@JsonKey(name: 'product_id')  int productId)  product,required TResult Function( String url)  url,required TResult Function()  none,}) {final _that = this;
switch (_that) {
case BillboardProductTarget():
return product(_that.productId);case BillboardUrlTarget():
return url(_that.url);case BillboardNoTarget():
return none();}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function(@JsonKey(name: 'product_id')  int productId)?  product,TResult? Function( String url)?  url,TResult? Function()?  none,}) {final _that = this;
switch (_that) {
case BillboardProductTarget() when product != null:
return product(_that.productId);case BillboardUrlTarget() when url != null:
return url(_that.url);case BillboardNoTarget() when none != null:
return none();case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class BillboardProductTarget implements BillboardTarget {
  const BillboardProductTarget({@JsonKey(name: 'product_id') required this.productId, final  String? $type}): $type = $type ?? 'product';
  factory BillboardProductTarget.fromJson(Map<String, dynamic> json) => _$BillboardProductTargetFromJson(json);

@JsonKey(name: 'product_id') final  int productId;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of BillboardTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BillboardProductTargetCopyWith<BillboardProductTarget> get copyWith => _$BillboardProductTargetCopyWithImpl<BillboardProductTarget>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BillboardProductTargetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BillboardProductTarget&&(identical(other.productId, productId) || other.productId == productId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId);

@override
String toString() {
  return 'BillboardTarget.product(productId: $productId)';
}


}

/// @nodoc
abstract mixin class $BillboardProductTargetCopyWith<$Res> implements $BillboardTargetCopyWith<$Res> {
  factory $BillboardProductTargetCopyWith(BillboardProductTarget value, $Res Function(BillboardProductTarget) _then) = _$BillboardProductTargetCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'product_id') int productId
});




}
/// @nodoc
class _$BillboardProductTargetCopyWithImpl<$Res>
    implements $BillboardProductTargetCopyWith<$Res> {
  _$BillboardProductTargetCopyWithImpl(this._self, this._then);

  final BillboardProductTarget _self;
  final $Res Function(BillboardProductTarget) _then;

/// Create a copy of BillboardTarget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? productId = null,}) {
  return _then(BillboardProductTarget(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class BillboardUrlTarget implements BillboardTarget {
  const BillboardUrlTarget({required this.url, final  String? $type}): $type = $type ?? 'url';
  factory BillboardUrlTarget.fromJson(Map<String, dynamic> json) => _$BillboardUrlTargetFromJson(json);

 final  String url;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of BillboardTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BillboardUrlTargetCopyWith<BillboardUrlTarget> get copyWith => _$BillboardUrlTargetCopyWithImpl<BillboardUrlTarget>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BillboardUrlTargetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BillboardUrlTarget&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url);

@override
String toString() {
  return 'BillboardTarget.url(url: $url)';
}


}

/// @nodoc
abstract mixin class $BillboardUrlTargetCopyWith<$Res> implements $BillboardTargetCopyWith<$Res> {
  factory $BillboardUrlTargetCopyWith(BillboardUrlTarget value, $Res Function(BillboardUrlTarget) _then) = _$BillboardUrlTargetCopyWithImpl;
@useResult
$Res call({
 String url
});




}
/// @nodoc
class _$BillboardUrlTargetCopyWithImpl<$Res>
    implements $BillboardUrlTargetCopyWith<$Res> {
  _$BillboardUrlTargetCopyWithImpl(this._self, this._then);

  final BillboardUrlTarget _self;
  final $Res Function(BillboardUrlTarget) _then;

/// Create a copy of BillboardTarget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? url = null,}) {
  return _then(BillboardUrlTarget(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class BillboardNoTarget implements BillboardTarget {
  const BillboardNoTarget({final  String? $type}): $type = $type ?? 'none';
  factory BillboardNoTarget.fromJson(Map<String, dynamic> json) => _$BillboardNoTargetFromJson(json);



@JsonKey(name: 'type')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$BillboardNoTargetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BillboardNoTarget);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BillboardTarget.none()';
}


}





/// @nodoc
mixin _$Billboard {

 int get id;/// Doubles as the alt text a screen reader announces, which is why the server never sends
/// it null.
 String get title;@JsonKey(name: 'image_url') String get imageUrl;/// The picture's own dimensions, so the carousel can reserve the right box before the
/// image arrives — a home screen that jumps when each banner loads is a home screen that
/// moves the thing somebody was about to tap.
@JsonKey(name: 'width_px') int? get widthPx;@JsonKey(name: 'height_px') int? get heightPx; BillboardTarget get target;
/// Create a copy of Billboard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BillboardCopyWith<Billboard> get copyWith => _$BillboardCopyWithImpl<Billboard>(this as Billboard, _$identity);

  /// Serializes this Billboard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Billboard&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.widthPx, widthPx) || other.widthPx == widthPx)&&(identical(other.heightPx, heightPx) || other.heightPx == heightPx)&&(identical(other.target, target) || other.target == target));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,imageUrl,widthPx,heightPx,target);

@override
String toString() {
  return 'Billboard(id: $id, title: $title, imageUrl: $imageUrl, widthPx: $widthPx, heightPx: $heightPx, target: $target)';
}


}

/// @nodoc
abstract mixin class $BillboardCopyWith<$Res>  {
  factory $BillboardCopyWith(Billboard value, $Res Function(Billboard) _then) = _$BillboardCopyWithImpl;
@useResult
$Res call({
 int id, String title,@JsonKey(name: 'image_url') String imageUrl,@JsonKey(name: 'width_px') int? widthPx,@JsonKey(name: 'height_px') int? heightPx, BillboardTarget target
});


$BillboardTargetCopyWith<$Res> get target;

}
/// @nodoc
class _$BillboardCopyWithImpl<$Res>
    implements $BillboardCopyWith<$Res> {
  _$BillboardCopyWithImpl(this._self, this._then);

  final Billboard _self;
  final $Res Function(Billboard) _then;

/// Create a copy of Billboard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? imageUrl = null,Object? widthPx = freezed,Object? heightPx = freezed,Object? target = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,widthPx: freezed == widthPx ? _self.widthPx : widthPx // ignore: cast_nullable_to_non_nullable
as int?,heightPx: freezed == heightPx ? _self.heightPx : heightPx // ignore: cast_nullable_to_non_nullable
as int?,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as BillboardTarget,
  ));
}
/// Create a copy of Billboard
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BillboardTargetCopyWith<$Res> get target {
  
  return $BillboardTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}


/// Adds pattern-matching-related methods to [Billboard].
extension BillboardPatterns on Billboard {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Billboard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Billboard() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Billboard value)  $default,){
final _that = this;
switch (_that) {
case _Billboard():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Billboard value)?  $default,){
final _that = this;
switch (_that) {
case _Billboard() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title, @JsonKey(name: 'image_url')  String imageUrl, @JsonKey(name: 'width_px')  int? widthPx, @JsonKey(name: 'height_px')  int? heightPx,  BillboardTarget target)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Billboard() when $default != null:
return $default(_that.id,_that.title,_that.imageUrl,_that.widthPx,_that.heightPx,_that.target);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title, @JsonKey(name: 'image_url')  String imageUrl, @JsonKey(name: 'width_px')  int? widthPx, @JsonKey(name: 'height_px')  int? heightPx,  BillboardTarget target)  $default,) {final _that = this;
switch (_that) {
case _Billboard():
return $default(_that.id,_that.title,_that.imageUrl,_that.widthPx,_that.heightPx,_that.target);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title, @JsonKey(name: 'image_url')  String imageUrl, @JsonKey(name: 'width_px')  int? widthPx, @JsonKey(name: 'height_px')  int? heightPx,  BillboardTarget target)?  $default,) {final _that = this;
switch (_that) {
case _Billboard() when $default != null:
return $default(_that.id,_that.title,_that.imageUrl,_that.widthPx,_that.heightPx,_that.target);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Billboard implements Billboard {
  const _Billboard({required this.id, required this.title, @JsonKey(name: 'image_url') required this.imageUrl, @JsonKey(name: 'width_px') this.widthPx, @JsonKey(name: 'height_px') this.heightPx, this.target = const BillboardTarget.none()});
  factory _Billboard.fromJson(Map<String, dynamic> json) => _$BillboardFromJson(json);

@override final  int id;
/// Doubles as the alt text a screen reader announces, which is why the server never sends
/// it null.
@override final  String title;
@override@JsonKey(name: 'image_url') final  String imageUrl;
/// The picture's own dimensions, so the carousel can reserve the right box before the
/// image arrives — a home screen that jumps when each banner loads is a home screen that
/// moves the thing somebody was about to tap.
@override@JsonKey(name: 'width_px') final  int? widthPx;
@override@JsonKey(name: 'height_px') final  int? heightPx;
@override@JsonKey() final  BillboardTarget target;

/// Create a copy of Billboard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BillboardCopyWith<_Billboard> get copyWith => __$BillboardCopyWithImpl<_Billboard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BillboardToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Billboard&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.widthPx, widthPx) || other.widthPx == widthPx)&&(identical(other.heightPx, heightPx) || other.heightPx == heightPx)&&(identical(other.target, target) || other.target == target));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,imageUrl,widthPx,heightPx,target);

@override
String toString() {
  return 'Billboard(id: $id, title: $title, imageUrl: $imageUrl, widthPx: $widthPx, heightPx: $heightPx, target: $target)';
}


}

/// @nodoc
abstract mixin class _$BillboardCopyWith<$Res> implements $BillboardCopyWith<$Res> {
  factory _$BillboardCopyWith(_Billboard value, $Res Function(_Billboard) _then) = __$BillboardCopyWithImpl;
@override @useResult
$Res call({
 int id, String title,@JsonKey(name: 'image_url') String imageUrl,@JsonKey(name: 'width_px') int? widthPx,@JsonKey(name: 'height_px') int? heightPx, BillboardTarget target
});


@override $BillboardTargetCopyWith<$Res> get target;

}
/// @nodoc
class __$BillboardCopyWithImpl<$Res>
    implements _$BillboardCopyWith<$Res> {
  __$BillboardCopyWithImpl(this._self, this._then);

  final _Billboard _self;
  final $Res Function(_Billboard) _then;

/// Create a copy of Billboard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? imageUrl = null,Object? widthPx = freezed,Object? heightPx = freezed,Object? target = null,}) {
  return _then(_Billboard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,widthPx: freezed == widthPx ? _self.widthPx : widthPx // ignore: cast_nullable_to_non_nullable
as int?,heightPx: freezed == heightPx ? _self.heightPx : heightPx // ignore: cast_nullable_to_non_nullable
as int?,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as BillboardTarget,
  ));
}

/// Create a copy of Billboard
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BillboardTargetCopyWith<$Res> get target {
  
  return $BillboardTargetCopyWith<$Res>(_self.target, (value) {
    return _then(_self.copyWith(target: value));
  });
}
}

// dart format on
