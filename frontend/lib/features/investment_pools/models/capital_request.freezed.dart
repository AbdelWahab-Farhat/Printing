// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'capital_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CapitalRequest {

 int get id;@JsonKey(name: 'investment_pool_id') int get investmentPoolId;@JsonKey(name: 'investor_id') int get investorId; CapitalRequestInvestor? get investor;/// `in` or `out`.
 String get direction;@JsonKey(name: 'direction_label') String get directionLabel; String get amount;/// `pending`, `applied` or `cancelled`.
 String get status;@JsonKey(name: 'status_label') String get statusLabel;@JsonKey(name: 'can_be_cancelled') bool get canBeCancelled;@JsonKey(name: 'requested_at') String? get requestedAt;/// Null while pending — the period it will join does not exist yet, and naming a row that has
/// not been created would be a promise this cannot keep.
@JsonKey(name: 'effective_period_id') int? get effectivePeriodId;/// **What a screen should key «تمّت» off**, not the status alone: it is the wallet row this
/// became, and its presence is the only proof the money actually moved.
@JsonKey(name: 'applied_entry_id') int? get appliedEntryId; String? get notes;
/// Create a copy of CapitalRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CapitalRequestCopyWith<CapitalRequest> get copyWith => _$CapitalRequestCopyWithImpl<CapitalRequest>(this as CapitalRequest, _$identity);

  /// Serializes this CapitalRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CapitalRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.investmentPoolId, investmentPoolId) || other.investmentPoolId == investmentPoolId)&&(identical(other.investorId, investorId) || other.investorId == investorId)&&(identical(other.investor, investor) || other.investor == investor)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.directionLabel, directionLabel) || other.directionLabel == directionLabel)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.canBeCancelled, canBeCancelled) || other.canBeCancelled == canBeCancelled)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.effectivePeriodId, effectivePeriodId) || other.effectivePeriodId == effectivePeriodId)&&(identical(other.appliedEntryId, appliedEntryId) || other.appliedEntryId == appliedEntryId)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,investmentPoolId,investorId,investor,direction,directionLabel,amount,status,statusLabel,canBeCancelled,requestedAt,effectivePeriodId,appliedEntryId,notes);

@override
String toString() {
  return 'CapitalRequest(id: $id, investmentPoolId: $investmentPoolId, investorId: $investorId, investor: $investor, direction: $direction, directionLabel: $directionLabel, amount: $amount, status: $status, statusLabel: $statusLabel, canBeCancelled: $canBeCancelled, requestedAt: $requestedAt, effectivePeriodId: $effectivePeriodId, appliedEntryId: $appliedEntryId, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $CapitalRequestCopyWith<$Res>  {
  factory $CapitalRequestCopyWith(CapitalRequest value, $Res Function(CapitalRequest) _then) = _$CapitalRequestCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'investment_pool_id') int investmentPoolId,@JsonKey(name: 'investor_id') int investorId, CapitalRequestInvestor? investor, String direction,@JsonKey(name: 'direction_label') String directionLabel, String amount, String status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'can_be_cancelled') bool canBeCancelled,@JsonKey(name: 'requested_at') String? requestedAt,@JsonKey(name: 'effective_period_id') int? effectivePeriodId,@JsonKey(name: 'applied_entry_id') int? appliedEntryId, String? notes
});


$CapitalRequestInvestorCopyWith<$Res>? get investor;

}
/// @nodoc
class _$CapitalRequestCopyWithImpl<$Res>
    implements $CapitalRequestCopyWith<$Res> {
  _$CapitalRequestCopyWithImpl(this._self, this._then);

  final CapitalRequest _self;
  final $Res Function(CapitalRequest) _then;

/// Create a copy of CapitalRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? investmentPoolId = null,Object? investorId = null,Object? investor = freezed,Object? direction = null,Object? directionLabel = null,Object? amount = null,Object? status = null,Object? statusLabel = null,Object? canBeCancelled = null,Object? requestedAt = freezed,Object? effectivePeriodId = freezed,Object? appliedEntryId = freezed,Object? notes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,investmentPoolId: null == investmentPoolId ? _self.investmentPoolId : investmentPoolId // ignore: cast_nullable_to_non_nullable
as int,investorId: null == investorId ? _self.investorId : investorId // ignore: cast_nullable_to_non_nullable
as int,investor: freezed == investor ? _self.investor : investor // ignore: cast_nullable_to_non_nullable
as CapitalRequestInvestor?,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,directionLabel: null == directionLabel ? _self.directionLabel : directionLabel // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,canBeCancelled: null == canBeCancelled ? _self.canBeCancelled : canBeCancelled // ignore: cast_nullable_to_non_nullable
as bool,requestedAt: freezed == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as String?,effectivePeriodId: freezed == effectivePeriodId ? _self.effectivePeriodId : effectivePeriodId // ignore: cast_nullable_to_non_nullable
as int?,appliedEntryId: freezed == appliedEntryId ? _self.appliedEntryId : appliedEntryId // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of CapitalRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CapitalRequestInvestorCopyWith<$Res>? get investor {
    if (_self.investor == null) {
    return null;
  }

  return $CapitalRequestInvestorCopyWith<$Res>(_self.investor!, (value) {
    return _then(_self.copyWith(investor: value));
  });
}
}


/// Adds pattern-matching-related methods to [CapitalRequest].
extension CapitalRequestPatterns on CapitalRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CapitalRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CapitalRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CapitalRequest value)  $default,){
final _that = this;
switch (_that) {
case _CapitalRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CapitalRequest value)?  $default,){
final _that = this;
switch (_that) {
case _CapitalRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'investment_pool_id')  int investmentPoolId, @JsonKey(name: 'investor_id')  int investorId,  CapitalRequestInvestor? investor,  String direction, @JsonKey(name: 'direction_label')  String directionLabel,  String amount,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'can_be_cancelled')  bool canBeCancelled, @JsonKey(name: 'requested_at')  String? requestedAt, @JsonKey(name: 'effective_period_id')  int? effectivePeriodId, @JsonKey(name: 'applied_entry_id')  int? appliedEntryId,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CapitalRequest() when $default != null:
return $default(_that.id,_that.investmentPoolId,_that.investorId,_that.investor,_that.direction,_that.directionLabel,_that.amount,_that.status,_that.statusLabel,_that.canBeCancelled,_that.requestedAt,_that.effectivePeriodId,_that.appliedEntryId,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'investment_pool_id')  int investmentPoolId, @JsonKey(name: 'investor_id')  int investorId,  CapitalRequestInvestor? investor,  String direction, @JsonKey(name: 'direction_label')  String directionLabel,  String amount,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'can_be_cancelled')  bool canBeCancelled, @JsonKey(name: 'requested_at')  String? requestedAt, @JsonKey(name: 'effective_period_id')  int? effectivePeriodId, @JsonKey(name: 'applied_entry_id')  int? appliedEntryId,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _CapitalRequest():
return $default(_that.id,_that.investmentPoolId,_that.investorId,_that.investor,_that.direction,_that.directionLabel,_that.amount,_that.status,_that.statusLabel,_that.canBeCancelled,_that.requestedAt,_that.effectivePeriodId,_that.appliedEntryId,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'investment_pool_id')  int investmentPoolId, @JsonKey(name: 'investor_id')  int investorId,  CapitalRequestInvestor? investor,  String direction, @JsonKey(name: 'direction_label')  String directionLabel,  String amount,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'can_be_cancelled')  bool canBeCancelled, @JsonKey(name: 'requested_at')  String? requestedAt, @JsonKey(name: 'effective_period_id')  int? effectivePeriodId, @JsonKey(name: 'applied_entry_id')  int? appliedEntryId,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _CapitalRequest() when $default != null:
return $default(_that.id,_that.investmentPoolId,_that.investorId,_that.investor,_that.direction,_that.directionLabel,_that.amount,_that.status,_that.statusLabel,_that.canBeCancelled,_that.requestedAt,_that.effectivePeriodId,_that.appliedEntryId,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CapitalRequest implements CapitalRequest {
  const _CapitalRequest({required this.id, @JsonKey(name: 'investment_pool_id') required this.investmentPoolId, @JsonKey(name: 'investor_id') required this.investorId, this.investor, required this.direction, @JsonKey(name: 'direction_label') required this.directionLabel, required this.amount, required this.status, @JsonKey(name: 'status_label') required this.statusLabel, @JsonKey(name: 'can_be_cancelled') this.canBeCancelled = false, @JsonKey(name: 'requested_at') this.requestedAt, @JsonKey(name: 'effective_period_id') this.effectivePeriodId, @JsonKey(name: 'applied_entry_id') this.appliedEntryId, this.notes});
  factory _CapitalRequest.fromJson(Map<String, dynamic> json) => _$CapitalRequestFromJson(json);

@override final  int id;
@override@JsonKey(name: 'investment_pool_id') final  int investmentPoolId;
@override@JsonKey(name: 'investor_id') final  int investorId;
@override final  CapitalRequestInvestor? investor;
/// `in` or `out`.
@override final  String direction;
@override@JsonKey(name: 'direction_label') final  String directionLabel;
@override final  String amount;
/// `pending`, `applied` or `cancelled`.
@override final  String status;
@override@JsonKey(name: 'status_label') final  String statusLabel;
@override@JsonKey(name: 'can_be_cancelled') final  bool canBeCancelled;
@override@JsonKey(name: 'requested_at') final  String? requestedAt;
/// Null while pending — the period it will join does not exist yet, and naming a row that has
/// not been created would be a promise this cannot keep.
@override@JsonKey(name: 'effective_period_id') final  int? effectivePeriodId;
/// **What a screen should key «تمّت» off**, not the status alone: it is the wallet row this
/// became, and its presence is the only proof the money actually moved.
@override@JsonKey(name: 'applied_entry_id') final  int? appliedEntryId;
@override final  String? notes;

/// Create a copy of CapitalRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CapitalRequestCopyWith<_CapitalRequest> get copyWith => __$CapitalRequestCopyWithImpl<_CapitalRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CapitalRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CapitalRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.investmentPoolId, investmentPoolId) || other.investmentPoolId == investmentPoolId)&&(identical(other.investorId, investorId) || other.investorId == investorId)&&(identical(other.investor, investor) || other.investor == investor)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.directionLabel, directionLabel) || other.directionLabel == directionLabel)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.canBeCancelled, canBeCancelled) || other.canBeCancelled == canBeCancelled)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.effectivePeriodId, effectivePeriodId) || other.effectivePeriodId == effectivePeriodId)&&(identical(other.appliedEntryId, appliedEntryId) || other.appliedEntryId == appliedEntryId)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,investmentPoolId,investorId,investor,direction,directionLabel,amount,status,statusLabel,canBeCancelled,requestedAt,effectivePeriodId,appliedEntryId,notes);

@override
String toString() {
  return 'CapitalRequest(id: $id, investmentPoolId: $investmentPoolId, investorId: $investorId, investor: $investor, direction: $direction, directionLabel: $directionLabel, amount: $amount, status: $status, statusLabel: $statusLabel, canBeCancelled: $canBeCancelled, requestedAt: $requestedAt, effectivePeriodId: $effectivePeriodId, appliedEntryId: $appliedEntryId, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$CapitalRequestCopyWith<$Res> implements $CapitalRequestCopyWith<$Res> {
  factory _$CapitalRequestCopyWith(_CapitalRequest value, $Res Function(_CapitalRequest) _then) = __$CapitalRequestCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'investment_pool_id') int investmentPoolId,@JsonKey(name: 'investor_id') int investorId, CapitalRequestInvestor? investor, String direction,@JsonKey(name: 'direction_label') String directionLabel, String amount, String status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'can_be_cancelled') bool canBeCancelled,@JsonKey(name: 'requested_at') String? requestedAt,@JsonKey(name: 'effective_period_id') int? effectivePeriodId,@JsonKey(name: 'applied_entry_id') int? appliedEntryId, String? notes
});


@override $CapitalRequestInvestorCopyWith<$Res>? get investor;

}
/// @nodoc
class __$CapitalRequestCopyWithImpl<$Res>
    implements _$CapitalRequestCopyWith<$Res> {
  __$CapitalRequestCopyWithImpl(this._self, this._then);

  final _CapitalRequest _self;
  final $Res Function(_CapitalRequest) _then;

/// Create a copy of CapitalRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? investmentPoolId = null,Object? investorId = null,Object? investor = freezed,Object? direction = null,Object? directionLabel = null,Object? amount = null,Object? status = null,Object? statusLabel = null,Object? canBeCancelled = null,Object? requestedAt = freezed,Object? effectivePeriodId = freezed,Object? appliedEntryId = freezed,Object? notes = freezed,}) {
  return _then(_CapitalRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,investmentPoolId: null == investmentPoolId ? _self.investmentPoolId : investmentPoolId // ignore: cast_nullable_to_non_nullable
as int,investorId: null == investorId ? _self.investorId : investorId // ignore: cast_nullable_to_non_nullable
as int,investor: freezed == investor ? _self.investor : investor // ignore: cast_nullable_to_non_nullable
as CapitalRequestInvestor?,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,directionLabel: null == directionLabel ? _self.directionLabel : directionLabel // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,canBeCancelled: null == canBeCancelled ? _self.canBeCancelled : canBeCancelled // ignore: cast_nullable_to_non_nullable
as bool,requestedAt: freezed == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as String?,effectivePeriodId: freezed == effectivePeriodId ? _self.effectivePeriodId : effectivePeriodId // ignore: cast_nullable_to_non_nullable
as int?,appliedEntryId: freezed == appliedEntryId ? _self.appliedEntryId : appliedEntryId // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of CapitalRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CapitalRequestInvestorCopyWith<$Res>? get investor {
    if (_self.investor == null) {
    return null;
  }

  return $CapitalRequestInvestorCopyWith<$Res>(_self.investor!, (value) {
    return _then(_self.copyWith(investor: value));
  });
}
}


/// @nodoc
mixin _$CapitalRequestInvestor {

 int get id; String? get name;
/// Create a copy of CapitalRequestInvestor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CapitalRequestInvestorCopyWith<CapitalRequestInvestor> get copyWith => _$CapitalRequestInvestorCopyWithImpl<CapitalRequestInvestor>(this as CapitalRequestInvestor, _$identity);

  /// Serializes this CapitalRequestInvestor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CapitalRequestInvestor&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'CapitalRequestInvestor(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $CapitalRequestInvestorCopyWith<$Res>  {
  factory $CapitalRequestInvestorCopyWith(CapitalRequestInvestor value, $Res Function(CapitalRequestInvestor) _then) = _$CapitalRequestInvestorCopyWithImpl;
@useResult
$Res call({
 int id, String? name
});




}
/// @nodoc
class _$CapitalRequestInvestorCopyWithImpl<$Res>
    implements $CapitalRequestInvestorCopyWith<$Res> {
  _$CapitalRequestInvestorCopyWithImpl(this._self, this._then);

  final CapitalRequestInvestor _self;
  final $Res Function(CapitalRequestInvestor) _then;

/// Create a copy of CapitalRequestInvestor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CapitalRequestInvestor].
extension CapitalRequestInvestorPatterns on CapitalRequestInvestor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CapitalRequestInvestor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CapitalRequestInvestor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CapitalRequestInvestor value)  $default,){
final _that = this;
switch (_that) {
case _CapitalRequestInvestor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CapitalRequestInvestor value)?  $default,){
final _that = this;
switch (_that) {
case _CapitalRequestInvestor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String? name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CapitalRequestInvestor() when $default != null:
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String? name)  $default,) {final _that = this;
switch (_that) {
case _CapitalRequestInvestor():
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String? name)?  $default,) {final _that = this;
switch (_that) {
case _CapitalRequestInvestor() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CapitalRequestInvestor implements CapitalRequestInvestor {
  const _CapitalRequestInvestor({required this.id, this.name});
  factory _CapitalRequestInvestor.fromJson(Map<String, dynamic> json) => _$CapitalRequestInvestorFromJson(json);

@override final  int id;
@override final  String? name;

/// Create a copy of CapitalRequestInvestor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CapitalRequestInvestorCopyWith<_CapitalRequestInvestor> get copyWith => __$CapitalRequestInvestorCopyWithImpl<_CapitalRequestInvestor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CapitalRequestInvestorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CapitalRequestInvestor&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'CapitalRequestInvestor(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$CapitalRequestInvestorCopyWith<$Res> implements $CapitalRequestInvestorCopyWith<$Res> {
  factory _$CapitalRequestInvestorCopyWith(_CapitalRequestInvestor value, $Res Function(_CapitalRequestInvestor) _then) = __$CapitalRequestInvestorCopyWithImpl;
@override @useResult
$Res call({
 int id, String? name
});




}
/// @nodoc
class __$CapitalRequestInvestorCopyWithImpl<$Res>
    implements _$CapitalRequestInvestorCopyWith<$Res> {
  __$CapitalRequestInvestorCopyWithImpl(this._self, this._then);

  final _CapitalRequestInvestor _self;
  final $Res Function(_CapitalRequestInvestor) _then;

/// Create a copy of CapitalRequestInvestor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,}) {
  return _then(_CapitalRequestInvestor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PeriodOpened {

 List<CapitalRequest> get applied; Map<String, dynamic> get short;
/// Create a copy of PeriodOpened
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodOpenedCopyWith<PeriodOpened> get copyWith => _$PeriodOpenedCopyWithImpl<PeriodOpened>(this as PeriodOpened, _$identity);

  /// Serializes this PeriodOpened to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodOpened&&const DeepCollectionEquality().equals(other.applied, applied)&&const DeepCollectionEquality().equals(other.short, short));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(applied),const DeepCollectionEquality().hash(short));

@override
String toString() {
  return 'PeriodOpened(applied: $applied, short: $short)';
}


}

/// @nodoc
abstract mixin class $PeriodOpenedCopyWith<$Res>  {
  factory $PeriodOpenedCopyWith(PeriodOpened value, $Res Function(PeriodOpened) _then) = _$PeriodOpenedCopyWithImpl;
@useResult
$Res call({
 List<CapitalRequest> applied, Map<String, dynamic> short
});




}
/// @nodoc
class _$PeriodOpenedCopyWithImpl<$Res>
    implements $PeriodOpenedCopyWith<$Res> {
  _$PeriodOpenedCopyWithImpl(this._self, this._then);

  final PeriodOpened _self;
  final $Res Function(PeriodOpened) _then;

/// Create a copy of PeriodOpened
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? applied = null,Object? short = null,}) {
  return _then(_self.copyWith(
applied: null == applied ? _self.applied : applied // ignore: cast_nullable_to_non_nullable
as List<CapitalRequest>,short: null == short ? _self.short : short // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [PeriodOpened].
extension PeriodOpenedPatterns on PeriodOpened {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PeriodOpened value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PeriodOpened() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PeriodOpened value)  $default,){
final _that = this;
switch (_that) {
case _PeriodOpened():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PeriodOpened value)?  $default,){
final _that = this;
switch (_that) {
case _PeriodOpened() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CapitalRequest> applied,  Map<String, dynamic> short)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PeriodOpened() when $default != null:
return $default(_that.applied,_that.short);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CapitalRequest> applied,  Map<String, dynamic> short)  $default,) {final _that = this;
switch (_that) {
case _PeriodOpened():
return $default(_that.applied,_that.short);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CapitalRequest> applied,  Map<String, dynamic> short)?  $default,) {final _that = this;
switch (_that) {
case _PeriodOpened() when $default != null:
return $default(_that.applied,_that.short);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PeriodOpened implements PeriodOpened {
  const _PeriodOpened({final  List<CapitalRequest> applied = const <CapitalRequest>[], final  Map<String, dynamic> short = const <String, dynamic>{}}): _applied = applied,_short = short;
  factory _PeriodOpened.fromJson(Map<String, dynamic> json) => _$PeriodOpenedFromJson(json);

 final  List<CapitalRequest> _applied;
@override@JsonKey() List<CapitalRequest> get applied {
  if (_applied is EqualUnmodifiableListView) return _applied;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_applied);
}

 final  Map<String, dynamic> _short;
@override@JsonKey() Map<String, dynamic> get short {
  if (_short is EqualUnmodifiableMapView) return _short;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_short);
}


/// Create a copy of PeriodOpened
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PeriodOpenedCopyWith<_PeriodOpened> get copyWith => __$PeriodOpenedCopyWithImpl<_PeriodOpened>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PeriodOpenedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodOpened&&const DeepCollectionEquality().equals(other._applied, _applied)&&const DeepCollectionEquality().equals(other._short, _short));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_applied),const DeepCollectionEquality().hash(_short));

@override
String toString() {
  return 'PeriodOpened(applied: $applied, short: $short)';
}


}

/// @nodoc
abstract mixin class _$PeriodOpenedCopyWith<$Res> implements $PeriodOpenedCopyWith<$Res> {
  factory _$PeriodOpenedCopyWith(_PeriodOpened value, $Res Function(_PeriodOpened) _then) = __$PeriodOpenedCopyWithImpl;
@override @useResult
$Res call({
 List<CapitalRequest> applied, Map<String, dynamic> short
});




}
/// @nodoc
class __$PeriodOpenedCopyWithImpl<$Res>
    implements _$PeriodOpenedCopyWith<$Res> {
  __$PeriodOpenedCopyWithImpl(this._self, this._then);

  final _PeriodOpened _self;
  final $Res Function(_PeriodOpened) _then;

/// Create a copy of PeriodOpened
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? applied = null,Object? short = null,}) {
  return _then(_PeriodOpened(
applied: null == applied ? _self._applied : applied // ignore: cast_nullable_to_non_nullable
as List<CapitalRequest>,short: null == short ? _self._short : short // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
