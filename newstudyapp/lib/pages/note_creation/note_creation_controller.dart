import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:newstudyapp/pages/note_creation/note_creation_state.dart';
import 'package:newstudyapp/routes/app_routes.dart';
import 'package:newstudyapp/services/http_service.dart';

class NoteCreationController extends GetxController {
  final httpService = HttpService();
  late final NoteCreationState state;

  @override
  void onInit() {
    super.onInit();
    state = NoteCreationState();
  }

  @override
  void onClose() {
    state.dispose();
    super.onClose();
  }

  Future<void> extractTerms() async {
    final text = state.noteTextController.text.trim();
    if (text.isEmpty) {
      Get.snackbar(
        '提示',
        '请先粘贴/输入笔记内容',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(milliseconds: 1600),
      );
      return;
    }

    state.isLoading.value = true;
    try {
      final resp = await httpService.extractTermsFromNote(
        text: text,
        title: state.titleController.text.trim().isEmpty
            ? null
            : state.titleController.text.trim(),
        maxTerms: 30,
      );

      state.terms.value = List.of(resp.terms);
      state.isEditingTerms.value = true;

      if (state.terms.isEmpty) {
        Get.snackbar(
          '提示',
          '没有从笔记中抽取到词语，你可以手动添加',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1800),
        );
      }
    } catch (e) {
      Get.snackbar(
        '错误',
        '抽取词语失败：$e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(milliseconds: 2000),
      );
    } finally {
      state.isLoading.value = false;
    }
  }

  Future<void> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'docx', 'txt', 'md'],
        withData: false,
      );
      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      if (file.path == null) {
        Get.snackbar(
          '错误',
          '无法获取文件路径，请重试',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1800),
        );
        return;
      }

      state.selectedFileName.value = file.name;
      state.selectedFilePath.value = file.path;
    } catch (e) {
      Get.snackbar(
        '错误',
        '选择文件失败：$e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(milliseconds: 2000),
      );
    }
  }

  Future<void> extractTermsFromSelectedFile() async {
    final path = state.selectedFilePath.value;
    final name = state.selectedFileName.value;
    if (path == null || name == null) {
      Get.snackbar(
        '提示',
        '请先选择文件（PDF/DOCX/TXT）',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(milliseconds: 1600),
      );
      return;
    }

    state.isLoading.value = true;
    try {
      final resp = await httpService.extractTermsFromNoteFile(
        filePath: path,
        filename: name,
        maxTerms: 30,
      );
      // 如果用户没填标题，用文件名做标题
      if (state.titleController.text.trim().isEmpty && resp.title != null) {
        state.titleController.text = resp.title!;
      }
      state.terms.value = List.of(resp.terms);
      state.isEditingTerms.value = true;

      if (state.terms.isEmpty) {
        Get.snackbar(
          '提示',
          '没有从文件中抽取到词语，你可以手动添加',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1800),
        );
      }
    } catch (e) {
      Get.snackbar(
        '错误',
        '解析文件失败：$e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(milliseconds: 2000),
      );
    } finally {
      state.isLoading.value = false;
    }
  }

  void addTerm(String term) {
    final t = term.trim();
    if (t.isEmpty) return;
    if (state.terms.contains(t)) return;
    state.terms.add(t);
  }

  void updateTerm(int index, String newValue) {
    if (index < 0 || index >= state.terms.length) return;
    final t = newValue.trim();
    if (t.isEmpty) return;
    state.terms[index] = t;
    state.terms.refresh();
  }

  void removeTerm(int index) {
    if (index < 0 || index >= state.terms.length) return;
    state.terms.removeAt(index);
  }

  void startLearning() {
    if (state.terms.isEmpty) {
      Get.snackbar(
        '提示',
        '词表为空，请先添加至少一个词语',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(milliseconds: 1600),
      );
      return;
    }

    final title = state.titleController.text.trim();
    Get.toNamed(
      AppRoutes.feynmanLearning,
      arguments: {
        'topic': title.isEmpty ? '我的笔记' : title,
        'terms': state.terms.toList(growable: false),
      },
    );
  }
}


