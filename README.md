# SignApp

A mobile-friendly IPA signing frontend and iOS wrapper project.

## Current status

The repository has been restored with the website, responsive IPA picker, upload/sign/install interface, icon assets, and iOS build workflow foundation.

**Important:** the browser interface requires a real signing backend. It does not claim to sign files locally. Configure `config.js` with your backend endpoints before using the Sign button.

## User flow

1. Select an `.ipa` file from iOS Files.
2. Upload it to your private signing service.
3. The macOS runner signs the IPA using your certificate and provisioning profile.
4. The service returns a hosted OTA `manifest.plist`.
5. Tap **Install signed app** and confirm the iOS installation prompt.

The provisioning profile must authorize the target app identifier and the device must be eligible under the profile. iOS does not permit a website to silently install arbitrary IPA files.

## Required backend contract

Set `uploadUrl` and `statusUrl` in `config.js`.

- Upload: `POST multipart/form-data`, file field named `file`.
- Upload response: `{ "jobId": "unique-job-id" }`.
- Status: `GET` URL with `{jobId}` replaced by the job ID.
- In-progress response: `{ "status": "queued" }` or `{ "status": "running" }`.
- Success response: `{ "status": "complete", "manifestUrl": "https://…/manifest.plist" }`.
- Failure response: `{ "status": "failed", "error": "Reason" }`.

The backend must authenticate requests, enforce upload-size limits, validate IPA archives, isolate jobs, and keep signing material private. Never put a P12, private key, certificate password, or API secret in this public repository or in frontend JavaScript.

## GitHub Pages

Enable Pages in **Settings → Pages → Deploy from a branch → main → /(root)**. The site is `index.html`.

## iOS app

The `ios/` directory and XcodeGen project configuration can be used to build the native WKWebView wrapper on a macOS runner. The web UI remains usable directly in Safari.

## Signing credentials

Use protected repository Actions secrets or a private signing service. Recommended secrets include a base64-encoded P12, its password, and the provisioning profile. Do not commit credential files.

## Safety

Only sign apps you own or are authorized to distribute. Do not use signing to bypass an app developer's security controls or distribute modified apps without permission.
