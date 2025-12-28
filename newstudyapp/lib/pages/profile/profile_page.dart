import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/config/theme_controller.dart';
import 'package:newstudyapp/config/app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  '个人中心',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 40),
                
                // 用户信息卡片
                _buildUserCard(isDark),
                const SizedBox(height: 24),
                
                // 设置列表
                _buildSettingsSection(isDark, themeController),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(bool isDark) {
    final cardColor = isDark ? Colors.grey[900] : Colors.white;
    final borderColor = isDark ? Colors.grey[800] : Colors.grey[300];
    final iconBgColor = isDark ? Colors.grey[800] : Colors.grey[200];
    final iconColor = isDark ? Colors.grey[600] : Colors.grey[500];
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[500] : Colors.grey[600];
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor!, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, color: iconColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'thyself Know',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 4),
                Text(
                  '学习中...',
                  style: TextStyle(fontSize: 14, color: secondaryColor),
                ),
              ],
            ),
          ),
          Icon(Icons.edit_outlined, color: iconColor, size: 20),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(bool isDark, ThemeController themeController) {
    final textColor = isDark ? Colors.white : Colors.black;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '设置',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 16),
        
        // 主题切换
        Obx(() => _buildSettingItem(
          isDark: isDark,
          icon: themeController.isDarkMode ? Icons.dark_mode : Icons.light_mode,
          title: '主题模式',
          subtitle: themeController.isDarkMode ? '深色模式' : '浅色模式',
          trailing: Switch(
            value: themeController.isDarkMode,
            onChanged: (value) => themeController.toggleTheme(),
            activeColor: AppTheme.darkPrimary,
          ),
        )),
        
        const SizedBox(height: 12),
        
        _buildSettingItem(
          isDark: isDark,
          icon: Icons.notifications_outlined,
          title: '通知设置',
          subtitle: '管理推送通知',
          trailing: Icon(
            Icons.chevron_right,
            color: isDark ? Colors.grey[600] : Colors.grey[500],
          ),
          onTap: () {},
        ),
        
        const SizedBox(height: 12),
        
        _buildSettingItem(
          isDark: isDark,
          icon: Icons.language_outlined,
          title: '语言',
          subtitle: '简体中文',
          trailing: Icon(
            Icons.chevron_right,
            color: isDark ? Colors.grey[600] : Colors.grey[500],
          ),
          onTap: () {},
        ),
        
        const SizedBox(height: 12),
        
        _buildSettingItem(
          isDark: isDark,
          icon: Icons.info_outline,
          title: '关于',
          subtitle: '版本 1.0.0',
          trailing: Icon(
            Icons.chevron_right,
            color: isDark ? Colors.grey[600] : Colors.grey[500],
          ),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final cardColor = isDark ? Colors.grey[900] : Colors.white;
    final borderColor = isDark ? Colors.grey[800] : Colors.grey[300];
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[500] : Colors.grey[600];
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor!, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.darkPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.darkPrimary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: secondaryColor),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
