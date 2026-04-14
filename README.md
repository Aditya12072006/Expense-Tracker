# expensetracker

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## iOS Build From Windows via GitHub Actions

This repository includes a workflow at .github/workflows/ios-build-and-lambdatest.yml.

What it does on each push to main or master (and manual run):

- Builds an unsigned iOS app on macOS and packages Runner-unsigned.ipa
- Uploads unsigned IPA as a downloadable GitHub Actions artifact
- Optionally builds a signed IPA if signing secrets are configured
- Optionally uploads the signed IPA to LambdaTest

### Required GitHub Secrets for signed IPA

Add these in GitHub repository settings under Secrets and variables, Actions:

- IOS_CERTIFICATE_BASE64: Base64 of your .p12 certificate
- IOS_CERTIFICATE_PASSWORD: Password for the .p12 certificate
- IOS_PROVISION_PROFILE_BASE64: Base64 of your .mobileprovision file
- IOS_EXPORT_OPTIONS_PLIST_BASE64: Base64 of ExportOptions.plist content

### Optional GitHub Secrets for LambdaTest upload

- LAMBDATEST_USERNAME
- LAMBDATEST_ACCESS_KEY
- LAMBDATEST_ORG_ID (optional)

### Notes

- Unsigned IPA can be downloaded from workflow artifacts but may not install on real iOS devices.
- Signed IPA is required for reliable real-device testing.
- If LambdaTest secrets are set, upload response is saved as a workflow artifact named lambdatest-upload-response.
