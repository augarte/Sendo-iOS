# Firebase testing

Run the `Sendo Dev` scheme's tests on an iOS simulator. The hosted unit tests and UI tests launch in Debug fixture mode. The exercise catalog and measurement repository are in memory, and the app skips Firebase initialization. Launch the app from Xcode with `--sendo-fixtures` to inspect the same fixture screens. Simulator builds skip Crashlytics symbol upload.

Use the Firebase CLI and Java 21 for local Auth and Firestore testing:

```sh
firebase emulators:start --project demo-sendo \
  --config TestSupport/Firebase/firebase.json --only auth,firestore
```

The demo project and loopback addresses isolate the emulators from live data. The rules under `TestSupport` apply to the emulator. Treat verification of the deployed Firebase rules as a separate release task.
