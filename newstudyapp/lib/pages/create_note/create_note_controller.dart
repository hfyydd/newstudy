import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:newstudyapp/routes/app_routes.dart';
import 'create_note_state.dart';

/// 创建笔记控制器
class CreateNoteController extends GetxController {
  final CreateNoteState state = CreateNoteState();

  /// 内容输入控制器
  final TextEditingController contentController = TextEditingController();

  /// 音频录制器
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();

  /// 录音计时器
  Timer? _recordTimer;

  /// 录制器是否已初始化
  bool _isRecorderInitialized = false;

  @override
  void onInit() {
    super.onInit();

    // 初始化录制器
    _initRecorder();

    // 监听输入变化
    contentController.addListener(_onContentChanged);
  }

  @override
  void onClose() {
    contentController.dispose();
    _closeRecorder();
    _recordTimer?.cancel();
    super.onClose();
  }

  /// 初始化录制器
  Future<void> _initRecorder() async {
    try {
      await _audioRecorder.openRecorder();
      _isRecorderInitialized = true;
    } catch (e) {
      print('初始化录制器失败：$e');
    }
  }

  /// 关闭录制器
  Future<void> _closeRecorder() async {
    try {
      if (_isRecorderInitialized) {
        await _audioRecorder.closeRecorder();
        _isRecorderInitialized = false;
      }
    } catch (e) {
      print('关闭录制器失败：$e');
    }
  }

  /// 内容变化回调
  void _onContentChanged() {
    state.noteContent.value = contentController.text;
  }

  /// 开始/停止录音
  Future<void> toggleRecording() async {
    if (state.isRecording.value) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }

  /// 开始录音
  Future<void> startRecording() async {
    try {
      if (!_isRecorderInitialized) {
        await _initRecorder();
      }

      // 请求麦克风权限
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        Get.snackbar(
          '权限错误',
          '需要麦克风权限才能录音',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFFF6B6B),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
        return;
      }

      // 生成录音文件路径
      final Directory tempDir = await getTemporaryDirectory();
      final String filePath =
          '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';

      // 开始录音
      await _audioRecorder.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
        sampleRate: 44100,
        bitRate: 128000,
      );

      state.isRecording.value = true;
      state.recordDuration.value = 0;
      state.audioPath.value = filePath;

      // 开始计时
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        state.recordDuration.value++;
      });
    } catch (e) {
      Get.snackbar(
        '错误',
        '录音启动失败：$e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFF6B6B),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  /// 停止录音
  Future<void> stopRecording() async {
    try {
      await _audioRecorder.stopRecorder();

      _recordTimer?.cancel();
      state.isRecording.value = false;

      if (state.audioPath.value.isNotEmpty) {
        Get.snackbar(
          '成功',
          '录音已保存（${state.recordDuration.value}秒）',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF4ECDC4),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      }
    } catch (e) {
      Get.snackbar(
        '错误',
        '录音停止失败：$e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFF6B6B),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  /// 删除音频
  void deleteAudio() {
    state.audioPath.value = '';
    state.recordDuration.value = 0;
  }

  /// 保存笔记
  Future<void> saveNote() async {
    if (!state.isFormValid) {
      Get.snackbar(
        '提示',
        '请输入内容或录制音频',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFF6B6B),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    state.isSaving.value = true;

    try {
      // TODO: 调用后端API保存笔记
      await Future.delayed(const Duration(seconds: 1)); // 模拟网络请求

      // 关闭创建笔记弹窗
      Get.back();
      // 再关闭创建来源选择弹窗
      Get.back();

      // 跳转到笔记详情页
      Get.toNamed(AppRoutes.noteDetail);

      Get.snackbar(
        '成功',
        '笔记创建成功',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4ECDC4),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      Get.snackbar(
        '错误',
        '笔记创建失败：$e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFF6B6B),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      state.isSaving.value = false;
    }
  }

  /// 清空内容
  void clearContent() {
    contentController.clear();
    deleteAudio();
  }
}
