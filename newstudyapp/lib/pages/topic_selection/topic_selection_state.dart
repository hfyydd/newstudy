import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 预设主题数据模型
class PresetTopic {
  final String id;
  final String name;
  final String? icon;
  final String description;

  const PresetTopic({
    required this.id,
    required this.name,
    this.icon,
    required this.description,
  });
}

class TopicSelectionState {
  /// 预设主题列表（常量列表，不需要响应式）
  static const List<PresetTopic> presetTopics = [
    PresetTopic(
      id: 'economics',
      name: '经济学',
      icon: '💰',
      description: '学习经济学基础概念和理论',
    ),
    PresetTopic(
      id: 'finance',
      name: '金融',
      icon: '📈',
      description: '了解金融市场和投资理财',
    ),
    PresetTopic(
      id: 'technology',
      name: '科技',
      icon: '💻',
      description: '探索前沿科技和编程概念',
    ),
    PresetTopic(
      id: 'medicine',
      name: '医学',
      icon: '🏥',
      description: '学习医学知识和健康常识',
    ),
    PresetTopic(
      id: 'law',
      name: '法律',
      icon: '⚖️',
      description: '了解法律条文和法理知识',
    ),
    PresetTopic(
      id: 'psychology',
      name: '心理学',
      icon: '🧠',
      description: '探索人类心理和行为模式',
    ),
    PresetTopic(
      id: 'philosophy',
      name: '哲学',
      icon: '🤔',
      description: '思考人生和世界的本质',
    ),
    PresetTopic(
      id: 'history',
      name: '历史',
      icon: '📜',
      description: '回顾历史事件和人物',
    ),
  ];

  /// 选中的主题ID（预设主题）
  final selectedTopic = Rxn<String>();

  /// 自定义主题输入框控制器
  final customTopicController = TextEditingController();

  /// 是否正在加载
  final isLoading = false.obs;

  void dispose() {
    customTopicController.dispose();
  }

  /// 获取最终选择的主题名称
  String? getFinalTopic() {
    if (selectedTopic.value != null) {
      final topic = presetTopics.firstWhereOrNull(
        (t) => t.id == selectedTopic.value,
      );
      return topic?.name ?? selectedTopic.value;
    }
    final custom = customTopicController.text.trim();
    if (custom.isNotEmpty) {
      return custom;
    }
    return null;
  }

  /// 获取最终选择的主题ID（用于API调用）
  String? getFinalTopicId() {
    if (selectedTopic.value != null) {
      return selectedTopic.value;
    }
    final custom = customTopicController.text.trim();
    if (custom.isNotEmpty) {
      // 自定义主题使用小写和空格替换为下划线
      return custom.toLowerCase().replaceAll(' ', '_');
    }
    return null;
  }
}

