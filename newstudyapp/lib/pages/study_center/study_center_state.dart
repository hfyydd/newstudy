import 'package:get/get.dart';
import 'package:newstudyapp/models/note_models.dart';

/// 学习中心页面状态
class StudyCenterState {
  // 当前显示的子页面
  final Rx<StudyCenterPageType> currentPage = StudyCenterPageType.main.obs;

  // 分类显示模式：true=词条分类，false=笔记分类
  final RxBool showCardCategory = true.obs;

  // 统计数据
  final RxInt todayReviewCount = 0.obs; // 今日复习数量
  final RxInt masteredCount = 0.obs; // 已掌握数量
  final RxInt needsReviewCount = 0.obs; // 需巩固数量（70-89分）
  final RxInt needsImproveCount = 0.obs; // 需改进数量
  final RxInt notMasteredCount = 0.obs; // 未掌握数量
  final RxInt totalCardsCount = 0.obs; // 全部词条数量

  // 加载状态
  final RxBool isLoading = false.obs;

  // 各页面的词条列表数据
  final RxList<FlashCardListItem> todayReviewCards = <FlashCardListItem>[].obs;
  final RxInt todayReviewCardsTotal = 0.obs;

  final RxList<FlashCardListItem> weakCards = <FlashCardListItem>[].obs;
  final RxInt weakCardsTotal = 0.obs;
  
  // 当前薄弱词条页面的状态筛选（null表示显示所有薄弱词条）
  final RxnString weakCardsStatusFilter = RxnString();

  final RxList<FlashCardListItem> masteredCards = <FlashCardListItem>[].obs;
  final RxInt masteredCardsTotal = 0.obs;

  final RxList<FlashCardListItem> allCards = <FlashCardListItem>[].obs;
  final RxInt allCardsTotal = 0.obs;

  final RxList<CardsByNoteItem> cardsByNote = <CardsByNoteItem>[].obs;
  final RxInt cardsByNoteTotal = 0.obs;
}

/// 学习中心页面类型
enum StudyCenterPageType {
  main, // 主页
  todayReview, // 今日复习
  weakCards, // 薄弱词条
  masteredCards, // 已掌握词条
  allCards, // 全部词条
  byNote, // 按笔记分类
}

