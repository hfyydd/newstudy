import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/services/http_service.dart';
import 'package:newstudyapp/config/api_config.dart';
import 'package:newstudyapp/routes/app_routes.dart';
import 'package:newstudyapp/pages/home/home_controller.dart';
import 'package:newstudyapp/pages/feynman_learning/feynman_learning_page.dart';
import 'package:newstudyapp/pages/feynman_learning/feynman_learning_controller.dart';
import 'note_detail_state.dart';

/// 笔记详情页控制器
class NoteDetailController extends GetxController {
  final NoteDetailState state = NoteDetailState();
  final HttpService _httpService = HttpService();
  
  /// 保存完整的闪词卡片数据（包含ID）
  List<Map<String, dynamic>> _flashCardsData = [];

  /// 是否自动开始学习（从学习中心跳转时使用）- 使用可观察变量，确保返回时页面能重新构建
  final RxBool _autoStartLearning = false.obs;
  Map<String, dynamic>? _autoStartLearningArgs;

  /// 是否从学习中心跳转过来
  bool _fromStudyCenter = false;

  @override
  void onInit() {
    super.onInit();
    // 获取传入的参数
    final args = Get.arguments;
    if (args != null && args is Map<String, dynamic>) {
      // 检查是否需要自动开始学习
      _autoStartLearning.value = args['autoStartLearning'] as bool? ?? false;
      if (_autoStartLearning.value) {
        // 标记从学习中心跳转过来
        _fromStudyCenter = true;
        // 保存自动学习所需的参数
        _autoStartLearningArgs = {
          'flashCards': args['flashCards'],
          'noteId': args['noteId'],
          'topic': args['topic'] ?? '我的笔记',
          'defaultRole': args['defaultRole'] ?? '',
        };
      }

      // 优先检查是否有noteId（从笔记列表进入）
      final noteIdArg = args['noteId'];
      if (noteIdArg != null) {
        _loadNoteById(noteIdArg.toString());
        return;
      }
      
      // 检查是否有userInput（创建新笔记）
      final userInput = args['userInput'] as String?;
      if (userInput != null && userInput.isNotEmpty) {
        state.userInput.value = userInput;
        // 调用API创建笔记（保存到数据库）
        _createNote(userInput);
        return;
      }
    }
    
    // 如果没有传入任何参数，显示空状态
    state.isLoading.value = false;
  }

  /// 创建笔记（保存到数据库）
  Future<void> _createNote(String userInput) async {
    state.isLoading.value = true;
    state.isGenerating.value = true;
    state.generatingStatus.value = 'AI 正在分析内容...';

    try {
      // 调用后端API创建笔记（生成并保存到数据库）
      final response = await _httpService.createNote(
        userInput: userInput,
        maxTerms: 30,
      );

      // 创建成功后，通过noteId加载笔记详情
      await _loadNoteById(response.noteId.toString());

      // 刷新首页的笔记列表
      try {
        final homeController = Get.find<HomeController>();
        homeController.loadNotes();
      } catch (e) {
        // 如果首页控制器不存在，忽略错误
        print('首页控制器未找到，跳过刷新: $e');
      }

      // 显示成功提示
      Get.snackbar(
        '成功',
        '笔记创建成功',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4ECDC4),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );

    } catch (e) {
      Get.snackbar(
        '创建失败',
        '笔记创建失败：$e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFF6B6B),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      state.isLoading.value = false;
      state.isGenerating.value = false;
      state.generatingStatus.value = '';
    }
  }

  /// 调用AI生成智能笔记（不保存，仅预览）
  Future<void> _generateSmartNote(String userInput) async {
    state.isLoading.value = true;
    state.isGenerating.value = true;
    state.generatingStatus.value = 'AI 正在分析内容...';

    try {
      // 调用后端API生成智能笔记
      final response = await _httpService.generateSmartNote(
        userInput: userInput,
        maxTerms: 30,
      );

      // 从内容中提取标题（取第一行或前20个字符）
      String title = '智能笔记';
      final lines = response.noteContent.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty) {
          // 移除Markdown标题符号
          title = trimmed.replaceAll(RegExp(r'^#+\s*'), '');
          if (title.length > 20) {
            title = '${title.substring(0, 20)}...';
          }
          break;
        }
      }

      // 创建笔记模型
      state.note.value = NoteModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: userInput,
        markdownContent: response.noteContent,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        termCount: response.terms.length,
        terms: response.terms,
      );

      // 初始化学习进度
      state.progress.value = FlashCardProgress(
        total: response.terms.length,
        mastered: 0,
        needsReview: 0,
        needsImprove: 0,
        notMastered: 0,
        notStarted: response.terms.length,
      );

    } catch (e) {
      Get.snackbar(
        '生成失败',
        '智能笔记生成失败：$e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFF6B6B),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      state.isLoading.value = false;
      state.isGenerating.value = false;
      state.generatingStatus.value = '';
    }
  }

  /// 根据noteId加载笔记详情
  Future<void> _loadNoteById(String noteId) async {
    // 如果是自动学习模式，不显示加载状态，实现无感跳转
    if (!_autoStartLearning.value) {
      state.isLoading.value = true;
    }

    try {
      // 调用后端API获取笔记详情
      final response = await _httpService.get<Map<String, dynamic>>(
        ApiConfig.getNoteDetail(noteId),
      );

      // 解析响应数据
      final id = response['id'];
      final title = response['title'] as String;
      final content = response['content'] as String?;
      final markdownContent = response['markdown_content'] as String?;
      final createdAtStr = response['created_at'] as String;
      final defaultRole = response['default_role'] as String?;
      final flashCardsRaw = response['flash_cards'] as List;
      
      // 保存默认角色
      state.defaultRole.value = defaultRole ?? '';

      // 如果是从学习中心跳转过来的，使用传入的闪词卡片数据
      // 否则使用从API获取的数据
      if (_autoStartLearning.value && _autoStartLearningArgs != null) {
        final flashCardsFromArgs = _autoStartLearningArgs!['flashCards'] as List?;
        if (flashCardsFromArgs != null && flashCardsFromArgs.isNotEmpty) {
          _flashCardsData = flashCardsFromArgs
              .whereType<Map<String, dynamic>>()
              .where((card) => card['term'] != null && card['id'] != null)
              .toList();
        } else {
          _flashCardsData = flashCardsRaw.cast<Map<String, dynamic>>().toList();
        }
      } else {
        // 懒加载优化：如果已有闪词卡片数据且后端返回有闪词，保留现有数据
        // 只有在数据为空或第一次加载时，才使用后端数据
        final hasCardsFromBackend = flashCardsRaw.isNotEmpty;

        if (!hasCardsFromBackend && _flashCardsData.isNotEmpty) {
          // 保留现有的闪词卡片数据
          debugPrint('[NoteDetailController] 保留现有闪词卡片数据，数量：${_flashCardsData.length}');
        } else {
          // 使用后端数据
          _flashCardsData = flashCardsRaw.cast<Map<String, dynamic>>().toList();
        }
      }
      
      // 解析闪词列表
      final terms = flashCardsRaw
          .map((fc) => fc['term'] as String)
          .toList();

      // 统计闪词状态（后端返回的状态可能是大写或小写，统一转换为大写比较）
      int mastered = 0;
      int needsReview = 0;
      int needsImprove = 0;
      int notMastered = 0;
      int notStarted = 0;

      for (final fc in flashCardsRaw) {
        final statusRaw = fc['status'] as String? ?? 'NOT_STARTED';
        final status = statusRaw.toUpperCase(); // 统一转换为大写比较
        switch (status) {
          case 'MASTERED':
            mastered++;
            break;
          case 'NEEDS_REVIEW':
            needsReview++;
            break;
          case 'NEEDS_IMPROVE':
            needsImprove++;
            break;
          case 'NOT_MASTERED':
            notMastered++;
            break;
          case 'NOT_STARTED':
            notStarted++;
            break;
          default:
            // 如果状态不匹配，默认为未开始
            debugPrint('[NoteDetailController] 未知状态: $statusRaw');
            notStarted++;
            break;
        }
      }
      
      final total = mastered + needsReview + needsImprove + notMastered + notStarted;
      debugPrint('[NoteDetailController] 进度统计: 总数=$total, 已掌握=$mastered, 需巩固=$needsReview, 需改进=$needsImprove, 未掌握=$notMastered, 未开始=$notStarted');

      // 创建笔记模型（懒加载：默认不包含闪词列表）
      state.note.value = NoteModel(
        id: id.toString(),
        title: title,
        content: content ?? '',
        markdownContent: markdownContent ?? '',
        createdAt: DateTime.tryParse(createdAtStr) ?? DateTime.now(),
        updatedAt: DateTime.now(),
        termCount: total, // 使用统计的总数
        terms: [], // 懒加载：初始为空
      );

      // 标记闪词卡片未加载
      state.flashCardsLoaded.value = false;

      // 闪词内容已通过note.value设置，无需单独设置

      // 设置学习进度
      state.progress.value = FlashCardProgress(
        total: 0, // 懒加载：初始为0
        mastered: 0,
        needsReview: 0,
        needsImprove: 0,
        notMastered: 0,
        notStarted: 0,
      );

      // 设置加载完成（数据已加载，即使自动学习模式也要设置，以便返回时能正常显示）
      state.isLoading.value = false;

      // 如果需要自动开始学习，立即跳转（使用下一帧，确保路由替换完成）
      if (_autoStartLearning.value && _autoStartLearningArgs != null) {
        // 使用下一帧确保路由替换完成后再跳转，实现完全无感
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startAutoLearning();
        });
        return;
      }
    } catch (e) {
      Get.snackbar(
        '错误',
        '加载笔记失败：$e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      // 确保加载状态被设置（如果上面没有设置）
      if (state.isLoading.value) {
        state.isLoading.value = false;
      }
    }
  }

  /// 刷新笔记数据（从服务器重新加载）
  Future<void> refreshNoteData(String noteId) async {
    debugPrint('[NoteDetailController] 开始刷新笔记数据，noteId: $noteId');
    await _loadNoteById(noteId);
    debugPrint('[NoteDetailController] 笔记数据刷新完成');
  }

  /// 生成闪词卡片
  Future<void> generateFlashCards() async {
    state.isGenerating.value = true;
    state.generatingStatus.value = '正在提取核心概念...';

    try {
      // 重新调用AI生成
      if (state.userInput.value.isNotEmpty) {
        await _generateSmartNote(state.userInput.value);
      } else if (state.note.value != null) {
        await _generateSmartNote(state.note.value!.content);
      }

      Get.snackbar(
        '成功',
        '已生成 ${state.terms.length} 个闪词卡片',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4ECDC4),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      Get.snackbar(
        '错误',
        '生成闪词失败：$e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      state.isGenerating.value = false;
      state.generatingStatus.value = '';
    }
  }

  /// 加载闪词卡片（懒加载）
  Future<void> loadFlashCards() async {
    final note = state.note.value;
    if (note == null) return;

    try {
      state.isLoading.value = true;
      state.generatingStatus.value = '加载闪词...';

      // 调用后端API获取闪词卡片列表
      final response = await _httpService.getFlashCards(note.id);

      // 保存闪词数据
      _flashCardsData = response.cards.map((card) => {
        'id': card.id,
        'term': card.term,
        'status': card.status,
        'review_count': card.reviewCount,
      }).toList();

      // 解析闪词列表
      final terms = response.cards.map((card) => card.term).toList();

      // 更新笔记模型
      state.note.value = note.copyWith(
        termCount: terms.length,
        terms: terms,
      );

      // 标记已加载
      state.flashCardsLoaded.value = true;

      // 统计闪词状态
      int mastered = 0;
      int needsReview = 0;
      int needsImprove = 0;
      int notMastered = 0;
      int notStarted = 0;

      for (final card in response.cards) {
        switch (card.status.toUpperCase()) {
          case 'MASTERED':
            mastered++;
            break;
          case 'NEEDS_REVIEW':
            needsReview++;
            break;
          case 'NEEDS_IMPROVE':
            needsImprove++;
            break;
          case 'NOT_MASTERED':
            notMastered++;
            break;
          default:
            notStarted++;
            break;
        }
      }

      // 更新进度
      state.progress.value = FlashCardProgress(
        total: terms.length,
        mastered: mastered,
        needsReview: needsReview,
        needsImprove: needsImprove,
        notMastered: notMastered,
        notStarted: notStarted,
      );

      debugPrint('[NoteDetailController] 闪词已加载，共${terms.length}个');
    } catch (e) {
      Get.snackbar(
        '错误',
        '加载闪词失败：$e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFF6B6B),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } finally {
      state.isLoading.value = false;
      state.generatingStatus.value = '';
    }
  }

  /// 继续学习（跳转到费曼学习页面）
  void continueLearning() {
    // 修改：只检查闪词卡片数据是否已加载，允许懒加载后学习
    if (_flashCardsData.isEmpty) {
      Get.snackbar(
        '提示',
        '请先加载闪词卡片',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // 获取笔记ID（已经是字符串类型）
    final noteId = state.note.value?.id;

    // 跳转到费曼学习页面，传递完整的闪词卡片数据（包含ID）和默认角色
    Get.toNamed(
      AppRoutes.feynmanLearning,
      arguments: {
        'flashCards': _flashCardsData,  // 完整的卡片数据，包含ID
        'terms': state.terms,  // 保留兼容
        'noteId': noteId,
        'topic': state.note.value?.title ?? '我的笔记',
        'defaultRole': state.defaultRole.value,  // 笔记的默认角色
      },
    );
  }
  
  /// Ask AI（与AI对话）
  void askAI() {
    Get.snackbar(
      '提示',
      'Ask AI 功能开发中',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF5B8DEF),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }
  
  /// 费曼学习
  void startFeynmanLearning() {
    continueLearning();
  }

  /// 根据状态开始学习（点击统计项时调用）
  void startLearningByStatus(String status) {
    if (_flashCardsData.isEmpty) {
      Get.snackbar(
        '提示',
        '暂无闪词可学习',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // 根据状态筛选词条
    final filteredCards = _flashCardsData.where((card) {
      final cardStatus = card['status'] as String?;
      return cardStatus == status;
    }).toList();

    if (filteredCards.isEmpty) {
      Get.snackbar(
        '提示',
        '该状态下暂无词条可学习',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // 获取笔记ID
    final noteId = state.note.value?.id;

    // 状态名称映射
    final statusNames = {
      'MASTERED': '已掌握',
      'NEEDS_REVIEW': '需巩固',
      'NEEDS_IMPROVE': '需改进',
      'NOT_MASTERED': '未掌握',
      'NOT_STARTED': '未学习',
    };
    final statusName = statusNames[status] ?? status;

    // 跳转到费曼学习页面，传递筛选后的词条
    Get.toNamed(
      AppRoutes.feynmanLearning,
      arguments: {
        'flashCards': filteredCards,
        'noteId': noteId,
        'topic': '${state.note.value?.title ?? "我的笔记"} - $statusName',
        'defaultRole': state.defaultRole.value,
      },
    );
  }

  /// 检查是否是自动开始学习模式（用于页面显示判断）
  /// 返回可观察变量，供 Obx 使用
  RxBool get autoStartLearning => _autoStartLearning;

  /// 检查是否从学习中心跳转过来
  bool isFromStudyCenter() {
    return _fromStudyCenter;
  }

  /// 自动开始学习（从学习中心跳转时调用）
  void _startAutoLearning() {
    if (_autoStartLearningArgs == null) {
      return;
    }

    final flashCards = _autoStartLearningArgs!['flashCards'] as List?;
    if (flashCards == null || flashCards.isEmpty) {
      return;
    }

    // 转换为费曼学习页面需要的格式
    final flashCardsFormatted = flashCards
        .whereType<Map<String, dynamic>>()
        .where((card) => card['term'] != null && card['id'] != null)
        .toList();

    if (flashCardsFormatted.isEmpty) {
      return;
    }

    // 跳转到费曼学习页面（使用无动画跳转，避免闪动）
    Get.to(
      () {
        // 确保控制器被注册
        if (!Get.isRegistered<FeynmanLearningController>()) {
          Get.lazyPut<FeynmanLearningController>(() => FeynmanLearningController());
        }
        return const FeynmanLearningPage();
      },
      arguments: {
        'flashCards': flashCardsFormatted,
        'noteId': _autoStartLearningArgs!['noteId'],
        'topic': _autoStartLearningArgs!['topic'] ?? state.note.value?.title ?? '我的笔记',
        'defaultRole': _autoStartLearningArgs!['defaultRole'] ?? state.defaultRole.value,
      },
      transition: Transition.noTransition, // 无动画跳转
    );

    // 清除自动学习标记（使用可观察变量，会自动触发页面重新构建）
    _autoStartLearning.value = false;
    _autoStartLearningArgs = null;
  }

  /// 重新生成闪词
  Future<void> regenerateFlashCards() async {
    final confirmed = await Get.dialog<bool>(
      _buildConfirmDialog(),
    );

    if (confirmed == true) {
      await generateFlashCards();
    }
  }

  /// 构建确认对话框
  Widget _buildConfirmDialog() {
    return AlertDialog(
      title: const Text('⚠️ 重新生成闪词卡片'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('将会：'),
          SizedBox(height: 8),
          Text('✓ 保留所有已有词条的学习记录'),
          Text('✓ 添加新提取的词条到学习列表'),
          Text('✓ 新旧词条自动去重合并'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Get.back(result: true),
          child: const Text('确认重新生成'),
        ),
      ],
    );
  }

  /// 查看学习记录
  void viewLearningRecords() {
    Get.snackbar(
      '提示',
      '学习记录功能开发中',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// 格式化日期
  String formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} 分钟前';
      }
      return '${diff.inHours} 小时前';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  /// 删除笔记
  Future<void> deleteNote() async {
    final noteId = state.note.value?.id;
    final noteTitle = state.noteTitle;

    if (noteId == null) {
      Get.snackbar(
        '错误',
        '无法获取笔记ID',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // 显示确认对话框
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('删除笔记'),
        content: Text('确定要删除「$noteTitle」吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    // 如果用户取消，直接返回
    if (confirmed != true) return;

    try {
      // 调用删除接口
      await _httpService.deleteNote(noteId);

      // 显示成功提示
      Get.snackbar(
        '成功',
        '笔记已删除',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // 刷新首页数据
      try {
        final homeController = Get.find<HomeController>();
        await homeController.loadNotes();
        await homeController.loadHomeStatistics();
      } catch (e) {
        // 如果找不到 HomeController，忽略错误
        debugPrint('无法刷新首页数据: $e');
      }

      // 返回首页
      Get.offAllNamed(AppRoutes.main);
    } catch (e) {
      debugPrint('删除笔记失败: $e');
      Get.snackbar(
        '错误',
        '删除笔记失败：$e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
