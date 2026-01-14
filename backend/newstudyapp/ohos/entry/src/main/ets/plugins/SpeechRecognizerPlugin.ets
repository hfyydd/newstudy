import { FlutterEngine, MethodChannel } from '@ohos/flutter_ohos';
import hilog from '@ohos.hilog';
import { speechRecognizer } from '@kit.CoreSpeechKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { audio } from '@kit.AudioKit';

const TAG = "SpeechRecognizerPlugin";
const CHANNEL_NAME = "com.newstudyapp.speech_recognizer";

// 定义事件数据接口
interface EventData {
  sessionId?: string;
  message?: string;
  eventCode?: number;
  result?: string;
  isFinal?: boolean;
  errorCode?: number;
  errorMessage?: string;
}

// 定义事件负载接口
interface EventPayload {
  event: string;
  data: EventData;
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

export class SpeechRecognizerPlugin {
  private static engine: speechRecognizer.SpeechRecognitionEngine | null = null;
  private static sessionId: string = '';
  private static channel: MethodChannel | null = null;
  private static audioCapturer: audio.AudioCapturer | null = null;
  private static isListening: boolean = false;

  static registerWith(flutterEngine: FlutterEngine) {
    try {
      hilog.info(0x0000, TAG, "Registering SpeechRecognizerPlugin with channel: %{public}s", CHANNEL_NAME);
      const channel = new MethodChannel(flutterEngine.dartExecutor, CHANNEL_NAME);
      hilog.info(0x0000, TAG, "MethodChannel created successfully");
      
      channel.setMethodCallHandler({
        onMethodCall: (call: MethodCall, result: MethodResult) => {
          hilog.info(0x0000, TAG, "Method call received: %{public}s", call.method);
          SpeechRecognizerPlugin.handleMethodCall(call, result);
        }
      });
      hilog.info(0x0000, TAG, "Method call handler set successfully");
      
      SpeechRecognizerPlugin.channel = channel;
      hilog.info(0x0000, TAG, "SpeechRecognizerPlugin registered successfully");
    } catch (e) {
      hilog.error(0x0000, TAG, "Failed to register SpeechRecognizerPlugin");
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
      const args = call.argument as Record<string, Object> | undefined;

      hilog.info(0x0000, TAG, "Method called: %{public}s", method);

      switch (method) {
        case 'initialize':
          await SpeechRecognizerPlugin.initialize(result);
          break;
        case 'startListening':
          await SpeechRecognizerPlugin.startListening(result);
          break;
        case 'stopListening':
          await SpeechRecognizerPlugin.stopListening(result);
          break;
        case 'cancel':
          await SpeechRecognizerPlugin.cancel(result);
          break;
        case 'isAvailable':
          result.success(SpeechRecognizerPlugin.engine !== null);
          break;
        case 'shutdown':
          await SpeechRecognizerPlugin.shutdown(result);
          break;
        default:
          result.error('METHOD_NOT_IMPLEMENTED', `Method ${method} not implemented`, null);
      }
    } catch (e) {
      hilog.error(0x0000, TAG, "Error handling method call: %{public}s", JSON.stringify(e));
      result.error('ERROR', `Error: ${JSON.stringify(e)}`, null);
    }
  }

  private static async initialize(result: MethodResult) {
    try {
      if (SpeechRecognizerPlugin.engine !== null) {
        result.success(true);
        return;
      }

      // 创建引擎参数
      const extraParam: Record<string, Object> = {
        "locate": "CN",
        "recognizerMode": "short"
      };
      const initParamsInfo: speechRecognizer.CreateEngineParams = {
        language: 'zh-CN',
        online: 1,
        extraParams: extraParam
      };

      // 创建引擎
      speechRecognizer.createEngine(initParamsInfo, (err: BusinessError, engine: speechRecognizer.SpeechRecognitionEngine) => {
        if (!err) {
          SpeechRecognizerPlugin.engine = engine;
          SpeechRecognizerPlugin.sessionId = `session_${Date.now()}`;
          
          // 设置回调监听器
          SpeechRecognizerPlugin.setListener();
          
          hilog.info(0x0000, TAG, "Engine initialized successfully");
          result.success(true);
        } else {
          hilog.error(0x0000, TAG, "Failed to create engine: %{public}s", err.message);
          result.error('INIT_ERROR', `Failed to initialize: ${err.message}`, null);
        }
      });
    } catch (e) {
      hilog.error(0x0000, TAG, "Initialize error: %{public}s", JSON.stringify(e));
      result.error('INIT_ERROR', `Error: ${JSON.stringify(e)}`, null);
    }
  }

  private static setListener() {
    if (SpeechRecognizerPlugin.engine === null) {
      return;
    }

    const listener: speechRecognizer.RecognitionListener = {
      // 开始识别成功回调
      onStart(sessionId: string, eventMessage: string) {
        hilog.info(0x0000, TAG, "onStart: sessionId=%{public}s, message=%{public}s", sessionId, eventMessage);
        const eventData: EventData = { sessionId, message: eventMessage };
        SpeechRecognizerPlugin.sendEvent('onStart', eventData);
        SpeechRecognizerPlugin.startAudioCapture();
      },
      
      // 事件回调
      onEvent(sessionId: string, eventCode: number, eventMessage: string) {
        hilog.info(0x0000, TAG, "onEvent: sessionId=%{public}s, code=%{public}d, message=%{public}s", sessionId, eventCode, eventMessage);
        const eventData: EventData = { sessionId, eventCode, message: eventMessage };
        SpeechRecognizerPlugin.sendEvent('onEvent', eventData);
      },
      
      // 识别结果回调
      onResult(sessionId: string, result: speechRecognizer.SpeechRecognitionResult) {
        hilog.info(0x0000, TAG, "onResult: sessionId=%{public}s, result=%{public}s", sessionId, result.result);
        const eventData: EventData = {
          sessionId,
          result: result.result,
          isFinal: result.isFinal || false
        };
        SpeechRecognizerPlugin.sendEvent('onResult', eventData);
      },
      
      // 识别完成回调
      onComplete(sessionId: string, eventMessage: string) {
        hilog.info(0x0000, TAG, "onComplete: sessionId=%{public}s, message=%{public}s", sessionId, eventMessage);
        SpeechRecognizerPlugin.isListening = false;
        SpeechRecognizerPlugin.stopAudioCapture();
        const eventData: EventData = { sessionId, message: eventMessage };
        SpeechRecognizerPlugin.sendEvent('onComplete', eventData);
      },
      
      // 错误回调
      onError(sessionId: string, errorCode: number, errorMessage: string) {
        hilog.error(0x0000, TAG, "onError: sessionId=%{public}s, code=%{public}d, message=%{public}s", sessionId, errorCode, errorMessage);
        SpeechRecognizerPlugin.isListening = false;
        SpeechRecognizerPlugin.stopAudioCapture();
        const eventData: EventData = {
          sessionId,
          errorCode,
          errorMessage
        };
        SpeechRecognizerPlugin.sendEvent('onError', eventData);
      }
    };

    SpeechRecognizerPlugin.engine.setListener(listener);
  }

  private static async startListening(result: MethodResult) {
    try {
      if (SpeechRecognizerPlugin.engine === null) {
        result.error('NOT_INITIALIZED', 'Engine not initialized', null);
        return;
      }

      if (SpeechRecognizerPlugin.isListening) {
        result.error('ALREADY_LISTENING', 'Already listening', null);
        return;
      }

      // 配置音频参数
      const audioParam: speechRecognizer.AudioInfo = {
        audioType: 'pcm',
        sampleRate: 16000,
        soundChannel: 1,
        sampleBit: 16
      };

      // 配置识别参数
      const extraParam: Record<string, Object> = {
        "recognitionMode": 0, // 0: 实时识别模式
        "vadBegin": 2000,     // 语音开始检测时间(ms)
        "vadEnd": 3000,       // 语音结束检测时间(ms)
        "maxAudioDuration": 60000 // 最大音频时长(ms)，60秒
      };

      const recognizerParams: speechRecognizer.StartParams = {
        sessionId: SpeechRecognizerPlugin.sessionId,
        audioInfo: audioParam,
        extraParams: extraParam
      };

      SpeechRecognizerPlugin.engine.startListening(recognizerParams);
      SpeechRecognizerPlugin.isListening = true;
      
      hilog.info(0x0000, TAG, "Started listening");
      result.success(true);
    } catch (e) {
      hilog.error(0x0000, TAG, "Start listening error: %{public}s", JSON.stringify(e));
      SpeechRecognizerPlugin.isListening = false;
      result.error('START_ERROR', `Error: ${JSON.stringify(e)}`, null);
    }
  }

  private static async startAudioCapture() {
    try {
      // 创建音频采集器
      const audioStreamInfo: audio.AudioStreamInfo = {
        samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_16000,
        channels: audio.AudioChannel.CHANNEL_1,
        sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
        encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
      };

      const audioCapturerInfo: audio.AudioCapturerInfo = {
        source: audio.SourceType.SOURCE_TYPE_MIC,
        capturerFlags: 0
      };

      const capturerOptions: audio.AudioCapturerOptions = {
        streamInfo: audioStreamInfo,
        capturerInfo: audioCapturerInfo
      };

      SpeechRecognizerPlugin.audioCapturer = await audio.createAudioCapturer(capturerOptions);
      await SpeechRecognizerPlugin.audioCapturer.start();

      // 开始读取音频数据并写入识别引擎
      SpeechRecognizerPlugin.readAudioData();
      
      hilog.info(0x0000, TAG, "Audio capture started");
    } catch (e) {
      hilog.error(0x0000, TAG, "Start audio capture error: %{public}s", JSON.stringify(e));
    }
  }

  private static async readAudioData() {
    if (SpeechRecognizerPlugin.audioCapturer === null || SpeechRecognizerPlugin.engine === null) {
      return;
    }

    const bufferSize = 1280; // 音频流长度仅支持640或1280
    const buffer = new ArrayBuffer(bufferSize);

    // 使用异步函数处理音频流读取
    (async () => {
      while (SpeechRecognizerPlugin.isListening && SpeechRecognizerPlugin.audioCapturer !== null) {
        try {
          const readBuffer: ArrayBuffer = await (SpeechRecognizerPlugin.audioCapturer as audio.AudioCapturer).read(bufferSize, true);
          
          if (readBuffer && readBuffer.byteLength > 0 && SpeechRecognizerPlugin.engine !== null) {
            const uint8Array = new Uint8Array(readBuffer);
            SpeechRecognizerPlugin.engine.writeAudio(SpeechRecognizerPlugin.sessionId, uint8Array);
          }
          
          // 延迟40ms，模拟实时音频流
          await new Promise<void>((resolve: () => void) => setTimeout(resolve, 40));
        } catch (e) {
          hilog.error(0x0000, TAG, "Read audio data error: %{public}s", JSON.stringify(e));
          break;
        }
      }
    })();
  }

  private static async stopAudioCapture() {
    try {
      if (SpeechRecognizerPlugin.audioCapturer !== null) {
        await SpeechRecognizerPlugin.audioCapturer.stop();
        await SpeechRecognizerPlugin.audioCapturer.release();
        SpeechRecognizerPlugin.audioCapturer = null;
        hilog.info(0x0000, TAG, "Audio capture stopped");
      }
    } catch (e) {
      hilog.error(0x0000, TAG, "Stop audio capture error: %{public}s", JSON.stringify(e));
    }
  }

  private static async stopListening(result: MethodResult) {
    try {
      if (SpeechRecognizerPlugin.engine === null) {
        result.error('NOT_INITIALIZED', 'Engine not initialized', null);
        return;
      }

      if (!SpeechRecognizerPlugin.isListening) {
        result.success(true);
        return;
      }

      SpeechRecognizerPlugin.engine.finish(SpeechRecognizerPlugin.sessionId);
      SpeechRecognizerPlugin.isListening = false;
      
      hilog.info(0x0000, TAG, "Stopped listening");
      result.success(true);
    } catch (e) {
      hilog.error(0x0000, TAG, "Stop listening error: %{public}s", JSON.stringify(e));
      result.error('STOP_ERROR', `Error: ${JSON.stringify(e)}`, null);
    }
  }

  private static async cancel(result: MethodResult) {
    try {
      if (SpeechRecognizerPlugin.engine === null) {
        result.error('NOT_INITIALIZED', 'Engine not initialized', null);
        return;
      }

      SpeechRecognizerPlugin.engine.cancel(SpeechRecognizerPlugin.sessionId);
      SpeechRecognizerPlugin.isListening = false;
      await SpeechRecognizerPlugin.stopAudioCapture();
      
      hilog.info(0x0000, TAG, "Cancelled listening");
      result.success(true);
    } catch (e) {
      hilog.error(0x0000, TAG, "Cancel error: %{public}s", JSON.stringify(e));
      result.error('CANCEL_ERROR', `Error: ${JSON.stringify(e)}`, null);
    }
  }

  private static async shutdown(result: MethodResult) {
    try {
      await SpeechRecognizerPlugin.stopAudioCapture();
      
      if (SpeechRecognizerPlugin.engine !== null) {
        SpeechRecognizerPlugin.engine.shutdown();
        SpeechRecognizerPlugin.engine = null;
        SpeechRecognizerPlugin.isListening = false;
        hilog.info(0x0000, TAG, "Engine shut down");
      }
      
      result.success(true);
    } catch (e) {
      hilog.error(0x0000, TAG, "Shutdown error: %{public}s", JSON.stringify(e));
      result.error('SHUTDOWN_ERROR', `Error: ${JSON.stringify(e)}`, null);
    }
  }

  private static sendEvent(eventName: string, data: EventData) {
    if (SpeechRecognizerPlugin.channel !== null) {
      try {
        const eventPayload: EventPayload = {
          event: eventName,
          data: data
        };
        SpeechRecognizerPlugin.channel.invokeMethod('onEvent', eventPayload);
      } catch (e) {
        hilog.error(0x0000, TAG, "Send event error: %{public}s", JSON.stringify(e));
      }
    }
  }
}
