import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/pages/topic_selection/topic_selection_controller.dart';
import 'package:newstudyapp/pages/topic_selection/topic_selection_state.dart';

class TopicSelectionPage extends StatelessWidget {
  const TopicSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TopicSelectionController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8F9FA),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 自定义 AppBar
              _buildCustomAppBar(),
              
              // 主要内容区域
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题和描述
                      _buildHeader(),
                      const SizedBox(height: 24),

                      // 自定义输入框卡片
                      _buildCustomInputCard(controller),
                      const SizedBox(height: 24),

                      // 预设主题选项
                      _buildPresetTopicsSection(controller),
                      const SizedBox(height: 24),

                      // 开始学习按钮
                      _buildStartButton(controller),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建自定义 AppBar
  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
            ),
            onPressed: () => Get.back(),
          ),
          const SizedBox(width: 8),
          const Text(
            '选择学习主题',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建标题区域
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '你想学习什么主题？',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '选择一个预设主题，或输入自定义主题',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// 构建自定义输入框卡片
  Widget _buildCustomInputCard(TopicSelectionController controller) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_note,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '自定义主题',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: controller.state.customTopicController,
                decoration: InputDecoration(
                  hintText: '例如：机器学习、量子物理、投资理财...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                onChanged: (value) {
                  controller.onCustomTopicChanged(value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建预设主题区域
  Widget _buildPresetTopicsSection(TopicSelectionController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Color(0xFFFF6B6B),
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '热门主题',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: TopicSelectionState.presetTopics.length,
          itemBuilder: (context, index) {
            final topic = TopicSelectionState.presetTopics[index];
            return Obx(() {
              final isSelected = controller.state.selectedTopic.value == topic.id;
              return _buildTopicCard(
                topic: topic,
                isSelected: isSelected,
                onTap: () => controller.selectPresetTopic(topic.id),
              );
            });
          },
        ),
      ],
    );
  }

  /// 构建主题卡片
  Widget _buildTopicCard({
    required PresetTopic topic,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    // 为不同主题分配不同的渐变颜色
    final gradients = [
      [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)], // 红色到橙色
      [const Color(0xFF4A90E2), const Color(0xFF9B59B6)], // 蓝色到紫色
      [const Color(0xFF52C9A2), const Color(0xFF2ECC71)], // 绿色
      [const Color(0xFFFFD93D), const Color(0xFFFFB347)], // 黄色到橙色
      [const Color(0xFF6C5CE7), const Color(0xFFA29BFE)], // 紫色
      [const Color(0xFF00D2FF), const Color(0xFF3A7BD5)], // 蓝色
      [const Color(0xFFFF9A9E), const Color(0xFFFAD0C4)], // 粉色
      [const Color(0xFFA8EDEA), const Color(0xFFFED6E3)], // 青色到粉色
    ];
    
    final gradientIndex = TopicSelectionState.presetTopics.indexOf(topic) % gradients.length;
    final gradient = gradients[gradientIndex];

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? gradient
                : [Colors.grey[100]!, Colors.grey[200]!],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.white.withOpacity(0.5)
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (topic.icon != null) ...[
                Text(
                  topic.icon!,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                topic.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                topic.description,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? Colors.white.withOpacity(0.9)
                      : Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建开始学习按钮
  Widget _buildStartButton(TopicSelectionController controller) {
    return Obx(() {
      final hasSelection = controller.state.selectedTopic.value != null ||
          (controller.state.customTopicController.text.trim().isNotEmpty);
      final isLoading = controller.state.isLoading.value;

      return Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: hasSelection
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6366F1),
                    Color(0xFF8B5CF6),
                  ],
                )
              : null,
          color: hasSelection ? null : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
          boxShadow: hasSelection
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: hasSelection && !isLoading
                ? () => controller.startLearning()
                : null,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rocket_launch,
                          color: Colors.white,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '开始学习',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      );
    });
  }
}
