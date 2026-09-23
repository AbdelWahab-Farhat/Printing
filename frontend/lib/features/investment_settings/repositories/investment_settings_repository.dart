import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/investment_settings/models/investment_settings.dart';

/// بابُ إعدادات الاستثمار.
abstract interface class InvestmentSettingsRepository {
  Future<Either<Failure, InvestmentSettings>> settings();

  /// **تُرسَل الخمسةُ معاً** — النقطة على الخادم تقبل الجزئيّ، لكن الشاشةَ تعرضها كلَّها في
  /// نموذجٍ واحد، فإرسالُ ما لم يُلمس يجعل ما يصل صورةً مطابقةً لما يراه من ضغط الزرّ.
  Future<Either<Failure, InvestmentSettings>> update(InvestmentSettings settings);
}
