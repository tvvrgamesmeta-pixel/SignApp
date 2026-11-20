# SignApp

A mobile-friendly IPA signing frontend and iOS wrapper project connected to the SignApp Supabase project.

## User flow

1. Create a SignApp account or sign in with email and password.
2. Select an IPA file from the iOS Files app.
3. SignApp uploads it to the private Supabase Storage bucket.
4. An authenticated signing job is queued through GitHub Actions.
5. A macOS runner loads the signing identity from the `certificate/` folder, signs the IPA, and removes the private files afterward.
6. SignApp provides an OTA manifest. Tap **Install signed app** and confirm the iOS installation prompt.

The library starts empty; there are no fake sample apps.

## Certificate folder

The repository contains a `certificate/` folder. During each signing run, GitHub Actions creates:

- `certificate/signing.p12`
- `certificate/profile.mobileprovision`

The files are populated from protected Actions secrets at runtime and deleted at the end of the job. The `.gitignore` protects certificate and provisioning-profile files from being committed. Never upload private signing material to this public repository.

## Supabase connection

- Project ref: **hxjxekuvgufmnvbyzkre**
- URL: https://hxjxekuvgufmnvbyzkre.supabase.co
- Private Storage bucket: **ipa-jobs**
- Table: **public.sign_jobs**
- Edge Functions: **upload-ipa**, **signing-status**

The database migration has been applied and both Edge Functions are deployed. The browser uses only the public publishable key. The table has RLS enabled, and users can only read their own jobs. IPA files remain in a private bucket.

## Required owner setup before signing works

### Supabase Edge Function secrets

In Supabase Dashboard → Edge Functions → Secrets, add:
- **GITHUB_TOKEN** — a GitHub token with Actions read/write permission for tvvrgamesmeta-pixel/SignApp.

### GitHub Actions repository secrets

In GitHub → SignApp → Settings → Secrets and variables → Actions, add:
- **SUPABASE_URL** — https://hxjxekuvgufmnvbyzkre.supabase.co
- **SUPABASE_SERVICE_ROLE_KEY** — the project's server-side service-role/secret key.
- **SIGNING_CERTIFICATE_P12_BASE64** — base64-encoded signing certificate file.
- **SIGNING_CERTIFICATE_PASSWORD** — certificate password.
- **SIGNING_MOBILEPROVISION_BASE64** — base64-encoded provisioning profile.

Never commit a certificate, private key, password, GitHub token, or service-role key to this public repository. Keep the service-role key only in server-side secrets.

## Apple signing requirements

The provisioning profile must authorize the app identifier and intended distribution method. The certificate must match the profile. Some IPAs contain app extensions or special entitlements that require additional matching provisioning profiles; those cases may need extra signing configuration. A successful codesign operation does not guarantee every IPA can be installed.

iOS installation always requires user confirmation. Only sign apps you own or are authorized to use.

## Repository layout

- **certificate/** — protected signing files are materialized here only during CI signing.
- **index.html** — responsive website, Supabase account UI, and IPA workflow.
- **config.js** — public Supabase project URL, publishable key, and function endpoints.
- **assets/** — app icon and favicon.
- **ios/** — SwiftUI WKWebView app wrapper and library UI.
- **project.yml** — XcodeGen project configuration.
- **supabase/migrations/** — database and Storage setup.
- **supabase/functions/** — authenticated upload and job-status endpoints.
- **.github/workflows/sign-ipa.yml** — macOS IPA signing worker.
- **.github/workflows/pages.yml** — GitHub Pages deployment.
