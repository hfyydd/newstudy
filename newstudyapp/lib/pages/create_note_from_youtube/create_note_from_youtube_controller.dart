import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/routes/app_routes.dart';
import 'package:newstudyapp/services/toast_service.dart';

/// 从YouTube创建笔记控制器
class CreateNoteFromYoutubeController extends GetxController {

  /// URL输入控制器
  final TextEditingController urlController = TextEditingController();

  /// 加载状态
  final RxBool isLoading = false.obs;

  /// 加载消息
  final RxString loadingMessage = '正在获取视频字幕...'.obs;

  @override
  void onInit() {
    super.onInit();
    // 每次打开页面时清空输入框
    _clearInput();
  }

  @override
  void onReady() {
    super.onReady();
    // 确保输入框被清空（onReady 在页面构建完成后调用）
    _clearInput();
  }

  /// 清空输入框
  void _clearInput() {
    if (urlController.text.isNotEmpty) {
      urlController.clear();
    }
  }

  @override
  void onClose() {
    urlController.dispose();
    super.onClose();
  }

  /// 验证YouTube URL格式
  bool _validateUrl(String url) {
    if (url.trim().isEmpty) {
      ToastService.showError('请输入YouTube视频地址');
      return false;
    }

    // YouTube URL格式验证
    final youtubePatterns = [
      // 标准格式：https://www.youtube.com/watch?v=VIDEO_ID
      RegExp(r'^https?://(www\.)?youtube\.com/watch\?v=[\w-]+', caseSensitive: false),
      // 短链接：https://youtu.be/VIDEO_ID
      RegExp(r'^https?://youtu\.be/[\w-]+', caseSensitive: false),
      // 嵌入格式：https://www.youtube.com/embed/VIDEO_ID
      RegExp(r'^https?://(www\.)?youtube\.com/embed/[\w-]+', caseSensitive: false),
    ];

    for (final pattern in youtubePatterns) {
      if (pattern.hasMatch(url.trim())) {
        return true;
      }
    }

    ToastService.showError('请输入有效的YouTube视频地址');
    return false;
  }

  /// 创建笔记（跳转到详情页，由详情页负责创建）
  Future<void> createNote() async {
    final url = urlController.text.trim();

    // 验证URL
    if (!_validateUrl(url)) {
      return;
    }

    try {
      // 清空输入框
      urlController.clear();

      // 关闭当前页面
      Get.back();

      // 延迟一小段时间，确保 BottomSheet 完全关闭后再跳转
      await Future.delayed(const Duration(milliseconds: 200));

      // 跳转到笔记详情页，传递 youtubeUrl，让详情页负责创建笔记并显示 Loading
      Get.toNamed(
        AppRoutes.noteDetail,
        arguments: {
          'youtubeUrl': url,
        },
      );
    } catch (e) {
      ToastService.showError('处理失败: $e');
      debugPrint('处理失败: $e');
    }
  }
}
