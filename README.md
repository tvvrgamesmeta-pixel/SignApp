# SignApp

A mobile-friendly IPA signing frontend and iOS wrapper project.

## User flow

1. Select an `.ipa` file from the iOS Files app.
2. SignApp uploads it to the private Supabase Storage bucket.
3. An authenticated signing job is queued.
4. A macOS GitHub Actions runner signs the IPA using the configured Apple certificate and provisioning profile.
5. SignApp receives a hosted OTA manifest. Tap **Install signed app** and confirm the iOS installation prompt.

The library starts empty. It does not contain fake sample apps.

## Repository layout

- `index.html` — responsive website and IPA upload/sign/install interface.
- `config.js` — Supabase Edge Function endpoints.
- `assets/signapp-icon.svg`, `favicon.svg` — reusable app icon and favicon.
- `ios/` — SwiftUI WKWebView app wrapper and mobile library UI.
- `project.yml` — XcodeGen project configuration.
- `supabase/migrations/` — private jobs table and Storage bucket.
- `supabase/functions/upload-ipa/` — authenticated upload and GitHub Actions dispatch.
- `supabase/functions/signing-status/` — authenticated job status and OTA manifest URL.
- `.github/workflows/sign-ipa.yml` — macOS IPA signing worker.
- `.github/workflows/build.yml` — iOS client build workflow.
- `.github/workflows/pages.yml` — GitHub Pages deployment.

## Backend setup

The source is restored, but signing will not start until the project owner configures their own Supabase project and Apple signing credentials.

### 1. Supabase database and storage

Run `supabase/migrations/202611200001_signapp.sql` in the Supabase SQL Editor. Ensure the `public` schema is exposed to the Data API for the signing worker's service-role REST calls.

Deploy both Edge Functions:
- `upload-ipa`
- `signing-status`

Set these Edge Function secrets:
- `GITHUB_TOKEN` — fine-grained GitHub token with Actions read/write permission for this repository.
- `GITHUB_REPOSITORY` — `tvvrgamesmeta-pixel/SignApp`
- `GITHUB_WORKFLOW` — `sign-ipa.yml`

### 2. GitHub Actions secrets

Add the following repository Actions secrets:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SIGNING_CERTIFICATE_P12_BASE64`
- `SIGNING_CERTIFICATE_PASSWORD`
- `SIGNING_MOBILEPROVISION_BASE64`

The P12 and provisioning profile should be base64-encoded before being saved as secrets. Never commit certificates, private keys, passwords, access tokens, or service-role keys to this public repository.

### 3. Website configuration

Edit `config.js`:
- Replace `YOUR_PROJECT_REF` with the Supabase project reference.
- Set `apiKey` to the current signed-in user's Supabase access token (JWT).

The website sends the selected IPA as multipart form data to `upload-ipa`, then polls `signing-status`. The project owner must provide a sign-in flow and supply a valid user access token; do not put a service-role key in browser code.

### 4. Apple signing requirements

The provisioning profile must authorize the app identifier and the intended device/distribution method. The certificate must match the profile. Some IPAs contain app extensions or app-specific entitlements that require their own matching provisioning profiles; those cases may need additional signing configuration. A successful codesign operation alone does not guarantee every IPA can be installed.

iOS installation is always user-confirmed. SignApp cannot silently install apps or make an ineligible device eligible.

## GitHub Pages

Enable Pages in **Settings → Pages → GitHub Actions**. The Pages workflow deploys the root website.

## iOS app

The `ios/` directory and `project.yml` can be used to generate an Xcode project with XcodeGen and build on macOS.

## Safety

Only sign and install apps you own or are authorized to distribute. Review the source and trust the signing identity before installing an app.
