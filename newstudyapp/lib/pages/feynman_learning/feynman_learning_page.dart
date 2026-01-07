import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer' as developer;
import 'package:newstudyapp/pages/feynman_learning/feynman_learning_controller.dart';
import 'package:newstudyapp/pages/feynman_learning/feynman_learning_state.dart';
import 'package:newstudyapp/config/app_theme.dart';
import 'package:newstudyapp/models/note_models.dart';

class FeynmanLearningPage extends StatelessWidget {
  const FeynmanLearningPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FeynmanLearningController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      // 如果学习流程可见，使用独立的完整页面（完全覆盖）
      if (controller.state.isExplanationViewVisible.value) {
        return _buildLearningFlowPage(context, controller, isDark);
      }
      
      // 否则显示正常的闪词卡片页面
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(controller, isDark),
      body: Obx(() {
        if (controller.state.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: AppTheme.darkPrimary,
            ),
          );
        }

        if (controller.state.errorMessage.value != null) {
          return _buildErrorView(controller, isDark);
        }

        final terms = controller.state.terms.value;
        if (terms == null || terms.isEmpty) {
          return _buildEmptyView(controller, isDark);
        }

        return Column(

          children: [
            // 进度显示
            _buildProgressBar(controller, terms.length, isDark),
            const SizedBox(height: 16),

            // 卡片区域
            Expanded(
              child: _buildCardSection(controller, terms, isDark),
            ),

            const SizedBox(height: 24),

            // 分页指示器
            _buildPageIndicator(controller, terms.length, isDark),
            const SizedBox(height: 32),
          ],
        );
      }),
    );
    });
  }

  /// 构建AppBar
  PreferredSizeWidget _buildAppBar(
      FeynmanLearningController controller, bool isDark) {
    final iconColor = isDark ? Colors.white : Colors.black87;
    final textColor = isDark ? Colors.white : Colors.black87;

    return AppBar(
      backgroundColor: Theme.of(Get.context!).scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: iconColor),
        onPressed: () => Get.back(),
      ),
      title: Obx(() => Text(
            controller.getCategoryDisplayName(),
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          )),
      centerTitle: true,
    );
  }

  /// 构建进度条
  Widget _buildProgressBar(
      FeynmanLearningController controller, int total, bool isDark) {
    return Obx(() {
      final current = controller.state.currentCardIndex.value + 1;
      final progress = current / total;
      final textColor = isDark ? Colors.grey[400] : Colors.black54;
      final bgColor = isDark ? Colors.grey[800] : Colors.grey[200];

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '进度：$current/$total',
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: bgColor,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.darkPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// 构建卡片区域（支持滑动）
  Widget _buildCardSection(
      FeynmanLearningController controller, List<String> terms, bool isDark) {
    return PageView.builder(
      controller: PageController(
        initialPage: controller.state.currentCardIndex.value,
        viewportFraction: 0.85,
      ),
      onPageChanged: (index) {
        controller.goToCard(index);
      },
      itemCount: terms.length,
      itemBuilder: (context, index) {
        return Obx(() {
          final currentIndex = controller.state.currentCardIndex.value;
          final isCurrentCard = index == currentIndex;

          return AnimatedScale(
            duration: const Duration(milliseconds: 300),
            scale: isCurrentCard ? 1.0 : 0.9,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isCurrentCard ? 1.0 : 0.6,
              child: _buildCard(
                context,
                controller,
                terms[index],
                index,
                isCurrentCard,
                isDark,
              ),
            ),
          );
        });
      },
    );
  }

  /// 构建单个卡片
  Widget _buildCard(
    BuildContext context,
    FeynmanLearningController controller,
    String term,
    int index,
    bool isCurrentCard,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: isCurrentCard
          ? () {
              _showLearningOptions(context, controller, term, isDark);
            }
          : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getCardColor(index).withOpacity(0.9),
              _getCardColor(index),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _getCardColor(index).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 装饰圆圈
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),

            // 学习状态标记（右上角）
            Positioned(
              top: 16,
              right: 16,
              child: _buildStatusBadge(controller, term),
            ),

            // 卡片内容
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 词条类型标签
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      controller.getCategoryDisplayName(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 词条名称
                  Text(
                    term,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const Spacer(),

                  // 提示
                  if (isCurrentCard)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.touch_app,
                            color: Colors.white.withOpacity(0.9),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '点击开始学习',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建状态标记
  Widget _buildStatusBadge(FeynmanLearningController controller, String term) {
    // 从控制器获取卡片数据
    final cardData = controller.getCardDataByTerm(term);
    if (cardData == null) {
      return const SizedBox.shrink();
    }
    
    final statusRaw = cardData['status'] as String? ?? 'NOT_STARTED';
    final status = statusRaw.toUpperCase();
    
    // 如果是未开始，不显示标记
    if (status == 'NOT_STARTED') {
      return const SizedBox.shrink();
    }
    
    final statusColor = controller.getStatusColor(status);
    final statusName = controller.getStatusDisplayName(status);
    final statusIcon = _getStatusIcon(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            statusName,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 获取状态对应的图标
  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'MASTERED':
        return Icons.check_circle;
      case 'NEEDS_REVIEW':
        return Icons.refresh;
      case 'NEEDS_IMPROVE':
        return Icons.edit;
      case 'NOT_MASTERED':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  /// 根据索引返回卡片颜色
  Color _getCardColor(int index) {
    final colors = [
      const Color(0xFF6366F1), // 紫色
      const Color(0xFFEC4899), // 粉色
      const Color(0xFF10B981), // 绿色
      const Color(0xFFF59E0B), // 橙色
      const Color(0xFF3B82F6), // 蓝色
      const Color(0xFF8B5CF6), // 深紫色
    ];
    return colors[index % colors.length];
  }

  /// 构建分页指示器
  Widget _buildPageIndicator(
      FeynmanLearningController controller, int total, bool isDark) {
    return Obx(() {
      final current = controller.state.currentCardIndex.value;
      final dotColor = isDark ? Colors.grey[700] : Colors.grey[300];
      final activeDotColor = AppTheme.darkPrimary;

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total > 8 ? 8 : total, (index) {
          if (total > 8) {
            // 显示前3个、当前、后3个和省略号
            if (index < 3) {
              return _buildDot(index == current, dotColor, activeDotColor);
            } else if (index == 3) {
              if (current > 3 && current < total - 4) {
                return _buildDot(true, dotColor, activeDotColor);
              } else if (current <= 3) {
                return _buildDot(index == current, dotColor, activeDotColor);
              } else {
                return _buildEllipsis(dotColor);
              }
            } else if (index >= 4 && index < 7) {
              final actualIndex = total - (8 - index);
              return _buildDot(
                  actualIndex == current, dotColor, activeDotColor);
            } else {
              return _buildDot(
                  (total - 1) == current, dotColor, activeDotColor);
            }
          } else {
            return _buildDot(index == current, dotColor, activeDotColor);
          }
        }),
      );
    });
  }

  Widget _buildDot(bool isActive, Color? inactiveColor, Color activeColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? activeColor : inactiveColor,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildEllipsis(Color? color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '...',
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 显示学习选项
  void _showLearningOptions(
    BuildContext context,
    FeynmanLearningController controller,
    String term,
    bool isDark,
  ) {
    // 直接进入学习流程（异步方法，使用 unawaited 避免警告）
    // 添加错误处理，防止异常导致手势识别错误
    try {
      controller.startLearningCard(term).catchError((error, stackTrace) {
        developer.log(
          '开始学习失败',
          error: error,
          stackTrace: stackTrace,
          name: 'FeynmanLearningPage',
        );
        // 使用 Future.microtask 确保在正确的时机显示 snackbar
        Future.microtask(() {
          if (Get.isSnackbarOpen) {
            Get.closeAllSnackbars();
          }
          Get.snackbar(
            '错误',
            '开始学习失败：${error.toString()}',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        });
      });
    } catch (e, stackTrace) {
      developer.log(
        '调用 startLearningCard 时发生异常',
        error: e,
        stackTrace: stackTrace,
        name: 'FeynmanLearningPage',
      );
      Future.microtask(() {
        if (Get.isSnackbarOpen) {
          Get.closeAllSnackbars();
        }
        Get.snackbar(
          '错误',
          '操作失败：${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      });
    }
  }

  /// 构建学习流程页面（完整独立页面）
  Widget _buildLearningFlowPage(
    BuildContext context,
    FeynmanLearningController controller,
    bool isDark,
  ) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      body: Obx(() {
        final phase = controller.state.learningPhase.value;

        switch (phase) {
          case LearningPhase.selectingRole:
            return _buildRoleSelectionView(controller, isDark);
          case LearningPhase.explaining:
            return _buildExplanationInputView(controller, isDark);
          case LearningPhase.evaluating:
            return _buildEvaluatingView(controller, isDark);
          case LearningPhase.result:
            return _buildResultView(controller, isDark);
          default:
            return const SizedBox.shrink();
        }
      }),
    );
  }

  /// 构建角色选择视图
  Widget _buildRoleSelectionView(
      FeynmanLearningController controller, bool isDark) {
    final bgColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final secondaryColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final textColor = isDark ? Colors.white : Colors.black;

    final term = controller.state.currentExplainingTerm.value ?? '';

    return Container(
          color: bgColor,
      child: SafeArea(
        child: Column(
          children: [
            // 自定义 AppBar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: textColor, size: 24),
                    onPressed: () => controller.cancelLearning(),
                  ),
                  Expanded(
                    child: Text(
                      '选择角色',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // 平衡左侧关闭按钮
                ],
              ),
            ),
            Expanded(
        child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                  // 头部（带动画）
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // 当前词条
            Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF6366F1).withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Text(
                              term,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
                            '选择一个角色，用TA能理解的方式来解释',
              style: TextStyle(
                              fontSize: 16,
                              color: secondaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 角色列表（带动画）
                  Expanded(
                    child: Obx(() {
                      if (controller.state.isLoadingRoles.value) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final roles = controller.state.roles;

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: roles.length,
                        itemBuilder: (context, index) {
                          final role = roles[index];
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration:
                                Duration(milliseconds: 400 + (index * 100)),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 30 * (1 - value)),
                                  child: Transform.scale(
                                    scale: 0.8 + (0.2 * value),
                                    child: child,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _RoleCard(
                                role: role,
                                isDark: isDark,
                                onTap: () => controller.selectRole(role),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建解释输入视图
  Widget _buildExplanationInputView(
      FeynmanLearningController controller, bool isDark) {
    final bgColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final borderColor =
        isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5E5);
    final inputBgColor =
        isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF8F8F8);

    final term = controller.state.currentExplainingTerm.value ?? '';
    final role = controller.state.selectedRole.value;

    return Container(
      color: bgColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 自定义 AppBar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: textColor, size: 24),
                    onPressed: () => controller.cancelLearning(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '解释词条',
                        style: TextStyle(
                color: textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // 占位，保持标题居中
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // 分割线
            Divider(color: borderColor, height: 1),

            // 头部信息卡片
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF6366F1).withOpacity(0.1),
                      const Color(0xFF8B5CF6).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF6366F1).withOpacity(0.3)
                        : const Color(0xFF6366F1).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // 词条名称
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        term,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 角色标签
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: secondaryColor,
                        ),
                        const SizedBox(width: 6),
            Text(
                          '向「${role?.name ?? ''}」解释',
              style: TextStyle(
                fontSize: 14,
                color: secondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      role?.description ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // 主要内容区域
            Expanded(
              child: Stack(
                children: [
                  // 输入区域
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                    child: _buildInputArea(
                        controller, isDark, textColor, secondaryColor, borderColor, inputBgColor, role),
                  ),

                  // 底部悬浮区域：语音输入按钮和状态
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildFloatingBottom(
                        controller, isDark, textColor, secondaryColor, borderColor),
                  ),
                ],
              ),
            ),

            // 底部提交按钮
            _buildBottomActions(controller, isDark, bgColor, borderColor),
          ],
        ),
      ),
    );
  }

  /// 构建输入区域
  Widget _buildInputArea(
      FeynmanLearningController controller,
      bool isDark,
      Color textColor,
      Color? secondaryColor,
      Color borderColor,
      Color inputBgColor,
      LearningRole? role) {
    return Container(
      decoration: BoxDecoration(
        color: inputBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Stack(
        children: [
          TextField(
            controller: controller.state.textInputController,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
              height: 1.6,
            ),
            decoration: InputDecoration(
              hintText: '输入你的解释...\n\n例如：${role?.description ?? ''}',
              hintStyle: TextStyle(
                color: secondaryColor,
                fontSize: 15,
                height: 1.6,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 44),
              counterText: '', // 隐藏默认的字数统计
            ),
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
              final hasContent = controller.state.inputText.value.isNotEmpty;
              if (!hasContent) return const SizedBox.shrink();

              return GestureDetector(
              onTap: () {
                  controller.state.textInputController.clear();
                  controller.state.inputText.value = '';
                },
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
      FeynmanLearningController controller,
      bool isDark,
      Color textColor,
      Color? secondaryColor,
      Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // 左侧：语音识别状态
          Expanded(
            child: Obx(() {
              final isListening = controller.state.isListening.value;
              final speechText = controller.state.speechText.value;

              if (isListening) {
                return Row(
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFF6B6B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        speechText.isNotEmpty
                            ? '正在识别：$speechText'
                            : '正在聆听...',
                        style: TextStyle(
                          fontSize: 13,
                          color: secondaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }

              if (speechText.isNotEmpty) {
                return Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '已识别：$speechText',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF10B981),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }

              return const SizedBox.shrink();
            }),
          ),

          // 右侧：语音输入按钮
          Obx(() {
            final isListening = controller.state.isListening.value;

            return GestureDetector(
              onTap: controller.toggleSpeechInput,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: isListening ? 16 : 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isListening
                      ? const Color(0xFFFF6B6B)
                      : (isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFF0F0F0)),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isListening
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
                      isListening ? Icons.stop : Icons.mic,
                      color: isListening
                          ? Colors.white
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      size: 20,
                    ),
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
  Widget _buildBottomActions(FeynmanLearningController controller, bool isDark,
      Color bgColor, Color borderColor) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 16 + MediaQuery.of(Get.context!).padding.bottom),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () {
            final text = controller.state.textInputController.text.trim();
            if (text.isEmpty) {
                Get.snackbar(
                  '提示',
                '请输入你的解释',
                  snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
              );
              return;
            }
            controller.submitExplanation(text);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.send, size: 20),
              SizedBox(width: 8),
              Text(
                '提交解释',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建评估中视图
  Widget _buildEvaluatingView(
      FeynmanLearningController controller, bool isDark) {
    final bgColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Container(
      color: bgColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'AI 正在评估你的解释...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '这可能需要几秒钟',
              style: TextStyle(
                fontSize: 14,
                color: secondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建结果视图
  Widget _buildResultView(FeynmanLearningController controller, bool isDark) {
    final bgColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final cardBgColor =
        isDark ? const Color(0xFF252540) : Colors.grey[50]; // 用于AI反馈卡片

    final result = controller.state.evaluationResult.value;
    if (result == null) return const SizedBox.shrink();

    final term = controller.state.currentExplainingTerm.value ?? '';
    final score = result.score;
    final status = result.status;
    final statusColor = controller.getStatusColor(status);
    final statusName = controller.getStatusDisplayName(status);

    return Container(
      color: bgColor,
      child: SafeArea(
        child: Column(
          children: [
            // 自定义 AppBar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: textColor, size: 24),
                    onPressed: () => controller.cancelLearning(),
                  ),
                  Expanded(
                    child: Obx(() {
                      // 如果有学习历史，显示"学习记录"，否则显示"评估结果"
                      final hasHistory = controller.state.cardLearningHistory.isNotEmpty;
                      return Text(
                        hasHistory ? '学习记录' : '评估结果',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      );
                    }),
                  ),
                  const SizedBox(width: 48), // 平衡左侧关闭按钮
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 词条和状态
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          term,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // 如果是学习历史，显示提示和角色信息
                    Obx(() {
                      final hasHistory = controller.state.cardLearningHistory.isNotEmpty;
                      final selectedRole = controller.state.selectedRole.value;
                      if (hasHistory) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.history, size: 14, color: secondaryColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      '这是你之前的学习记录',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: secondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (selectedRole != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person, size: 14, color: const Color(0xFF10B981)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '学习角色: ${selectedRole.name}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF10B981),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    const SizedBox(height: 32),

                    // 分数圆环
                    Center(
                      child:
                          _ScoreCircle(score: score, statusColor: statusColor),
                    ),
                    const SizedBox(height: 32),

                    // AI反馈
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.smart_toy,
                                  color: secondaryColor, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'AI 反馈',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            result.feedback,
                            style: TextStyle(
                              fontSize: 15,
                              color: textColor,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
            ),
            const SizedBox(height: 16),

                    // 做得好的点
                    if (result.highlights.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.thumb_up,
                                    color: Color(0xFF10B981), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  '做得好',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...result.highlights.map((h) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('• ',
                                          style: TextStyle(
                                              color: Color(0xFF10B981))),
                                      Expanded(
                                        child: Text(
                                          h,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: textColor,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 改进建议
                    if (result.suggestions.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.lightbulb,
                                    color: Color(0xFFF59E0B), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  '可以改进',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...result.suggestions.map((s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('• ',
                                          style: TextStyle(
                                              color: Color(0xFFF59E0B))),
                                      Expanded(
                                        child: Text(
                                          s,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: textColor,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 24),

                    // 操作按钮
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => controller.retryCurrentCard(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: secondaryColor!),
                            ),
                            child: const Text('重新学习'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () => controller.continueToNextCard(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('下一张',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建错误视图
  Widget _buildErrorView(FeynmanLearningController controller, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: secondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() => Text(
                  controller.state.errorMessage.value ?? '未知错误',
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryColor,
                  ),
                  textAlign: TextAlign.center,
                )),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建空视图
  Widget _buildEmptyView(FeynmanLearningController controller, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: secondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无词条',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '请先选择学习主题',
              style: TextStyle(
                fontSize: 14,
                color: secondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 学习选项按钮组件
class _LearningOptionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _LearningOptionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? Colors.grey[850] : Colors.grey[50];
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: secondaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 角色选择卡片组件
class _RoleCard extends StatefulWidget {
  final LearningRole role;
  final bool isDark;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  IconData _getRoleIcon() {
    switch (widget.role.id) {
      case 'child_5':
        return Icons.child_care;
      case 'elementary':
        return Icons.school;
      case 'middle_school':
        return Icons.auto_stories;
      case 'college':
        return Icons.school_outlined;
      case 'master':
        return Icons.psychology;
      default:
        return Icons.person;
    }
  }

  Color _getRoleColor() {
    switch (widget.role.id) {
      case 'child_5':
        return const Color(0xFFEC4899); // 粉色
      case 'elementary':
        return const Color(0xFF10B981); // 绿色
      case 'middle_school':
        return const Color(0xFF3B82F6); // 蓝色
      case 'college':
        return const Color(0xFFF59E0B); // 橙色
      case 'master':
        return const Color(0xFF8B5CF6); // 紫色
      default:
        return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.isDark ? const Color(0xFF252540) : Colors.grey[50];
    final textColor = widget.isDark ? Colors.white : Colors.black;
    final secondaryColor = widget.isDark ? Colors.grey[400] : Colors.grey[600];
    final roleColor = _getRoleColor();

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isDark ? Colors.grey[700]! : Colors.grey[200]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: roleColor.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getRoleIcon(),
                  color: roleColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.role.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.role.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: secondaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 分数圆环组件
class _ScoreCircle extends StatelessWidget {
  final int score;
  final Color statusColor;

  const _ScoreCircle({
    required this.score,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 背景圆环
          SizedBox(
            width: 140,
            height: 140,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 12,
              valueColor: AlwaysStoppedAnimation<Color>(
                statusColor.withOpacity(0.2),
              ),
            ),
          ),
          // 分数圆环
          SizedBox(
            width: 140,
            height: 140,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 12,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          // 分数文字
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              Text(
                '分',
                style: TextStyle(
                  fontSize: 16,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
