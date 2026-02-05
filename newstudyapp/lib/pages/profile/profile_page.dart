import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/config/theme_controller.dart';
import 'package:newstudyapp/config/app_theme.dart';
import 'package:newstudyapp/config/language_controller.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final l10n = AppLocalizations.of(context)!;
    
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
                  l10n.profile,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 40),
                
                // 用户信息卡片
                _buildUserCard(context, isDark),
                const SizedBox(height: 24),
                
                // 设置列表
                _buildSettingsSection(context, isDark, themeController),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
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
                  l10n.studying,
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

  Widget _buildSettingsSection(BuildContext context, bool isDark, ThemeController themeController) {
    final textColor = isDark ? Colors.white : Colors.black;
    final l10n = AppLocalizations.of(context)!;
    final languageController = Get.find<LanguageController>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.settings,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 16),
        
        // 主题切换
        Obx(() => _buildSettingItem(
          isDark: isDark,
          icon: themeController.isDarkMode ? Icons.dark_mode : Icons.light_mode,
          title: l10n.themeMode,
          subtitle: themeController.isDarkMode ? l10n.darkMode : l10n.lightMode,
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
          title: l10n.notifications,
          subtitle: l10n.manageNotifications,
          trailing: Icon(
            Icons.chevron_right,
            color: isDark ? Colors.grey[600] : Colors.grey[500],
          ),
          onTap: () {},
        ),
        
        const SizedBox(height: 12),
        
        Obx(() => _buildSettingItem(
          isDark: isDark,
          icon: Icons.language_outlined,
          title: l10n.language,
          subtitle: languageController.currentLanguage.nativeName,
          trailing: Icon(
            Icons.chevron_right,
            color: isDark ? Colors.grey[600] : Colors.grey[500],
          ),
          onTap: () => _showLanguageSelector(context, isDark),
        )),
        
        const SizedBox(height: 12),
        
        _buildSettingItem(
          isDark: isDark,
          icon: Icons.info_outline,
          title: l10n.about,
          subtitle: l10n.version('1.0.0'),
          trailing: Icon(
            Icons.chevron_right,
            color: isDark ? Colors.grey[600] : Colors.grey[500],
          ),
          onTap: () {},
        ),
      ],
    );
  }

  /// 显示语言选择器
  void _showLanguageSelector(BuildContext context, bool isDark) {
    final languageController = Get.find<LanguageController>();
    final l10n = AppLocalizations.of(context)!;
    final cardColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.language,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              ...LanguageController.supportedLanguages.map((lang) => Obx(() {
                final isSelected = languageController.currentLanguageCode.value == lang.code;
                return ListTile(
                  leading: Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isSelected ? AppTheme.darkPrimary : (isDark ? Colors.grey[600] : Colors.grey[400]),
                  ),
                  title: Text(
                    lang.nativeName,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    lang.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                  onTap: () {
                    languageController.changeLanguage(lang.code);
                    Navigator.pop(context);
                  },
                );
              })),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
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
