import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/config/app_theme.dart';
import 'create_note_controller.dart';

/// 创建笔记页面
class CreateNotePage extends GetView<CreateNoteController> {
  const CreateNotePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor =
        isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final secondaryColor = isDark ? Colors.grey[500] : Colors.grey[600];
    final borderColor =
        isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5E5);

    // 计算 BottomSheet 的高度：屏幕高度 - 状态栏高度 - 一些顶部间距
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
                    child: Obx(() => Text(
                      controller.state.isEdit.value ? '编辑笔记' : '创建笔记',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    )),
                  ),
                ),
                // 占位，保持标题居中
                const SizedBox(width: 48),
              ],
            ),
          ),

          // 分割线
          Divider(color: borderColor, height: 1),

          // 主要内容区域
          Expanded(
            child: Stack(
              children: [
                // 输入区域
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 输入框
                      Expanded(
                        child: _buildInputArea(
                            isDark, textColor, secondaryColor, borderColor),
                      ),
                    ],
                  ),
                ),

                // 底部悬浮区域：字数统计 + 录音按钮
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildFloatingBottom(
                      isDark, textColor, secondaryColor, borderColor),
                ),
              ],
            ),
          ),

          // 底部保存按钮
          _buildBottomActions(isDark, bgColor, borderColor),
        ],
      ),
    );
  }

  /// 构建输入区域
  Widget _buildInputArea(
      bool isDark, Color textColor, Color? secondaryColor, Color borderColor) {
    final inputBgColor =
        isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF8F8F8);

    return Container(
      decoration: BoxDecoration(
        color: inputBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Stack(
        children: [
          TextField(
            controller: controller.contentController,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
              height: 1.6,
            ),
            decoration: InputDecoration(
              hintText: '输入您想要学习的内容...\n\n可以是任何知识、概念或信息，AI 将为您生成笔记和闪词卡片。',
              hintStyle: TextStyle(
                color: secondaryColor,
                fontSize: 15,
                height: 1.6,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 44),
              counterText: '', // 隐藏默认的字数统计
            ),
            maxLength: 500,
            maxLines: null,
            expands: true,
            textInputAction: TextInputAction.newline,
            autofocus: true,
            textAlignVertical: TextAlignVertical.top,
          ),
          // 清除按钮
          Positioned(
            bottom: 10,
            right: 10,
            child: Obx(() {
              final hasContent = controller.state.noteContent.value.isNotEmpty;
              if (!hasContent) return const SizedBox.shrink();

              return GestureDetector(
                onTap: () => controller.contentController.clear(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: isDark ? Colors.grey[300] : Colors.grey[600],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// 构建底部悬浮区域
  Widget _buildFloatingBottom(
      bool isDark, Color textColor, Color? secondaryColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // 左侧：字数统计和录音状态
          Expanded(
            child: Obx(() {
              final contentLength = controller.state.noteContent.value.length;
              final hasAudio = controller.state.hasAudio;
              final duration = controller.state.recordDuration.value;

              // 字数颜色：接近上限时变色
              final isNearLimit = contentLength >= 450;
              final isAtLimit = contentLength >= 500;
              final countColor = isAtLimit
                  ? const Color(0xFFFF6B6B)
                  : (isNearLimit ? const Color(0xFFFFAA33) : secondaryColor);

              return Row(
                children: [
                  Icon(Icons.text_fields, size: 16, color: countColor),
                  const SizedBox(width: 4),
                  Text(
                    '$contentLength / 500',
                    style: TextStyle(
                      fontSize: 13,
                      color: countColor,
                      fontWeight:
                          isNearLimit ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (hasAudio) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ECDC4).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.audiotrack,
                              size: 14, color: Color(0xFF4ECDC4)),
                          const SizedBox(width: 4),
                          Text(
                            _formatDuration(duration),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4ECDC4),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: controller.deleteAudio,
                            child: const Icon(Icons.close,
                                size: 14, color: Color(0xFF4ECDC4)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            }),
          ),

          // 右侧：录音按钮
          Obx(() {
            final isRecording = controller.state.isRecording.value;
            final hasAudio = controller.state.hasAudio;
            final duration = controller.state.recordDuration.value;

            return GestureDetector(
              onTap: controller.toggleRecording,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: isRecording ? 16 : 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isRecording
                      ? const Color(0xFFFF6B6B)
                      : (hasAudio
                          ? const Color(0xFF4ECDC4)
                          : (isDark
                              ? const Color(0xFF2C2C2E)
                              : const Color(0xFFF0F0F0))),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isRecording
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF6B6B).withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isRecording ? Icons.stop : Icons.mic,
                      color: isRecording || hasAudio
                          ? Colors.white
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      size: 20,
                    ),
                    if (isRecording) ...[
                      const SizedBox(width: 8),
                      Text(
                        _formatDuration(duration),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 构建底部操作按钮
  Widget _buildBottomActions(bool isDark, Color bgColor, Color borderColor) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 16 + MediaQuery.of(Get.context!).padding.bottom),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Obx(() {
        final isFormValid = controller.state.isFormValid;

        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: !isFormValid ? null : controller.saveNote,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.darkPrimary,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  isDark ? Colors.grey[800] : Colors.grey[300],
              disabledForegroundColor:
                  isDark ? Colors.grey[600] : Colors.grey[500],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, size: 20),
                SizedBox(width: 8),
                Text(
                  '开始学习',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// 格式化时长
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
