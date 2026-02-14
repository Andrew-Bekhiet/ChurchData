# Compiling ChurchData source code

## Overview

This guide covers setting up the ChurchData application, which consists of:

- **Frontend**: Flutter app for Android (and iOS support available)
- **Backend**: Firebase services including Authentication, Cloud Firestore, Realtime Database, Cloud Storage, and Cloud Functions

## Requirements

1. [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.0 or later)
2. Java (e.g. JDK 17) for Android builds — Flutter and Gradle use it for compiling the app
3. Firebase App
4. [Firebase CLI](https://firebase.google.com/docs/cli) (either using npm (recommended) or the standalone binary)

## Steps

### 1. Download and install the Flutter SDK on your local machine

After installing Flutter, clone the repository and run:

```bash
flutter pub get
```

This will fetch all dependencies including the `churchdata_core` package from GitHub.

### 2. Create Firebase App

1. Go to <https://console.firebase.google.com/> and follow the steps to create new Firebase App

2. Add android App and follow the instructions to download the `google-services.json` file and save it in `android/app/` directory

3. Enable the following Firebase APIs:
   - Authentication
   - Cloud Firestore
   - Realtime Database
   - Storage
   - Functions (requires Blaze plan)
   - Crashlytics (optional but recommended)
   - Cloud Messaging
   - In-App Messaging (optional for updates messages)
   - Remote Config (optional for latest version and update mechanism)

### 3. Google Maps API

1. Get an API key at <https://cloud.google.com/maps-platform>

2. Click Get started

3. Enable Google Map SDK for each platform.
   - Go to [Google Developers Console](https://console.cloud.google.com/).
   - Choose the project that you want to enable Google Maps on.
   - Select the navigation menu and then select "Google Maps".
   - Select "APIs" under the Google Maps menu.
   - To enable Google Maps for Android, select "Maps SDK for Android" in the "Additional APIs" section, then select "ENABLE".
   - To enable Google Maps for iOS, select "Maps SDK for iOS" in the "Additional APIs" section, then select "ENABLE".
   - Make sure the APIs you enabled are under the "Enabled APIs" section.

   - You can also find detailed steps to get start with Google Maps Platform [here](https://developers.google.com/maps/gmp-get-started).

4. Create strings file and put your GMaps API key `android/app/src/main/res/values/strings.xml`:

```xml
<resources>
    ...
    <string name="gmaps_api_key">Your GMaps API Key</string>
    ...
</resources>
```

### 4. Android Signing Configuration

1. Generate keystore for debug `dKey.jks` and another for release `rKey.jks`

   > For how to create keystores refer to [flutter documentation](https://flutter.dev/docs/deployment/android#signing-the-app)

2. Put the keystores in `android/app/` directory

3. Create `debugKey.properties` and `releaseKey.properties` files with the following structure:
   - Release key:

     ```
     storePassword=<your store password>
     keyPassword=<your key password>
     keyAlias=<your key alias>
     storeFile=rKey.jks
     ```

   - Debug key:

     ```
     storePassword=<your store password>
     keyPassword=<your key password>
     keyAlias=<your key alias>
     storeFile=dKey.jks
     ```

4. Put the `debugKey.properties` and `releaseKey.properties` files in the `android/` directory

5. Get the SHA-1 and SHA-256 fingerprints of each of the keystores ([more info here](https://stackoverflow.com/questions/15727912/sha-1-fingerprint-of-keystore-certificate)) and put them in the firebase console in android app configurations

### 5. Firebase Cloud Functions

Some functionalities in the app requires using the cloud functions API like managing users, setting permissions using token... etc

1. Clone the repo (if not already done)

2. Navigate to the `Firebase CLI Sample` directory and install dependencies:

   ```bash
   cd "Firebase CLI Sample/functions"
   npm install
   ```

3. Run `firebase init` from the `Firebase CLI Sample` directory (if setting up for the first time, or use the existing `firebase.json` configuration)

4. Edit the `adminPassword` in `functions/src/adminPassword.ts`:
   - Open the file and replace `"{admin password}"` with your desired admin password

5. (Optional) Edit the `packageName` variable if you're using a different Android application ID than `com.AndroidQuartz.churchdata`:
   - Update `applicationId` in `android/app/build.gradle`
   - Update `restrictedPackageName` references in `functions/src/firestore-triggers.ts`

6. (Optional) Edit the following files:
   - database-rules.json
   - firestore.rules
   - firestore.indexes.json

7. Deploy the project using the command `firebase deploy --only functions`

> **Note**: The Firebase Functions use Node.js. The current `package.json` specifies Node 14, which is EOL. Consider updating to Node 18 or 20 by changing the `"node"` value in the `engines` field of `functions/package.json`.

#### Firestore Automatic Backup to Google Cloud Storage

The application includes automated weekly backups of Firestore data. To set this up:

1. **Create the backup bucket**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Navigate to Cloud Storage
   - Create a new bucket named exactly `{your-project-id}-firestore-backup` (replace `{your-project-id}` with your actual Firebase project ID)

2. **Grant IAM permissions for export**:
   - In Google Cloud Console, go to IAM & Admin
   - Find the **App Engine default service account** (or the service account used by Cloud Functions)
   - Grant it the role **Cloud Datastore Import Export Admin** at the project level

3. **Grant bucket access**:
   - Go to your `{your-project-id}-firestore-backup` bucket
   - In the Permissions tab, grant the same service account **Storage Admin** or **Owner** role on the bucket

4. **Deploy the function**:
   - The backup function is already configured to run weekly (every Sunday at midnight)
   - Deploy it with: `firebase deploy --only functions`

5. **Optional - Verify backup configuration**:
   - The function exports to: `gs://{projectId}-firestore-backup/{timestamp}/`
   - Collections backed up include: Areas, Streets, Families, Persons, Invitations, Users, Churches, Classes, Colleges, Fathers, Jobs, Schools, ServingTypes, States, StudyYears, Types, and history collections

> For more information, see the [Firebase documentation on scheduled exports](https://firebase.google.com/docs/firestore/solutions/schedule-export#configure_access_permissions)

### 6. Flutter App Configuration

#### EncryptionKeys.dart Setup

In order to complete the compilation of the app you have to create a file named `EncryptionKeys.dart` inside the `lib` directory with the following structure:

```dart
// ignore_for_file: file_names

import 'dart:convert';

import 'package:pointycastle/digests/sha3.dart';
import 'package:pointycastle/pointycastle.dart';

const sentryDSN = 'your sentry DSN';
const String googleSignInServerClientId = 'your google sign in web client id';

class Encryption {
  static String encryptPassword(String q) {
    // TODO: implement hashing algorithm
  }
}

```

**Required configuration**:

1. **Sentry DSN** (for error reporting):
   - Sign up or log in to [Sentry](https://sentry.io)
   - Create a project or use an existing one
   - Go to Project Settings → Client Keys (DSN)
   - Copy the DSN and paste it in the `sentryDSN` constant

2. **Google Web Client ID** (for Google Sign-In):
   - First, set up Google Sign-In for Android: In the [Firebase Console](https://console.firebase.google.com/), ensure you have added your Android app and downloaded `google-services.json` (see step 2). This registers your app for Google Sign-In.
   - Then get the Web client ID: Go to [Google Cloud Console](https://console.cloud.google.com/) (same project as your Firebase app) → APIs & Services → Credentials.
   - Under "OAuth 2.0 Client IDs", create or use an existing **Web application** client (not the Android client). Copy that Client ID and paste it in the `googleSignInServerClientId` constant.

#### Building the app

Once the above configuration is in place, build the release APK with:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build apk
```

The `build_runner` step generates code used by the app; the CI uses the same sequence. The output APK is at `build/app/outputs/flutter-apk/app-release.apk`.

### Optional: GitHub Actions CI for release builds

The repository includes a workflow at [.github/workflows/release-app.yml](.github/workflows/release-app.yml) that builds the Android APK and creates a GitHub release. It runs only when:

- The push commit message contains `[ci release]`, or
- The workflow is triggered manually (Actions → "Build and Release app" → Run workflow)

and only for the repository owner.

To use it, add the following **repository secrets** (Settings → Secrets and variables → Actions). Each secret must be the **base64-encoded** contents of the corresponding file (no newlines; single line).

| Secret name | File to encode | Resulting path in CI |
|-------------|----------------|----------------------|
| `ANDROID_SIGNING_KEY` | Release keystore `rKey.jks` | `android/app/rKey.jks` |
| `ANDROID_STRINGS` | `android/app/src/main/res/values/strings.xml` | `android/app/src/main/res/values/strings.xml` |
| `GOOGLE_SERVICES_JSON` | `android/app/google-services.json` | `android/app/google-services.json` |
| `ANDROID_KEYSTORE_PROPERTIES` | `android/releaseKey.properties` | `android/releaseKey.properties` |
| `ENCRYPTION_KEYS_DART` | `lib/EncryptionKeys.dart` | `lib/EncryptionKeys.dart` |

**Encoding the files** (use the same project files you created from the steps above):

- **macOS**: `base64 -i path/to/file -o - | tr -d '\n' | pbcopy` then paste into the secret value.
- **Linux**: `base64 -w 0 path/to/file` and copy the output.

The workflow creates an empty `.env` file automatically; you do not need a secret for it. The workflow uses Flutter stable and Java 17 (Corretto) and runs the same build steps: `flutter pub get`, `dart run build_runner build --delete-conflicting-outputs`, then `flutter build apk`. The APK is attached to the release with a version tag taken from `pubspec.yaml`.
