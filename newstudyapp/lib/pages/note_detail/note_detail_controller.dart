import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
          'topic': args['topic'] ?? (_l10n?.defaultNoteTopic ?? 'My Notes'),
          'defaultRole': args['defaultRole'] ?? '',
        };
      }

      // 优先检查是否有noteId（从笔记列表进入）
      final noteId = args['noteId'] as int?;
      if (noteId != null) {
        _loadNoteById(noteId);
        return;
      }
      
      // 检查是否有userInput（从自定义文本创建笔记）
      final userInput = args['userInput'] as String?;
      if (userInput != null && userInput.isNotEmpty) {
        state.userInput.value = userInput;
        // 调用API创建笔记（保存到数据库）
        _createNote(userInput);
        return;
      }
      
      // 检查是否有imageBase64（从图片创建笔记）
      final imageBase64 = args['imageBase64'] as String?;
      if (imageBase64 != null && imageBase64.isNotEmpty) {
        // 调用API创建笔记（保存到数据库）
        _createNoteFromImage(imageBase64);
        return;
      }
      
      // 检查是否有url（从网站创建笔记）
      final url = args['url'] as String?;
      if (url != null && url.isNotEmpty) {
        // 调用API创建笔记（保存到数据库）
        _createNoteFromUrl(url);
        return;
      }
      
      // 检查是否有youtubeUrl（从YouTube创建笔记）
      final youtubeUrl = args['youtubeUrl'] as String?;
      if (youtubeUrl != null && youtubeUrl.isNotEmpty) {
        // 调用API创建笔记（保存到数据库）
        _createNoteFromYoutube(youtubeUrl);
        return;
      }
      
      // 检查是否有bilibiliUrl（从Bilibili创建笔记）
      final bilibiliUrl = args['bilibiliUrl'] as String?;
      if (bilibiliUrl != null && bilibiliUrl.isNotEmpty) {
        // 调用API创建笔记（保存到数据库）
        _createNoteFromBilibili(bilibiliUrl);
        return;
      }
      
      // 检查是否有pdfFilePath（从PDF创建笔记）
      final pdfFilePath = args['pdfFilePath'] as String?;
      if (pdfFilePath != null && pdfFilePath.isNotEmpty) {
        // 调用API创建笔记（保存到数据库）
        _createNoteFromPdf(pdfFilePath);
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
    state.hasError.value = false;
    state.generatingStatus.value = _l10n?.analyzeContent ?? 'AI is analyzing content...';

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
        _l10n?.success ?? 'Success',
        _l10n?.noteCreated ?? 'Note created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4ECDC4),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );

    } catch (e) {
      // 标记创建失败，防止显示"此笔记尚未生成闪词卡片"页面
      state.hasError.value = true;
      // 创建失败，直接返回上一页
      Get.back();
      Get.snackbar(
        _l10n?.noteCreateFailed ?? 'Creation Failed',
        '${_l10n?.noteCreateFailed ?? "Note creation failed"}: $e',
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

  /// 从图片创建笔记（保存到数据库）
  Future<void> _createNoteFromImage(String imageBase64) async {
    state.isLoading.value = true;
    state.isGenerating.value = true;
    state.hasError.value = false;
    state.generatingStatus.value = _l10n?.recognizeImage ?? 'Recognizing image content...';

    try {
      // 调用后端API创建笔记（生成并保存到数据库）
      final response = await _httpService.createNoteFromImage(
        imageBase64: imageBase64,
        maxTerms: 30,
      );

      // 创建成功后，通过noteId加载笔记详情
      await _loadNoteById(response.noteId);

      // 刷新首页的笔记列表
      try {
        final homeController = Get.find<HomeController>();
        homeController.loadNotes(showLoading: false);
      } catch (e) {
        // 如果首页控制器不存在，忽略错误
        print('首页控制器未找到，跳过刷新: $e');
      }

      // 显示成功提示
      Get.snackbar(
        _l10n?.success ?? 'Success',
        _l10n?.noteCreated ?? 'Note created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4ECDC4),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );

    } catch (e) {
      // 标记创建失败，防止显示"此笔记尚未生成闪词卡片"页面
      state.hasError.value = true;
      // 创建失败，直接返回上一页
      Get.back();
      Get.snackbar(
        _l10n?.noteCreateFailed ?? 'Creation Failed',
        '${_l10n?.noteCreateFailed ?? "Note creation failed"}: $e',
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

  /// 从网站创建笔记（保存到数据库）
  Future<void> _createNoteFromUrl(String url) async {
    state.isLoading.value = true;
    state.isGenerating.value = true;
    state.hasError.value = false;
    state.generatingStatus.value = _l10n?.fetchWebContent ?? 'Fetching web page content...';

    try {
      // 调用后端API创建笔记（生成并保存到数据库）
      final response = await _httpService.createNoteFromUrl(
        url: url,
        maxTerms: 30,
      );

      // 创建成功后，通过noteId加载笔记详情
      await _loadNoteById(response.noteId);

      // 刷新首页的笔记列表
      try {
        final homeController = Get.find<HomeController>();
        homeController.loadNotes(showLoading: false);
      } catch (e) {
        // 如果首页控制器不存在，忽略错误
        print('首页控制器未找到，跳过刷新: $e');
      }

      // 显示成功提示
      Get.snackbar(
        _l10n?.success ?? 'Success',
        _l10n?.noteCreated ?? 'Note created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4ECDC4),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );

    } catch (e) {
      // 标记创建失败，防止显示"此笔记尚未生成闪词卡片"页面
      state.hasError.value = true;
      // 创建失败，直接返回上一页
      Get.back();
      Get.snackbar(
        _l10n?.noteCreateFailed ?? 'Creation Failed',
        '${_l10n?.noteCreateFailed ?? "Note creation failed"}: $e',
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

  /// 从YouTube创建笔记（保存到数据库）
  Future<void> _createNoteFromYoutube(String youtubeUrl) async {
    state.isLoading.value = true;
    state.isGenerating.value = true;
    state.hasError.value = false;
    state.generatingStatus.value = _l10n?.fetchVideoSubtitle ?? 'Fetching video subtitles...';

    try {
      // 调用后端API创建笔记（生成并保存到数据库）
      final response = await _httpService.createNoteFromYoutube(
        youtubeUrl: youtubeUrl,
        maxTerms: 30,
      );

      // 创建成功后，通过noteId加载笔记详情
      await _loadNoteById(response.noteId);

      // 刷新首页的笔记列表
      try {
        final homeController = Get.find<HomeController>();
        homeController.loadNotes(showLoading: false);
      } catch (e) {
        // 如果首页控制器不存在，忽略错误
        print('首页控制器未找到，跳过刷新: $e');
      }

      // 显示成功提示
      Get.snackbar(
        _l10n?.success ?? 'Success',
        _l10n?.noteCreated ?? 'Note created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4ECDC4),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );

    } catch (e) {
      // 标记创建失败，防止显示"此笔记尚未生成闪词卡片"页面
      state.hasError.value = true;
      // 创建失败，直接返回上一页
      Get.back();
      Get.snackbar(
        _l10n?.noteCreateFailed ?? 'Creation Failed',
        '${_l10n?.noteCreateFailed ?? "Note creation failed"}: $e',
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

  /// 从Bilibili创建笔记（保存到数据库）
  Future<void> _createNoteFromBilibili(String bilibiliUrl) async {
    state.isLoading.value = true;
    state.isGenerating.value = true;
    state.hasError.value = false;
    state.generatingStatus.value = _l10n?.fetchVideoSubtitle ?? 'Fetching video subtitles...';

    try {
      // 调用后端API创建笔记（生成并保存到数据库）
      final response = await _httpService.createNoteFromBilibili(
        bilibiliUrl: bilibiliUrl,
        maxTerms: 30,
      );

      // 创建成功后，通过noteId加载笔记详情
      await _loadNoteById(response.noteId);

      // 刷新首页的笔记列表
      try {
        final homeController = Get.find<HomeController>();
        homeController.loadNotes(showLoading: false);
      } catch (e) {
        // 如果首页控制器不存在，忽略错误
        print('首页控制器未找到，跳过刷新: $e');
      }

      // 显示成功提示
      Get.snackbar(
        _l10n?.success ?? 'Success',
        _l10n?.noteCreated ?? 'Note created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4ECDC4),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );

    } catch (e) {
      // 标记创建失败，防止显示"此笔记尚未生成闪词卡片"页面
      state.hasError.value = true;
      // 创建失败，直接返回上一页
      Get.back();
      Get.snackbar(
        _l10n?.noteCreateFailed ?? 'Creation Failed',
        '${_l10n?.noteCreateFailed ?? "Note creation failed"}: $e',
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

  /// 从PDF创建笔记（保存到数据库）
  Future<void> _createNoteFromPdf(String pdfFilePath) async {
    state.isLoading.value = true;
    state.isGenerating.value = true;
    state.hasError.value = false;
    state.generatingStatus.value = _l10n?.extractPdfContent ?? 'Extracting PDF content...';

    try {
      // 调用后端API创建笔记（生成并保存到数据库）
      final response = await _httpService.createNoteFromPdf(
        pdfFilePath: pdfFilePath,
        maxTerms: 30,
        maxPages: 50,
        maxChars: 50000,
      );

      // 创建成功后，通过noteId加载笔记详情
      await _loadNoteById(response.noteId);

      // 刷新首页的笔记列表
      try {
        final homeController = Get.find<HomeController>();
        homeController.loadNotes(showLoading: false);
      } catch (e) {
        // 如果首页控制器不存在，忽略错误
        print('首页控制器未找到，跳过刷新: $e');
      }

      // 显示成功提示
      Get.snackbar(
        _l10n?.success ?? 'Success',
        _l10n?.noteCreated ?? 'Note created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4ECDC4),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );

    } catch (e) {
      // 标记创建失败，防止显示"此笔记尚未生成闪词卡片"页面
      state.hasError.value = true;
      // 创建失败，直接返回上一页
      Get.back();
      Get.snackbar(
        _l10n?.noteCreateFailed ?? 'Creation Failed',
        '${_l10n?.noteCreateFailed ?? "Note creation failed"}: $e',
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
    state.generatingStatus.value = _l10n?.analyzeContent ?? 'AI is analyzing content...';

    try {
      // 调用后端API生成智能笔记
      final response = await _httpService.generateSmartNote(
        userInput: userInput,
        maxTerms: 30,
      );

      // 从内容中提取标题（取第一行或前20个字符）
      String title = _l10n?.smartNote ?? 'Smart Note';
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
        _l10n?.generationFailed ?? 'Generation Failed',
        _l10n?.generateSmartNoteFailed(e.toString()) ?? 'Failed to generate smart note: $e',
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
      final id = response['id'] as int;
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
        // 保存完整的闪词卡片数据（包含ID）
        _flashCardsData = flashCardsRaw.cast<Map<String, dynamic>>().toList();
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
        notMastered: notMastered,
        notStarted: notStarted,
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
        _l10n?.error ?? 'Error',
        _l10n?.loadNoteFailed(e.toString()) ?? 'Failed to load note: $e',
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
  Future<void> refreshNoteData(int noteId) async {
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
        _l10n?.success ?? 'Success',
        _l10n?.generatedFlashCardsCount(state.terms.length) ?? 'Generated ${state.terms.length} flash cards',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4ECDC4),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      Get.snackbar(
        _l10n?.error ?? 'Error',
        _l10n?.generateFlashCardsFailed(e.toString()) ?? 'Failed to generate flash cards: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      state.isGenerating.value = false;
      state.generatingStatus.value = '';
    }
  }

  /// 继续学习（跳转到费曼学习页面）
  void continueLearning() {
    if (state.terms.isEmpty || _flashCardsData.isEmpty) {
      Get.snackbar(
        _l10n?.hint ?? 'Hint',
        _l10n?.noFlashCardsToLearn ?? 'No flash cards to learn',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    // 获取笔记ID
    int? noteId;
    final noteIdStr = state.note.value?.id;
    if (noteIdStr != null) {
      noteId = int.tryParse(noteIdStr);
    }
    
    // 跳转到费曼学习页面，传递完整的闪词卡片数据（包含ID）和默认角色
    Get.toNamed(
      AppRoutes.feynmanLearning,
      arguments: {
        'flashCards': _flashCardsData,  // 完整的卡片数据，包含ID
        'terms': state.terms,  // 保留兼容
        'noteId': noteId,
        'topic': state.note.value?.title ?? (_l10n?.defaultNoteTopic ?? 'My Notes'),
        'defaultRole': state.defaultRole.value,  // 笔记的默认角色
      },
    );
  }
  
  /// Ask AI（与AI对话）
  void askAI() {
    Get.snackbar(
      _l10n?.hint ?? 'Hint',
      _l10n?.askAIInDev ?? 'Ask AI feature is under development',
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
        _l10n?.hint ?? 'Hint',
        _l10n?.noFlashCardsToLearn ?? 'No flash cards to learn',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // 根据状态筛选闪词
    final filteredCards = _flashCardsData.where((card) {
      final cardStatus = card['status'] as String?;
      return cardStatus == status;
    }).toList();

    if (filteredCards.isEmpty) {
      Get.snackbar(
        _l10n?.hint ?? 'Hint',
        _l10n?.noFlashCardsInStatus ?? 'No flash cards in this status',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // 获取笔记ID
    int? noteId;
    final noteIdStr = state.note.value?.id;
    if (noteIdStr != null) {
      noteId = int.tryParse(noteIdStr);
    }

    // 获取本地化状态名称
    final statusName = _getStatusName(status);

    // 跳转到费曼学习页面，传递筛选后的闪词
    Get.toNamed(
      AppRoutes.feynmanLearning,
      arguments: {
        'flashCards': filteredCards,
        'noteId': noteId,
        'topic': '${state.note.value?.title ?? (_l10n?.defaultNoteTopic ?? "My Notes")} - $statusName',
        'defaultRole': state.defaultRole.value,
      },
    );
  }
  
  /// 获取状态的本地化名称
  String _getStatusName(String status) {
    switch (status) {
      case 'MASTERED':
        return _l10n?.mastered ?? 'Mastered';
      case 'NEEDS_REVIEW':
        return _l10n?.needsConsolidation ?? 'Needs Consolidation';
      case 'NEEDS_IMPROVE':
        return _l10n?.needsImprovement ?? 'Needs Improvement';
      case 'NOT_MASTERED':
        return _l10n?.notMastered ?? 'Not Mastered';
      case 'NOT_STARTED':
        return _l10n?.notStarted ?? 'Not Started';
      default:
        return status;
    }
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
        'topic': _autoStartLearningArgs!['topic'] ?? state.note.value?.title ?? (_l10n?.defaultNoteTopic ?? 'My Notes'),
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
      title: Text(_l10n?.regenerateFlashCardsTitle ?? '⚠️ Regenerate Flash Cards'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_l10n?.regenerateFlashCardsInfo ?? 'This will:'),
          const SizedBox(height: 8),
          Text(_l10n?.regenerateKeepRecords ?? '✓ Keep all existing learning records'),
          Text(_l10n?.regenerateAddNew ?? '✓ Add newly extracted flash cards'),
          Text(_l10n?.regenerateDeduplicate ?? '✓ Auto-deduplicate and merge'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: Text(_l10n?.cancel ?? 'Cancel'),
        ),
        TextButton(
          onPressed: () => Get.back(result: true),
          child: Text(_l10n?.confirmRegenerate ?? 'Confirm Regeneration'),
        ),
      ],
    );
  }

  /// 查看学习记录
  void viewLearningRecords() {
    Get.snackbar(
      _l10n?.hint ?? 'Hint',
      _l10n?.learningRecordInDev ?? 'Learning record feature is under development',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// 格式化日期
  String formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return _l10n?.minutesAgo(diff.inMinutes) ?? '${diff.inMinutes} minutes ago';
      }
      return _l10n?.hoursAgo(diff.inHours) ?? '${diff.inHours} hours ago';
    } else if (diff.inDays == 1) {
      return _l10n?.yesterday ?? 'Yesterday';
    } else if (diff.inDays < 7) {
      return _l10n?.daysAgo(diff.inDays) ?? '${diff.inDays} days ago';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }
}
