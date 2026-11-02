import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapor_jalan/features/reports/domain/report.dart';
import 'package:lapor_jalan/features/reports/domain/report_repository.dart';
import 'package:lapor_jalan/features/reports/data/report_repository_provider.dart';

final reportDetailControllerProvider =
    FutureProvider.autoDispose.family<Report, int>((ref, id) async {
  final repository = ref.watch(reportRepositoryProvider);
  return repository.getReportDetail(id);
});
