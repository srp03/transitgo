import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/notice_model.dart';
import 'core_providers.dart';

final noticesProvider = FutureProvider<List<NoticeModel>>((ref) async {
  final repo = ref.watch(noticeRepositoryProvider);
  return await repo.getNotices();
});
