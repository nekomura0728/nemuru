/// API関連の定数を定義するファイル
/// 環境別の設定やエンドポイントを管理
class ApiConstants {
  // Supabase設定
  static const String supabaseProjectId = 'nemuru';
  
  // 本番環境では実際のSupabase URLに置き換える
  static const String _prodSupabaseUrl = 'https://your-project.supabase.co';
  static const String _localSupabaseUrl = 'http://127.0.0.1:54321';
  
  // 本番環境かどうかの判定
  static bool get isProd => const bool.fromEnvironment('dart.vm.product');
  
  // 環境に応じたSupabase URL
  static String get supabaseUrl => isProd ? _prodSupabaseUrl : _localSupabaseUrl;
  
  // Edge Function エンドポイント
  static String get verifyPurchaseUrl => '$supabaseUrl/functions/v1/verify-purchase';
  static String get chatCompletionUrl => '$supabaseUrl/functions/v1/chat-completion';
  
  // Supabase Anonymous Key (本番では環境変数から取得)
  // 注意: これは公開鍵で、秘密情報ではありません
  static const String _prodAnonKey = 'YOUR_PRODUCTION_ANON_KEY_HERE';
  static const String _localAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';
  
  static String get anonKey => isProd ? _prodAnonKey : _localAnonKey;
  
  // API タイムアウト設定
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // その他の設定
  static const String packageName = 'com.nemuruapp.nemuru';
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
  };
  
  // 認証ヘッダーを生成
  static Map<String, String> get authHeaders => {
    ...defaultHeaders,
    'Authorization': 'Bearer $anonKey',
  };
}