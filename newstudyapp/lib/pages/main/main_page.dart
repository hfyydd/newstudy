import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/pages/main/main_controller.dart';
import 'package:newstudyapp/pages/home/home_page.dart';
import 'package:newstudyapp/pages/home/home_controller.dart';
import 'package:newstudyapp/pages/review/review_page.dart';
import 'package:newstudyapp/pages/review/review_controller.dart';
import 'package:newstudyapp/pages/notes/notes_page.dart';
import 'package:newstudyapp/pages/profile/profile_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MainController());
    // 注册 HomeController，因为 HomePage 使用 GetView<HomeController>
    // 使用 lazyPut 确保只在需要时创建，避免重复创建
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
    // 注册 ReviewController
    Get.lazyPut<ReviewController>(() => ReviewController(), fenix: true);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Obx(() => _buildPage(controller.currentIndex.value)),
      bottomNavigationBar: _buildAnimatedBottomNavBar(controller),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const HomePage();
      case 1:
        return const ReviewPage();
      case 2:
        return const NotesPage();
      case 3:
        return const ProfilePage();
      default:
        return const HomePage();
    }
  }

  /// 构建带动画效果的底部导航栏（现代浮动设计）
  Widget _buildAnimatedBottomNavBar(MainController controller) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final navBgColor = isDark ? Colors.black : Colors.white;
        final shadowColor = isDark ? Colors.black : Colors.grey;
        
        return Container(
          margin: const EdgeInsets.all(20),
          child: SafeArea(
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: navBgColor,
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildModernNavItem(
                controller: controller,
                index: 0,
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore,
                label: '发现',
              ),
              _buildModernNavItem(
                controller: controller,
                index: 1,
                icon: Icons.auto_stories_outlined,
                activeIcon: Icons.auto_stories,
                label: '学习',
                badge: 8,
              ),
              _buildModernNavItem(
                controller: controller,
                index: 2,
                icon: Icons.emoji_events_outlined,
                activeIcon: Icons.emoji_events,
                label: '成就',
              ),
              _buildModernNavItem(
                controller: controller,
                index: 3,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: '我的',
              ),
            ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建现代风格的导航项
  Widget _buildModernNavItem({
    required MainController controller,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int? badge,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final iconColor = isDark ? Colors.white : Colors.black;
        final activeColor = isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1);
        final badgeBorderColor = isDark ? Colors.black : Colors.white;
        
        return Obx(() {
          final isActive = controller.currentIndex.value == index;
          
          return GestureDetector(
            onTap: () => controller.changeTab(index),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: isActive ? 20 : 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isActive ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 图标
                      AnimatedScale(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                        scale: isActive ? 1.1 : 1.0,
                        child: Icon(
                          isActive ? activeIcon : icon,
                          color: iconColor,
                          size: 28,
                        ),
                      ),
                      
                      // 文字（仅在选中时显示）
                      AnimatedSize(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        child: isActive
                            ? Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: iconColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  
                  // 徽章（仅在未选中时显示）
                  if (badge != null && badge > 0 && !isActive)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4444),
                          shape: BoxShape.circle,
                          border: Border.all(color: badgeBorderColor, width: 2),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Center(
                          child: Text(
                            badge > 9 ? '9+' : '$badge',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}

