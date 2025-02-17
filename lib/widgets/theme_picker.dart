import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../config/theme_config.dart';
import 'upgrade_prompt_dialog.dart';

class ThemePicker extends StatelessWidget {
  const ThemePicker({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        final collections = themeService.getThemesByCollection();
        final availableThemes = themeService.getAvailableThemes();

        if (availableThemes.length <= 1) {
          return _buildUpgradePrompt(context);
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: themeService.currentTheme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: themeService.currentTheme.textColor.withOpacity(0.1),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: themeService.currentTheme.textColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  children: [
                    Text(
                      'Theme Gallery',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: themeService.currentTheme.textColor.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: collections.length,
                  itemBuilder: (context, collectionIndex) {
                    final collection = collections.entries.elementAt(collectionIndex);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          collection.key,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: themeService.currentTheme.textColor.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: collection.value.length,
                            itemBuilder: (context, index) {
                              final theme = collection.value[index];
                              return _buildThemePreview(
                                context,
                                theme,
                                themeService,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  bottom: 16 + MediaQuery.of(context).padding.bottom,
                ),
                child: GestureDetector(
                  onTap: () {
                    themeService.resetToDefault();
                    Navigator.pop(context);
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: themeService.currentTheme.textColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: themeService.currentTheme.textColor.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Reset to Default',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: themeService.currentTheme.textColor.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemePreview(
    BuildContext context,
    FlowTheme theme,
    ThemeService themeService,
  ) {
    final isSelected = theme.id == themeService.currentTheme.id;

    return GestureDetector(
      onTap: () {
        themeService.setTheme(theme);
        Navigator.pop(context);
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          gradient: theme.backgroundGradient,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.accentColor
                : theme.textColor.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Card Preview
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.textColor.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    CupertinoIcons.star,
                    color: theme.accentColor,
                    size: 16,
                  ),
                ),
              ),
            ),
            // Nav Bar Preview
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.navBarColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: theme.textColor.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.circle_fill,
                          color: theme.accentColor,
                          size: 5,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            theme.name,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                              color: theme.textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: theme.accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.accentColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    CupertinoIcons.checkmark_alt,
                    color: theme.cardColor,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradePrompt(BuildContext context) {
    return UpgradePromptDialog(
      title: 'Unlock Custom Themes',
      message: 'Upgrade to Flow Pro to access beautiful custom themes and personalize your experience.',
      onUpgrade: () {
        Navigator.pop(context);
        // TODO: Navigate to subscription screen
      },
    );
  }
} 