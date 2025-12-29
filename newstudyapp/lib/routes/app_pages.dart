import 'package:get/get.dart';
import 'package:newstudyapp/pages/main/main_page.dart';
import 'package:newstudyapp/pages/main/main_controller.dart';
import 'package:newstudyapp/pages/feynman_card/feynman_card_detail_page.dart';
import 'package:newstudyapp/pages/topic_selection/topic_selection_page.dart';
import 'package:newstudyapp/pages/topic_selection/topic_selection_controller.dart';
import 'package:newstudyapp/pages/feynman_learning/feynman_learning_page.dart';
import 'package:newstudyapp/pages/feynman_learning/feynman_learning_controller.dart';
import 'package:newstudyapp/pages/note_creation/note_creation_page.dart';
import 'package:newstudyapp/pages/note_creation/note_creation_controller.dart';
import 'package:newstudyapp/pages/create_note/create_note_page.dart';
import 'package:newstudyapp/pages/create_note/create_note_controller.dart';
import 'package:newstudyapp/pages/note_detail/note_detail_page.dart';
import 'package:newstudyapp/pages/note_detail/note_detail_controller.dart';
import 'package:newstudyapp/routes/app_routes.dart';

/// GetX 页面路由配置
class AppPages {
  AppPages._();

  /// 初始路由
  static const initial = AppRoutes.main;

  /// 所有路由页面配置
  static final routes = [
    GetPage(
      name: AppRoutes.main,
      page: () => const MainPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<MainController>(() => MainController());
      }),
    ),
    GetPage(
      name: AppRoutes.feynmanCardDetail,
      page: () => const FeynmanCardDetailPage(),
    ),
    GetPage(
      name: AppRoutes.topicSelection,
      page: () => const TopicSelectionPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<TopicSelectionController>(() => TopicSelectionController());
      }),
    ),
    GetPage(
      name: AppRoutes.feynmanLearning,
      page: () => const FeynmanLearningPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<FeynmanLearningController>(() => FeynmanLearningController());
      }),
    ),
    GetPage(
      name: AppRoutes.noteCreation,
      page: () => const NoteCreationPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<NoteCreationController>(() => NoteCreationController());
      }),
    ),
    GetPage(
      name: AppRoutes.createNote,
      page: () => const CreateNotePage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<CreateNoteController>(() => CreateNoteController());
      }),
    ),
    GetPage(
      name: AppRoutes.noteDetail,
      page: () => const NoteDetailPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<NoteDetailController>(() => NoteDetailController());
      }),
    ),
  ];
}
