# HKImport

## About

Import HealthKit data from a device to simulator or another device. To import your own values, get an export.xml file from a device containing health data and replace the one added to this project in the Data folder:

1. Open Health app
2. Tap your avatar in the top-right corner
3. Tap Export All Health Data
4. Airdrop the exported file to your Mac
5. Replace the export.xml file in the project

Not all HealthKit record types are supported.

## Requirements

- iOS 26.0+

## Developer Setup (Code Signing)

This project is configured so each developer can use their own Apple Developer account without changing committed project files.

1. Run the setup script:

```bash
./setup.sh
```

Or manually:

2. Copy the template:

```bash
cp DeveloperSettings.template.xcconfig DeveloperSettings.xcconfig
```

3. Update `DeveloperSettings.xcconfig` with your values:

```xcconfig
CODE_SIGN_IDENTITY = Apple Development
DEVELOPMENT_TEAM = <Your Team ID>
CODE_SIGN_STYLE = Automatic
ORGANIZATION_IDENTIFIER = <Your Reversed Domain>
```

`DeveloperSettings.xcconfig` is gitignored and loaded automatically by `HKImport/HKImportConfig.xcconfig`.

## Origin

This repository was forked from [HealthKitImporter](https://github.com/Comocomo/HealthKitImporter).
