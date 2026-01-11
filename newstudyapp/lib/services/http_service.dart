import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:newstudyapp/config/api_config.dart';
import 'package:newstudyapp/models/agent_models.dart';
import 'package:newstudyapp/models/note_models.dart';
import 'package:newstudyapp/pages/note_detail/note_detail_state.dart';

/// HTTP 网络请求服务（单例模式）
///
/// 单例模式实现原理：
/// 1. 私有构造函数 `_internal()` - 防止外部直接创建实例
/// 2. 静态私有实例 `_instance` - 保存唯一的实例对象
/// 3. 工厂构造函数 `factory HttpService()` - 对外暴露的唯一入口，总是返回同一实例
///
/// 优势：
/// - 全局唯一：整个应用中只有一个 HttpService 实例
/// - 线程安全：Dart 保证静态变量初始化的线程安全性
/// - 懒加载：首次调用时才创建实例，节省资源
/// - 资源共享：所有地方共用同一个 Dio 实例，避免重复配置
class HttpService {
  // 工厂构造函数：对外暴露的创建方法
  // 每次调用 HttpService() 都会返回 _instance，不会创建新对象
  // 使用方式：final http = HttpService();
  factory HttpService() => _instance;

  // 静态私有实例：全局唯一的 HttpService 对象
  // static - 属于类本身，不属于任何实例
  // final - 一旦赋值不可修改
  // 这行代码只会执行一次，在类首次使用时初始化
  static final HttpService _instance = HttpService._internal();

  // Dio 实例：用于发送 HTTP 请求
  late final Dio _dio;

  // 私有构造函数：只能在类内部调用，外部无法使用
  // 这里进行 Dio 的初始化配置
  // 命名构造函数前的 _ 表示私有，防止外部调用 HttpService._internal()
  HttpService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // 添加请求日志拦截器
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        requestHeader: false,
        responseHeader: false,
      ),
    );
  }

  /// 获取 Dio 实例（用于特殊场景）
  Dio get dio => _dio;

  // ==================== Agent 相关接口 ====================

  /// 运行好奇学生 Agent（提问获取新词汇）
  Future<AgentResponse> runCuriousStudent(String text) async {
    try {
      final response = await _dio.post(
        ApiConfig.curiousStudent,
        data: {'text': text},
      );
      return AgentResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 运行简单解释器 Agent（获取词汇解释）
  Future<AgentResponse> runSimpleExplainer(String text) async {
    try {
      final response = await _dio.post(
        ApiConfig.simpleExplainer,
        data: {'text': text},
      );
      return AgentResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Topic 相关接口 ====================

  /// 获取术语列表
  Future<TermsResponse> fetchTerms({String category = 'economics'}) async {
    try {
      final response = await _dio.get(
        ApiConfig.fetchTerms,
        queryParameters: {'category': category},
      );
      return TermsResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Notes 相关接口 ====================

  /// 从笔记文本中抽取待学习词语
  Future<NoteExtractResponse> extractTermsFromNote({
    required String text,
    String? title,
    int maxTerms = 30,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.extractNoteTerms,
        data: {
          'title': title,
          'text': text,
          'max_terms': maxTerms,
        },
      );
      return NoteExtractResponse.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 从笔记文件中抽取待学习词语（PDF/DOCX/TXT/图片）
  Future<NoteExtractResponse> extractTermsFromNoteFile({
    required String filePath,
    required String filename,
    int maxTerms = 30,
  }) async {
    try {
      // 读取文件内容
      Uint8List fileBytes;

      // 处理HarmonyOS的file:// URI格式
      String actualPath = filePath;
      if (filePath.startsWith('file://')) {
        actualPath = filePath.substring(7); // 移除 'file://' 前缀
      }

      try {
        final file = File(actualPath);
        fileBytes = await file.readAsBytes();
      } catch (e) {
        // 如果直接读取失败，尝试使用HarmonyOS原生方式
        debugPrint('[HttpService] 直接读取文件失败: $e');
        throw Exception('无法读取文件: $e');
      }

      final formData = FormData.fromMap({
        'max_terms': maxTerms,
        'file': MultipartFile.fromBytes(
          fileBytes,
          filename: filename,
        ),
      });

      final response = await _dio.post(
        ApiConfig.extractNoteTermsFile,
        data: formData,
      );
      return NoteExtractResponse.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      debugPrint('[HttpService] 提取文件词语失败: $e');
      throw Exception('解析文件失败：$e');
    }
  }

  // ==================== 笔记管理接口 ====================

  /// 获取笔记列表
  Future<NotesListResponse> listNotes() async {
    try {
      final url = '${ApiConfig.baseUrl}${ApiConfig.listNotes}';
      print('[HttpService] 请求笔记列表: $url');
      final response = await _dio.get(
        ApiConfig.listNotes,
      );
      print('[HttpService] 响应状态码: ${response.statusCode}');
      print('[HttpService] 响应数据: ${response.data}');
      return NotesListResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      print('[HttpService] 请求失败: ${e.message}');
      print('[HttpService] 错误类型: ${e.type}');
      if (e.response != null) {
        print('[HttpService] 响应状态码: ${e.response?.statusCode}');
        print('[HttpService] 响应数据: ${e.response?.data}');
      }
      throw _handleError(e);
    } catch (e) {
      print('[HttpService] 未知错误: $e');
      rethrow;
    }
  }

  /// 创建笔记
  Future<NoteResponse> createNote({
    String? title,
    required String content,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.createNote,
        data: {
          'title': title,
          'content': content,
        },
      );
      return NoteResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 获取笔记详情
  Future<NoteResponse> getNote(String noteId) async {
    try {
      final response = await _dio.get(
        ApiConfig.getNote(noteId),
      );
      return NoteResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 更新笔记
  Future<NoteResponse> updateNote({
    required String noteId,
    String? title,
    String? content,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (content != null) data['content'] = content;

      final response = await _dio.put(
        ApiConfig.updateNote(noteId),
        data: data,
      );
      return NoteResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 删除笔记
  Future<void> deleteNote(String noteId) async {
    try {
      debugPrint('[HttpService] 准备删除笔记，noteId: $noteId');
      debugPrint('[HttpService] 删除接口URL: ${ApiConfig.deleteNote(noteId)}');

      final response = await _dio.delete(
        ApiConfig.deleteNote(noteId),
      );

      // 打印响应以便调试
      debugPrint('[HttpService] 删除笔记响应状态码: ${response.statusCode}');
      debugPrint('[HttpService] 删除笔记响应数据: ${response.data}');

      // 验证响应
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('删除失败：状态码 ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('[HttpService] 删除笔记失败: ${e.message}');
      debugPrint('[HttpService] 响应状态码: ${e.response?.statusCode}');
      debugPrint('[HttpService] 响应数据: ${e.response?.data}');
      debugPrint('[HttpService] 错误类型: ${e.type}');
      throw _handleError(e);
    } catch (e) {
      debugPrint('[HttpService] 删除笔记未知错误: $e');
      rethrow;
    }
  }

  /// 生成闪词卡片
  Future<FlashCardGenerateResponse> generateFlashCards({
    required String noteId,
    int maxTerms = 30,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.generateFlashCards(noteId),
        data: {
          'max_terms': maxTerms,
        },
      );
      return FlashCardGenerateResponse.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 获取闪词卡片列表
  Future<FlashCardListResponse> getFlashCards(String noteId) async {
    try {
      final response = await _dio.get(
        ApiConfig.getFlashCards(noteId),
      );
      return FlashCardListResponse.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 获取闪词学习进度
  Future<FlashCardProgress> getFlashCardProgress(String noteId) async {
    try {
      final response = await _dio.get(
        ApiConfig.getFlashCardProgress(noteId),
      );
      return flashCardProgressFromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 更新闪词卡片状态
  Future<void> updateFlashCardStatus(
    String noteId,
    String term,
    String status,
  ) async {
    try {
      await _dio.put(
        ApiConfig.updateFlashCardStatus(noteId),
        data: {
          'term': term,
          'status': status,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 添加困惑词到闪词卡片
  Future<void> addConfusedTerms(
    String noteId,
    List<String> terms, {
    String status = 'needsReview',
  }) async {
    try {
      debugPrint(
          '[HttpService] 添加困惑词: noteId=$noteId, terms=$terms, status=$status');
      await _dio.post(
        ApiConfig.addConfusedTerms(noteId),
        data: {
          'terms': terms,
          'status': status,
        },
      );
      debugPrint('[HttpService] 困惑词添加成功');
    } on DioException catch (e) {
      debugPrint('[HttpService] 添加困惑词失败: $e');
      throw _handleError(e);
    }
  }

  // ==================== 学习统计接口 ====================

  /// 获取学习统计
  Future<LearningStatisticsResponse> getLearningStatistics() async {
    try {
      debugPrint('[HttpService] 获取学习统计: ${ApiConfig.getStatistics}');
      final response = await _dio.get(ApiConfig.getStatistics);
      debugPrint(
          '[HttpService] 获取学习统计响应: ${response.statusCode} ${response.data}');
      return LearningStatisticsResponse.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[HttpService] 获取学习统计失败: $e');
      throw _handleError(e);
    }
  }

  /// 获取今日复习统计
  Future<TodayReviewStatisticsResponse> getTodayReviewStatistics() async {
    try {
      debugPrint(
          '[HttpService] 获取今日复习统计: ${ApiConfig.getTodayReviewStatistics}');
      final response = await _dio.get(ApiConfig.getTodayReviewStatistics);
      debugPrint(
          '[HttpService] 获取今日复习统计响应: ${response.statusCode} ${response.data}');
      return TodayReviewStatisticsResponse.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[HttpService] 获取今日复习统计失败: $e');
      throw _handleError(e);
    }
  }

  /// 获取需要复习的闪词卡片列表
  Future<ReviewFlashCardsResponse> getReviewFlashCards(
      {bool includeAll = false}) async {
    try {
      final url = includeAll
          ? '${ApiConfig.getReviewFlashCards}?include_all=true'
          : ApiConfig.getReviewFlashCards;
      debugPrint('[HttpService] 获取复习卡片列表: $url');
      final response = await _dio.get(url);
      debugPrint(
          '[HttpService] 获取复习卡片列表响应: ${response.statusCode} ${response.data}');
      return ReviewFlashCardsResponse.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('[HttpService] 获取复习卡片列表失败: $e');
      throw _handleError(e);
    }
  }

  // ==================== 通用请求方法 ====================

  /// 通用 GET 请求
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 通用 POST 请求
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== 错误处理 ====================

  /// 处理 Dio 异常
  Exception _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('请求超时，请检查网络连接');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        final message = error.response?.data?.toString() ?? '请求失败';
        return Exception('服务器错误($statusCode): $message');
      case DioExceptionType.cancel:
        return Exception('请求已取消');
      case DioExceptionType.connectionError:
        return Exception('网络连接失败，请检查网络设置');
      default:
        return Exception(error.message ?? '未知错误');
    }
  }

  /// 关闭服务（通常在应用退出时调用）
  void dispose() {
    _dio.close();
  }
}
