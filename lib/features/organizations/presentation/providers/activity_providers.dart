import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/activity_log_repository.dart';
import '../../domain/models/activity_log.dart';

final activityLogRepositoryProvider = Provider<ActivityLogRepository>(
  (ref) => ActivityLogRepository(),
);

final activityLogsProvider =
    FutureProvider.family<List<ActivityLog>, String>((ref, orgId) {
  return ref.read(activityLogRepositoryProvider).getLogs(orgId);
});
