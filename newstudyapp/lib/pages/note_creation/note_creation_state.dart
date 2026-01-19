import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NoteCreationState {
  final titleController = TextEditingController();
  final noteTextController = TextEditingController();

  /// 选择的文件（可选）
  final selectedFileName = RxnString();
  final selectedFilePath = RxnString();

  /// 是否正在向后端请求抽词
  final isLoading = false.obs;

  /// 是否正在保存笔记
  final isSaving = false.obs;

  /// 抽取出的词语列表（可编辑）
  final terms = <String>[].obs;

  /// 从文件提取的原始文本内容（用于保存笔记）
  final extractedText = ''.obs;

  /// 已保存的笔记ID（文件解析后自动保存的笔记）
  final savedNoteId = RxnString();

  /// 已保存的闪卡数据（包含真实ID，用于学习时使用）
  final savedFlashCards = <Map<String, dynamic>>[].obs;

  /// 当前是否已进入"编辑词表"步骤
  final isEditingTerms = false.obs;

  void dispose() {
    titleController.dispose();
    noteTextController.dispose();
  }
}
