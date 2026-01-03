import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// HarmonyOS 原生文件选择器服务
class HarmonyOSFilePickerService {
  static const MethodChannel _channel = MethodChannel('com.newstudyapp.file_picker');

  /// 选择文件
  /// 
  /// [allowedExtensions] 允许的文件扩展名列表，例如 ['pdf', 'docx', 'txt', 'md']
  /// 如果为空，则允许选择所有文件类型
  /// 
  /// 返回选中的文件列表，每个文件包含：
  /// - name: 文件名
  /// - path: 文件路径（可能是 URI）
  /// - uri: 文件 URI
  /// - size: 文件大小（字节）
  static Future<List<Map<String, dynamic>>> pickFiles({
    List<String>? allowedExtensions,
  }) async {
    try {
      final result = await _channel.invokeMethod('pickFiles', {
        if (allowedExtensions != null) 'allowedExtensions': allowedExtensions,
      });
      
      if (result == null) {
        return [];
      }
      
      // 将结果转换为 List<Map<String, dynamic>>
      if (result is List) {
        return result.cast<Map<dynamic, dynamic>>().map((item) {
          return {
            'name': item['name'] as String? ?? '',
            'path': item['path'] as String? ?? item['uri'] as String? ?? '',
            'uri': item['uri'] as String? ?? item['path'] as String? ?? '',
            'size': item['size'] as int? ?? 0,
          };
        }).toList();
      }
      
      return [];
    } on PlatformException catch (e) {
      throw Exception('文件选择失败: ${e.message}');
    } catch (e) {
      throw Exception('文件选择失败: $e');
    }
  }

  /// 选择图片
  static Future<List<Map<String, dynamic>>> pickImages() async {
    try {
      debugPrint('[HarmonyOSFilePickerService] 调用 pickImages 方法');
      final result = await _channel.invokeMethod('pickImages');
      debugPrint('[HarmonyOSFilePickerService] pickImages 返回结果: $result');
      
      if (result == null) {
        debugPrint('[HarmonyOSFilePickerService] pickImages 返回 null');
        return [];
      }
      
      if (result is List) {
        debugPrint('[HarmonyOSFilePickerService] pickImages 返回列表，数量: ${result.length}');
        return result.cast<Map<dynamic, dynamic>>().map((item) {
          return {
            'name': item['name'] as String? ?? '',
            'path': item['path'] as String? ?? item['uri'] as String? ?? '',
            'uri': item['uri'] as String? ?? item['path'] as String? ?? '',
            'size': item['size'] as int? ?? 0,
          };
        }).toList();
      }
      
      debugPrint('[HarmonyOSFilePickerService] pickImages 返回类型不是 List: ${result.runtimeType}');
      return [];
    } on PlatformException catch (e) {
      debugPrint('[HarmonyOSFilePickerService] pickImages PlatformException: ${e.message}, code: ${e.code}, details: ${e.details}');
      throw Exception('图片选择失败: ${e.message}');
    } catch (e) {
      debugPrint('[HarmonyOSFilePickerService] pickImages 异常: $e');
      throw Exception('图片选择失败: $e');
    }
  }

  /// 拍照
  static Future<List<Map<String, dynamic>>> takePhoto() async {
    try {
      debugPrint('[HarmonyOSFilePickerService] 调用 takePhoto 方法');
      final result = await _channel.invokeMethod('takePhoto');
      debugPrint('[HarmonyOSFilePickerService] takePhoto 返回结果: $result');
      
      if (result == null) {
        debugPrint('[HarmonyOSFilePickerService] takePhoto 返回 null');
        return [];
      }
      
      if (result is List) {
        debugPrint('[HarmonyOSFilePickerService] takePhoto 返回列表，数量: ${result.length}');
        return result.cast<Map<dynamic, dynamic>>().map((item) {
          return {
            'name': item['name'] as String? ?? '',
            'path': item['path'] as String? ?? item['uri'] as String? ?? '',
            'uri': item['uri'] as String? ?? item['path'] as String? ?? '',
            'size': item['size'] as int? ?? 0,
          };
        }).toList();
      }
      
      debugPrint('[HarmonyOSFilePickerService] takePhoto 返回类型不是 List: ${result.runtimeType}');
      return [];
    } on PlatformException catch (e) {
      debugPrint('[HarmonyOSFilePickerService] takePhoto PlatformException: ${e.message}, code: ${e.code}, details: ${e.details}');
      throw Exception('拍照失败: ${e.message}');
    } catch (e) {
      debugPrint('[HarmonyOSFilePickerService] takePhoto 异常: $e');
      throw Exception('拍照失败: $e');
    }
  }
}
