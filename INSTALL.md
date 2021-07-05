# Compiling ChurchData source code

## Requirements

1. [Flutter SDK](https://flutter.dev/docs/get-started/install) (v2.2.0 or later)
2. Firebase App
3. [Firebase CLI](https://firebase.google.com/docs/cli) (either using npm (recommended) or the standalone binary)

## Steps

### 1. Download and install the Flutter SDK on your local machine

### 2. Create Firebase App

1. Go to https://console.firebase.google.com/ and follow the steps to create new Firebase App

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
   - Dynamic Links

### 3. Google Maps API

1. Get an API key at https://cloud.google.com/maps-platform

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

### 4. Connect the App:

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

### 6. Firebase Cloud Functions

Some functionalities in the app requires using the cloud functions API like managing users, setting permissions using token... etc

1. Clone the repo
2. Open cmd in 'Firebase CLI Smaple' directory and run `firebase init`
3. Implement encrypting algorithm in the `functions/src/userEndpoints.ts` file
4. Edit the `adminPassword` and (optional) `packageName` variables
5. Get the project web API key and put it in `firestore-triggers.ts`
6. (Optional) Edit the following files:
   - database-rules.json
   - firestore.rules
   - firestore.indexes.json
7. Deploy the project using the command `firebase deploy`

#### Firebase Auto-Backup

1. Create new Cloud Storage bucket from google cloud platform and give it the name '{your project id}-firestore-backup'
2. Give 'Cloud Datastore Import Export Admin' permission to app engine defualt account
3. Give 'Owner' or 'Storage Admin' permission for the same service account for the created bucket
   > For more info see [this](https://firebase.google.com/docs/firestore/solutions/schedule-export#configure_access_permissions)

### 7. Flutter app

In order to complete the compilation of the app you have to create a file named `EncryptionKeys.dart` inside the `lib` directory with the following structure:

```dart
class Encryption {
  static String encryptPassword(String q) {
    //TODO: Implement Encryption algorithm
    //return encrypted Password
  }

  static Future setUserData(Map<String, dynamic> data) async {
    //TODO: Implement Encryption algorithm
    //Sets the User Data
  }

  static Future<Map<String, dynamic>> getUserData() async {
    //TODO: Implement Encryption algorithm
    //return UserData
  }

}

```
