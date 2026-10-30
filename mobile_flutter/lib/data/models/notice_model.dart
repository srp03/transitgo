class NoticeModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String publishedAt;
  final String source;
  final bool isVerified;
  final String? actionUrl;

  NoticeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.publishedAt,
    required this.source,
    this.isVerified = true,
    this.actionUrl,
  });

  factory NoticeModel.fromJson(Map<String, dynamic> json) {
    return NoticeModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'ADVISORY',
      publishedAt: json['publishedAt']?.toString() ?? '',
      source: json['source']?.toString() ?? 'TMT',
      isVerified: json['isVerified'] as bool? ?? true,
      actionUrl: json['actionUrl']?.toString(),
    );
  }
}
