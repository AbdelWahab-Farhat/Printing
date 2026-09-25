// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'place_order_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BasketPricing implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'BasketPricing'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BasketPricing);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'BasketPricing()';
}


}

/// @nodoc
class $BasketPricingCopyWith<$Res>  {
$BasketPricingCopyWith(BasketPricing _, $Res Function(BasketPricing) __);
}


/// Adds pattern-matching-related methods to [BasketPricing].
extension BasketPricingPatterns on BasketPricing {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( BasketPricingPending value)?  pending,TResult Function( BasketPriced value)?  priced,TResult Function( BasketPricingFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case BasketPricingPending() when pending != null:
return pending(_that);case BasketPriced() when priced != null:
return priced(_that);case BasketPricingFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( BasketPricingPending value)  pending,required TResult Function( BasketPriced value)  priced,required TResult Function( BasketPricingFailed value)  failed,}){
final _that = this;
switch (_that) {
case BasketPricingPending():
return pending(_that);case BasketPriced():
return priced(_that);case BasketPricingFailed():
return failed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( BasketPricingPending value)?  pending,TResult? Function( BasketPriced value)?  priced,TResult? Function( BasketPricingFailed value)?  failed,}){
final _that = this;
switch (_that) {
case BasketPricingPending() when pending != null:
return pending(_that);case BasketPriced() when priced != null:
return priced(_that);case BasketPricingFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  pending,TResult Function( BasketQuote quote)?  priced,TResult Function( Failure failure)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case BasketPricingPending() when pending != null:
return pending();case BasketPriced() when priced != null:
return priced(_that.quote);case BasketPricingFailed() when failed != null:
return failed(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  pending,required TResult Function( BasketQuote quote)  priced,required TResult Function( Failure failure)  failed,}) {final _that = this;
switch (_that) {
case BasketPricingPending():
return pending();case BasketPriced():
return priced(_that.quote);case BasketPricingFailed():
return failed(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  pending,TResult? Function( BasketQuote quote)?  priced,TResult? Function( Failure failure)?  failed,}) {final _that = this;
switch (_that) {
case BasketPricingPending() when pending != null:
return pending();case BasketPriced() when priced != null:
return priced(_that.quote);case BasketPricingFailed() when failed != null:
return failed(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class BasketPricingPending with DiagnosticableTreeMixin implements BasketPricing {
  const BasketPricingPending();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'BasketPricing.pending'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BasketPricingPending);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'BasketPricing.pending()';
}


}




/// @nodoc


class BasketPriced with DiagnosticableTreeMixin implements BasketPricing {
  const BasketPriced(this.quote);
  

 final  BasketQuote quote;

/// Create a copy of BasketPricing
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BasketPricedCopyWith<BasketPriced> get copyWith => _$BasketPricedCopyWithImpl<BasketPriced>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'BasketPricing.priced'))
    ..add(DiagnosticsProperty('quote', quote));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BasketPriced&&(identical(other.quote, quote) || other.quote == quote));
}


@override
int get hashCode => Object.hash(runtimeType,quote);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'BasketPricing.priced(quote: $quote)';
}


}

/// @nodoc
abstract mixin class $BasketPricedCopyWith<$Res> implements $BasketPricingCopyWith<$Res> {
  factory $BasketPricedCopyWith(BasketPriced value, $Res Function(BasketPriced) _then) = _$BasketPricedCopyWithImpl;
@useResult
$Res call({
 BasketQuote quote
});


$BasketQuoteCopyWith<$Res> get quote;

}
/// @nodoc
class _$BasketPricedCopyWithImpl<$Res>
    implements $BasketPricedCopyWith<$Res> {
  _$BasketPricedCopyWithImpl(this._self, this._then);

  final BasketPriced _self;
  final $Res Function(BasketPriced) _then;

/// Create a copy of BasketPricing
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? quote = null,}) {
  return _then(BasketPriced(
null == quote ? _self.quote : quote // ignore: cast_nullable_to_non_nullable
as BasketQuote,
  ));
}

/// Create a copy of BasketPricing
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BasketQuoteCopyWith<$Res> get quote {
  
  return $BasketQuoteCopyWith<$Res>(_self.quote, (value) {
    return _then(_self.copyWith(quote: value));
  });
}
}

/// @nodoc


class BasketPricingFailed with DiagnosticableTreeMixin implements BasketPricing {
  const BasketPricingFailed(this.failure);
  

 final  Failure failure;

/// Create a copy of BasketPricing
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BasketPricingFailedCopyWith<BasketPricingFailed> get copyWith => _$BasketPricingFailedCopyWithImpl<BasketPricingFailed>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'BasketPricing.failed'))
    ..add(DiagnosticsProperty('failure', failure));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BasketPricingFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'BasketPricing.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $BasketPricingFailedCopyWith<$Res> implements $BasketPricingCopyWith<$Res> {
  factory $BasketPricingFailedCopyWith(BasketPricingFailed value, $Res Function(BasketPricingFailed) _then) = _$BasketPricingFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$BasketPricingFailedCopyWithImpl<$Res>
    implements $BasketPricingFailedCopyWith<$Res> {
  _$BasketPricingFailedCopyWithImpl(this._self, this._then);

  final BasketPricingFailed _self;
  final $Res Function(BasketPricingFailed) _then;

/// Create a copy of BasketPricing
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(BasketPricingFailed(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of BasketPricing
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

/// @nodoc
mixin _$PlaceOrderState implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'PlaceOrderState'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceOrderState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'PlaceOrderState()';
}


}

/// @nodoc
class $PlaceOrderStateCopyWith<$Res>  {
$PlaceOrderStateCopyWith(PlaceOrderState _, $Res Function(PlaceOrderState) __);
}


/// Adds pattern-matching-related methods to [PlaceOrderState].
extension PlaceOrderStatePatterns on PlaceOrderState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PlaceOrderLoading value)?  loading,TResult Function( PlaceOrderReady value)?  ready,TResult Function( PlaceOrderFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PlaceOrderLoading() when loading != null:
return loading(_that);case PlaceOrderReady() when ready != null:
return ready(_that);case PlaceOrderFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PlaceOrderLoading value)  loading,required TResult Function( PlaceOrderReady value)  ready,required TResult Function( PlaceOrderFailure value)  failure,}){
final _that = this;
switch (_that) {
case PlaceOrderLoading():
return loading(_that);case PlaceOrderReady():
return ready(_that);case PlaceOrderFailure():
return failure(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PlaceOrderLoading value)?  loading,TResult? Function( PlaceOrderReady value)?  ready,TResult? Function( PlaceOrderFailure value)?  failure,}){
final _that = this;
switch (_that) {
case PlaceOrderLoading() when loading != null:
return loading(_that);case PlaceOrderReady() when ready != null:
return ready(_that);case PlaceOrderFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<City> cities,  List<CustomerDesign> designs,  List<Shop> shops,  List<OrderDraftLine> lines,  CheckoutStep step,  int? shopId,  int? cityId,  int? regionId,  List<int> designIds,  String? customerPhone,  BasketPricing pricing,  bool isSubmitting,  CustomerOrderDetail? placed,  Failure? lastFailure)?  ready,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PlaceOrderLoading() when loading != null:
return loading();case PlaceOrderReady() when ready != null:
return ready(_that.cities,_that.designs,_that.shops,_that.lines,_that.step,_that.shopId,_that.cityId,_that.regionId,_that.designIds,_that.customerPhone,_that.pricing,_that.isSubmitting,_that.placed,_that.lastFailure);case PlaceOrderFailure() when failure != null:
return failure(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<City> cities,  List<CustomerDesign> designs,  List<Shop> shops,  List<OrderDraftLine> lines,  CheckoutStep step,  int? shopId,  int? cityId,  int? regionId,  List<int> designIds,  String? customerPhone,  BasketPricing pricing,  bool isSubmitting,  CustomerOrderDetail? placed,  Failure? lastFailure)  ready,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case PlaceOrderLoading():
return loading();case PlaceOrderReady():
return ready(_that.cities,_that.designs,_that.shops,_that.lines,_that.step,_that.shopId,_that.cityId,_that.regionId,_that.designIds,_that.customerPhone,_that.pricing,_that.isSubmitting,_that.placed,_that.lastFailure);case PlaceOrderFailure():
return failure(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<City> cities,  List<CustomerDesign> designs,  List<Shop> shops,  List<OrderDraftLine> lines,  CheckoutStep step,  int? shopId,  int? cityId,  int? regionId,  List<int> designIds,  String? customerPhone,  BasketPricing pricing,  bool isSubmitting,  CustomerOrderDetail? placed,  Failure? lastFailure)?  ready,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case PlaceOrderLoading() when loading != null:
return loading();case PlaceOrderReady() when ready != null:
return ready(_that.cities,_that.designs,_that.shops,_that.lines,_that.step,_that.shopId,_that.cityId,_that.regionId,_that.designIds,_that.customerPhone,_that.pricing,_that.isSubmitting,_that.placed,_that.lastFailure);case PlaceOrderFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class PlaceOrderLoading with DiagnosticableTreeMixin implements PlaceOrderState {
  const PlaceOrderLoading();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'PlaceOrderState.loading'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceOrderLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'PlaceOrderState.loading()';
}


}




/// @nodoc


class PlaceOrderReady with DiagnosticableTreeMixin implements PlaceOrderState {
  const PlaceOrderReady({required final  List<City> cities, final  List<CustomerDesign> designs = const <CustomerDesign>[], final  List<Shop> shops = const <Shop>[], final  List<OrderDraftLine> lines = const <OrderDraftLine>[], this.step = CheckoutStep.products, this.shopId, this.cityId, this.regionId, final  List<int> designIds = const <int>[], this.customerPhone, this.pricing = const BasketPricing.pending(), this.isSubmitting = false, this.placed, this.lastFailure}): _cities = cities,_designs = designs,_shops = shops,_lines = lines,_designIds = designIds;
  

/// كل الوجهات بمناطقها، مرةً واحدة — المنتقي لا يُقلَّب صفحات.
 final  List<City> _cities;
/// كل الوجهات بمناطقها، مرةً واحدة — المنتقي لا يُقلَّب صفحات.
 List<City> get cities {
  if (_cities is EqualUnmodifiableListView) return _cities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cities);
}

/// مكتبة العميل لإرفاق التصاميم. **الفارغة مقبولة**: الإرفاق اختياري، والمكتبة التي فشل
/// تحميلها تبدو هكذا أيضاً، ولا يستحق أيٌّ منهما رفضَ طلبية.
 final  List<CustomerDesign> _designs;
/// مكتبة العميل لإرفاق التصاميم. **الفارغة مقبولة**: الإرفاق اختياري، والمكتبة التي فشل
/// تحميلها تبدو هكذا أيضاً، ولا يستحق أيٌّ منهما رفضَ طلبية.
@JsonKey() List<CustomerDesign> get designs {
  if (_designs is EqualUnmodifiableListView) return _designs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_designs);
}

/// متاجر العميل بترتيب إضافتها — ومنها تُختار الوجهة.
 final  List<Shop> _shops;
/// متاجر العميل بترتيب إضافتها — ومنها تُختار الوجهة.
@JsonKey() List<Shop> get shops {
  if (_shops is EqualUnmodifiableListView) return _shops;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_shops);
}

 final  List<OrderDraftLine> _lines;
@JsonKey() List<OrderDraftLine> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}

@JsonKey() final  CheckoutStep step;
/// المتجر الذي تذهب إليه البضاعة. اختياريٌّ عند الخادم، ويُختار أولُ المتاجر عند الفتح.
 final  int? shopId;
 final  int? cityId;
 final  int? regionId;
 final  List<int> _designIds;
@JsonKey() List<int> get designIds {
  if (_designIds is EqualUnmodifiableListView) return _designIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_designIds);
}

/// رقم الحساب، يُملأ به حقل «هاتف الاستلام» مرةً عند الفتح ثم يبقى الحقل للعميل. `null` حين
/// لم تصل قراءة الحساب — فيكتبه العميل، ولا يتوقف شيء.
 final  String? customerPhone;
/// سعر كل سطرٍ والتكلفة النهائية، كما حسبها الخادم للسطور والمدينة الحاليّتين.
@JsonKey() final  BasketPricing pricing;
@JsonKey() final  bool isSubmitting;
/// الطلبية التي أنشأها المتجر. **«بانتظار المراجعة»** — لا شيء مؤكَّد ولا شيء مُسعَّر من المخزن
/// قبل أن يقرأها أحد.
 final  CustomerOrderDetail? placed;
 final  Failure? lastFailure;

/// Create a copy of PlaceOrderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaceOrderReadyCopyWith<PlaceOrderReady> get copyWith => _$PlaceOrderReadyCopyWithImpl<PlaceOrderReady>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'PlaceOrderState.ready'))
    ..add(DiagnosticsProperty('cities', cities))..add(DiagnosticsProperty('designs', designs))..add(DiagnosticsProperty('shops', shops))..add(DiagnosticsProperty('lines', lines))..add(DiagnosticsProperty('step', step))..add(DiagnosticsProperty('shopId', shopId))..add(DiagnosticsProperty('cityId', cityId))..add(DiagnosticsProperty('regionId', regionId))..add(DiagnosticsProperty('designIds', designIds))..add(DiagnosticsProperty('customerPhone', customerPhone))..add(DiagnosticsProperty('pricing', pricing))..add(DiagnosticsProperty('isSubmitting', isSubmitting))..add(DiagnosticsProperty('placed', placed))..add(DiagnosticsProperty('lastFailure', lastFailure));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceOrderReady&&const DeepCollectionEquality().equals(other._cities, _cities)&&const DeepCollectionEquality().equals(other._designs, _designs)&&const DeepCollectionEquality().equals(other._shops, _shops)&&const DeepCollectionEquality().equals(other._lines, _lines)&&(identical(other.step, step) || other.step == step)&&(identical(other.shopId, shopId) || other.shopId == shopId)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&(identical(other.regionId, regionId) || other.regionId == regionId)&&const DeepCollectionEquality().equals(other._designIds, _designIds)&&(identical(other.customerPhone, customerPhone) || other.customerPhone == customerPhone)&&(identical(other.pricing, pricing) || other.pricing == pricing)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.placed, placed) || other.placed == placed)&&(identical(other.lastFailure, lastFailure) || other.lastFailure == lastFailure));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_cities),const DeepCollectionEquality().hash(_designs),const DeepCollectionEquality().hash(_shops),const DeepCollectionEquality().hash(_lines),step,shopId,cityId,regionId,const DeepCollectionEquality().hash(_designIds),customerPhone,pricing,isSubmitting,placed,lastFailure);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'PlaceOrderState.ready(cities: $cities, designs: $designs, shops: $shops, lines: $lines, step: $step, shopId: $shopId, cityId: $cityId, regionId: $regionId, designIds: $designIds, customerPhone: $customerPhone, pricing: $pricing, isSubmitting: $isSubmitting, placed: $placed, lastFailure: $lastFailure)';
}


}

/// @nodoc
abstract mixin class $PlaceOrderReadyCopyWith<$Res> implements $PlaceOrderStateCopyWith<$Res> {
  factory $PlaceOrderReadyCopyWith(PlaceOrderReady value, $Res Function(PlaceOrderReady) _then) = _$PlaceOrderReadyCopyWithImpl;
@useResult
$Res call({
 List<City> cities, List<CustomerDesign> designs, List<Shop> shops, List<OrderDraftLine> lines, CheckoutStep step, int? shopId, int? cityId, int? regionId, List<int> designIds, String? customerPhone, BasketPricing pricing, bool isSubmitting, CustomerOrderDetail? placed, Failure? lastFailure
});


$BasketPricingCopyWith<$Res> get pricing;$CustomerOrderDetailCopyWith<$Res>? get placed;$FailureCopyWith<$Res>? get lastFailure;

}
/// @nodoc
class _$PlaceOrderReadyCopyWithImpl<$Res>
    implements $PlaceOrderReadyCopyWith<$Res> {
  _$PlaceOrderReadyCopyWithImpl(this._self, this._then);

  final PlaceOrderReady _self;
  final $Res Function(PlaceOrderReady) _then;

/// Create a copy of PlaceOrderState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? cities = null,Object? designs = null,Object? shops = null,Object? lines = null,Object? step = null,Object? shopId = freezed,Object? cityId = freezed,Object? regionId = freezed,Object? designIds = null,Object? customerPhone = freezed,Object? pricing = null,Object? isSubmitting = null,Object? placed = freezed,Object? lastFailure = freezed,}) {
  return _then(PlaceOrderReady(
cities: null == cities ? _self._cities : cities // ignore: cast_nullable_to_non_nullable
as List<City>,designs: null == designs ? _self._designs : designs // ignore: cast_nullable_to_non_nullable
as List<CustomerDesign>,shops: null == shops ? _self._shops : shops // ignore: cast_nullable_to_non_nullable
as List<Shop>,lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<OrderDraftLine>,step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as CheckoutStep,shopId: freezed == shopId ? _self.shopId : shopId // ignore: cast_nullable_to_non_nullable
as int?,cityId: freezed == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as int?,regionId: freezed == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as int?,designIds: null == designIds ? _self._designIds : designIds // ignore: cast_nullable_to_non_nullable
as List<int>,customerPhone: freezed == customerPhone ? _self.customerPhone : customerPhone // ignore: cast_nullable_to_non_nullable
as String?,pricing: null == pricing ? _self.pricing : pricing // ignore: cast_nullable_to_non_nullable
as BasketPricing,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,placed: freezed == placed ? _self.placed : placed // ignore: cast_nullable_to_non_nullable
as CustomerOrderDetail?,lastFailure: freezed == lastFailure ? _self.lastFailure : lastFailure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of PlaceOrderState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BasketPricingCopyWith<$Res> get pricing {
  
  return $BasketPricingCopyWith<$Res>(_self.pricing, (value) {
    return _then(_self.copyWith(pricing: value));
  });
}/// Create a copy of PlaceOrderState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustomerOrderDetailCopyWith<$Res>? get placed {
    if (_self.placed == null) {
    return null;
  }

  return $CustomerOrderDetailCopyWith<$Res>(_self.placed!, (value) {
    return _then(_self.copyWith(placed: value));
  });
}/// Create a copy of PlaceOrderState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get lastFailure {
    if (_self.lastFailure == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.lastFailure!, (value) {
    return _then(_self.copyWith(lastFailure: value));
  });
}
}

/// @nodoc


class PlaceOrderFailure with DiagnosticableTreeMixin implements PlaceOrderState {
  const PlaceOrderFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of PlaceOrderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaceOrderFailureCopyWith<PlaceOrderFailure> get copyWith => _$PlaceOrderFailureCopyWithImpl<PlaceOrderFailure>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'PlaceOrderState.failure'))
    ..add(DiagnosticsProperty('failure', failure));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceOrderFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'PlaceOrderState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $PlaceOrderFailureCopyWith<$Res> implements $PlaceOrderStateCopyWith<$Res> {
  factory $PlaceOrderFailureCopyWith(PlaceOrderFailure value, $Res Function(PlaceOrderFailure) _then) = _$PlaceOrderFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$PlaceOrderFailureCopyWithImpl<$Res>
    implements $PlaceOrderFailureCopyWith<$Res> {
  _$PlaceOrderFailureCopyWithImpl(this._self, this._then);

  final PlaceOrderFailure _self;
  final $Res Function(PlaceOrderFailure) _then;

/// Create a copy of PlaceOrderState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(PlaceOrderFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of PlaceOrderState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
