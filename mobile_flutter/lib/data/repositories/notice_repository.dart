import '../../core/network/api_client.dart';
import '../models/notice_model.dart';

class NoticeRepository {
  final ApiClient apiClient;

  NoticeRepository(this.apiClient);

  Future<List<NoticeModel>> getNotices() async {
    try {
      final data = await apiClient.get('/notices');
      if (data is List) {
        return data.map((json) => NoticeModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      // Fallback notices if offline
      return [
        NoticeModel(
          id: 'TMT-NOTICE-01',
          title: 'TMT Control Room Helpline',
          description: 'For inquiries and lost & found, call TMT Control Room at +91 022 2539 4922.',
          category: 'HELPLINE',
          publishedAt: '2026-10-01',
          source: 'Thane Municipal Transport',
          isVerified: true,
          actionUrl: 'tel:+9102225394922',
        )
      ];
    }
  }
}
