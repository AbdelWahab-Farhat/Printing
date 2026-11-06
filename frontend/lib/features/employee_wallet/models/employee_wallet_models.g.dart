// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee_wallet_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EmployeeWalletEntry _$EmployeeWalletEntryFromJson(Map<String, dynamic> json) =>
    _EmployeeWalletEntry(
      id: (json['id'] as num).toInt(),
      type: json['type'] as String,
      typeLabel: json['type_label'] as String,
      direction: json['direction'] as String,
      amount: json['amount'] as String,
      userId: (json['user_id'] as num?)?.toInt(),
      user: json['user'] == null
          ? null
          : EmployeeWalletPerson.fromJson(json['user'] as Map<String, dynamic>),
      methodLabel: json['method_label'] as String?,
      categoryName: _categoryName(json, 'category_name') as String?,
      notes: json['notes'] as String?,
      occurredAt: _localDate(json['occurred_at']),
      isReversed: json['is_reversed'] as bool? ?? false,
      canReverse: json['can_reverse'] as bool? ?? false,
      reversalReason: _reversalReason(json, 'reversal_reason') as String?,
      recorderName: _recorderName(json, 'recorder_name') as String?,
    );

Map<String, dynamic> _$EmployeeWalletEntryToJson(
  _EmployeeWalletEntry instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'type_label': instance.typeLabel,
  'direction': instance.direction,
  'amount': instance.amount,
  'user_id': instance.userId,
  'user': instance.user?.toJson(),
  'method_label': instance.methodLabel,
  'category_name': instance.categoryName,
  'notes': instance.notes,
  'occurred_at': instance.occurredAt?.toIso8601String(),
  'is_reversed': instance.isReversed,
  'can_reverse': instance.canReverse,
  'reversal_reason': instance.reversalReason,
  'recorder_name': instance.recorderName,
};

_EmployeeWalletPerson _$EmployeeWalletPersonFromJson(
  Map<String, dynamic> json,
) => _EmployeeWalletPerson(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  code: json['code'] as String?,
);

Map<String, dynamic> _$EmployeeWalletPersonToJson(
  _EmployeeWalletPerson instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'code': instance.code,
};

_EmployeeWallet _$EmployeeWalletFromJson(Map<String, dynamic> json) =>
    _EmployeeWallet(
      balance: json['balance'] as String,
      canMove: json['can_move'] as bool? ?? false,
      salary: json['salary'] as String?,
    );

Map<String, dynamic> _$EmployeeWalletToJson(_EmployeeWallet instance) =>
    <String, dynamic>{
      'balance': instance.balance,
      'can_move': instance.canMove,
      'salary': instance.salary,
    };

_EmployeeWalletWrite _$EmployeeWalletWriteFromJson(Map<String, dynamic> json) =>
    _EmployeeWalletWrite(
      entry: EmployeeWalletEntry.fromJson(
        json['entry'] as Map<String, dynamic>,
      ),
      balance: json['balance'] as String,
    );

Map<String, dynamic> _$EmployeeWalletWriteToJson(
  _EmployeeWalletWrite instance,
) => <String, dynamic>{
  'entry': instance.entry.toJson(),
  'balance': instance.balance,
};
