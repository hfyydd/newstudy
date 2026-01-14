import { FlutterEngine, MethodChannel } from '@ohos/flutter_ohos';
import hilog from '@ohos.hilog';
import { BusinessError } from '@kit.BasicServicesKit';
import picker from '@ohos.file.picker';
import fs from '@ohos.file.fs';
import { cameraPicker } from '@kit.CameraKit';
import { camera } from '@kit.CameraKit';
import common from '@ohos.app.ability.common';

const TAG = "FilePickerPlugin";
const CHANNEL_NAME = "com.newstudyapp.file_picker";

// 定义文件信息接口
interface FileInfo {
  name: string;
  path: string;
  uri: string;
  size: number;
}

// 定义方法参数接口
interface PickFilesArgs {
  allowedExtensions?: string[];
}

// 定义 MethodCall 接口
interface MethodCall {
  method: string;
  argument: Object | undefined;
}

// 定义 MethodResult 接口
interface MethodResult {
  success: (value: Object | null) => void;
  error: (code: string, message: string, details: Object | null) => void;
}

export class FilePickerPlugin {
  private static channel: MethodChannel | null = null;
  private static context: common.UIAbilityContext | null = null;

  static setContext(context: common.UIAbilityContext) {
    FilePickerPlugin.context = context;
    hilog.info(0x0000, TAG, "FilePickerPlugin context set");
  }

  static registerWith(flutterEngine: FlutterEngine) {
    try {
      hilog.info(0x0000, TAG, "Registering FilePickerPlugin with channel: %{public}s", CHANNEL_NAME);
      const channel = new MethodChannel(flutterEngine.dartExecutor, CHANNEL_NAME);
      hilog.info(0x0000, TAG, "MethodChannel created successfully");
      
      channel.setMethodCallHandler({
        onMethodCall: (call: MethodCall, result: MethodResult) => {
          hilog.info(0x0000, TAG, "Method call received: %{public}s", call.method);
          FilePickerPlugin.handleMethodCall(call, result);
        }
      });
      hilog.info(0x0000, TAG, "Method call handler set successfully");
      
      FilePickerPlugin.channel = channel;
      hilog.info(0x0000, TAG, "FilePickerPlugin registered successfully");
    } catch (e) {
      hilog.error(0x0000, TAG, "Failed to register FilePickerPlugin");
      hilog.error(0x0000, TAG, "Error type: %{public}s", typeof e);
      hilog.error(0x0000, TAG, "Error message: %{public}s", (e as Error)?.message || "Unknown");
      hilog.error(0x0000, TAG, "Error details: %{public}s", JSON.stringify(e));
      if ((e as Error)?.stack) {
        hilog.error(0x0000, TAG, "Error stack: %{public}s", (e as Error).stack);
      }
    }
  }

  private static async handleMethodCall(call: MethodCall, result: MethodResult) {
    try {
      const method = call.method;
      const args = call.argument as PickFilesArgs | undefined;

      hilog.info(0x0000, TAG, "Method called: %{public}s", method);
      hilog.info(0x0000, TAG, "Available methods: pickFiles, pickImages, takePhoto");

      switch (method) {
        case 'pickFiles':
          hilog.info(0x0000, TAG, "Handling pickFiles method");
          await FilePickerPlugin.pickFiles(args, result);
          break;
        case 'pickImages':
          hilog.info(0x0000, TAG, "Handling pickImages method");
          await FilePickerPlugin.pickImages(result);
          break;
        case 'takePhoto':
          hilog.info(0x0000, TAG, "Handling takePhoto method");
          await FilePickerPlugin.takePhoto(result);
          break;
        default:
          hilog.error(0x0000, TAG, "Unknown method: %{public}s", method);
          hilog.error(0x0000, TAG, "Available methods are: pickFiles, pickImages, takePhoto");
          result.error("UNKNOWN_METHOD", `Unknown method: ${method}. Available methods: pickFiles, pickImages, takePhoto`, null);
          break;
      }
    } catch (e) {
      hilog.error(0x0000, TAG, "Error handling method call: %{public}s", (e as Error)?.message || "Unknown");
      result.error("EXCEPTION", (e as Error)?.message || "Unknown error", null);
    }
  }

  /**
   * 选择文件
   * @param args 参数对象，包含 allowedExtensions (可选)
   * @param result 结果回调
   */
  private static async pickFiles(args: PickFilesArgs | undefined, result: MethodResult) {
    try {
      hilog.info(0x0000, TAG, "Starting file picker");

      // 创建文档选择器（不需要上下文，picker 会自动处理）
      const documentViewPicker = new picker.DocumentViewPicker();
      
      // 设置文件类型过滤（如果提供了 allowedExtensions）
      const allowedExtensions = args?.allowedExtensions;
      if (allowedExtensions && allowedExtensions.length > 0) {
        // 创建选择选项
        const documentSelectOptions: picker.DocumentSelectOptions = {
          fileSuffixFilters: allowedExtensions
        };
        
        documentViewPicker.select(documentSelectOptions).then((documentSelectResult: Array<string>) => {
          hilog.info(0x0000, TAG, "File picker result: %{public}s", JSON.stringify(documentSelectResult));
          
          if (documentSelectResult && documentSelectResult.length > 0) {
            const fileResults: FileInfo[] = [];
            
            documentSelectResult.forEach((uri: string) => {
              try {
                hilog.info(0x0000, TAG, "Processing URI: %{public}s", uri);
                
                // 确保URI有正确的格式
                let correctUri = uri;
                if (!uri.startsWith('file://') && !uri.startsWith('/')) {
                  // 如果没有 file:// 前缀，尝试直接访问
                  correctUri = uri;
                }
                
                // 打开文件获取信息
                const file = fs.openSync(correctUri, fs.OpenMode.READ_ONLY);
                const stat = fs.statSync(file.fd);
                hilog.info(0x0000, TAG, "File opened successfully, size: %{public}d", stat.size);
                
                // 拷贝到缓存目录
                const cachedPath = FilePickerPlugin.copyFileToCache(correctUri);
                hilog.info(0x0000, TAG, "Cached path: %{public}s", cachedPath);
                
                // 从 URI 中提取文件名
                let fileName = correctUri.split('/').pop() || 'unknown';
                if (fileName.includes('?')) {
                  fileName = fileName.split('?')[0];
                }
                // URL解码
                try {
                  fileName = decodeURIComponent(fileName);
                } catch (e) {}
                
                const fileInfoObj: FileInfo = {
                  name: fileName,
                  path: cachedPath,
                  uri: correctUri,
                  size: stat.size
                };
                fileResults.push(fileInfoObj);
                
                fs.closeSync(file);
              } catch (fileError) {
                hilog.error(0x0000, TAG, "Error processing file: %{public}s", (fileError as Error)?.message || "Unknown");
                hilog.error(0x0000, TAG, "Error details: %{public}s", JSON.stringify(fileError));
              }
            });
            
            if (fileResults.length > 0) {
              hilog.info(0x0000, TAG, "Returning %{public}d files", fileResults.length);
              result.success(fileResults);
            } else {
              hilog.info(0x0000, TAG, "No files selected");
              result.success([]);
            }
          } else {
            hilog.info(0x0000, TAG, "User cancelled file selection");
            result.success([]);
          }
        }).catch((error: BusinessError) => {
          hilog.error(0x0000, TAG, "File picker error: %{public}s", error.message);
          result.error("PICKER_ERROR", error.message, null);
        });
      } else {
        // 没有文件类型限制，使用默认选择器
        documentViewPicker.select().then((documentSelectResult: Array<string>) => {
          hilog.info(0x0000, TAG, "File picker result: %{public}s", JSON.stringify(documentSelectResult));
          
          if (documentSelectResult && documentSelectResult.length > 0) {
            const fileResults: FileInfo[] = [];
            
            documentSelectResult.forEach((uri: string) => {
              try {
                hilog.info(0x0000, TAG, "Processing URI: %{public}s", uri);
                
                let correctUri = uri;
                if (!uri.startsWith('file://') && !uri.startsWith('/')) {
                  correctUri = uri;
                }
                
                const file = fs.openSync(correctUri, fs.OpenMode.READ_ONLY);
                const stat = fs.statSync(file.fd);
                hilog.info(0x0000, TAG, "File opened, size: %{public}d", stat.size);
                
                // 拷贝到缓存目录
                const cachedPath = FilePickerPlugin.copyFileToCache(correctUri);
                hilog.info(0x0000, TAG, "Cached path: %{public}s", cachedPath);
                
                let fileName = uri.split('/').pop() || 'unknown';
                if (fileName.includes('?')) {
                  fileName = fileName.split('?')[0];
                }
                try {
                  fileName = decodeURIComponent(fileName);
                } catch (e) {}
                
                const fileInfoObj: FileInfo = {
                  name: fileName,
                  path: cachedPath,
                  uri: correctUri,
                  size: stat.size
                };
                fileResults.push(fileInfoObj);
                
                fs.closeSync(file);
              } catch (fileError) {
                hilog.error(0x0000, TAG, "Error processing file: %{public}s", (fileError as Error)?.message || "Unknown");
                hilog.error(0x0000, TAG, "Error details: %{public}s", JSON.stringify(fileError));
              }
            });
            
            if (fileResults.length > 0) {
              result.success(fileResults);
            } else {
              result.success([]);
            }
          } else {
            result.success([]);
          }
        }).catch((error: BusinessError) => {
          hilog.error(0x0000, TAG, "File picker error: %{public}s", error.message);
          result.error("PICKER_ERROR", error.message, null);
        });
      }
    } catch (e) {
      hilog.error(0x0000, TAG, "Error in pickFiles: %{public}s", (e as Error)?.message || "Unknown");
      result.error("EXCEPTION", (e as Error)?.message || "Unknown error", null);
    }
  }

  /**
   * 选择图片
   * @param result 结果回调
   */
  private static async pickImages(result: MethodResult) {
    try {
      hilog.info(0x0000, TAG, "Starting photo picker");

      const photoViewPicker = new picker.PhotoViewPicker();
      const photoSelectOptions: picker.PhotoSelectOptions = {
        MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      };

      photoViewPicker.select(photoSelectOptions).then((photoSelectResult: picker.PhotoSelectResult) => {
        hilog.info(0x0000, TAG, "Photo picker result: %{public}s", JSON.stringify(photoSelectResult));
        
        if (photoSelectResult && photoSelectResult.photoUris.length > 0) {
          const fileResults: FileInfo[] = [];
          
          photoSelectResult.photoUris.forEach((uri: string) => {
            try {
              hilog.info(0x0000, TAG, "Processing image URI: %{public}s", uri);
              
              let correctUri = uri;
              if (!uri.startsWith('file://') && !uri.startsWith('/')) {
                correctUri = uri;
              }
              
              const file = fs.openSync(correctUri, fs.OpenMode.READ_ONLY);
              const stat = fs.statSync(file.fd);
              hilog.info(0x0000, TAG, "Image file opened, size: %{public}d", stat.size);
              
              // 拷贝到缓存目录
              const cachedPath = FilePickerPlugin.copyFileToCache(correctUri);
              hilog.info(0x0000, TAG, "Cached path: %{public}s", cachedPath);
              
              let fileName = uri.split('/').pop() || 'image.jpg';
              if (fileName.includes('?')) {
                fileName = fileName.split('?')[0];
              }
              try {
                fileName = decodeURIComponent(fileName);
              } catch (e) {}

              const fileInfoObj: FileInfo = {
                name: fileName,
                path: cachedPath,
                uri: correctUri,
                size: stat.size
              };
              fileResults.push(fileInfoObj);
              fs.closeSync(file);
            } catch (fileError) {
              hilog.error(0x0000, TAG, "Error processing image: %{public}s", (fileError as Error)?.message || "Unknown");
              hilog.error(0x0000, TAG, "Error details: %{public}s", JSON.stringify(fileError));
            }
          });
          
          result.success(fileResults);
        } else {
          result.success([]);
        }
      }).catch((error: BusinessError) => {
        hilog.error(0x0000, TAG, "Photo picker error: %{public}s", error.message);
        result.error("PICKER_ERROR", error.message, null);
      });
    } catch (e) {
      hilog.error(0x0000, TAG, "Error in pickImages: %{public}s", (e as Error)?.message || "Unknown");
      result.error("EXCEPTION", (e as Error)?.message || "Unknown error", null);
    }
  }

  /**
   * 拍照
   * 使用 cameraPicker 直接拍摄
   * @param result 结果回调
   */
  private static async takePhoto(result: MethodResult) {
    try {
      hilog.info(0x0000, TAG, "Starting camera via cameraPicker");

      if (!FilePickerPlugin.context) {
        hilog.error(0x0000, TAG, "Context not available for cameraPicker");
        result.error("NO_CONTEXT", "Context not available", null);
        return;
      }

      try {
        let pickerProfile: cameraPicker.PickerProfile = {
          cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK
        };

        cameraPicker.pick(FilePickerPlugin.context, [cameraPicker.PickerMediaType.PHOTO], pickerProfile)
          .then((pickerResult: cameraPicker.PickerResult) => {
            hilog.info(0x0000, TAG, "cameraPicker result: %{public}s", JSON.stringify(pickerResult));
            
            if (pickerResult && pickerResult.resultCode === 0 && pickerResult.resultUri) {
              const uri = pickerResult.resultUri;
              hilog.info(0x0000, TAG, "Camera photo URI: %{public}s", uri);
              
              try {
                let correctUri = uri;
                if (!uri.startsWith('file://') && !uri.startsWith('/')) {
                  correctUri = uri;
                }
                
                const file = fs.openSync(correctUri, fs.OpenMode.READ_ONLY);
                const stat = fs.statSync(file.fd);
                hilog.info(0x0000, TAG, "Photo file opened, size: %{public}d", stat.size);
                
                // 拷贝到缓存目录
                const cachedPath = FilePickerPlugin.copyFileToCache(correctUri);
                hilog.info(0x0000, TAG, "Cached path: %{public}s", cachedPath);
                
                let fileName = uri.split('/').pop() || 'photo.jpg';
                if (fileName.includes('?')) {
                  fileName = fileName.split('?')[0];
                }
                try {
                  fileName = decodeURIComponent(fileName);
                } catch (e) {}

                const fileInfoObj: FileInfo = {
                  name: fileName,
                  path: cachedPath,
                  uri: correctUri,
                  size: stat.size
                };
                
                fs.closeSync(file);
                result.success([fileInfoObj]);
              } catch (fileError) {
                hilog.error(0x0000, TAG, "Error processing photo from cameraPicker: %{public}s", (fileError as Error)?.message || "Unknown");
                hilog.error(0x0000, TAG, "Error details: %{public}s", JSON.stringify(fileError));
                result.error("FILE_ERROR", (fileError as Error)?.message || "Failed to process captured photo", null);
              }
            } else {
              hilog.info(0x0000, TAG, "Photo capture cancelled or failed");
              result.success([]);
            }
          })
          .catch((error: BusinessError) => {
            hilog.error(0x0000, TAG, "cameraPicker error: %{public}s", error.message);
            result.error("PICKER_ERROR", error.message, null);
          });
      } catch (e) {
        hilog.error(0x0000, TAG, "Error invoking cameraPicker: %{public}s", (e as Error)?.message || "Unknown");
        result.error("CAMERA_ERROR", (e as Error)?.message || "Failed to start camera picker", null);
      }
    } catch (e) {
      hilog.error(0x0000, TAG, "Error in takePhoto: %{public}s", (e as Error)?.message || "Unknown");
      result.error("EXCEPTION", (e as Error)?.message || "Unknown error", null);
    }
  }

  /**
   * 将文件从 URI 拷贝到应用缓存目录
   * @param uri 文件 URI
   * @returns 拷贝后的缓存文件路径
   */
  private static copyFileToCache(uri: string): string {
    if (!FilePickerPlugin.context) {
      hilog.error(0x0000, TAG, "Context not available for copyFileToCache");
      return uri;
    }

    try {
      // 获取缓存目录
      const cacheDir = FilePickerPlugin.context.cacheDir;
      hilog.info(0x0000, TAG, "Cache directory: %{public}s", cacheDir);
      
      // 打开原始文件
      const file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
      hilog.info(0x0000, TAG, "Opened source file: %{public}s", uri);
      
      // 从URI中提取文件名（处理URL编码）
      let fileName = uri.split('/').pop() || `file_${Date.now()}`;
      if (fileName.includes('?')) {
        fileName = fileName.split('?')[0];
      }
      // URL解码文件名
      try {
        fileName = decodeURIComponent(fileName);
      } catch (e) {
        hilog.warn(0x0000, TAG, "Failed to decode filename: %{public}s", fileName);
      }
      
      // 构建目标路径
      const destPath = `${cacheDir}/${fileName}`;
      hilog.info(0x0000, TAG, "Destination path: %{public}s", destPath);
      
      // 如果目标文件已存在，先删除
      try {
        if (fs.accessSync(destPath)) {
          hilog.info(0x0000, TAG, "Destination file exists, deleting...");
          fs.unlinkSync(destPath);
        }
      } catch (e) {
        // 忽略 access 或 unlink 错误
        hilog.info(0x0000, TAG, "Destination file does not exist or delete failed, continue...");
      }
      
      // 拷贝文件
      fs.copyFileSync(file.fd, destPath);
      fs.closeSync(file);
      
      hilog.info(0x0000, TAG, "File successfully cached to: %{public}s", destPath);
      return destPath;
    } catch (e) {
      hilog.error(0x0000, TAG, "Failed to copy file to cache: %{public}s", (e as Error)?.message || "Unknown");
      hilog.error(0x0000, TAG, "Error details: %{public}s", JSON.stringify(e));
      // 如果拷贝失败，尝试返回原始URI
      return uri;
    }
  }
}
