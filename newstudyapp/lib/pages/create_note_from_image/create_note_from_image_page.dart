import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:newstudyapp/config/app_theme.dart';
import 'package:newstudyapp/pages/create_note_from_image/create_note_from_image_controller.dart';

/// 从图片创建笔记页面
class CreateNoteFromImagePage extends GetView<CreateNoteFromImageController> {
  const CreateNoteFromImagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor =
        isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final secondaryColor = isDark ? Colors.grey[500] : Colors.grey[600];
    final borderColor =
        isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5E5);

    // 计算 BottomSheet 的高度
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final sheetHeight = screenHeight - statusBarHeight - 40;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // 顶部拖拽指示器
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 顶部标题栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.close, color: textColor, size: 24),
                  onPressed: () => Get.back(),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.createNoteFromImage,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // 分割线
          Divider(color: borderColor, height: 1),

          // 主要内容区域
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 说明文字
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.grey[800]! : Colors.blue[200]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.darkPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '请选择一张包含文字或图表的图片，系统将自动识别并生成笔记',
                            style: TextStyle(
                              fontSize: 13,
                              color: secondaryColor,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 选择图片按钮区域
                  Row(
                    children: [
                      Expanded(
                        child: _buildImageSourceButton(
                          isDark: isDark,
                          textColor: textColor,
                          borderColor: borderColor,
                          icon: Icons.camera_alt,
                          label: AppLocalizations.of(context)!.takePhotoLabel,
                          onTap: () => controller.pickImageFromCamera(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildImageSourceButton(
                          isDark: isDark,
                          textColor: textColor,
                          borderColor: borderColor,
                          icon: Icons.photo_library,
                          label: AppLocalizations.of(context)!.albumLabel,
                          onTap: () => controller.pickImageFromGallery(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 选中的图片预览
                  Obx(() {
                    final image = controller.selectedImage.value;
                    if (image == null) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.imageSelected,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1C1C1E)
                                : const Color(0xFFF8F8F8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 1),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(image.path),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.error_outline,
                                    color: secondaryColor,
                                    size: 48,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 重新选择按钮
                        TextButton.icon(
                          onPressed: () => controller.selectedImage.value = null,
                          icon: Icon(Icons.refresh, color: AppTheme.darkPrimary),
                          label: Text(
                            AppLocalizations.of(context)!.reselect,
                            style: TextStyle(color: AppTheme.darkPrimary),
                          ),
                        ),
                      ],
                    );
                  }),

                  // 加载状态
                  Obx(() {
                    if (controller.isLoading.value) {
                      return Column(
                        children: [
                          const SizedBox(height: 24),
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            controller.loadingMessage.value,
                            style: TextStyle(
                              fontSize: 14,
                              color: secondaryColor,
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  }),

                  const Spacer(),

                  // 底部按钮
                  Obx(() {
                    final isLoading = controller.isLoading.value;
                    final hasImage = controller.selectedImage.value != null;
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (isLoading || !hasImage)
                            ? null
                            : () => controller.createNote(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.darkPrimary,
                          disabledBackgroundColor: Colors.grey[400],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isLoading
                              ? AppLocalizations.of(context)!.processing
                              : hasImage
                                  ? AppLocalizations.of(context)!.createNote
                                  : AppLocalizations.of(context)!.pleaseSelectImage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSourceButton({
    required bool isDark,
    required Color textColor,
    required Color borderColor,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppTheme.darkPrimary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
