import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Something named and picked: a warehouse, an account, an employee.
typedef Named = ({int id, String name});

Named? _named(Object? json) =>
    json is Map<String, dynamic> ? (id: json['id'] as int, name: json['name'] as String) : null;

/// One branch as «إعدادات الفروع» edits it — INSTANT-ORDERS-PLAN.md §8.
@immutable
class BranchSettings {
  const BranchSettings({
    required this.id,
    required this.name,
    required this.isActive,
    this.warehouse,
    this.cashAccount,
    this.bankTransferAccount,
    this.bankCardAccount,
    this.employees = const [],
  });

  factory BranchSettings.fromJson(Map<String, dynamic> json) => BranchSettings(
    id: json['id'] as int,
    name: json['name'] as String,
    isActive: json['is_branch_active'] as bool? ?? true,
    warehouse: _named(json['default_warehouse']),
    cashAccount: _named(json['cash_account']),
    bankTransferAccount: _named(json['bank_transfer_account']),
    bankCardAccount: _named(json['bank_card_account']),
    employees: [
      for (final row in (json['employees'] as List<dynamic>? ?? const [])) _named(row)!,
    ],
  );

  final int id;
  final String name;
  final bool isActive;
  final Named? warehouse;
  final Named? cashAccount;
  final Named? bankTransferAccount;
  final Named? bankCardAccount;
  final List<Named> employees;

  /// What a sale here still lacks: without a warehouse nothing can be sold, without an account
  /// that method is refused at handover.
  List<String> get missing => [
    if (warehouse == null) 'المخزن',
    if (cashAccount == null) 'حساب الكاش',
    if (bankTransferAccount == null) 'حساب الحوالة',
    if (bankCardAccount == null) 'حساب البطاقة',
  ];

  BranchSettings copyWith({
    bool? isActive,
    Named? warehouse,
    Named? cashAccount,
    Named? bankTransferAccount,
    Named? bankCardAccount,
    List<Named>? employees,
    bool clearWarehouse = false,
    bool clearCash = false,
    bool clearTransfer = false,
    bool clearCard = false,
  }) => BranchSettings(
    id: id,
    name: name,
    isActive: isActive ?? this.isActive,
    warehouse: clearWarehouse ? null : (warehouse ?? this.warehouse),
    cashAccount: clearCash ? null : (cashAccount ?? this.cashAccount),
    bankTransferAccount: clearTransfer ? null : (bankTransferAccount ?? this.bankTransferAccount),
    bankCardAccount: clearCard ? null : (bankCardAccount ?? this.bankCardAccount),
    employees: employees ?? this.employees,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'is_branch_active': isActive,
    'default_warehouse_id': warehouse?.id,
    'cash_account_id': cashAccount?.id,
    'bank_transfer_account_id': bankTransferAccount?.id,
    'bank_card_account_id': bankCardAccount?.id,
    'employee_ids': [for (final employee in employees) employee.id],
  };
}

/// Every branch, and the company-wide «متأخرة» threshold beside them.
@immutable
class BranchList {
  const BranchList({required this.branches, required this.lateHours});

  final List<BranchSettings> branches;
  final int lateHours;
}

abstract interface class BranchRepository {
  Future<Either<Failure, BranchList>> branches();

  Future<Either<Failure, BranchSettings>> save(BranchSettings branch);

  Future<Either<Failure, int>> saveLateHours(int hours);
}

class BranchRepositoryImpl implements BranchRepository {
  const BranchRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, BranchList>> branches() {
    return safeMetaRequest<BranchList>(
      () => _dio.get(BranchEndpoints.index),
      parse: (data, meta) => BranchList(
        branches: [
          for (final row in data as List<dynamic>) BranchSettings.fromJson(row as Map<String, dynamic>),
        ],
        lateHours: meta['instant_order_late_hours'] as int? ?? 24,
      ),
    );
  }

  @override
  Future<Either<Failure, BranchSettings>> save(BranchSettings branch) {
    return safeRequest<BranchSettings>(
      () => _dio.put(BranchEndpoints.update(branch.id), data: branch.toJson()),
      parse: (data) => BranchSettings.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, int>> saveLateHours(int hours) {
    return safeRequest<int>(
      () => _dio.put(BranchEndpoints.lateHours, data: {'instant_order_late_hours': hours}),
      parse: (data) => (data as Map<String, dynamic>)['instant_order_late_hours'] as int,
    );
  }
}
