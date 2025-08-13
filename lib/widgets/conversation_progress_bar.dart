import 'package:flutter/material.dart';
import 'package:nemuru/theme/app_theme.dart';
import 'package:nemuru/services/subscription_service.dart';
import 'package:provider/provider.dart';

class ConversationProgressBar extends StatelessWidget {
  final int currentConversationCount;

  const ConversationProgressBar({
    super.key,
    required this.currentConversationCount,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionService>(
      builder: (context, subscriptionService, _) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final isPremium = subscriptionService.isPremium;
        final maxTurns = isPremium
            ? SubscriptionService.premiumConversationTurns
            : SubscriptionService.freeConversationTurns;
        final maxConversations = isPremium
            ? SubscriptionService.premiumConversationLimit
            : SubscriptionService.freeConversationLimit;

        // 送信回数に基づく色の設定
        final progressColor = currentConversationCount > maxTurns * 0.8
            ? Colors.redAccent.withValues(alpha: isDarkMode ? 0.7 : 1.0)
            : currentConversationCount > maxTurns * 0.5
                ? Colors.orangeAccent.withValues(alpha: isDarkMode ? 0.8 : 1.0)
                : (isDarkMode ? AppTheme.darkPrimaryColor : AppTheme.primaryColor);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? AppTheme.darkBackgroundColor.withValues(alpha: 0.3)
                    : AppTheme.backgroundColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode
                      ? AppTheme.darkPrimaryColor.withValues(alpha: 0.1)
                      : AppTheme.primaryColor.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildProgressInfo(
                    icon: Icons.chat_bubble_outline,
                    text: '送信回数: $currentConversationCount/$maxTurns',
                    isDarkMode: isDarkMode,
                    isHighlighted: currentConversationCount > maxTurns * 0.7,
                  ),
                  _buildProgressInfo(
                    icon: Icons.calendar_today_outlined,
                    text: '今日: ${subscriptionService.todayConversationCount}/$maxConversations',
                    isDarkMode: isDarkMode,
                    isHighlighted: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: currentConversationCount / maxTurns,
                backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 5,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgressInfo({
    required IconData icon,
    required String text,
    required bool isDarkMode,
    required bool isHighlighted,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: isDarkMode
              ? AppTheme.darkSecondaryTextColor
              : AppTheme.secondaryTextColor,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode
                ? AppTheme.darkSecondaryTextColor
                : AppTheme.secondaryTextColor,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}