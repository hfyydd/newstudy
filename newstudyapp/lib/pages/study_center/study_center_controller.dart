import 'package:get/get.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:newstudyapp/pages/study_center/study_center_state.dart';
import 'package:newstudyapp/services/http_service.dart';
import 'package:newstudyapp/routes/app_routes.dart';
import 'package:newstudyapp/pages/note_detail/note_detail_page.dart';
import 'package:newstudyapp/pages/note_detail/note_detail_controller.dart';
import 'package:newstudyapp/pages/feynman_learning/feynman_learning_page.dart';
import 'package:newstudyapp/pages/feynman_learning/feynman_learning_controller.dart';
import 'package:newstudyapp/models/note_models.dart';

/// 学习中心控制器
class StudyCenterController extends GetxController {
  final StudyCenterState state = StudyCenterState();
  final HttpService _httpService = HttpService();
  
  /// 获取 AppLocalizations 实例
  AppLocalizations? get _l10n {
    try {
      final context = Get.context;
      if (context != null) {
        return AppLocalizations.of(context);
      }
    } catch (_) {}
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    _loadStatistics();
    // 预加载笔记分类数据（用于主页显示）
    _loadCardsByNote();
  }

  /// 加载统计数据
  /// [showLoading] - 是否显示加载状态（初次加载时为true，下拉刷新时为false）
  Future<void> _loadStatistics({bool showLoading = true}) async {
    if (showLoading) {
    state.isLoading.value = true;
    }
    try {
      final statistics = await _httpService.getStudyCenterStatistics();
      state.todayReviewCount.value = statistics.todayReviewCount;
      state.masteredCount.value = statistics.masteredCount;
      state.needsReviewCount.value = statistics.needsReviewCount;
      state.needsImproveCount.value = statistics.needsImproveCount;
      state.notMasteredCount.value = statistics.notMasteredCount;
      state.totalCardsCount.value = statistics.totalCardsCount;
    } catch (e) {
      Get.snackbar(
        _l10n?.error ?? 'Error',
        _l10n?.loadStatsFailed(e.toString()) ?? 'Failed to load stats: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      // 如果API调用失败，使用假数据作为降级方案
      _loadFallbackStatistics();
    } finally {
      if (showLoading) {
      state.isLoading.value = false;
      }
    }
  }

  /// 降级方案：使用假数据
  void _loadFallbackStatistics() {
    state.todayReviewCount.value = 8;
    state.masteredCount.value = 25;
    state.needsReviewCount.value = 12;
    state.needsImproveCount.value = 5;
    state.notMasteredCount.value = 3;
    state.totalCardsCount.value = 50;
  }

  /// 刷新统计数据（包括笔记分类数据）
  /// 下拉刷新时不显示全屏加载状态，由 RefreshIndicator 处理刷新动画
  Future<void> refreshStatistics() async {
    await Future.wait([
      _loadStatistics(showLoading: false),
      _loadCardsByNote(),
    ]);
  }

  /// 导航到指定页面
  void navigateToPage(StudyCenterPageType pageType, {String? statusFilter}) {
    state.currentPage.value = pageType;
    // 如果是薄弱闪词页面，设置状态筛选
    if (pageType == StudyCenterPageType.weakCards) {
      state.weakCardsStatusFilter.value = statusFilter;
    } else {
      state.weakCardsStatusFilter.value = null;
    }
    // 切换到新页面时，加载对应的数据
    _loadPageData(pageType);
  }

  /// 直接跳转到费曼学习页面（用于状态卡片点击）
  Future<void> navigateToFeynmanLearning({
    required StudyCenterPageType pageType,
    String? statusFilter,
    int initialLimit = 30, // 初始加载30条
  }) async {
    try {
      state.isLoading.value = true;

      // 根据页面类型加载第一页数据
      FlashCardListResponse response;
      String pageTitle;

      switch (pageType) {
        case StudyCenterPageType.todayReview:
          response = await _httpService.getTodayReviewCards(
            skip: 0,
            limit: initialLimit,
          );
          pageTitle = _l10n?.todayReviewTitle ?? 'Today\'s Review';
          break;
        case StudyCenterPageType.weakCards:
          response = await _httpService.getWeakCards(
            skip: 0,
            limit: initialLimit,
            status: statusFilter,
          );
          // 根据状态筛选设置标题
          if (statusFilter == 'NEEDS_REVIEW') {
            pageTitle = _l10n?.needsConsolidationCards ?? 'Needs Consolidation';
          } else if (statusFilter == 'NEEDS_IMPROVE') {
            pageTitle = _l10n?.needsImprovementCards ?? 'Needs Improvement';
          } else if (statusFilter == 'NOT_MASTERED') {
            pageTitle = _l10n?.notMasteredCards ?? 'Not Mastered';
          } else {
            pageTitle = _l10n?.weakFlashCards ?? 'Weak Flash Cards';
          }
          break;
        case StudyCenterPageType.masteredCards:
          response = await _httpService.getMasteredCards(
            skip: 0,
            limit: initialLimit,
          );
          pageTitle = _l10n?.masteredFlashCards ?? 'Mastered Flash Cards';
          break;
        case StudyCenterPageType.allCards:
          response = await _httpService.getAllCards(
            skip: 0,
            limit: initialLimit,
          );
          pageTitle = _l10n?.allFlashCards ?? 'All Flash Cards';
          break;
        default:
          // 其他类型不支持直接跳转
          return;
      }

      // 转换为费曼学习页面需要的格式
      final flashCards = response.cards
          .map((card) => {
                'id': card.id,
                'term': card.term,
                'status': card.status,
                'review_count': card.reviewCount,
                // FlashCardListItem 可能没有这些字段，使用可选值
                'last_reviewed_at': null,
                'mastered_at': null,
              })
          .toList();

      if (flashCards.isEmpty) {
        Get.snackbar(
          _l10n?.hint ?? 'Hint',
          _l10n?.noFlashCardsToLearn ?? 'No flash cards to learn',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      // 跳转到费曼学习页面，传递分页信息
      Get.to(
        () {
          // 确保控制器被注册
          if (!Get.isRegistered<FeynmanLearningController>()) {
            Get.lazyPut<FeynmanLearningController>(
                () => FeynmanLearningController());
          }
          return const FeynmanLearningPage();
        },
        arguments: {
          'flashCards': flashCards,
          'topic': pageTitle,
          'pageType': pageType.name, // 保存页面类型，用于后续加载更多
          'statusFilter': statusFilter, // 保存状态筛选，用于后续加载更多
          'currentSkip': initialLimit, // 当前已加载的数量
          'total': response.total, // 总数
        },
        transition: Transition.noTransition, // 无动画跳转
      );
    } catch (e) {
      Get.snackbar(
        _l10n?.error ?? 'Error',
        _l10n?.loadFlashCardsFailed(e.toString()) ?? 'Failed to load flash cards: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } finally {
      state.isLoading.value = false;
    }
  }

  /// 返回主页
  void backToMain() {
    state.currentPage.value = StudyCenterPageType.main;
    // 返回主页时刷新统计数据
    refreshStatistics();
  }

  /// 切换分类显示模式
  void toggleCategory() {
    state.showCardCategory.value = !state.showCardCategory.value;
  }

  /// 加载页面数据
  Future<void> _loadPageData(StudyCenterPageType pageType) async {
    state.isLoading.value = true;
    try {
      switch (pageType) {
        case StudyCenterPageType.todayReview:
          await _loadTodayReviewCards();
          break;
        case StudyCenterPageType.weakCards:
          await _loadWeakCards();
          break;
        case StudyCenterPageType.masteredCards:
          await _loadMasteredCards();
          break;
        case StudyCenterPageType.allCards:
          await _loadAllCards();
          break;
        case StudyCenterPageType.byNote:
          await _loadCardsByNote();
          break;
        case StudyCenterPageType.main:
          // 主页不需要加载列表数据
          break;
      }
    } catch (e) {
      Get.snackbar(
        _l10n?.error ?? 'Error',
        _l10n?.loadDataFailed(e.toString()) ?? 'Failed to load data: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } finally {
      state.isLoading.value = false;
    }
  }

  /// 加载今日复习闪词列表
  Future<void> _loadTodayReviewCards() async {
    try {
      final response = await _httpService.getTodayReviewCards(
        skip: 0,
        limit: 100,
      );
      state.todayReviewCards.value = response.cards;
      state.todayReviewCardsTotal.value = response.total;
    } catch (e) {
      // 如果API调用失败，使用空列表
      state.todayReviewCards.value = [];
      state.todayReviewCardsTotal.value = 0;
    }
  }

  /// 加载薄弱闪词列表
  Future<void> _loadWeakCards() async {
    try {
      final response = await _httpService.getWeakCards(
        skip: 0,
        limit: 100,
        status: state.weakCardsStatusFilter.value, // 根据状态筛选（可能为null）
      );
      state.weakCards.value = response.cards;
      state.weakCardsTotal.value = response.total;
    } catch (e) {
      state.weakCards.value = [];
      state.weakCardsTotal.value = 0;
    }
  }

  /// 加载已掌握闪词列表
  Future<void> _loadMasteredCards() async {
    try {
      final response = await _httpService.getMasteredCards(
        skip: 0,
        limit: 100,
      );
      state.masteredCards.value = response.cards;
      state.masteredCardsTotal.value = response.total;
    } catch (e) {
      state.masteredCards.value = [];
      state.masteredCardsTotal.value = 0;
    }
  }

  /// 加载全部闪词列表
  Future<void> _loadAllCards() async {
    try {
      final response = await _httpService.getAllCards(
        skip: 0,
        limit: 100,
      );
      state.allCards.value = response.cards;
      state.allCardsTotal.value = response.total;
    } catch (e) {
      state.allCards.value = [];
      state.allCardsTotal.value = 0;
    }
  }

  /// 加载按笔记分类的闪词列表
  Future<void> _loadCardsByNote() async {
    try {
      final response = await _httpService.getCardsByNote(
        skip: 0,
        limit: 100,
      );
      state.cardsByNote.value = response.notes;
      state.cardsByNoteTotal.value = response.total;
    } catch (e) {
      state.cardsByNote.value = [];
      state.cardsByNoteTotal.value = 0;
    }
  }

  /// 刷新当前页面数据
  Future<void> refreshCurrentPage() async {
    await _loadPageData(state.currentPage.value);
  }

  /// 处理笔记卡片点击
  /// 智能判断：如果有闪词则直接进入学习，如果没有闪词则进入详情页
  Future<void> handleNoteCardTap(
      int noteId, String noteTitle, int totalCount) async {
    // 如果笔记没有闪词，跳转到笔记详情页让用户生成闪词卡片
    if (totalCount == 0) {
      Get.toNamed(
        AppRoutes.noteDetail,
        arguments: {
          'noteId': noteId,
        },
      );
      return;
    }

    // 如果笔记有闪词，先获取笔记详情（包含闪词卡片数据），然后直接进入学习
    try {
      state.isLoading.value = true;
      final noteDetail = await _httpService.getNoteDetail(noteId);

      final flashCardsRaw = noteDetail['flash_cards'] as List? ?? [];
      if (flashCardsRaw.isEmpty) {
        // 如果获取不到闪词卡片，跳转到详情页
        Get.toNamed(
          AppRoutes.noteDetail,
          arguments: {
            'noteId': noteId,
          },
        );
        return;
      }

      // 转换为费曼学习页面需要的格式
      final flashCards = flashCardsRaw
          .whereType<Map<String, dynamic>>()
          .where((card) => card['term'] != null && card['id'] != null)
          .toList();

      final defaultRole = noteDetail['default_role'] as String? ?? '';

      // 先跳转到笔记详情页（在路由栈中保留），然后自动跳转到费曼学习页面
      // 路由栈：MainPage(学习中心tab) → 笔记详情页 → 费曼学习页面
      // 返回时：费曼学习页面 → 笔记详情页 → MainPage(学习中心tab)
      // 使用无动画跳转，避免闪动
      Get.to(
        () {
          // 确保控制器被注册
          if (!Get.isRegistered<NoteDetailController>()) {
            Get.lazyPut<NoteDetailController>(() => NoteDetailController());
          }
          return const NoteDetailPage();
        },
        arguments: {
          'noteId': noteId,
          'autoStartLearning': true, // 标记需要自动开始学习
          'flashCards': flashCards, // 传递闪词卡片数据
          'defaultRole': defaultRole, // 传递默认角色
          'topic': noteTitle, // 传递笔记标题作为费曼学习页面的标题
        },
        transition: Transition.noTransition, // 无动画跳转
      );
    } catch (e) {
      // 如果获取失败，降级到笔记详情页
      Get.snackbar(
        _l10n?.hint ?? 'Hint',
        _l10n?.loadNoteDataFailed ?? 'Failed to load note data, redirected to detail page',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      Get.toNamed(
        AppRoutes.noteDetail,
        arguments: {
          'noteId': noteId,
        },
      );
    } finally {
      state.isLoading.value = false;
    }
  }
}
