import 'package:get/get.dart';
import 'package:newstudyapp/models/note_models.dart';

/// 首页状态
class HomeState {
  /// 笔记列表
  final RxList<NoteListItemResponse> notes = <NoteListItemResponse>[].obs;

  /// 是否正在加载
  final RxBool isLoading = false.obs;

  /// 错误信息
  final RxnString errorMessage = RxnString();
}
