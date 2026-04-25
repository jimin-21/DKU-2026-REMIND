import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addPost({
    required String url,
    required String title,
    required String summary,
    required List<String> tags,
    required String category,
    required String thumbnail,
    String status = 'ACTIVE',
  }) async {
    await _db.collection('posts').add({
      'url': url,
      'title': title,
      'summary': summary,
      'tags': tags,
      'category': category,
      'thumbnail': thumbnail,
      'status': status,
      'memo': '',
      'originalText': '',
      'isRead': false,
      'isFavorite': false,
      'isPinned': false,
      'isDeleted': false,
      'isCollected': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getPosts() async {
    final snapshot = await _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data(),
      };
    }).toList();
  }

  Future<Map<String, dynamic>?> getPostById(String id) async {
    final doc = await _db.collection('posts').doc(id).get();

    if (!doc.exists) return null;

    return {
      'id': doc.id,
      ...doc.data()!,
    };
  }

  Future<List<Map<String, dynamic>>> getTrashPosts() async {
    final posts = await getPosts();

    return posts.where((post) {
      return (post['isDeleted'] ?? false) == true;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getCollectedPosts() async {
    final posts = await getPosts();

    return posts.where((post) {
      final bool isCollected = post['isCollected'] ?? false;
      final bool isDeleted = post['isDeleted'] ?? false;

      return isCollected == true && isDeleted == false;
    }).toList();
  }

  Future<void> updateReadStatus(String id, bool isRead) async {
    await _db.collection('posts').doc(id).update({
      'isRead': isRead,
    });
  }

  Future<void> updateFavoriteStatus(String id, bool isFavorite) async {
    await _db.collection('posts').doc(id).update({
      'isFavorite': isFavorite,
    });
  }

  Future<void> updatePinnedStatus(String id, bool isPinned) async {
    await _db.collection('posts').doc(id).update({
      'isPinned': isPinned,
    });
  }

  Future<void> updateCollectedStatus(String id, bool isCollected) async {
    await _db.collection('posts').doc(id).update({
      'isCollected': isCollected,
    });
  }

  Future<void> updateSummary(String id, String summary) async {
    await _db.collection('posts').doc(id).update({
      'summary': summary,
    });
  }

  Future<void> updateMemo(String id, String memo) async {
    await _db.collection('posts').doc(id).update({
      'memo': memo,
    });
  }

  Future<void> moveToTrash(String id) async {
    await _db.collection('posts').doc(id).update({
      'isDeleted': true,
    });
  }

  Future<void> restoreFromTrash(String id) async {
    await _db.collection('posts').doc(id).update({
      'isDeleted': false,
    });
  }

  Future<void> deletePostPermanently(String id) async {
    await _db.collection('posts').doc(id).delete();
  }

  Future<void> seedDefaultCategoriesIfNeeded() async {
    final snapshot = await _db.collection('categories').get();

    if (snapshot.docs.isNotEmpty) return;

    final batch = _db.batch();

    final defaultCategories = [
      {
        'name': '자기계발',
        'originalName': '자기계발',
        'color': 0xFFC2D6CF,
        'isMain': true,
        'sortOrder': 0,
      },
      {
        'name': '운동',
        'originalName': '운동',
        'color': 0xFFD8B4FE,
        'isMain': true,
        'sortOrder': 1,
      },
      {
        'name': '장소',
        'originalName': '장소',
        'color': 0xFFFBBF24,
        'isMain': true,
        'sortOrder': 2,
      },
      {
        'name': '쇼핑',
        'originalName': '쇼핑',
        'color': 0xFFF87171,
        'isMain': true,
        'sortOrder': 3,
      },
    ];

    for (final category in defaultCategories) {
      final ref = _db.collection('categories').doc();
      batch.set(ref, category);
    }

    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    await seedDefaultCategoriesIfNeeded();

    final snapshot =
        await _db.collection('categories').orderBy('sortOrder').get();

    final categories = snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data(),
      };
    }).toList();

    categories.sort((a, b) {
      final bool aMain = a['isMain'] ?? false;
      final bool bMain = b['isMain'] ?? false;

      if (aMain != bMain) {
        return aMain ? -1 : 1;
      }

      final int aOrder = (a['sortOrder'] ?? 0) as int;
      final int bOrder = (b['sortOrder'] ?? 0) as int;

      return aOrder.compareTo(bOrder);
    });

    return categories;
  }

  Future<List<String>> getMainCategoryNames() async {
    final categories = await getCategories();

    return categories
        .where((category) => (category['isMain'] ?? false) == true)
        .map((category) => (category['name'] ?? '').toString().trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }

  Future<void> addCategory({
    required String name,
    bool isMain = false,
    int? color,
  }) async {
    final snapshot = await _db.collection('categories').get();

    await _db.collection('categories').add({
      'name': name,
      'originalName': name,
      'color': color ?? 0xFF9ED0F6,
      'isMain': isMain,
      'sortOrder': snapshot.docs.length,
    });
  }

  Future<void> updateCategoryName({
    required String id,
    required String name,
  }) async {
    await _db.collection('categories').doc(id).update({
      'name': name,
    });
  }

  Future<void> deleteCategory(String id) async {
    await _db.collection('categories').doc(id).delete();
  }

  Future<void> updateCategoryMainStatus({
    required String id,
    required bool isMain,
  }) async {
    await _db.collection('categories').doc(id).update({
      'isMain': isMain,
    });
  }

  Future<void> updateCategorySortOrder({
    required String id,
    required int sortOrder,
  }) async {
    await _db.collection('categories').doc(id).update({
      'sortOrder': sortOrder,
    });
  }

  Future<void> reorderCategories(List<Map<String, dynamic>> categories) async {
    final batch = _db.batch();

    for (int i = 0; i < categories.length; i++) {
      final id = (categories[i]['id'] ?? '').toString();
      if (id.isEmpty) continue;

      final ref = _db.collection('categories').doc(id);

      batch.update(ref, {
        'sortOrder': i,
      });
    }

    await batch.commit();
  }

  Future<void> promoteCategoryToMain({
    required String id,
    required int sortOrder,
  }) async {
    await _db.collection('categories').doc(id).update({
      'isMain': true,
      'sortOrder': sortOrder,
    });
  }

  Future<void> demoteCategoryToEtc({
    required String id,
    required int sortOrder,
  }) async {
    await _db.collection('categories').doc(id).update({
      'isMain': false,
      'sortOrder': sortOrder,
    });
  }
}