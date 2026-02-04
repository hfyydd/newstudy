import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/routes/app_routes.dart';
import 'package:newstudyapp/services/http_service.dart';
import 'package:newstudyapp/services/toast_service.dart';
import 'package:newstudyapp/pages/home/home_controller.dart';

/// 从URL创建笔记控制器
class CreateNoteFromUrlController extends GetxController {
  final HttpService _httpService = HttpService();

  /// URL输入控制器
  final TextEditingController urlController = TextEditingController();

  /// 加载状态
  final RxBool isLoading = false.obs;

  /// 加载消息
  final RxString loadingMessage = '正在抓取网页内容...'.obs;

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

  /// 验证URL格式
  bool _validateUrl(String url) {
    if (url.trim().isEmpty) {
      ToastService.showError('请输入网页地址');
      return false;
    }

    // 简单的URL格式验证
    final urlPattern = RegExp(
      r'^https?://[^\s/$.?#].[^\s]*$',
      caseSensitive: false,
    );

    if (!urlPattern.hasMatch(url.trim())) {
      // 如果没有协议，尝试添加 https://
      final urlWithProtocol = 'https://${url.trim()}';
      if (urlPattern.hasMatch(urlWithProtocol)) {
        urlController.text = urlWithProtocol;
        return true;
      }
      ToastService.showError('请输入有效的网页地址');
      return false;
    }

    return true;
  }

  /// 创建笔记
  Future<void> createNote() async {
    final url = urlController.text.trim();

    // 验证URL
    if (!_validateUrl(url)) {
      return;
    }

    try {
      isLoading.value = true;
      loadingMessage.value = '正在抓取网页内容...';

      // 调用API创建笔记
      final response = await _httpService.createNoteFromUrl(
        url: url,
        maxTerms: 30,
      );

      // 清空输入框
      urlController.clear();

      // 刷新首页笔记列表
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        homeController.loadNotes(showLoading: false);
      }

      // 关闭当前页面
      Get.back();

      // 延迟一小段时间，确保 BottomSheet 完全关闭后再跳转
      await Future.delayed(const Duration(milliseconds: 200));

      // 跳转到笔记详情页
      Get.toNamed(
        AppRoutes.noteDetail,
        arguments: {
          'noteId': response.noteId,
        },
      );

      ToastService.showSuccess('笔记创建成功！');
    } catch (e) {
      // 错误已经在HttpService中通过ToastService显示
      debugPrint('创建笔记失败: $e');
    } finally {
      isLoading.value = false;
      loadingMessage.value = '正在抓取网页内容...';
    }
  }
}
