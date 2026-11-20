// Set these values to your Supabase project after deploying the Edge Functions.
// apiKey must be a signed-in user's access token (JWT), never a service-role key.
window.SIGNAPP_CONFIG = {
  uploadUrl: "https://YOUR_PROJECT_REF.supabase.co/functions/v1/upload-ipa",
  statusUrl: "https://YOUR_PROJECT_REF.supabase.co/functions/v1/signing-status?jobId={jobId}",
  apiKey: ""
};