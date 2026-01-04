import 'package:get/get.dart';
import 'package:newstudyapp/models/note_models.dart';

/// 首页状态
class HomeState {
  /// 笔记列表
  final RxList<NoteListItemResponse> notes = <NoteListItemResponse>[].obs;

  /// 是否正在加载
  final RxBool isLoading = false.obs;

  /// 错误信息
  final RxnString errorMessage = RxnString();

  /// 学习统计数据
  final Rx<LearningStatisticsResponse?> statistics = Rx<LearningStatisticsResponse?>(null);

  /// 是否正在加载统计数据
  final RxBool isLoadingStatistics = false.obs;

  /// 今日复习统计数据
  final Rx<TodayReviewStatisticsResponse?> todayReviewStatistics = Rx<TodayReviewStatisticsResponse?>(null);

  /// 是否正在加载今日复习统计数据
  final RxBool isLoadingTodayReview = false.obs;
}
