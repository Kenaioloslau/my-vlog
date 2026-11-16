// worker.ts
import worker from "ziscus/worker";

export default {
  async fetch(request: Request, env: any, ctx: any) {
    const origin = request.headers.get("Origin");
    // 允许的域名列表：包含你的正式域名和本地开发域名
    const allowedOrigins = [
      "https://canaiolos.com",
      "http://localhost:1313"
    ];

    // 如果请求来源在允许列表中，就设置对应的 CORS 头
    const corsHeaders = {
      "Access-Control-Allow-Origin": allowedOrigins.includes(origin || "") ? origin! : "",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
      "Access-Control-Max-Age": "86400",
    };

    // 1. 处理浏览器的 CORS 预检请求 (OPTIONS)
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    // 2. 调用 Ziscus 原本的处理逻辑
    const response = await worker.fetch(request, env, ctx);

    // 3. 将 CORS 头强行注入到返回的响应中
    const newResponse = new Response(response.body, response);
    for (const [key, value] of Object.entries(corsHeaders)) {
      if (value) newResponse.headers.set(key, value);
    }

    return newResponse;
  },
};