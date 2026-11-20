// Public client configuration only. Never place a service-role key here.
// accessToken must be a signed-in user's short-lived Supabase access token (JWT).
window.SIGNAPP_CONFIG = {
  uploadUrl: "https://YOUR_PROJECT_REF.supabase.co/functions/v1/upload-ipa",
  statusUrl: "https://YOUR_PROJECT_REF.supabase.co/functions/v1/signing-status?jobId={jobId}",
  publishableKey: "YOUR_SUPABASE_PUBLISHABLE_KEY",
  accessToken: ""
};