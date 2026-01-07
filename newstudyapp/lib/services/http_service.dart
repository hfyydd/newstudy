import 'package:dio/dio.dart';
import 'package:newstudyapp/config/api_config.dart';
import 'package:newstudyapp/models/agent_models.dart';
import 'package:newstudyapp/models/note_models.dart';

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
      return NoteExtractResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 从笔记文件中抽取待学习词语（PDF/DOCX/TXT）
  Future<NoteExtractResponse> extractTermsFromNoteFile({
    required String filePath,
    required String filename,
    int maxTerms = 30,
  }) async {
    try {
      final formData = FormData.fromMap({
        'max_terms': maxTerms,
        'file': await MultipartFile.fromFile(
          filePath,
          filename: filename,
        ),
      });
      final response = await _dio.post(
        ApiConfig.extractNoteTermsFile,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );
      return NoteExtractResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 生成智能笔记（AI生成Markdown笔记+闪词列表）
  Future<SmartNoteResponse> generateSmartNote({
    required String userInput,
    int maxTerms = 30,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.generateSmartNote,
        data: {
          'user_input': userInput,
          'max_terms': maxTerms,
        },
        options: Options(
          // 智能笔记生成可能需要较长时间
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
        ),
      );
      return SmartNoteResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 创建笔记（生成并保存到数据库）
  Future<CreateNoteResponse> createNote({
    required String userInput,
    int maxTerms = 30,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.createNote,
        data: {
          'user_input': userInput,
          'max_terms': maxTerms,
        },
        options: Options(
          // 创建笔记可能需要较长时间（AI生成+数据库保存）
          receiveTimeout: const Duration(seconds: 90),
          sendTimeout: const Duration(seconds: 90),
        ),
      );
      return CreateNoteResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 获取笔记列表
  Future<NotesListResponse> listNotes({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.listNotes,
        queryParameters: {
          'skip': skip,
          'limit': limit,
        },
      );
      return NotesListResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 获取笔记详情
  Future<Map<String, dynamic>> getNoteDetail(int noteId) async {
    try {
      final response = await _dio.get(ApiConfig.getNoteDetail(noteId));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 设置笔记默认角色
  Future<Map<String, dynamic>> setNoteDefaultRole({
    required int noteId,
    required String roleId,
  }) async {
    try {
      final response = await _dio.patch(
        ApiConfig.setNoteDefaultRole(noteId),
        data: {'role_id': roleId},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== 学习相关接口 ====================

  /// 获取学习角色列表
  Future<RolesResponse> getLearningRoles() async {
    try {
      final response = await _dio.get(ApiConfig.learningRoles);
      return RolesResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 评估用户解释
  Future<EvaluateResponse> evaluateExplanation({
    required int cardId,
    required int noteId,
    required String selectedRole,
    required String userExplanation,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.evaluateExplanation,
        data: {
          'card_id': cardId,
          'note_id': noteId,
          'selected_role': selectedRole,
          'user_explanation': userExplanation,
        },
        options: Options(
          // AI 评估可能需要较长时间
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
        ),
      );
      return EvaluateResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 更新闪词卡片状态
  Future<CardStatusResponse> updateCardStatus({
    required int cardId,
    required String status,
  }) async {
    try {
      final response = await _dio.patch(
        ApiConfig.updateCardStatus(cardId),
        data: {'status': status},
      );
      return CardStatusResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 获取闪词卡片详情（包含学习历史）
  Future<FlashCard> getCardDetail(int cardId) async {
    try {
      final response = await _dio.get(ApiConfig.getCardDetail(cardId));
      return FlashCard.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== 学习中心相关接口 ====================

  /// 获取学习中心统计数据
  Future<StudyCenterStatistics> getStudyCenterStatistics() async {
    try {
      final response = await _dio.get(ApiConfig.studyCenterStatistics);
      return StudyCenterStatistics.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 获取今日复习词条列表
  Future<FlashCardListResponse> getTodayReviewCards({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.todayReviewCards,
        queryParameters: {
          'skip': skip,
          'limit': limit,
        },
      );
      return FlashCardListResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 获取薄弱词条列表（需巩固、需改进、未掌握）
  Future<FlashCardListResponse> getWeakCards({
    int skip = 0,
    int limit = 100,
    String? status, // 'NEEDS_REVIEW'（需巩固）, 'NEEDS_IMPROVE', 'NOT_MASTERED'
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'skip': skip,
        'limit': limit,
      };
      if (status != null) {
        queryParams['status'] = status;
      }
      final response = await _dio.get(
        ApiConfig.weakCards,
        queryParameters: queryParams,
      );
      return FlashCardListResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 获取已掌握词条列表
  Future<FlashCardListResponse> getMasteredCards({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.masteredCards,
        queryParameters: {
          'skip': skip,
          'limit': limit,
        },
      );
      return FlashCardListResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 获取全部词条列表
  Future<FlashCardListResponse> getAllCards({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.allCards,
        queryParameters: {
          'skip': skip,
          'limit': limit,
        },
      );
      return FlashCardListResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 按笔记分类获取词条列表
  Future<CardsByNoteResponse> getCardsByNote({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.cardsByNote,
        queryParameters: {
          'skip': skip,
          'limit': limit,
        },
      );
      return CardsByNoteResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
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
