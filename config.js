// Public client configuration only. Never place a service-role or secret key here.
// accessToken must be a signed-in user's Supabase access token (JWT).
window.SIGNAPP_CONFIG = {
  uploadUrl: "https://hxjxekuvgufmnvbyzkre.supabase.co/functions/v1/upload-ipa",
  statusUrl: "https://hxjxekuvgufmnvbyzkre.supabase.co/functions/v1/signing-status?jobId={jobId}",
  publishableKey: "sb_publishable_QD-uPtgKnglULNGBZMaQ2Q_Hie5DpHx",
  accessToken: ""
};
