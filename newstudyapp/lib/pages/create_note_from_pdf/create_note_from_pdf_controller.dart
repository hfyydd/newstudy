import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:newstudyapp/routes/app_routes.dart';
import 'package:newstudyapp/services/toast_service.dart';

/// 从PDF创建笔记控制器
class CreateNoteFromPdfController extends GetxController {

  /// 选中的PDF文件
  final Rx<PlatformFile?> selectedPdfFile = Rx<PlatformFile?>(null);

  /// 加载状态
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // 每次打开页面时清空选中的文件
    selectedPdfFile.value = null;
  }

  @override
  void onReady() {
    super.onReady();
    // 确保清空选中的文件
    selectedPdfFile.value = null;
  }

  /// 选择PDF文件
  Future<void> pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: false,
      );

      if (result == null || result.files.isEmpty) {
        // 用户取消了选择
        debugPrint('用户取消了PDF文件选择');
        return;
      }

      final file = result.files.first;
      if (file.path == null) {
        ToastService.showError('无法获取文件路径，请重试');
        return;
      }

      // 检查文件大小（限制为 50MB）
      if (file.size > 50 * 1024 * 1024) {
        ToastService.showError('PDF文件过大，请选择小于 50MB 的文件');
        return;
      }

      selectedPdfFile.value = file;
      debugPrint('已选择PDF文件: ${file.name}, 大小: ${file.size} bytes');
    } catch (e) {
      debugPrint('选择PDF文件失败: $e');
      ToastService.showError('选择PDF文件失败: $e');
    }
  }

  /// 创建笔记（跳转到详情页，由详情页负责创建）
  Future<void> createNote() async {
    if (selectedPdfFile.value == null) {
      ToastService.showError('请先选择PDF文件');
      return;
    }

    final filePath = selectedPdfFile.value!.path;
    if (filePath == null) {
      ToastService.showError('无法获取文件路径');
      return;
    }

    try {
      // 关闭当前页面
      Get.back();

      // 延迟一小段时间，确保 BottomSheet 完全关闭后再跳转
      await Future.delayed(const Duration(milliseconds: 200));

      // 跳转到笔记详情页，传递 pdfFilePath，让详情页负责创建笔记并显示 Loading
      Get.toNamed(
        AppRoutes.noteDetail,
        arguments: {
          'pdfFilePath': filePath,
        },
      );
    } catch (e) {
      ToastService.showError('处理失败: $e');
      debugPrint('处理失败: $e');
    }
  }
}
