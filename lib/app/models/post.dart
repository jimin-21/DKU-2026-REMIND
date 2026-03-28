import 'post_status.dart';

class Post {
  final int id;
  final String category;
  final String? source;
  final List<String> tags;
  final String title;
  final String date;
  final List<String> keyPoints;
  final bool isFavorite;
  final bool isPinned;
  final bool isRead;
  final PostStatus status;

  const Post({
    required this.id,
    required this.category,
    this.source,
    required this.tags,
    required this.title,
    required this.date,
    required this.keyPoints,
    required this.isFavorite,
    required this.isPinned,
    required this.isRead,
    required this.status,
  });

  Post copyWith({
    int? id,
    String? category,
    String? source,
    List<String>? tags,
    String? title,
    String? date,
    List<String>? keyPoints,
    bool? isFavorite,
    bool? isPinned,
    bool? isRead,
    PostStatus? status,
  }) {
    return Post(
      id: id ?? this.id,
      category: category ?? this.category,
      source: source ?? this.source,
      tags: tags ?? this.tags,
      title: title ?? this.title,
      date: date ?? this.date,
      keyPoints: keyPoints ?? this.keyPoints,
      isFavorite: isFavorite ?? this.isFavorite,
      isPinned: isPinned ?? this.isPinned,
      isRead: isRead ?? this.isRead,
      status: status ?? this.status,
    );
  }
}