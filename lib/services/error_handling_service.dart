import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nemuru/theme/app_theme.dart';

/// エラータイプの列挙型
enum ErrorType {
  network,      // ネットワーク接続エラー
  timeout,      // タイムアウトエラー
  server,       // サーバーエラー
  authentication, // 認証エラー
  unknown,      // 不明なエラー
  validation    // 入力検証エラー
}

/// エラーハンドリングサービス
/// アプリ全体で統一されたエラー処理を提供します
class ErrorHandlingService {
  // シングルトンパターン
  static final ErrorHandlingService _instance = ErrorHandlingService._internal();
  factory ErrorHandlingService() => _instance;
  ErrorHandlingService._internal();

  /// エラーメッセージとエラータイプのマッピング
  final Map<ErrorType, String> _errorMessages = {
    ErrorType.network: 'インターネット接続に問題があります。ネットワーク設定を確認してください。',
    ErrorType.timeout: 'サーバーからの応答がありません。しばらくしてからもう一度お試しください。',
    ErrorType.server: 'サーバーでエラーが発生しました。しばらくしてからもう一度お試しください。',
    ErrorType.authentication: '認証に失敗しました。アプリを再起動してお試しください。',
    ErrorType.unknown: '予期せぬエラーが発生しました。しばらくしてからもう一度お試しください。',
    ErrorType.validation: '入力内容に問題があります。入力内容を確認してください。',
  };

  /// エラータイプに基づいてエラーメッセージを取得
  String getErrorMessage(ErrorType type) {
    return _errorMessages[type] ?? _errorMessages[ErrorType.unknown]!;
  }

  /// 例外からエラータイプを判定
  ErrorType getErrorTypeFromException(dynamic error) {
    if (error is SocketException || error is HttpException) {
      return ErrorType.network;
    } else if (error is TimeoutException) {
      return ErrorType.timeout;
    } else if (error is http.ClientException) {
      return ErrorType.server;
    } else {
      return ErrorType.unknown;
    }
  }

  /// HTTPステータスコードからエラータイプを判定
  ErrorType getErrorTypeFromStatusCode(int statusCode) {
    if (statusCode >= 500) {
      return ErrorType.server;
    } else if (statusCode == 401 || statusCode == 403) {
      return ErrorType.authentication;
    } else if (statusCode == 400 || statusCode == 422) {
      return ErrorType.validation;
    } else {
      return ErrorType.unknown;
    }
  }

  /// エラーダイアログを表示
  void showErrorDialog(BuildContext context, ErrorType errorType, {String? customMessage, VoidCallback? onRetry}) {
    final message = customMessage ?? getErrorMessage(errorType);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[700],
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              'エラーが発生しました',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppTheme.darkTextColor : AppTheme.textColor,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 16,
            color: isDarkMode ? AppTheme.darkTextColor : AppTheme.textColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? AppTheme.darkPrimaryColor : AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('再試行'),
            ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: isDarkMode ? AppTheme.darkCardColor : Colors.white,
      ),
    );
  }

  /// スナックバーでエラーを表示（軽微なエラー用）
  void showErrorSnackBar(BuildContext context, ErrorType errorType, {String? customMessage}) {
    final message = customMessage ?? getErrorMessage(errorType);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: isDarkMode ? Colors.red[700] : Colors.red[600],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: '閉じる',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// APIリクエストのラッパー関数
  /// エラーハンドリングを統一的に行う
  Future<T> handleApiRequest<T>({
    required Future<T> Function() apiCall,
    required BuildContext context,
    required String errorMessage,
    bool showDialog = true,
    VoidCallback? onRetry,
  }) async {
    try {
      return await apiCall();
    } catch (error) {
      
      final errorType = getErrorTypeFromException(error);
      final message = '$errorMessage\n${getErrorMessage(errorType)}';
      
      if (showDialog) {
        showErrorDialog(
          context, 
          errorType, 
          customMessage: message,
          onRetry: onRetry,
        );
      } else {
        showErrorSnackBar(context, errorType, customMessage: message);
      }
      
      rethrow;
    }
  }
}
