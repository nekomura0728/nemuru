-- サブスクリプション情報を保存するテーブル
CREATE TABLE IF NOT EXISTS subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  device_id TEXT NOT NULL,
  product_id TEXT NOT NULL,
  purchase_id TEXT,
  transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_active BOOLEAN DEFAULT TRUE,
  verification_data TEXT,
  platform TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- デバイスIDとプロダクトIDの組み合わせでユニーク制約
CREATE UNIQUE INDEX IF NOT EXISTS idx_subscriptions_device_product
ON subscriptions (device_id, product_id);

-- デバイスIDでの検索を高速化するインデックス
CREATE INDEX IF NOT EXISTS idx_subscriptions_device_id
ON subscriptions (device_id);

-- アクティブなサブスクリプションのみを取得するためのインデックス
CREATE INDEX IF NOT EXISTS idx_subscriptions_is_active
ON subscriptions (is_active);

-- RLS（Row Level Security）ポリシーを設定
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- デバイスIDに基づいて自分のサブスクリプション情報のみを参照可能にするポリシー
CREATE POLICY select_own_subscriptions ON subscriptions
FOR SELECT USING (device_id = current_setting('request.jwt.claims')::json->>'device_id');

-- デバイスIDに基づいて自分のサブスクリプション情報のみを更新可能にするポリシー
CREATE POLICY update_own_subscriptions ON subscriptions
FOR UPDATE USING (device_id = current_setting('request.jwt.claims')::json->>'device_id');

-- デバイスIDに基づいて自分のサブスクリプション情報のみを挿入可能にするポリシー
CREATE POLICY insert_own_subscriptions ON subscriptions
FOR INSERT WITH CHECK (device_id = current_setting('request.jwt.claims')::json->>'device_id');

-- デバイスIDに基づいて自分のサブスクリプション情報のみを削除可能にするポリシー
CREATE POLICY delete_own_subscriptions ON subscriptions
FOR DELETE USING (device_id = current_setting('request.jwt.claims')::json->>'device_id');
