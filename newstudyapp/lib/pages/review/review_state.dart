import 'package:get/get.dart';
import 'package:newstudyapp/models/note_models.dart';

/// 学习中心筛选类型
enum ReviewFilterType {
  /// 今日复习
  today,
  /// 困难词条
  difficult,
  /// 已掌握
  mastered,
  /// 全部
  all,
}

/// 学习中心状态管理
class ReviewState {
  // 加载状态
  final isLoading = false.obs;
  final errorMessage = Rxn<String>();

  // 今日复习统计
  final todayReviewStatistics = Rxn<TodayReviewStatisticsResponse>();

  // 复习卡片列表
  final reviewCards = <ReviewFlashCardResponse>[].obs;

  // 当前筛选类型
  final currentFilter = ReviewFilterType.today.obs;

  // 按笔记分组的卡片
  final cardsByNote = <String, List<ReviewFlashCardResponse>>{}.obs;

  /// 获取当前筛选后的卡片列表
  List<ReviewFlashCardResponse> get filteredCards {
    switch (currentFilter.value) {
      case ReviewFilterType.today:
        // 今日复习：显示 NEEDS_REVIEW 和 NEEDS_IMPROVE 状态的卡片
        return reviewCards
            .where((card) =>
                card.status == 'NEEDS_REVIEW' || card.status == 'NEEDS_IMPROVE')
            .toList();
      case ReviewFilterType.difficult:
        // 困难词条：显示 NEEDS_REVIEW 和 NEEDS_IMPROVE 状态的卡片
        return reviewCards
            .where((card) =>
                card.status == 'NEEDS_REVIEW' || card.status == 'NEEDS_IMPROVE')
            .toList();
      case ReviewFilterType.mastered:
        // 已掌握：显示 MASTERED 状态的卡片
        return reviewCards
            .where((card) => card.status == 'MASTERED')
            .toList();
      case ReviewFilterType.all:
        // 全部：显示所有卡片
        return reviewCards.toList();
    }
  }

  /// 按笔记分组卡片
  void groupCardsByNote() {
    final grouped = <String, List<ReviewFlashCardResponse>>{};
    for (final card in filteredCards) {
      final noteId = card.noteId;
      if (!grouped.containsKey(noteId)) {
        grouped[noteId] = [];
      }
      grouped[noteId]!.add(card);
    }
    cardsByNote.value = grouped;
  }
}
