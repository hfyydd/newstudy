import 'package:flutter/services.dart';
import 'dart:async';

/// HarmonyOS 原生语音识别服务
class SpeechRecognizerService {
  static const MethodChannel _channel = MethodChannel('com.newstudyapp.speech_recognizer');
  
  // 事件流控制器
  static final StreamController<SpeechRecognizerEvent> _eventController = 
      StreamController<SpeechRecognizerEvent>.broadcast();
  
  static Stream<SpeechRecognizerEvent> get events => _eventController.stream;
  
  static bool _isInitialized = false;

  /// 初始化事件监听
  static void _initEventListeners() {
    if (_isInitialized) return;
    
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onEvent') {
        final eventData = call.arguments as Map<dynamic, dynamic>;
        final event = eventData['event'] as String;
        final data = eventData['data'] as Map<dynamic, dynamic>;
        
        switch (event) {
          case 'onStart':
            _eventController.add(SpeechRecognizerEvent(
              type: SpeechEventType.onStart,
              sessionId: data['sessionId'] as String?,
              message: data['message'] as String?,
            ));
            break;
          case 'onResult':
            _eventController.add(SpeechRecognizerEvent(
              type: SpeechEventType.onResult,
              sessionId: data['sessionId'] as String?,
              result: data['result'] as String?,
              isFinal: data['isFinal'] as bool? ?? false,
            ));
            break;
          case 'onComplete':
            _eventController.add(SpeechRecognizerEvent(
              type: SpeechEventType.onComplete,
              sessionId: data['sessionId'] as String?,
              message: data['message'] as String?,
            ));
            break;
          case 'onError':
            _eventController.add(SpeechRecognizerEvent(
              type: SpeechEventType.onError,
              sessionId: data['sessionId'] as String?,
              errorCode: data['errorCode'] as int?,
              errorMessage: data['errorMessage'] as String?,
            ));
            break;
        }
      }
    });
    
    _isInitialized = true;
  }

  /// 初始化语音识别引擎
  static Future<bool> initialize() async {
    try {
      _initEventListeners();
      final result = await _channel.invokeMethod<bool>('initialize');
      if (result == null) {
        // 如果返回 null，可能是方法调用失败，尝试检查通道是否可用
        print('SpeechRecognizer initialize returned null, channel may not be available');
        return false;
      }
      return result;
    } on PlatformException catch (e) {
      print('SpeechRecognizer initialize PlatformException: ${e.code} - ${e.message}');
      // 如果是 MissingPluginException，说明插件未注册
      if (e.code == 'MissingPluginException' || e.message?.contains('No implementation found') == true) {
        print('SpeechRecognizer plugin not registered. Make sure GeneratedPluginRegistrant includes SpeechRecognizerPlugin.');
      }
      return false;
    } catch (e) {
      print('SpeechRecognizer initialize error: $e');
      return false;
    }
  }

  /// 开始语音识别
  static Future<bool> startListening() async {
    try {
      final result = await _channel.invokeMethod<bool>('startListening');
      return result ?? false;
    } catch (e) {
      print('SpeechRecognizer startListening error: $e');
      return false;
    }
  }

  /// 停止语音识别
  static Future<bool> stopListening() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopListening');
      return result ?? false;
    } catch (e) {
      print('SpeechRecognizer stopListening error: $e');
      return false;
    }
  }

  /// 取消语音识别
  static Future<bool> cancel() async {
    try {
      final result = await _channel.invokeMethod<bool>('cancel');
      return result ?? false;
    } catch (e) {
      print('SpeechRecognizer cancel error: $e');
      return false;
    }
  }

  /// 检查是否可用
  static Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 释放资源
  static Future<bool> shutdown() async {
    try {
      final result = await _channel.invokeMethod<bool>('shutdown');
      return result ?? false;
    } catch (e) {
      print('SpeechRecognizer shutdown error: $e');
      return false;
    }
  }

  /// 释放事件流
  static void dispose() {
    _eventController.close();
  }
}

/// 语音识别事件类型
enum SpeechEventType {
  onStart,
  onResult,
  onComplete,
  onError,
}

/// 语音识别事件
class SpeechRecognizerEvent {
  final SpeechEventType type;
  final String? sessionId;
  final String? message;
  final String? result;
  final bool isFinal;
  final int? errorCode;
  final String? errorMessage;

  SpeechRecognizerEvent({
    required this.type,
    this.sessionId,
    this.message,
    this.result,
    this.isFinal = false,
    this.errorCode,
    this.errorMessage,
  });
}
