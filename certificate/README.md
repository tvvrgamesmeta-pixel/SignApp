# Private signing certificate files

This folder is the runtime location used by the macOS signing workflow.

The workflow writes these files here during a signing run:
- `signing.p12` — Apple signing certificate and private key.
- `profile.mobileprovision` — matching provisioning profile.

They are decoded from protected GitHub Actions secrets at runtime and deleted when the job finishes. Do not commit either file to this public repository.

The `.gitignore` intentionally excludes certificate and provisioning-profile files in this folder.
