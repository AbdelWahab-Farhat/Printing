// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wallet_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WalletEntry {

 int get id; String get type;@JsonKey(name: 'type_label') String get typeLabel;/// `capital` · `investment` · `profit` · `loss` — وعكسُ الحركة يأخذ عائلةَ ما عكسه.
 String? get category; String get amount;/// «-3000.00» لما أنقص رصيده — من الرصيد الذي حرّكه الصفّ فعلاً.
@JsonKey(name: 'signed_amount') String get signedAmount; String? get method; String? get reference; WalletEntryDeal? get deal; WalletEntryPeriod? get period;/// ما اشتراه الاشتراكُ من وحدات، أو ما ألغاه الاسترداد — `null` لكلّ ما سواهما.
@JsonKey(name: 'fund_units') WalletEntryUnits? get fundUnits;@JsonKey(name: 'reverses_entry_id') int? get reversesEntryId;@JsonKey(name: 'is_reversed') bool get isReversed;/// يقوله الخادم: ما سُجّل بيدٍ ولم يُعكس بعد. الأرباحُ لا تُعكس من هنا أبداً.
@JsonKey(name: 'can_be_reversed') bool get canBeReversed;@JsonKey(name: 'occurred_at') DateTime? get occurredAt; String? get notes;@JsonKey(name: 'recorded_by') WalletEntryActor? get recordedBy;
/// Create a copy of WalletEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalletEntryCopyWith<WalletEntry> get copyWith => _$WalletEntryCopyWithImpl<WalletEntry>(this as WalletEntry, _$identity);

  /// Serializes this WalletEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalletEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.typeLabel, typeLabel) || other.typeLabel == typeLabel)&&(identical(other.category, category) || other.category == category)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.signedAmount, signedAmount) || other.signedAmount == signedAmount)&&(identical(other.method, method) || other.method == method)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.deal, deal) || other.deal == deal)&&(identical(other.period, period) || other.period == period)&&(identical(other.fundUnits, fundUnits) || other.fundUnits == fundUnits)&&(identical(other.reversesEntryId, reversesEntryId) || other.reversesEntryId == reversesEntryId)&&(identical(other.isReversed, isReversed) || other.isReversed == isReversed)&&(identical(other.canBeReversed, canBeReversed) || other.canBeReversed == canBeReversed)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.recordedBy, recordedBy) || other.recordedBy == recordedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,typeLabel,category,amount,signedAmount,method,reference,deal,period,fundUnits,reversesEntryId,isReversed,canBeReversed,occurredAt,notes,recordedBy);

@override
String toString() {
  return 'WalletEntry(id: $id, type: $type, typeLabel: $typeLabel, category: $category, amount: $amount, signedAmount: $signedAmount, method: $method, reference: $reference, deal: $deal, period: $period, fundUnits: $fundUnits, reversesEntryId: $reversesEntryId, isReversed: $isReversed, canBeReversed: $canBeReversed, occurredAt: $occurredAt, notes: $notes, recordedBy: $recordedBy)';
}


}

/// @nodoc
abstract mixin class $WalletEntryCopyWith<$Res>  {
  factory $WalletEntryCopyWith(WalletEntry value, $Res Function(WalletEntry) _then) = _$WalletEntryCopyWithImpl;
@useResult
$Res call({
 int id, String type,@JsonKey(name: 'type_label') String typeLabel, String? category, String amount,@JsonKey(name: 'signed_amount') String signedAmount, String? method, String? reference, WalletEntryDeal? deal, WalletEntryPeriod? period,@JsonKey(name: 'fund_units') WalletEntryUnits? fundUnits,@JsonKey(name: 'reverses_entry_id') int? reversesEntryId,@JsonKey(name: 'is_reversed') bool isReversed,@JsonKey(name: 'can_be_reversed') bool canBeReversed,@JsonKey(name: 'occurred_at') DateTime? occurredAt, String? notes,@JsonKey(name: 'recorded_by') WalletEntryActor? recordedBy
});


$WalletEntryDealCopyWith<$Res>? get deal;$WalletEntryPeriodCopyWith<$Res>? get period;$WalletEntryUnitsCopyWith<$Res>? get fundUnits;$WalletEntryActorCopyWith<$Res>? get recordedBy;

}
/// @nodoc
class _$WalletEntryCopyWithImpl<$Res>
    implements $WalletEntryCopyWith<$Res> {
  _$WalletEntryCopyWithImpl(this._self, this._then);

  final WalletEntry _self;
  final $Res Function(WalletEntry) _then;

/// Create a copy of WalletEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? typeLabel = null,Object? category = freezed,Object? amount = null,Object? signedAmount = null,Object? method = freezed,Object? reference = freezed,Object? deal = freezed,Object? period = freezed,Object? fundUnits = freezed,Object? reversesEntryId = freezed,Object? isReversed = null,Object? canBeReversed = null,Object? occurredAt = freezed,Object? notes = freezed,Object? recordedBy = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,typeLabel: null == typeLabel ? _self.typeLabel : typeLabel // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,signedAmount: null == signedAmount ? _self.signedAmount : signedAmount // ignore: cast_nullable_to_non_nullable
as String,method: freezed == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String?,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,deal: freezed == deal ? _self.deal : deal // ignore: cast_nullable_to_non_nullable
as WalletEntryDeal?,period: freezed == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as WalletEntryPeriod?,fundUnits: freezed == fundUnits ? _self.fundUnits : fundUnits // ignore: cast_nullable_to_non_nullable
as WalletEntryUnits?,reversesEntryId: freezed == reversesEntryId ? _self.reversesEntryId : reversesEntryId // ignore: cast_nullable_to_non_nullable
as int?,isReversed: null == isReversed ? _self.isReversed : isReversed // ignore: cast_nullable_to_non_nullable
as bool,canBeReversed: null == canBeReversed ? _self.canBeReversed : canBeReversed // ignore: cast_nullable_to_non_nullable
as bool,occurredAt: freezed == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,recordedBy: freezed == recordedBy ? _self.recordedBy : recordedBy // ignore: cast_nullable_to_non_nullable
as WalletEntryActor?,
  ));
}
/// Create a copy of WalletEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalletEntryDealCopyWith<$Res>? get deal {
    if (_self.deal == null) {
    return null;
  }

  return $WalletEntryDealCopyWith<$Res>(_self.deal!, (value) {
    return _then(_self.copyWith(deal: value));
  });
}/// Create a copy of WalletEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalletEntryPeriodCopyWith<$Res>? get period {
    if (_self.period == null) {
    return null;
  }

  return $WalletEntryPeriodCopyWith<$Res>(_self.period!, (value) {
    return _then(_self.copyWith(period: value));
  });
}/// Create a copy of WalletEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalletEntryUnitsCopyWith<$Res>? get fundUnits {
    if (_self.fundUnits == null) {
    return null;
  }

  return $WalletEntryUnitsCopyWith<$Res>(_self.fundUnits!, (value) {
    return _then(_self.copyWith(fundUnits: value));
  });
}/// Create a copy of WalletEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalletEntryActorCopyWith<$Res>? get recordedBy {
    if (_self.recordedBy == null) {
    return null;
  }

  return $WalletEntryActorCopyWith<$Res>(_self.recordedBy!, (value) {
    return _then(_self.copyWith(recordedBy: value));
  });
}
}


/// Adds pattern-matching-related methods to [WalletEntry].
extension WalletEntryPatterns on WalletEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WalletEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WalletEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WalletEntry value)  $default,){
final _that = this;
switch (_that) {
case _WalletEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WalletEntry value)?  $default,){
final _that = this;
switch (_that) {
case _WalletEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String type, @JsonKey(name: 'type_label')  String typeLabel,  String? category,  String amount, @JsonKey(name: 'signed_amount')  String signedAmount,  String? method,  String? reference,  WalletEntryDeal? deal,  WalletEntryPeriod? period, @JsonKey(name: 'fund_units')  WalletEntryUnits? fundUnits, @JsonKey(name: 'reverses_entry_id')  int? reversesEntryId, @JsonKey(name: 'is_reversed')  bool isReversed, @JsonKey(name: 'can_be_reversed')  bool canBeReversed, @JsonKey(name: 'occurred_at')  DateTime? occurredAt,  String? notes, @JsonKey(name: 'recorded_by')  WalletEntryActor? recordedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WalletEntry() when $default != null:
return $default(_that.id,_that.type,_that.typeLabel,_that.category,_that.amount,_that.signedAmount,_that.method,_that.reference,_that.deal,_that.period,_that.fundUnits,_that.reversesEntryId,_that.isReversed,_that.canBeReversed,_that.occurredAt,_that.notes,_that.recordedBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String type, @JsonKey(name: 'type_label')  String typeLabel,  String? category,  String amount, @JsonKey(name: 'signed_amount')  String signedAmount,  String? method,  String? reference,  WalletEntryDeal? deal,  WalletEntryPeriod? period, @JsonKey(name: 'fund_units')  WalletEntryUnits? fundUnits, @JsonKey(name: 'reverses_entry_id')  int? reversesEntryId, @JsonKey(name: 'is_reversed')  bool isReversed, @JsonKey(name: 'can_be_reversed')  bool canBeReversed, @JsonKey(name: 'occurred_at')  DateTime? occurredAt,  String? notes, @JsonKey(name: 'recorded_by')  WalletEntryActor? recordedBy)  $default,) {final _that = this;
switch (_that) {
case _WalletEntry():
return $default(_that.id,_that.type,_that.typeLabel,_that.category,_that.amount,_that.signedAmount,_that.method,_that.reference,_that.deal,_that.period,_that.fundUnits,_that.reversesEntryId,_that.isReversed,_that.canBeReversed,_that.occurredAt,_that.notes,_that.recordedBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String type, @JsonKey(name: 'type_label')  String typeLabel,  String? category,  String amount, @JsonKey(name: 'signed_amount')  String signedAmount,  String? method,  String? reference,  WalletEntryDeal? deal,  WalletEntryPeriod? period, @JsonKey(name: 'fund_units')  WalletEntryUnits? fundUnits, @JsonKey(name: 'reverses_entry_id')  int? reversesEntryId, @JsonKey(name: 'is_reversed')  bool isReversed, @JsonKey(name: 'can_be_reversed')  bool canBeReversed, @JsonKey(name: 'occurred_at')  DateTime? occurredAt,  String? notes, @JsonKey(name: 'recorded_by')  WalletEntryActor? recordedBy)?  $default,) {final _that = this;
switch (_that) {
case _WalletEntry() when $default != null:
return $default(_that.id,_that.type,_that.typeLabel,_that.category,_that.amount,_that.signedAmount,_that.method,_that.reference,_that.deal,_that.period,_that.fundUnits,_that.reversesEntryId,_that.isReversed,_that.canBeReversed,_that.occurredAt,_that.notes,_that.recordedBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WalletEntry extends WalletEntry {
  const _WalletEntry({required this.id, required this.type, @JsonKey(name: 'type_label') required this.typeLabel, this.category, required this.amount, @JsonKey(name: 'signed_amount') required this.signedAmount, this.method, this.reference, this.deal, this.period, @JsonKey(name: 'fund_units') this.fundUnits, @JsonKey(name: 'reverses_entry_id') this.reversesEntryId, @JsonKey(name: 'is_reversed') this.isReversed = false, @JsonKey(name: 'can_be_reversed') this.canBeReversed = false, @JsonKey(name: 'occurred_at') this.occurredAt, this.notes, @JsonKey(name: 'recorded_by') this.recordedBy}): super._();
  factory _WalletEntry.fromJson(Map<String, dynamic> json) => _$WalletEntryFromJson(json);

@override final  int id;
@override final  String type;
@override@JsonKey(name: 'type_label') final  String typeLabel;
/// `capital` · `investment` · `profit` · `loss` — وعكسُ الحركة يأخذ عائلةَ ما عكسه.
@override final  String? category;
@override final  String amount;
/// «-3000.00» لما أنقص رصيده — من الرصيد الذي حرّكه الصفّ فعلاً.
@override@JsonKey(name: 'signed_amount') final  String signedAmount;
@override final  String? method;
@override final  String? reference;
@override final  WalletEntryDeal? deal;
@override final  WalletEntryPeriod? period;
/// ما اشتراه الاشتراكُ من وحدات، أو ما ألغاه الاسترداد — `null` لكلّ ما سواهما.
@override@JsonKey(name: 'fund_units') final  WalletEntryUnits? fundUnits;
@override@JsonKey(name: 'reverses_entry_id') final  int? reversesEntryId;
@override@JsonKey(name: 'is_reversed') final  bool isReversed;
/// يقوله الخادم: ما سُجّل بيدٍ ولم يُعكس بعد. الأرباحُ لا تُعكس من هنا أبداً.
@override@JsonKey(name: 'can_be_reversed') final  bool canBeReversed;
@override@JsonKey(name: 'occurred_at') final  DateTime? occurredAt;
@override final  String? notes;
@override@JsonKey(name: 'recorded_by') final  WalletEntryActor? recordedBy;

/// Create a copy of WalletEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WalletEntryCopyWith<_WalletEntry> get copyWith => __$WalletEntryCopyWithImpl<_WalletEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WalletEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WalletEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.typeLabel, typeLabel) || other.typeLabel == typeLabel)&&(identical(other.category, category) || other.category == category)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.signedAmount, signedAmount) || other.signedAmount == signedAmount)&&(identical(other.method, method) || other.method == method)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.deal, deal) || other.deal == deal)&&(identical(other.period, period) || other.period == period)&&(identical(other.fundUnits, fundUnits) || other.fundUnits == fundUnits)&&(identical(other.reversesEntryId, reversesEntryId) || other.reversesEntryId == reversesEntryId)&&(identical(other.isReversed, isReversed) || other.isReversed == isReversed)&&(identical(other.canBeReversed, canBeReversed) || other.canBeReversed == canBeReversed)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.recordedBy, recordedBy) || other.recordedBy == recordedBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,typeLabel,category,amount,signedAmount,method,reference,deal,period,fundUnits,reversesEntryId,isReversed,canBeReversed,occurredAt,notes,recordedBy);

@override
String toString() {
  return 'WalletEntry(id: $id, type: $type, typeLabel: $typeLabel, category: $category, amount: $amount, signedAmount: $signedAmount, method: $method, reference: $reference, deal: $deal, period: $period, fundUnits: $fundUnits, reversesEntryId: $reversesEntryId, isReversed: $isReversed, canBeReversed: $canBeReversed, occurredAt: $occurredAt, notes: $notes, recordedBy: $recordedBy)';
}


}

/// @nodoc
abstract mixin class _$WalletEntryCopyWith<$Res> implements $WalletEntryCopyWith<$Res> {
  factory _$WalletEntryCopyWith(_WalletEntry value, $Res Function(_WalletEntry) _then) = __$WalletEntryCopyWithImpl;
@override @useResult
$Res call({
 int id, String type,@JsonKey(name: 'type_label') String typeLabel, String? category, String amount,@JsonKey(name: 'signed_amount') String signedAmount, String? method, String? reference, WalletEntryDeal? deal, WalletEntryPeriod? period,@JsonKey(name: 'fund_units') WalletEntryUnits? fundUnits,@JsonKey(name: 'reverses_entry_id') int? reversesEntryId,@JsonKey(name: 'is_reversed') bool isReversed,@JsonKey(name: 'can_be_reversed') bool canBeReversed,@JsonKey(name: 'occurred_at') DateTime? occurredAt, String? notes,@JsonKey(name: 'recorded_by') WalletEntryActor? recordedBy
});


@override $WalletEntryDealCopyWith<$Res>? get deal;@override $WalletEntryPeriodCopyWith<$Res>? get period;@override $WalletEntryUnitsCopyWith<$Res>? get fundUnits;@override $WalletEntryActorCopyWith<$Res>? get recordedBy;

}
/// @nodoc
class __$WalletEntryCopyWithImpl<$Res>
    implements _$WalletEntryCopyWith<$Res> {
  __$WalletEntryCopyWithImpl(this._self, this._then);

  final _WalletEntry _self;
  final $Res Function(_WalletEntry) _then;

/// Create a copy of WalletEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? typeLabel = null,Object? category = freezed,Object? amount = null,Object? signedAmount = null,Object? method = freezed,Object? reference = freezed,Object? deal = freezed,Object? period = freezed,Object? fundUnits = freezed,Object? reversesEntryId = freezed,Object? isReversed = null,Object? canBeReversed = null,Object? occurredAt = freezed,Object? notes = freezed,Object? recordedBy = freezed,}) {
  return _then(_WalletEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,typeLabel: null == typeLabel ? _self.typeLabel : typeLabel // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,signedAmount: null == signedAmount ? _self.signedAmount : signedAmount // ignore: cast_nullable_to_non_nullable
as String,method: freezed == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String?,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,deal: freezed == deal ? _self.deal : deal // ignore: cast_nullable_to_non_nullable
as WalletEntryDeal?,period: freezed == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as WalletEntryPeriod?,fundUnits: freezed == fundUnits ? _self.fundUnits : fundUnits // ignore: cast_nullable_to_non_nullable
as WalletEntryUnits?,reversesEntryId: freezed == reversesEntryId ? _self.reversesEntryId : reversesEntryId // ignore: cast_nullable_to_non_nullable
as int?,isReversed: null == isReversed ? _self.isReversed : isReversed // ignore: cast_nullable_to_non_nullable
as bool,canBeReversed: null == canBeReversed ? _self.canBeReversed : canBeReversed // ignore: cast_nullable_to_non_nullable
as bool,occurredAt: freezed == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,recordedBy: freezed == recordedBy ? _self.recordedBy : recordedBy // ignore: cast_nullable_to_non_nullable
as WalletEntryActor?,
  ));
}

/// Create a copy of WalletEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalletEntryDealCopyWith<$Res>? get deal {
    if (_self.deal == null) {
    return null;
  }

  return $WalletEntryDealCopyWith<$Res>(_self.deal!, (value) {
    return _then(_self.copyWith(deal: value));
  });
}/// Create a copy of WalletEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalletEntryPeriodCopyWith<$Res>? get period {
    if (_self.period == null) {
    return null;
  }

  return $WalletEntryPeriodCopyWith<$Res>(_self.period!, (value) {
    return _then(_self.copyWith(period: value));
  });
}/// Create a copy of WalletEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalletEntryUnitsCopyWith<$Res>? get fundUnits {
    if (_self.fundUnits == null) {
    return null;
  }

  return $WalletEntryUnitsCopyWith<$Res>(_self.fundUnits!, (value) {
    return _then(_self.copyWith(fundUnits: value));
  });
}/// Create a copy of WalletEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalletEntryActorCopyWith<$Res>? get recordedBy {
    if (_self.recordedBy == null) {
    return null;
  }

  return $WalletEntryActorCopyWith<$Res>(_self.recordedBy!, (value) {
    return _then(_self.copyWith(recordedBy: value));
  });
}
}


/// @nodoc
mixin _$WalletEntryDeal {

 int get id; String get code;@JsonKey(name: 'is_fund') bool get isFund;
/// Create a copy of WalletEntryDeal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalletEntryDealCopyWith<WalletEntryDeal> get copyWith => _$WalletEntryDealCopyWithImpl<WalletEntryDeal>(this as WalletEntryDeal, _$identity);

  /// Serializes this WalletEntryDeal to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalletEntryDeal&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.isFund, isFund) || other.isFund == isFund));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,isFund);

@override
String toString() {
  return 'WalletEntryDeal(id: $id, code: $code, isFund: $isFund)';
}


}

/// @nodoc
abstract mixin class $WalletEntryDealCopyWith<$Res>  {
  factory $WalletEntryDealCopyWith(WalletEntryDeal value, $Res Function(WalletEntryDeal) _then) = _$WalletEntryDealCopyWithImpl;
@useResult
$Res call({
 int id, String code,@JsonKey(name: 'is_fund') bool isFund
});




}
/// @nodoc
class _$WalletEntryDealCopyWithImpl<$Res>
    implements $WalletEntryDealCopyWith<$Res> {
  _$WalletEntryDealCopyWithImpl(this._self, this._then);

  final WalletEntryDeal _self;
  final $Res Function(WalletEntryDeal) _then;

/// Create a copy of WalletEntryDeal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? isFund = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,isFund: null == isFund ? _self.isFund : isFund // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [WalletEntryDeal].
extension WalletEntryDealPatterns on WalletEntryDeal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WalletEntryDeal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WalletEntryDeal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WalletEntryDeal value)  $default,){
final _that = this;
switch (_that) {
case _WalletEntryDeal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WalletEntryDeal value)?  $default,){
final _that = this;
switch (_that) {
case _WalletEntryDeal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code, @JsonKey(name: 'is_fund')  bool isFund)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WalletEntryDeal() when $default != null:
return $default(_that.id,_that.code,_that.isFund);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code, @JsonKey(name: 'is_fund')  bool isFund)  $default,) {final _that = this;
switch (_that) {
case _WalletEntryDeal():
return $default(_that.id,_that.code,_that.isFund);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code, @JsonKey(name: 'is_fund')  bool isFund)?  $default,) {final _that = this;
switch (_that) {
case _WalletEntryDeal() when $default != null:
return $default(_that.id,_that.code,_that.isFund);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WalletEntryDeal implements WalletEntryDeal {
  const _WalletEntryDeal({required this.id, required this.code, @JsonKey(name: 'is_fund') this.isFund = false});
  factory _WalletEntryDeal.fromJson(Map<String, dynamic> json) => _$WalletEntryDealFromJson(json);

@override final  int id;
@override final  String code;
@override@JsonKey(name: 'is_fund') final  bool isFund;

/// Create a copy of WalletEntryDeal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WalletEntryDealCopyWith<_WalletEntryDeal> get copyWith => __$WalletEntryDealCopyWithImpl<_WalletEntryDeal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WalletEntryDealToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WalletEntryDeal&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.isFund, isFund) || other.isFund == isFund));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,isFund);

@override
String toString() {
  return 'WalletEntryDeal(id: $id, code: $code, isFund: $isFund)';
}


}

/// @nodoc
abstract mixin class _$WalletEntryDealCopyWith<$Res> implements $WalletEntryDealCopyWith<$Res> {
  factory _$WalletEntryDealCopyWith(_WalletEntryDeal value, $Res Function(_WalletEntryDeal) _then) = __$WalletEntryDealCopyWithImpl;
@override @useResult
$Res call({
 int id, String code,@JsonKey(name: 'is_fund') bool isFund
});




}
/// @nodoc
class __$WalletEntryDealCopyWithImpl<$Res>
    implements _$WalletEntryDealCopyWith<$Res> {
  __$WalletEntryDealCopyWithImpl(this._self, this._then);

  final _WalletEntryDeal _self;
  final $Res Function(_WalletEntryDeal) _then;

/// Create a copy of WalletEntryDeal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? isFund = null,}) {
  return _then(_WalletEntryDeal(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,isFund: null == isFund ? _self.isFund : isFund // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$WalletEntryPeriod {

 int get id; String get code;
/// Create a copy of WalletEntryPeriod
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalletEntryPeriodCopyWith<WalletEntryPeriod> get copyWith => _$WalletEntryPeriodCopyWithImpl<WalletEntryPeriod>(this as WalletEntryPeriod, _$identity);

  /// Serializes this WalletEntryPeriod to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalletEntryPeriod&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code);

@override
String toString() {
  return 'WalletEntryPeriod(id: $id, code: $code)';
}


}

/// @nodoc
abstract mixin class $WalletEntryPeriodCopyWith<$Res>  {
  factory $WalletEntryPeriodCopyWith(WalletEntryPeriod value, $Res Function(WalletEntryPeriod) _then) = _$WalletEntryPeriodCopyWithImpl;
@useResult
$Res call({
 int id, String code
});




}
/// @nodoc
class _$WalletEntryPeriodCopyWithImpl<$Res>
    implements $WalletEntryPeriodCopyWith<$Res> {
  _$WalletEntryPeriodCopyWithImpl(this._self, this._then);

  final WalletEntryPeriod _self;
  final $Res Function(WalletEntryPeriod) _then;

/// Create a copy of WalletEntryPeriod
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WalletEntryPeriod].
extension WalletEntryPeriodPatterns on WalletEntryPeriod {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WalletEntryPeriod value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WalletEntryPeriod() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WalletEntryPeriod value)  $default,){
final _that = this;
switch (_that) {
case _WalletEntryPeriod():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WalletEntryPeriod value)?  $default,){
final _that = this;
switch (_that) {
case _WalletEntryPeriod() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WalletEntryPeriod() when $default != null:
return $default(_that.id,_that.code);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code)  $default,) {final _that = this;
switch (_that) {
case _WalletEntryPeriod():
return $default(_that.id,_that.code);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code)?  $default,) {final _that = this;
switch (_that) {
case _WalletEntryPeriod() when $default != null:
return $default(_that.id,_that.code);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WalletEntryPeriod implements WalletEntryPeriod {
  const _WalletEntryPeriod({required this.id, required this.code});
  factory _WalletEntryPeriod.fromJson(Map<String, dynamic> json) => _$WalletEntryPeriodFromJson(json);

@override final  int id;
@override final  String code;

/// Create a copy of WalletEntryPeriod
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WalletEntryPeriodCopyWith<_WalletEntryPeriod> get copyWith => __$WalletEntryPeriodCopyWithImpl<_WalletEntryPeriod>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WalletEntryPeriodToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WalletEntryPeriod&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code);

@override
String toString() {
  return 'WalletEntryPeriod(id: $id, code: $code)';
}


}

/// @nodoc
abstract mixin class _$WalletEntryPeriodCopyWith<$Res> implements $WalletEntryPeriodCopyWith<$Res> {
  factory _$WalletEntryPeriodCopyWith(_WalletEntryPeriod value, $Res Function(_WalletEntryPeriod) _then) = __$WalletEntryPeriodCopyWithImpl;
@override @useResult
$Res call({
 int id, String code
});




}
/// @nodoc
class __$WalletEntryPeriodCopyWithImpl<$Res>
    implements _$WalletEntryPeriodCopyWith<$Res> {
  __$WalletEntryPeriodCopyWithImpl(this._self, this._then);

  final _WalletEntryPeriod _self;
  final $Res Function(_WalletEntryPeriod) _then;

/// Create a copy of WalletEntryPeriod
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,}) {
  return _then(_WalletEntryPeriod(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$WalletEntryUnits {

 String get units;@JsonKey(name: 'unit_price') String get unitPrice;@JsonKey(name: 'locked_until') String? get lockedUntil;
/// Create a copy of WalletEntryUnits
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalletEntryUnitsCopyWith<WalletEntryUnits> get copyWith => _$WalletEntryUnitsCopyWithImpl<WalletEntryUnits>(this as WalletEntryUnits, _$identity);

  /// Serializes this WalletEntryUnits to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalletEntryUnits&&(identical(other.units, units) || other.units == units)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.lockedUntil, lockedUntil) || other.lockedUntil == lockedUntil));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,units,unitPrice,lockedUntil);

@override
String toString() {
  return 'WalletEntryUnits(units: $units, unitPrice: $unitPrice, lockedUntil: $lockedUntil)';
}


}

/// @nodoc
abstract mixin class $WalletEntryUnitsCopyWith<$Res>  {
  factory $WalletEntryUnitsCopyWith(WalletEntryUnits value, $Res Function(WalletEntryUnits) _then) = _$WalletEntryUnitsCopyWithImpl;
@useResult
$Res call({
 String units,@JsonKey(name: 'unit_price') String unitPrice,@JsonKey(name: 'locked_until') String? lockedUntil
});




}
/// @nodoc
class _$WalletEntryUnitsCopyWithImpl<$Res>
    implements $WalletEntryUnitsCopyWith<$Res> {
  _$WalletEntryUnitsCopyWithImpl(this._self, this._then);

  final WalletEntryUnits _self;
  final $Res Function(WalletEntryUnits) _then;

/// Create a copy of WalletEntryUnits
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? units = null,Object? unitPrice = null,Object? lockedUntil = freezed,}) {
  return _then(_self.copyWith(
units: null == units ? _self.units : units // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,lockedUntil: freezed == lockedUntil ? _self.lockedUntil : lockedUntil // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WalletEntryUnits].
extension WalletEntryUnitsPatterns on WalletEntryUnits {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WalletEntryUnits value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WalletEntryUnits() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WalletEntryUnits value)  $default,){
final _that = this;
switch (_that) {
case _WalletEntryUnits():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WalletEntryUnits value)?  $default,){
final _that = this;
switch (_that) {
case _WalletEntryUnits() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String units, @JsonKey(name: 'unit_price')  String unitPrice, @JsonKey(name: 'locked_until')  String? lockedUntil)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WalletEntryUnits() when $default != null:
return $default(_that.units,_that.unitPrice,_that.lockedUntil);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String units, @JsonKey(name: 'unit_price')  String unitPrice, @JsonKey(name: 'locked_until')  String? lockedUntil)  $default,) {final _that = this;
switch (_that) {
case _WalletEntryUnits():
return $default(_that.units,_that.unitPrice,_that.lockedUntil);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String units, @JsonKey(name: 'unit_price')  String unitPrice, @JsonKey(name: 'locked_until')  String? lockedUntil)?  $default,) {final _that = this;
switch (_that) {
case _WalletEntryUnits() when $default != null:
return $default(_that.units,_that.unitPrice,_that.lockedUntil);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WalletEntryUnits implements WalletEntryUnits {
  const _WalletEntryUnits({required this.units, @JsonKey(name: 'unit_price') required this.unitPrice, @JsonKey(name: 'locked_until') this.lockedUntil});
  factory _WalletEntryUnits.fromJson(Map<String, dynamic> json) => _$WalletEntryUnitsFromJson(json);

@override final  String units;
@override@JsonKey(name: 'unit_price') final  String unitPrice;
@override@JsonKey(name: 'locked_until') final  String? lockedUntil;

/// Create a copy of WalletEntryUnits
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WalletEntryUnitsCopyWith<_WalletEntryUnits> get copyWith => __$WalletEntryUnitsCopyWithImpl<_WalletEntryUnits>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WalletEntryUnitsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WalletEntryUnits&&(identical(other.units, units) || other.units == units)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.lockedUntil, lockedUntil) || other.lockedUntil == lockedUntil));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,units,unitPrice,lockedUntil);

@override
String toString() {
  return 'WalletEntryUnits(units: $units, unitPrice: $unitPrice, lockedUntil: $lockedUntil)';
}


}

/// @nodoc
abstract mixin class _$WalletEntryUnitsCopyWith<$Res> implements $WalletEntryUnitsCopyWith<$Res> {
  factory _$WalletEntryUnitsCopyWith(_WalletEntryUnits value, $Res Function(_WalletEntryUnits) _then) = __$WalletEntryUnitsCopyWithImpl;
@override @useResult
$Res call({
 String units,@JsonKey(name: 'unit_price') String unitPrice,@JsonKey(name: 'locked_until') String? lockedUntil
});




}
/// @nodoc
class __$WalletEntryUnitsCopyWithImpl<$Res>
    implements _$WalletEntryUnitsCopyWith<$Res> {
  __$WalletEntryUnitsCopyWithImpl(this._self, this._then);

  final _WalletEntryUnits _self;
  final $Res Function(_WalletEntryUnits) _then;

/// Create a copy of WalletEntryUnits
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? units = null,Object? unitPrice = null,Object? lockedUntil = freezed,}) {
  return _then(_WalletEntryUnits(
units: null == units ? _self.units : units // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,lockedUntil: freezed == lockedUntil ? _self.lockedUntil : lockedUntil // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$WalletEntryActor {

 int get id; String get name;
/// Create a copy of WalletEntryActor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalletEntryActorCopyWith<WalletEntryActor> get copyWith => _$WalletEntryActorCopyWithImpl<WalletEntryActor>(this as WalletEntryActor, _$identity);

  /// Serializes this WalletEntryActor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalletEntryActor&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'WalletEntryActor(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $WalletEntryActorCopyWith<$Res>  {
  factory $WalletEntryActorCopyWith(WalletEntryActor value, $Res Function(WalletEntryActor) _then) = _$WalletEntryActorCopyWithImpl;
@useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class _$WalletEntryActorCopyWithImpl<$Res>
    implements $WalletEntryActorCopyWith<$Res> {
  _$WalletEntryActorCopyWithImpl(this._self, this._then);

  final WalletEntryActor _self;
  final $Res Function(WalletEntryActor) _then;

/// Create a copy of WalletEntryActor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WalletEntryActor].
extension WalletEntryActorPatterns on WalletEntryActor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WalletEntryActor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WalletEntryActor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WalletEntryActor value)  $default,){
final _that = this;
switch (_that) {
case _WalletEntryActor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WalletEntryActor value)?  $default,){
final _that = this;
switch (_that) {
case _WalletEntryActor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WalletEntryActor() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name)  $default,) {final _that = this;
switch (_that) {
case _WalletEntryActor():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name)?  $default,) {final _that = this;
switch (_that) {
case _WalletEntryActor() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WalletEntryActor implements WalletEntryActor {
  const _WalletEntryActor({required this.id, required this.name});
  factory _WalletEntryActor.fromJson(Map<String, dynamic> json) => _$WalletEntryActorFromJson(json);

@override final  int id;
@override final  String name;

/// Create a copy of WalletEntryActor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WalletEntryActorCopyWith<_WalletEntryActor> get copyWith => __$WalletEntryActorCopyWithImpl<_WalletEntryActor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WalletEntryActorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WalletEntryActor&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'WalletEntryActor(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$WalletEntryActorCopyWith<$Res> implements $WalletEntryActorCopyWith<$Res> {
  factory _$WalletEntryActorCopyWith(_WalletEntryActor value, $Res Function(_WalletEntryActor) _then) = __$WalletEntryActorCopyWithImpl;
@override @useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class __$WalletEntryActorCopyWithImpl<$Res>
    implements _$WalletEntryActorCopyWith<$Res> {
  __$WalletEntryActorCopyWithImpl(this._self, this._then);

  final _WalletEntryActor _self;
  final $Res Function(_WalletEntryActor) _then;

/// Create a copy of WalletEntryActor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_WalletEntryActor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
