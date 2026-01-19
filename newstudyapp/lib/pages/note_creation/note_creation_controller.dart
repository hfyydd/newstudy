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

      // 提取成功后，执行“自动保存并获取真实ID”的逻辑
      await _autoSaveAndRefetch(text, initialTerms: resp.terms);

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
      final extractedText = resp.text ?? '';
      state.extractedText.value = extractedText;
      state.noteTextController.text = extractedText;

      // 提取成功后，执行“自动保存并获取真实ID”的逻辑
      if (extractedText.isNotEmpty) {
        await _autoSaveAndRefetch(extractedText, initialTerms: resp.terms);
      } else {
        // 如果没提取到文本但有词条（罕见），直接更新词条
        state.terms.value = List.of(resp.terms);
      }

      // 准备好数据后进入编辑模式
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

  /// 内部核心方法：自动保存笔记，并立即重新获取详情以同步真实卡片ID
  Future<void> _autoSaveAndRefetch(String text, {List<String>? initialTerms}) async {
    try {
      state.isSaving.value = true;
      debugPrint('[NoteCreationController] 开始自动保存笔记并获取详情... 内容长度: ${text.length}');
      
      final noteResponse = await httpService.createNote(
        userInput: text,
        maxTerms: 30,
        title: state.selectedFileName.value, // 如果有文件名，作为标题
        terms: initialTerms, // 如果有提取的词条，直接传入
        content: text, // 如果是提取的全文，直接作为内容
      );
      
      final noteId = noteResponse.noteId;
      state.savedNoteId.value = noteId;
      debugPrint('[NoteCreationController] 笔记自动保存成功: $noteId');

      // 立即重新获取笔记详情，以获取由后端生成的真实闪词卡片数据（带真实ID）
      try {
        final noteDetail = await httpService.getNoteDetail(noteId);
        final flashCardsRaw = noteDetail['flash_cards'] as List? ?? [];
        
        final savedCards = flashCardsRaw
            .whereType<Map<String, dynamic>>()
            .where((card) => card['term'] != null && card['id'] != null)
            .toList();
        
        state.savedFlashCards.value = savedCards;
        
        // 重要：将 state.terms 同步为真实卡片的词条，确保编辑时与后端一致
        if (savedCards.isNotEmpty) {
          state.terms.value = savedCards
              .map((c) => c['term'].toString())
              .toList();
          debugPrint('[NoteCreationController] 同步了 ${savedCards.length} 张真实卡片到界面');
        } else if (initialTerms != null) {
          state.terms.value = List.of(initialTerms);
        }
      } catch (e) {
        debugPrint('[NoteCreationController] 重新获取笔记详情失败: $e');
        if (initialTerms != null) {
          state.terms.value = List.of(initialTerms);
        }
      }

      // 刷新首页笔记列表
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().loadNotes();
      }
    } catch (e) {
      debugPrint('[NoteCreationController] 自动保存笔记失败: $e');
      if (initialTerms != null) {
        state.terms.value = List.of(initialTerms);
      }
      Get.snackbar(
        '错误',
        '自动保存失败 (请检查网络或重启后端):\n$e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      state.isSaving.value = false;
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
    final String? noteId = state.savedNoteId.value;
    final List<Map<String, dynamic>> savedCards = state.savedFlashCards.toList();

    debugPrint('[NoteCreationController] 进入学习: noteId=$noteId, cardsCount=${savedCards.length}');

    // 如果还没有保存笔记ID但有文字内容，尝试最后补救性保存一次
    if (noteId == null) {
      final text = state.noteTextController.text.trim();
      if (text.isNotEmpty) {
        await _autoSaveAndRefetch(text);
      }
    }

    // 跳转到学习页面
    Get.toNamed(
      AppRoutes.feynmanLearning,
      arguments: {
        'topic': title.isEmpty ? '我的笔记' : title,
        'flashCards': state.savedFlashCards.toList(),
        'terms': state.terms.toList(growable: false),
        'noteId': state.savedNoteId.value,
      },
    );
  }

  /// 保存并返回首页
  Future<void> saveAndExit() async {
    final text = state.noteTextController.text.trim();
    final title = state.titleController.text.trim();
    
    debugPrint('[NoteCreationController] 执行 saveAndExit: title=$title, textLength=${text.length}, termsCount=${state.terms.length}');
    
    try {
      state.isSaving.value = true;

      // 1. 如果还没有保存过笔记，先创建
      if (state.savedNoteId.value == null && text.isNotEmpty) {
        debugPrint('[NoteCreationController] 笔记未保存，开始自动保存...');
        await _autoSaveAndRefetch(text);
      }

      // 2. 如果已经有笔记ID，同步最新的标题和内容（用户可能在界面上修改过）
      if (state.savedNoteId.value != null) {
        debugPrint('[NoteCreationController] 同步最新的标题和内容...');
        await httpService.updateNote(
          noteId: state.savedNoteId.value!,
          title: title.isEmpty ? '我的笔记' : title,
          content: text,
        );
      }

      // 3. 刷新首页数据
      debugPrint('[NoteCreationController] 准备刷新首页并跳转...');
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        await homeController.loadNotes();
        await homeController.loadHomeStatistics();
      }

      // 4. 跳转回首页
      // 使用 offAllNamed 确保清理栈，或者如果确信是从首页来的，可以使用 Get.until
      Get.offAllNamed(AppRoutes.main);
      
      Get.snackbar(
        '成功',
        '笔记已保存',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('[NoteCreationController] 保存并退出失败: $e');
      Get.snackbar(
        '错误',
        '保存失败：$e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      state.isSaving.value = false;
    }
  }
}
