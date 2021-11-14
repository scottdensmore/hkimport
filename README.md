# HKImport

## About

Import HealthKit data from a device to simulator or another device. To import your own values, get an export.xml file from a device containing health data and replace the one added to this project in the Data folder:

1. Open Health app
2. Tap your avatar in the top-right corner
3. Tap Export All Health Data
4. Airdrop the exported file to your Mac
5. Replace the export.xml file in the project

Not all HealthKit record types are supported.

## Origin

This repository was forked from [HealthKitImporter](https://github.com/Comocomo/HealthKitImporter).

#### Building

HKImport relies on [swiftlint](https://realm.github.io/SwiftLint/). Itcan be installed 
via [homebrew](https://brew.sh) via the provided `Brewfile` by running `brew bundle`
or manually.

You can locally override the Xcode settings for code signing
by creating a `DeveloperSettings.xcconfig` file locally at the root of the project directory.
This allows for a pristine project with code signing set up with the appropriate
developer ID and certificates, and for developer to be able to have local settings
without needing to check in anything into source control.

You can do this in one of two ways: using the included `setup.sh` script or by creating the folder structure and file manually.

##### Using `setup.sh`

- Open Terminal and `cd` into the project directory. 
- Run this command to ensure you have execution rights for the script: `chmod +x setup.sh`
- Execute the script with the following command: `./setup.sh` and complete the answers.

##### Manually 

Create a plain text file in it: `DeveloperSettings.xcconfig` and
give it the contents:

```
CODE_SIGN_IDENTITY = Apple Development
DEVELOPMENT_TEAM = <Your Team ID>
CODE_SIGN_STYLE = Automatic
ORGANIZATION_IDENTIFIER = <Your Domain Name Reversed>
```

Set `DEVELOPMENT_TEAM` to your Apple supplied development team.  You can use Keychain
Access to [find your development team ID](/Technotes/FindingYourDevelopmentTeamID.md).
Set `ORGANIZATION_IDENTIFIER` to a reversed domain name that you control or have made up.

Now you should be able to build without code signing errors and without modifying
the project.