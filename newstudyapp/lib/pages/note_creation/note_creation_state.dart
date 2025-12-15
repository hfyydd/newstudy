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

  /// 抽取出的词语列表（可编辑）
  final terms = <String>[].obs;

  /// 当前是否已进入“编辑词表”步骤
  final isEditingTerms = false.obs;

  void dispose() {
    titleController.dispose();
    noteTextController.dispose();
  }
}


