import { createClient } from "https://esm.sh/@supabase/supabase-js@2.57.4";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "GET") return Response.json({ error: "Method not allowed" }, { status: 405, headers: cors });
  const authorization = req.headers.get("Authorization") ?? "";
  if (!authorization.startsWith("Bearer ")) return Response.json({ error: "Sign in first." }, { status: 401, headers: cors });

  const url = Deno.env.get("SUPABASE_URL")!;
  const anon = Deno.env.get("SUPABASE_ANON_KEY")!;
  const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const userClient = createClient(url, anon, { global: { headers: { Authorization: authorization } } });
  const { data: { user } } = await userClient.auth.getUser();
  if (!user) return Response.json({ error: "Invalid session." }, { status: 401, headers: cors });

  const jobId = new URL(req.url).searchParams.get("jobId") ?? "";
  if (!/^[0-9a-f-]{36}$/i.test(jobId)) return Response.json({ error: "Invalid job ID." }, { status: 400, headers: cors });
  const admin = createClient(url, service);
  const { data: job, error } = await admin.from("sign_jobs").select("id,status,error_message,manifest_path,original_name").eq("id", jobId).eq("user_id", user.id).maybeSingle();
  if (error || !job) return Response.json({ error: "Job not found." }, { status: 404, headers: cors });

  const result: Record<string, unknown> = { jobId, status: job.status, error: job.error_message, fileName: job.original_name };
  if (job.status === "complete" && job.manifest_path) {
    const { data: signed, error: signedError } = await admin.storage.from("ipa-jobs").createSignedUrl(job.manifest_path, 3600);
    if (signedError) return Response.json({ error: "Could not create install manifest URL." }, { status: 500, headers: cors });
    result.manifestUrl = signed.signedUrl.startsWith("http") ? signed.signedUrl : url + "/storage/v1" + signed.signedUrl;
  }
  return Response.json(result, { headers: cors });
});
