import { createClient } from "https://esm.sh/@supabase/supabase-js@2.57.4";
const cors = {"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type","Access-Control-Allow-Methods":"POST, OPTIONS"};
function envSecret(name: string) { const direct=Deno.env.get(name); if(direct)return direct; const map=JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS")??"{}"); return map.default??""; }
Deno.serve(async (req) => {
  if(req.method==="OPTIONS") return new Response("ok",{headers:cors});
  if(req.method!=="POST") return Response.json({error:"Method not allowed"},{status:405,headers:cors});
  const authorization=req.headers.get("Authorization")??"";
  if(!authorization.startsWith("Bearer ")) return Response.json({error:"Sign in first."},{status:401,headers:cors});
  const supabaseUrl=Deno.env.get("SUPABASE_URL")??"";
  const anonKey=Deno.env.get("SUPABASE_ANON_KEY")??"";
  const serviceKey=envSecret("SUPABASE_SERVICE_ROLE_KEY");
  const githubToken=Deno.env.get("GITHUB_TOKEN");
  const repository=Deno.env.get("GITHUB_REPOSITORY")??"tvvrgamesmeta-pixel/SignApp";
  const workflow=Deno.env.get("GITHUB_WORKFLOW")??"sign-ipa.yml";
  if(!supabaseUrl||!anonKey||!serviceKey) return Response.json({error:"Supabase function secrets are incomplete."},{status:503,headers:cors});
  const userClient=createClient(supabaseUrl,anonKey,{global:{headers:{Authorization:authorization}}});
  const {data:{user},error:authError}=await userClient.auth.getUser();
  if(authError||!user) return Response.json({error:"Invalid sign-in session."},{status:401,headers:cors});
  if(!githubToken) return Response.json({error:"Signing worker is not configured by the project owner."},{status:503,headers:cors});
  let form:FormData; try{form=await req.formData()}catch{return Response.json({error:"Expected a multipart IPA upload."},{status:400,headers:cors})}
  const file=form.get("file");
  if(!(file instanceof File)||!file.name.toLowerCase().endsWith(".ipa")) return Response.json({error:"Choose a valid .ipa file."},{status:400,headers:cors});
  if(file.size<1||file.size>500*1024*1024) return Response.json({error:"IPA must be between 1 byte and 500 MB."},{status:413,headers:cors});
  const admin=createClient(supabaseUrl,serviceKey),jobId=crypto.randomUUID(),inputPath=user.id+"/"+jobId+"/input.ipa";
  const {error:uploadError}=await admin.storage.from("ipa-jobs").upload(inputPath,file,{contentType:"application/octet-stream",upsert:false});
  if(uploadError) return Response.json({error:"Secure upload failed: "+uploadError.message},{status:502,headers:cors});
  const {error:rowError}=await admin.from("sign_jobs").insert({id:jobId,user_id:user.id,original_name:file.name.slice(0,180),input_path:inputPath,status:"queued"});
  if(rowError){await admin.storage.from("ipa-jobs").remove([inputPath]);return Response.json({error:"Could not create signing job."},{status:500,headers:cors})}
  const dispatch=await fetch("https://api.github.com/repos/"+repository+"/actions/workflows/"+workflow+"/dispatches",{method:"POST",headers:{Authorization:"Bearer "+githubToken,Accept:"application/vnd.github+json","X-GitHub-Api-Version":"2022-11-28"},body:JSON.stringify({ref:"main",inputs:{job_id:jobId}})});
  if(!dispatch.ok){await admin.from("sign_jobs").update({status:"failed",error_message:"Unable to start the signing runner."}).eq("id",jobId);return Response.json({error:"Could not start signing runner. Check backend configuration."},{status:502,headers:cors})}
  return Response.json({jobId,status:"queued"},{headers:cors});
});