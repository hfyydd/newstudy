import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum FloatingPhase { idle, flyingUp, flyingDown }
enum InputMode { voice, text }

class HomeState {
  // 服务相关
  static const String defaultCategory = 'economics';
  static const Alignment floatingTargetAlignment = Alignment(-0.9, -0.9);
  static const double floatingTargetSizeFactor = 0.55;

  // 加载状态
  final isLoading = true.obs;
  final errorMessage = Rxn<String>();

  // 术语列表管理
  final terms = Rxn<List<String>>();
  final selectedTerm = Rxn<String>();
  final activeCategory = 'economics'.obs;

  // 浮动卡片动画状态
  final floatingTerm = Rxn<String>();
  final floatingCardWidth = Rxn<double>();
  final floatingCardHeight = Rxn<double>();
  final floatingAlignment = Alignment.center.obs;
  final floatingSizeFactor = 1.0.obs;
  final floatingAnimating = false.obs;
  final floatingPhase = FloatingPhase.idle.obs;

  // 输入相关状态
  final inputMode = InputMode.voice.obs;
  final isExplaining = false.obs;
  final isSubmittingSuggestion = false.obs;
  final textInputController = TextEditingController();
  final isAppending = false.obs;

  void dispose() {
    textInputController.dispose();
  }
}
