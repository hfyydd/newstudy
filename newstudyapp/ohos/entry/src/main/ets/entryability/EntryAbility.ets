
import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import { SpeechRecognizerPlugin } from '../plugins/SpeechRecognizerPlugin';
import { FilePickerPlugin } from '../plugins/FilePickerPlugin';
import hilog from '@ohos.hilog';
import common from '@ohos.app.ability.common';

const TAG = "EntryAbility";

export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    
    // 先注册 Flutter 自动生成的插件（来自 pubspec.yaml 的依赖）
    GeneratedPluginRegistrant.registerWith(flutterEngine)
    
    // 然后注册我们自定义的原生插件
    try {
      hilog.info(0x0000, TAG, "Registering custom native plugins");
      SpeechRecognizerPlugin.registerWith(flutterEngine);
      FilePickerPlugin.registerWith(flutterEngine);
      
      // 设置 FilePickerPlugin 的上下文
      FilePickerPlugin.setContext(this.context);
      
      hilog.info(0x0000, TAG, "Custom native plugins registered successfully");
    } catch (e) {
      hilog.error(0x0000, TAG, "Failed to register custom native plugins: %{public}s", e?.message || "Unknown");
    }
  }
}
