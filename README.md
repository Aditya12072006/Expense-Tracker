# expensetracker

A new Flutter project.

## Third-Party APK Store Readiness (Uptodown, APKPure, etc.)

This app is now configured for direct APK distribution outside Google Play/App Store.

### Implemented in this project

- In-app Privacy Policy page in Settings
- In-app App Info page (version name, build number, package name)
- In-app Open Source Licenses page
- In-app clear local data action (for user data deletion)
- Android manifest network permissions for payment/web connectivity
- Release signing configuration using android/key.properties
- Android application ID preserved: com.example.expensetracker

### Required before uploading APK

1. Set a stable app version in pubspec.yaml (example: 1.2.0+12).
2. Generate a release keystore if you do not have one.
3. Copy android/key.properties.example to android/key.properties and fill real values.
4. Place your .jks keystore in android/ and ensure it is not committed.
5. Build a signed release APK.
6. Verify install on at least one real Android device.

### Build signed APK (Windows PowerShell)

1. Generate keystore (first time only):

	keytool -genkey -v -keystore android/upload-keystore.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000

2. Update signing config:

	Copy android/key.properties.example to android/key.properties and set:

	- storePassword
	- keyPassword
	- keyAlias
	- storeFile

3. Build APK:

	flutter clean
	flutter pub get
	flutter build apk --release

4. Output file:

	build/app/outputs/flutter-apk/app-release.apk

### Store listing items you still need to prepare manually

- App title and short description
- Full description and changelog
- Screenshots and app icon (store assets)
- Category and tags
- Support email: aditya12072006@gmail.com
- Public privacy policy URL (recommended for store submission forms)

If your store asks for architecture-specific APKs, use split build:

flutter build apk --release --split-per-abi

Outputs:

- app-armeabi-v7a-release.apk
- app-arm64-v8a-release.apk
- app-x86_64-release.apk

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
