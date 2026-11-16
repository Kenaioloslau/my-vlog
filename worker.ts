import worker from "ziscus/worker";

export default {
  async fetch(request: Request, env: any, ctx: any) {
    // 1. 无论对方是谁，直接给与最高级别的跨域通行证
    const corsHeaders = {
      "Access-Control-Allow-Origin": "*", // 允许任何域名（包括本地和线上）
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
    };

    // 2. 如果是浏览器的 OPTIONS 预检请求，直接放行
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    try {
      // 3. 让 Ziscus 去处理真正的业务
      const response = await worker.fetch(request, env, ctx);
      
      // 4. 把跨域头强行注入到 Ziscus 的响应中
      const newResponse = new Response(response.body, response);
      Object.keys(corsHeaders).forEach(key => {
        newResponse.headers.set(key, corsHeaders[key]);
      });
      return newResponse;
    } catch (error: any) {
      // 5. 如果 Ziscus 内部崩溃了（比如数据库报错），我们捕获它并带上跨域头返回
      return new Response(JSON.stringify({ 
        error: "Worker 内部错误", 
        message: error.message,
        stack: error.stack
      }), {
        status: 500,
        headers: { "Content-Type": "application/json", ...corsHeaders }
      });
    }
  }
};