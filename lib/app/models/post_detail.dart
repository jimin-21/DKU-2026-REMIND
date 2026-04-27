class PostDetail {
  final int id;
  final String type;
  final String category;
  final String? source;
  final List<String> tags;
  final String title;
  final String date;
  final List<String> keyPoints;
  final List<String> summaryList;
  final String originalText;
  final String originalUrl;
  final bool isFavorite;
  final bool isMastered;
  final String? masteredDate;
  final String memo;

  const PostDetail({
    required this.id,
    required this.type,
    required this.category,
    this.source,
    required this.tags,
    required this.title,
    required this.date,
    required this.keyPoints,
    required this.summaryList,
    required this.originalText,
    required this.originalUrl,
    required this.isFavorite,
    required this.isMastered,
    required this.masteredDate,
    required this.memo,
  });
}