import 'package:get/get.dart';

/// 创建笔记页面状态
class CreateNoteState {
  /// 笔记内容
  final RxString noteContent = ''.obs;

  /// 是否正在保存
  final RxBool isSaving = false.obs;

  /// 是否正在录音
  final RxBool isRecording = false.obs;

  /// 录音时长（秒）
  final RxInt recordDuration = 0.obs;

  /// 音频文件路径
  final RxString audioPath = ''.obs;

  /// 内容输入是否有效
  bool get isContentValid => noteContent.value.trim().isNotEmpty;

  /// 是否有音频
  bool get hasAudio => audioPath.value.isNotEmpty;

  /// 表单是否有效（内容或音频至少有一个）
  bool get isFormValid => isContentValid || hasAudio;
}
