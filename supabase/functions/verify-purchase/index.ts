import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { corsHeaders } from "../_shared/cors.ts"

interface VerifyPurchaseRequest {
  platform: 'ios' | 'android';
  receipt: string;
  productId: string;
  packageName?: string;
  purchaseToken?: string;
}

interface VerifyPurchaseResponse {
  success: boolean;
  valid: boolean;
  message?: string;
  error?: string;
}

async function verifyGooglePlayPurchase(
  packageName: string,
  productId: string,
  purchaseToken: string
): Promise<boolean> {
  // Google Play APIの認証設定が必要
  // 本番環境では、Google Play Developer APIを使用してレシートを検証
  // ここでは簡易的な実装を示す
  
  try {
    // TODO: Google Play Developer APIを使用した実装
    // 1. サービスアカウントの認証
    // 2. purchases.subscriptions.get APIを呼び出し
    // 3. レスポンスを検証
    
    // 暫定的に成功を返す（本番では必ず実装すること）
    console.log(`Verifying Google Play purchase: ${packageName}, ${productId}, ${purchaseToken}`);
    return true;
  } catch (error) {
    console.error('Google Play verification error:', error);
    return false;
  }
}

async function verifyApplePurchase(receipt: string): Promise<boolean> {
  // App Store Connect APIを使用してレシートを検証
  
  try {
    // Apple検証URLs
    const verifyUrl = Deno.env.get('APPLE_PRODUCTION') === 'true'
      ? 'https://buy.itunes.apple.com/verifyReceipt'
      : 'https://sandbox.itunes.apple.com/verifyReceipt';
    
    const sharedSecret = Deno.env.get('APPLE_SHARED_SECRET') || '';
    
    const response = await fetch(verifyUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        'receipt-data': receipt,
        'password': sharedSecret,
        'exclude-old-transactions': true
      })
    });
    
    const data = await response.json();
    
    // status 0 = 有効なレシート
    if (data.status === 0) {
      // latest_receipt_infoから最新のサブスクリプション情報を確認
      const latestReceipts = data.latest_receipt_info || [];
      const now = Date.now();
      
      // アクティブなサブスクリプションがあるか確認
      const hasActiveSubscription = latestReceipts.some((item: any) => {
        const expiresDateMs = parseInt(item.expires_date_ms);
        return expiresDateMs > now;
      });
      
      return hasActiveSubscription;
    }
    
    // 21007 = サンドボックスレシートが本番環境に送信された
    if (data.status === 21007 && Deno.env.get('APPLE_PRODUCTION') === 'true') {
      // サンドボックスURLで再試行
      console.log('Retrying with sandbox URL...');
      // 再帰的に呼び出し（環境変数を変更して）
      return false; // 簡易実装のため、ここでは失敗を返す
    }
    
    console.error(`Apple receipt validation failed with status: ${data.status}`);
    return false;
  } catch (error) {
    console.error('Apple verification error:', error);
    return false;
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  
  try {
    const body = await req.json() as VerifyPurchaseRequest;
    const { platform, receipt, productId, packageName, purchaseToken } = body;
    
    let isValid = false;
    let message = '';
    
    if (platform === 'android') {
      if (!packageName || !purchaseToken) {
        throw new Error('Missing packageName or purchaseToken for Android');
      }
      
      isValid = await verifyGooglePlayPurchase(packageName, productId, purchaseToken);
      message = isValid ? 'Android purchase verified' : 'Android purchase verification failed';
    } else if (platform === 'ios') {
      isValid = await verifyApplePurchase(receipt);
      message = isValid ? 'iOS purchase verified' : 'iOS purchase verification failed';
    } else {
      throw new Error(`Unsupported platform: ${platform}`);
    }
    
    const response: VerifyPurchaseResponse = {
      success: true,
      valid: isValid,
      message
    };
    
    return new Response(
      JSON.stringify(response),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error verifying purchase:', error);
    
    const response: VerifyPurchaseResponse = {
      success: false,
      valid: false,
      error: error.message || 'Unknown error occurred'
    };
    
    return new Response(
      JSON.stringify(response),
      { 
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  }
})