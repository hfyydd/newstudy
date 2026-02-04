import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:newstudyapp/routes/app_routes.dart';
import 'package:newstudyapp/services/toast_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// 从图片创建笔记控制器
class CreateNoteFromImageController extends GetxController {
  final ImagePicker _imagePicker = ImagePicker();

  /// 选中的图片文件
  final Rx<XFile?> selectedImage = Rx<XFile?>(null);

  /// 加载状态
  final RxBool isLoading = false.obs;

  /// 加载消息
  final RxString loadingMessage = '正在识别图片内容...'.obs;

  @override
  void onInit() {
    super.onInit();
    // 每次打开页面时清空选中的图片
    selectedImage.value = null;
  }

  @override
  void onReady() {
    super.onReady();
    // 确保清空选中的图片
    selectedImage.value = null;
  }

  /// 请求相机权限
  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// 请求相册权限
  Future<bool> _requestPhotoPermission() async {
    if (Platform.isAndroid) {
      // Android 13+ (API 33+) 使用 READ_MEDIA_IMAGES
      // Android 12 及以下使用 READ_EXTERNAL_STORAGE
      // 先检查 photos 权限（Android 13+）
      PermissionStatus photosStatus = await Permission.photos.status;
      if (photosStatus.isGranted) {
        return true;
      }
      if (photosStatus.isDenied) {
        photosStatus = await Permission.photos.request();
        if (photosStatus.isGranted) {
          return true;
        }
      }
      
      // 降级到 storage 权限（Android < 13）
      PermissionStatus storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) {
        return true;
      }
      if (storageStatus.isDenied) {
        storageStatus = await Permission.storage.request();
        if (storageStatus.isGranted) {
          return true;
        }
      }
      
      return false;
    } else {
      // iOS 需要照片库权限
      PermissionStatus status = await Permission.photos.status;
      if (status.isGranted) {
        return true;
      }
      if (status.isDenied) {
        status = await Permission.photos.request();
        return status.isGranted;
      }
      // 如果被永久拒绝，返回 false
      return false;
    }
  }

  /// 从相机拍照
  Future<void> pickImageFromCamera() async {
    try {
      // image_picker 会自动处理权限请求，我们直接调用
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // 压缩质量，减少文件大小
      );

      if (image != null) {
        selectedImage.value = image;
      } else {
        // 用户取消了拍照，不需要提示
        debugPrint('用户取消了拍照');
      }
    } on PlatformException catch (e) {
      // 处理平台异常（通常是权限问题）
      debugPrint('拍照失败 (PlatformException): $e');
      if (e.code == 'camera_access_denied' || 
          e.code == 'permission_denied' ||
          e.message?.contains('permission') == true ||
          e.message?.contains('权限') == true) {
        ToastService.showError('需要相机权限才能拍照，请在设置中授予权限');
      } else {
        ToastService.showError('拍照失败: ${e.message ?? "未知错误"}');
      }
    } catch (e) {
      // 处理其他异常
      debugPrint('拍照失败: $e');
      final errorMsg = e.toString();
      if (errorMsg.contains('permission') || 
          errorMsg.contains('权限') ||
          errorMsg.contains('denied')) {
        ToastService.showError('需要相机权限才能拍照，请在设置中授予权限');
      } else {
        ToastService.showError('拍照失败: $e');
      }
    }
  }

  /// 从相册选择图片
  Future<void> pickImageFromGallery() async {
    try {
      // image_picker 会自动处理权限请求，我们直接调用
      // 如果权限被拒绝，image_picker 会抛出异常或返回 null
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // 压缩质量，减少文件大小
      );

      if (image != null) {
        selectedImage.value = image;
      } else {
        // 用户取消了选择，不需要提示
        debugPrint('用户取消了图片选择');
      }
    } on PlatformException catch (e) {
      // 处理平台异常（通常是权限问题）
      debugPrint('选择图片失败 (PlatformException): $e');
      if (e.code == 'photo_library_access_denied' || 
          e.code == 'permission_denied' ||
          e.message?.contains('permission') == true ||
          e.message?.contains('权限') == true) {
        ToastService.showError('需要相册权限才能选择图片，请在设置中授予权限');
      } else {
        ToastService.showError('选择图片失败: ${e.message ?? "未知错误"}');
      }
    } catch (e) {
      // 处理其他异常
      debugPrint('选择图片失败: $e');
      final errorMsg = e.toString();
      if (errorMsg.contains('permission') || 
          errorMsg.contains('权限') ||
          errorMsg.contains('denied')) {
        ToastService.showError('需要相册权限才能选择图片，请在设置中授予权限');
      } else {
        ToastService.showError('选择图片失败: $e');
      }
    }
  }

  /// 将图片文件转换为 Base64
  Future<String?> _imageToBase64(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      debugPrint('图片转Base64失败: $e');
      return null;
    }
  }

  /// 创建笔记（跳转到详情页，由详情页负责创建）
  Future<void> createNote() async {
    if (selectedImage.value == null) {
      ToastService.showError('请先选择图片');
      return;
    }

    try {
      // 将图片转换为 Base64
      final base64String = await _imageToBase64(selectedImage.value!);
      if (base64String == null) {
        ToastService.showError('图片处理失败，请重试');
        return;
      }

      // 清空选中的图片
      selectedImage.value = null;

      // 延迟一小段时间，确保图片选择框完全关闭后再跳转
      await Future.delayed(const Duration(milliseconds: 200));

      // 跳转到笔记详情页，传递 imageBase64，让详情页负责创建笔记并显示 Loading
      Get.toNamed(
        AppRoutes.noteDetail,
        arguments: {
          'imageBase64': base64String,
        },
      );
    } catch (e) {
      ToastService.showError('图片处理失败: $e');
      debugPrint('图片处理失败: $e');
    }
  }
}
