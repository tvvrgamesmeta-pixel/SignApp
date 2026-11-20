// Configure these endpoints after deploying the signing backend.
// uploadUrl: POST multipart/form-data field "file"; response: { jobId: "..." }
// statusUrl: GET endpoint containing {jobId}; response: {status:"queued"|"running"|"failed"|"complete", manifestUrl:"..."}
window.SIGNAPP_CONFIG = {
  uploadUrl: "",
  statusUrl: "",
  apiKey: ""
};