import 'package:flutter/material.dart';
import 'package:nemuru/theme/app_theme.dart';
import 'package:nemuru/models/message.dart';
import 'package:nemuru/widgets/character_image_widget.dart';

class ChatMessageBubble extends StatelessWidget {
  final Message message;
  final int selectedCharacterId;
  final bool isDarkMode;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.selectedCharacterId,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final primaryColor = isDarkMode ? AppTheme.darkPrimaryColor : AppTheme.primaryColor;
    final accentColor = isDarkMode ? AppTheme.darkAccentColor : AppTheme.accentColor;
    final textColor = isDarkMode ? AppTheme.darkTextColor : AppTheme.textColor;

    // Improved bubble colors for better visibility
    final userBubbleColor = isDarkMode
        ? primaryColor.withValues(alpha: 0.7)
        : primaryColor.withValues(alpha: 0.6);
    final aiBubbleColor = isDarkMode
        ? accentColor.withValues(alpha: 0.6)
        : accentColor.withValues(alpha: 0.5);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildCharacterAvatar(accentColor),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: _buildBubbleDecoration(isUser, userBubbleColor, aiBubbleColor, primaryColor, accentColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: _buildTextStyle(isUser, textColor, context),
                  ),
                  const SizedBox(height: 4),
                  _buildTimestamp(isUser),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            _buildUserAvatar(primaryColor),
          ],
        ],
      ),
    );
  }

  Widget _buildCharacterAvatar(Color accentColor) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDarkMode
            ? accentColor.withValues(alpha: 0.15)
            : accentColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: CharacterImageWidget(
          characterId: selectedCharacterId,
          width: 40,
          height: 40,
        ),
      ),
    );
  }

  Widget _buildUserAvatar(Color primaryColor) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDarkMode
            ? primaryColor.withValues(alpha: 0.2)
            : primaryColor.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.person,
        color: primaryColor,
        size: 20,
      ),
    );
  }

  BoxDecoration _buildBubbleDecoration(bool isUser, Color userBubbleColor, Color aiBubbleColor, Color primaryColor, Color accentColor) {
    return BoxDecoration(
      color: isUser ? userBubbleColor : aiBubbleColor,
      borderRadius: BorderRadius.circular(20).copyWith(
        bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
        bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
      ),
      boxShadow: [
        BoxShadow(
          color: isDarkMode
              ? Colors.black.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
      border: Border.all(
        color: isUser
            ? primaryColor.withValues(alpha: isDarkMode ? 0.2 : 0.1)
            : accentColor.withValues(alpha: isDarkMode ? 0.2 : 0.1),
        width: 1,
      ),
    );
  }

  TextStyle _buildTextStyle(bool isUser, Color textColor, BuildContext context) {
    return isUser
        ? Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: textColor,
              height: 1.5,
            ) ?? TextStyle(color: textColor, height: 1.5)
        : AppTheme.handwrittenStyle.copyWith(
            fontSize: 16,
            height: 1.5,
            color: textColor,
          );
  }

  Widget _buildTimestamp(bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        '今', // In real app, format message.timestamp
        style: TextStyle(
          fontSize: 10,
          color: isDarkMode
              ? AppTheme.darkSecondaryTextColor.withValues(alpha: 0.7)
              : AppTheme.secondaryTextColor.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}