# SignApp

SignApp is a **native iOS IPA signing app**. The website is only an installation landing page; it is not the signer and does not contain a browser-based version of the app.

## User experience

1. Open the SignApp website in Safari on an iPhone or iPad.
2. Tap **Install on iPhone / iPad** to install the signed native app.
3. Open SignApp and sign in or create an account.
4. Choose an IPA from the iOS Files app.
5. SignApp uploads it to the private Supabase signing service.
6. The macOS signing worker signs the IPA and returns an OTA manifest.
7. Tap **Install Signed App** inside SignApp.

## Native app

- SwiftUI interface; no remote website is embedded in the app.
- Supabase email/password authentication.
- Session persistence on the device.
- iOS Files picker for IPA files.
- Upload, signing progress, and OTA installation link.
- App library UI is native and contained in the app.

## Website

GitHub Pages serves a minimal install page and `manifest.plist`. It does not expose the IPA signer UI. The install page uses Apple's `itms-services` OTA installation flow and points to the latest GitHub Release asset.

## Certificate folder

The signing workflows read these exact files from `certificate/`:

- `Chengdu Railway Bureau.p12`
- `Chengdu Railway Bureau.mobileprovision`
- `password.txt`

Keep these filenames unchanged. The workflows import the certificate into a temporary macOS keychain for the build/sign operation. They do not require Base64 certificate secrets.

## Supabase

- Project: `hxjxekuvgufmnvbyzkre`
- URL: https://hxjxekuvgufmnvbyzkre.supabase.co
- Storage bucket: `ipa-jobs`
- Edge Functions: `upload-ipa`, `signing-status`

The Edge Functions still require their server-side Supabase configuration and the GitHub Actions dispatch token. The service-role key must remain server-side; it is not embedded in the app.

## Build and publish

Push a version tag such as `v1.0.0` to run the signed iOS build workflow. It uses the certificate files above, exports `SignApp.ipa`, and publishes it as a GitHub Release asset. The website's OTA manifest references the latest release asset.

The provisioning profile must be compatible with bundle ID `com.cd-rail.zhct` and include the target device for ad-hoc installation. A valid Apple signing certificate and a matching profile are required. The first build must complete successfully before the website's Install button can install the app.

## Safety

Only sign apps you own or are authorized to use. Do not share signing credentials outside the people who need access.
