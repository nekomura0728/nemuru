import { serve } from "https://deno.land/std@0.177.0/http/server.ts"; // Deno標準ライブラリからserveをインポート
import { corsHeaders } from "../_shared/cors.ts"; // 先ほど作成したCORSヘッダーをインポート

console.log("chat-completion function script started"); // 関数起動時のログ

serve(async (req: Request) => {
  // CORSプリフライトリクエストへの対応
  if (req.method === "OPTIONS") {
    console.log("OPTIONS request received");
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    console.log("POST request received");
    // リクエストボディをJSONとしてパース
    const {
      messages, // フロントエンドからの会話履歴 (必須)
      model, // 使用するモデル (任意、デフォルトは'gpt-4o')
      temperature, // 生成の多様性 (任意、デフォルトは0.7)
      max_tokens, // 最大トークン数 (任意、デフォルトは250)
      // characterId, // 将来的にキャラクター情報を渡す場合 (任意)
    } = await req.json();

    // 必須パラメータのチェック
    if (!messages || !Array.isArray(messages) || messages.length === 0) {
      console.error("Invalid request: 'messages' is required and must be a non-empty array.");
      return new Response(
        JSON.stringify({ error: "'messages' is required and must be a non-empty array." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // OpenAI APIキーを環境変数から取得
    const openaiApiKey = Deno.env.get("OPENAI_API_KEY");
    if (!openaiApiKey) {
      console.error("OpenAI API key is not set in environment variables.");
      throw new Error("OpenAI API key is not set in environment variables."); // これはサーバー側のエラー
    }
    console.log("OpenAI API Key successfully retrieved.");

    // OpenAI APIへのリクエストボディを構築
    const requestBody = {
      model: model || "gpt-4o",
      messages: messages,
      temperature: temperature || 0.7,
      max_tokens: max_tokens || 250, // NEMURUの応答は短めなので調整
      // TODO: 将来的にキャラクターの性格などを反映させる場合、
      // messagesにシステムプロンプトとしてキャラクター設定を追加する処理をここに入れる
      // 例: if (characterId) { messages.unshift({ role: "system", content: getCharacterPrompt(characterId) }); }
    };
    console.log("Request body for OpenAI:", JSON.stringify(requestBody, null, 2));


    // OpenAI APIへリクエストを送信
    const openaiResponse = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${openaiApiKey}`,
      },
      body: JSON.stringify(requestBody),
    });
    console.log(`OpenAI API response status: ${openaiResponse.status}`);

    // OpenAI APIからのレスポンスチェック
    if (!openaiResponse.ok) {
      const errorBody = await openaiResponse.text();
      console.error(`OpenAI API error: ${openaiResponse.status} ${errorBody}`);
      throw new Error(`OpenAI API request failed with status ${openaiResponse.status}: ${errorBody}`);
    }

    const data = await openaiResponse.json();
    console.log("Response from OpenAI:", JSON.stringify(data, null, 2));

    // フロントエンドへレスポンスを返す
    return new Response(
      JSON.stringify(data), // OpenAIからのレスポンスをそのまま返す
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (error) {
    console.error("Error in chat-completion function:", error);
    // エラーレスポンスを返す
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});