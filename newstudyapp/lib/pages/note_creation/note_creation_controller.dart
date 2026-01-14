import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' show Platform;
import 'package:newstudyapp/pages/note_creation/note_creation_state.dart';
import 'package:newstudyapp/pages/home/home_controller.dart';
import 'package:newstudyapp/routes/app_routes.dart';
import 'package:newstudyapp/services/http_service.dart';
import 'package:newstudyapp/services/harmonyos_file_picker_service.dart';

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
      // 在 HarmonyOS 平台上使用原生文件选择器
      if (Platform.isAndroid || Platform.isIOS) {
        // 使用 file_picker 插件（Android/iOS）
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
      } else {
        // 在 HarmonyOS 平台上使用原生实现
        try {
          final files = await HarmonyOSFilePickerService.pickFiles(
            allowedExtensions: const ['pdf', 'docx', 'txt', 'md'],
          );

          if (files.isEmpty) {
            return; // 用户取消选择
          }

          final file = files.first;
          state.selectedFileName.value = file['name'] as String? ?? '未知文件';
          // 优先使用 path，如果没有则使用 uri
          state.selectedFilePath.value =
              file['path'] as String? ?? file['uri'] as String? ?? '';
        } catch (e) {
          // 如果原生实现失败，回退到 file_picker（如果支持）
          Get.snackbar(
            '错误',
            '选择文件失败：$e',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(milliseconds: 2000),
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        '错误',
        '选择文件失败：$e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(milliseconds: 2000),
      );
    }
  }

  /// 从相册或相机选择图片
  Future<void> pickImage(ImageSource source) async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );

        if (image == null) return;

        state.selectedFileName.value = image.name;
        state.selectedFilePath.value = image.path;
      } else {
        // HarmonyOS 原生实现
        if (source == ImageSource.camera) {
          // 使用拍照功能
          final photos = await HarmonyOSFilePickerService.takePhoto();
          if (photos.isEmpty) return;

          final photo = photos.first;
          state.selectedFileName.value = photo['name'] as String? ?? '未知照片';
          state.selectedFilePath.value =
              photo['path'] as String? ?? photo['uri'] as String? ?? '';
        } else {
          // 使用相册选择
          final images = await HarmonyOSFilePickerService.pickImages();
          if (images.isEmpty) return;

          final image = images.first;
          state.selectedFileName.value = image['name'] as String? ?? '未知图片';
          state.selectedFilePath.value =
              image['path'] as String? ?? image['uri'] as String? ?? '';
        }
      }

      // 跳转到文件上传流程
      Get.toNamed(AppRoutes.noteCreation);
    } catch (e) {
      Get.snackbar(
        '错误',
        '选择图片失败：$e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> extractTermsFromSelectedFile() async {
    final path = state.selectedFilePath.value;
    final name = state.selectedFileName.value;
    if (path == null || name == null) {
      Get.snackbar(
        '提示',
        '请先选择文件（PDF/DOCX/图片）',
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
      // 保存提取的文本内容（用于保存笔记）
      state.extractedText.value = resp.text;
      state.noteTextController.text = resp.text;
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

  void startLearning() async {
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

    // 如果有提取的文本内容，先保存笔记到数据库
    final extractedText = state.noteTextController.text.trim();
    String? savedNoteId;

    if (extractedText.isNotEmpty) {
      state.isSaving.value = true;
      try {
        final noteResponse = await httpService.createNote(
          title: title.isEmpty ? 'PDF笔记' : title,
          content: extractedText,
        );
        savedNoteId = noteResponse.id;
        debugPrint('[NoteCreationController] 笔记创建成功: $savedNoteId');

        // 通知 HomeController 刷新列表
        if (Get.isRegistered<HomeController>()) {
          final homeController = Get.find<HomeController>();
          await homeController.loadNotes();
          debugPrint('[NoteCreationController] 已刷新笔记列表');
        }
      } catch (e) {
        debugPrint('[NoteCreationController] 笔记创建失败: $e');
        // 即使保存失败也继续学习，只是不会有笔记ID
      } finally {
        state.isSaving.value = false;
      }
    }

    // 跳转到学习页面，传递笔记ID以便标记已掌握
    Get.toNamed(
      AppRoutes.feynmanLearning,
      arguments: {
        'topic': title.isEmpty ? '我的笔记' : title,
        'terms': state.terms.toList(growable: false),
        'noteId': savedNoteId,
      },
    );
  }
}
