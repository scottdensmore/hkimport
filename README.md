# HKImport

## About

`HKImport` imports Apple Health export data (`export.xml`) into HealthKit on a simulator or another device.

The app reads records from XML and writes supported sample types into HealthKit after permission is granted.

## Requirements

- iOS 26.0+
- Xcode with iOS 26 SDK support
- Apple Developer team for code signing

## Quick Start

1. Configure local code-signing settings:

```bash
./setup.sh
```

This also configures repo git hooks, including a guard that blocks accidental commits of `Data/export.xml`.

2. Open `HKImport.xcodeproj` in Xcode.
3. Select a target device/simulator and run the app.
4. Tap **Start Import** and grant Health access when prompted.

## Importing Your Own Data

Get `export.xml` from the Health app on a source device:

1. Open Health.
2. Tap your profile avatar.
3. Tap **Export All Health Data**.
4. Airdrop or copy the export to your Mac.

Then provide `export.xml` to this app using either method:

1. Replace `Data/export.xml` and rebuild.
2. Or place `export.xml` in the app's Documents directory on the target runtime (this file takes priority over the bundled one).

To protect private data, commits that stage `Data/export.xml` are blocked by default.
If you intentionally need to commit that file, run:

```bash
ALLOW_EXPORT_XML_COMMIT=1 git commit ...
```

## What You See In-App

- `Read count`: records parsed from XML.
- `Write count`: samples/workouts saved to HealthKit.
- `Status`: current import phase or failure details.

`Write count` may continue increasing after parsing completes because saves continue asynchronously in the background.

## Supported Data Notes

- Not all HealthKit record types are supported.
- Unsupported or unauthorized records are skipped.
- Very long-duration samples are skipped to avoid HealthKit save failures.

## Developer Setup (Manual Alternative)

If you do not use `./setup.sh`:

1. Copy `DeveloperSettings.template.xcconfig` to `DeveloperSettings.xcconfig`.
2. Set:

```xcconfig
CODE_SIGN_IDENTITY = Apple Development
DEVELOPMENT_TEAM = <YOUR_APPLE_TEAM_ID>
CODE_SIGN_STYLE = Automatic
ORGANIZATION_IDENTIFIER = <YOUR_REVERSED_DOMAIN>
```

`DeveloperSettings.xcconfig` is gitignored and loaded automatically by `HKImport/HKImportConfig.xcconfig`.
3. Configure repo hooks manually:

```bash
git config core.hooksPath .githooks
```

## Troubleshooting

- `Import failed: export.xml was not found.`  
  Ensure `Data/export.xml` exists in the project or `export.xml` is present in the app Documents directory.
- `Import failed: Health access was not granted.`  
  Re-enable Health permissions for the app and run import again.
- Parse errors  
  Confirm the file is a valid Apple Health `export.xml`.
