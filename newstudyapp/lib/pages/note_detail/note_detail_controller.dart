import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/services/http_service.dart';
import 'package:newstudyapp/config/api_config.dart';
import 'package:newstudyapp/routes/app_routes.dart';
import 'package:newstudyapp/pages/home/home_controller.dart';
import 'note_detail_state.dart';

/// 笔记详情页控制器
class NoteDetailController extends GetxController {
  final NoteDetailState state = NoteDetailState();
  final HttpService _httpService = HttpService();

  @override
  void onInit() {
    super.onInit();
    // 获取传入的参数
    final args = Get.arguments;
    if (args != null && args is Map<String, dynamic>) {
      // 优先检查是否有noteId（从笔记列表进入）
      final noteId = args['noteId'] as int?;
      if (noteId != null) {
        _loadNoteById(noteId);
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
      await _loadNoteById(response.noteId);

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
  Future<void> _loadNoteById(int noteId) async {
    state.isLoading.value = true;

    try {
      // 调用后端API获取笔记详情
      final response = await _httpService.get<Map<String, dynamic>>(
        ApiConfig.getNoteDetail(noteId),
      );

      // 解析响应数据
      final id = response['id'] as int;
      final title = response['title'] as String;
      final content = response['content'] as String?;
      final markdownContent = response['markdown_content'] as String?;
      final createdAtStr = response['created_at'] as String;
      final flashCardsRaw = response['flash_cards'] as List;

      // 解析闪词列表
      final terms = flashCardsRaw
          .map((fc) => fc['term'] as String)
          .toList();

      // 统计闪词状态
      int mastered = 0;
      int needsReview = 0;
      int needsImprove = 0;
      int notStarted = 0;

      for (final fc in flashCardsRaw) {
        final status = fc['status'] as String;
        switch (status) {
          case 'mastered':
            mastered++;
            break;
          case 'needs_review':
            needsReview++;
            break;
          case 'needs_improve':
            needsImprove++;
            break;
          case 'not_started':
            notStarted++;
            break;
        }
      }

      // 创建笔记模型
      state.note.value = NoteModel(
        id: id.toString(),
        title: title,
        content: content ?? '',
        markdownContent: markdownContent ?? '',
        createdAt: DateTime.tryParse(createdAtStr) ?? DateTime.now(),
        updatedAt: DateTime.now(),
        termCount: terms.length,
        terms: terms,
      );

      // 闪词内容已通过note.value设置，无需单独设置

      // 设置学习进度
      state.progress.value = FlashCardProgress(
        total: terms.length,
        mastered: mastered,
        needsReview: needsReview,
        needsImprove: needsImprove,
        notStarted: notStarted,
      );
    } catch (e) {
      Get.snackbar(
        '错误',
        '加载笔记失败：$e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      state.isLoading.value = false;
    }
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

  /// 继续学习（跳转到费曼学习页面）
  void continueLearning() {
    if (state.terms.isEmpty) {
      Get.snackbar(
        '提示',
        '暂无闪词可学习',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    // 跳转到费曼学习页面，传递闪词列表
    Get.toNamed(
      AppRoutes.feynmanLearning,
      arguments: {
        'terms': state.terms,
        'noteId': state.note.value?.id,
        'noteTitle': state.note.value?.title,
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
}
