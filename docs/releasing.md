# Releasing Markdown Viewer

Public binaries must be signed with a Developer ID Application certificate, use the hardened runtime, and be notarized by Apple. Development builds and CI builds intentionally do not contain distribution credentials.

## Prerequisites

- active Apple Developer Program membership
- Developer ID Application certificate in the login keychain
- App Store Connect API key or a notarization keychain profile
- clean `main` branch with passing CI

## Release checklist

1. Update `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.yml`.
2. Run `./scripts/test.sh`.
3. Generate the project with `./scripts/bootstrap.sh`.
4. Archive the `MarkdownViewer` scheme with the Developer ID identity.
5. Export the app for Developer ID distribution.
6. Put the app in a DMG, sign the DMG, and submit it with `xcrun notarytool`.
7. Staple and validate the ticket with `xcrun stapler`.
8. Verify with `spctl --assess --type execute --verbose` on a clean Mac account.
9. Create a signed Git tag and attach the notarized DMG to a GitHub Release.

Never store certificates, `.p8` files, passwords, or notary credentials in the repository.

