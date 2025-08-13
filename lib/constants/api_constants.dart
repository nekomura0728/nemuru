/// API関連の定数を管理するクラス
class ApiConstants {
  // プライベートコンストラクタ（インスタンス化を防ぐ）
  ApiConstants._();

  // ========== API エンドポイント ==========
  /// Supabase プロジェクトベースURL
  static const String supabaseBaseUrl = 'https://ldellkrfbgzrheisjret.supabase.co';
  
  /// チャット完了API エンドポイント
  static const String chatCompletionEndpoint = '$supabaseBaseUrl/functions/v1/chat-completion';
  
  /// 要約API エンドポイント（チャット完了と同じ）
  static const String summarizeEndpoint = chatCompletionEndpoint;

  // ========== API パラメータ ==========
  /// GPTモデル名
  static const String gptModel = 'gpt-4o-mini';
  
  /// 通常会話の最大トークン数
  static const int conversationMaxTokens = 200;
  
  /// 要約の最大トークン数
  static const int summaryMaxTokens = 150;
  
  /// 通常会話のtemperature
  static const double conversationTemperature = 0.7;
  
  /// 要約のtemperature
  static const double summaryTemperature = 0.5;
  
  /// APIタイムアウト時間
  static const Duration apiTimeout = Duration(seconds: 30);
  
  /// 会話履歴の最大保持数
  static const int maxConversationHistory = 10;

  // ========== HTTPヘッダー ==========
  /// Content-Type ヘッダー
  static const String contentTypeHeader = 'Content-Type';
  
  /// JSON Content-Type
  static const String jsonContentType = 'application/json';

  // ========== エラーメッセージ ==========
  /// タイムアウトエラーメッセージ
  static const String timeoutErrorMessage = '応答の取得がタイムアウトしました。ネットワーク環境を確認してください。';
  
  /// ネットワークエラーメッセージ
  static const String networkErrorMessage = 'ネットワークに接続できません。インターネット接続を確認して、もう一度お試しください。';
  
  /// レスポンス解析エラーメッセージ
  static const String parseErrorMessage = 'レスポンスの解析に失敗しました。';
  
  /// 一般的なエラーメッセージ
  static const String generalErrorMessage = 'エラーが発生しました。しばらくしてからもう一度お試しください。';
  
  /// AI応答取得エラーメッセージ
  static const String aiResponseErrorMessage = 'AIの応答取得中にエラーが発生しました。しばらくしてからもう一度お試しください。';
  
  /// 会話要約エラーメッセージ
  static const String summaryErrorMessage = '会話の要約中にエラーが発生しました。しばらくしてからもう一度お試しください。';

  // ========== 購入検証関連 ==========
  /// パッケージ名
  static const String packageName = 'com.nemuruapp.nemuru';
  
  /// 購入検証URL
  static const String verifyPurchaseUrl = '$supabaseBaseUrl/functions/v1/verify-purchase';
  
  /// Supabase APIキー（anon key）
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxkZWxsa3JmYmd6cmhlaXNqcmV0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgyMzg3MDgsImV4cCI6MjA2MzgxNDcwOH0.hFMbnqOdHIoROefUre-s7FLMowTh9nbmgV0bs46IrgY';
  
  /// 認証ヘッダー
  static const Map<String, String> authHeaders = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $supabaseAnonKey',
    'apikey': supabaseAnonKey,
  };
}