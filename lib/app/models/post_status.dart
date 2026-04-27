enum PostStatus {
  active,
  archived,
  mine,
  deleted,
  done,
}

extension PostStatusX on PostStatus {
  String get value {
    switch (this) {
      case PostStatus.active:
        return 'ACTIVE';
      case PostStatus.archived:
        return 'ARCHIVED';
      case PostStatus.mine:
        return 'MINE';
      case PostStatus.deleted:
        return 'DELETED';
      case PostStatus.done:
        return 'DONE';
    }
  }

  static PostStatus fromString(String value) {
    switch (value) {
      case 'ARCHIVED':
        return PostStatus.archived;
      case 'MINE':
        return PostStatus.mine;
      case 'DELETED':
        return PostStatus.deleted;
      case 'DONE':
        return PostStatus.done;
      case 'ACTIVE':
      default:
        return PostStatus.active;
    }
  }
}