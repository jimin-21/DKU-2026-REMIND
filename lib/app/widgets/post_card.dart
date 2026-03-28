import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/post_status.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_formatters.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final void Function(int postId, PostStatus status)? onStatusChange;
  final void Function(int postId, bool isPinned)? onPinChange;
  final void Function(int postId, bool isRead)? onReadChange;
  final bool isInArchive;
  final bool isInMine;
  final bool isInFixedZone;
  final bool isInRandomZone;
  final void Function(int postId)? onHideToday;
  final VoidCallback? onRefreshRandom;

  const PostCard({
    super.key,
    required this.post,
    this.onStatusChange,
    this.onPinChange,
    this.onReadChange,
    this.isInArchive = false,
    this.isInMine = false,
    this.isInFixedZone = false,
    this.isInRandomZone = false,
    this.onHideToday,
    this.onRefreshRandom,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool isFavorite;
  late bool isPinned;
  late PostStatus status;
  late bool isRead;

  @override
  void initState() {
    super.initState();
    isFavorite = widget.post.isFavorite;
    isPinned = widget.post.isPinned;
    status = widget.post.status;
    isRead = widget.post.isRead || widget.post.status == PostStatus.done;
  }

  void handleCheckClick() {
    final newReadStatus = !isRead;
    setState(() {
      isRead = newReadStatus;
    });
    widget.onReadChange?.call(widget.post.id, newReadStatus);

    if (!widget.isInArchive && !widget.isInMine) {
      final newStatus = newReadStatus ? PostStatus.done : PostStatus.active;
      setState(() {
        status = newStatus;
      });
      widget.onStatusChange?.call(widget.post.id, newStatus);
    }
  }

  void handleTogglePin() {
    final newPinned = !isPinned;
    setState(() {
      isPinned = newPinned;
    });
    widget.onPinChange?.call(widget.post.id, newPinned);
    Navigator.pop(context);
  }

  void handleAction(PostStatus newStatus) {
    setState(() {
      status = newStatus;
    });
    widget.onStatusChange?.call(widget.post.id, newStatus);
    Navigator.pop(context);
  }

  void openMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              if (!widget.isInArchive)
                ListTile(
                  leading: const Icon(Icons.folder_open_outlined),
                  title: const Text('아카이브로 이동'),
                  onTap: () => handleAction(PostStatus.archived),
                ),
              if (!widget.isInMine)
                ListTile(
                  leading: const Icon(Icons.inbox_outlined, color: AppColors.peachDustDark),
                  title: const Text(
                    '컬렉션으로 이동',
                    style: TextStyle(color: AppColors.peachDustDark),
                  ),
                  onTap: () => handleAction(PostStatus.mine),
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text(
                  '휴지통으로 이동',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () => handleAction(PostStatus.deleted),
              ),
              ListTile(
                leading: const Icon(Icons.push_pin_outlined),
                title: Text(widget.isInFixedZone
                    ? '홈 화면에서 고정 해제'
                    : (isPinned ? '고정 취소' : '홈 화면에 고정')),
                onTap: handleTogglePin,
              ),
              if (widget.isInRandomZone)
                ListTile(
                  leading: const Text('👁️', style: TextStyle(fontSize: 20)),
                  title: const Text('오늘은 그만 보기'),
                  onTap: () {
                    widget.onHideToday?.call(widget.post.id);
                    Navigator.pop(context);
                  },
                ),
              if (widget.isInRandomZone)
                ListTile(
                  leading: const Text('🔄', style: TextStyle(fontSize: 20)),
                  title: const Text('다른 카드 추천받기'),
                  onTap: () {
                    widget.onRefreshRandom?.call();
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tags = widget.post.tags.isNotEmpty ? widget.post.tags : ['#기록', '#습관'];
    final chipBgColor =
        AppColors.categoryChip[widget.post.category] ?? const Color.fromRGBO(0, 0, 0, 0.05);

    return Opacity(
      opacity: isRead && !widget.isInMine ? 0.5 : 1,
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/post',
            arguments: widget.post.id.toString(),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.card),
            boxShadow: AppShadows.card,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: chipBgColor,
                      borderRadius: BorderRadius.circular(AppRadii.chip),
                    ),
                    child: Text(
                      widget.post.category,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoal,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatDate(widget.post.date),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textDisabled,
                    ),
                  ),
                  if (isPinned) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.push_pin_outlined,
                      size: 16,
                      color: AppColors.peachDustDark,
                    ),
                  ],
                  if (!widget.isInMine && status != PostStatus.mine) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: handleCheckClick,
                      child: Icon(
                        isRead ? Icons.check_circle : Icons.check_circle_outline,
                        size: 18,
                        color: isRead ? AppColors.success : AppColors.textDisabled,
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isFavorite = !isFavorite;
                      });
                    },
                    child: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      size: 18,
                      color: isFavorite ? AppColors.star : AppColors.textDisabled,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: openMenu,
                    child: const Icon(
                      Icons.more_horiz,
                      size: 18,
                      color: AppColors.textDisabled,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.post.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  height: 1.4,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              ...widget.post.keyPoints.map(
                (point) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(
                          point,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.tagBg,
                            borderRadius: BorderRadius.circular(AppRadii.chip),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.tagText,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Row(
                    children: [
                      Text(
                        '원본 보기',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}