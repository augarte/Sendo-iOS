# Firebase testing

Run the `Sendo Dev` scheme's tests on an iOS simulator. The hosted unit tests and UI tests launch in Debug fixture mode. The exercise catalog and measurement repository are in memory, and the app skips Firebase initialization. Launch the app from Xcode with `--sendo-fixtures` to inspect the same fixture screens. Simulator builds skip Crashlytics symbol upload.

Use the Firebase CLI and Java 21 for local Auth and Firestore testing:

```sh
firebase emulators:start --project demo-sendo \
  --config TestSupport/Firebase/firebase.json --only auth,firestore
```

The demo project and loopback addresses isolate the emulators from live data. The rules under `TestSupport` apply to the emulator. Treat verification of the deployed Firebase rules as a separate release task.

With both emulators running, run the shared `Sendo Firebase Integration` scheme on an iOS simulator. The scheme enables the integration suite explicitly. It configures a named Firebase app with synthetic credentials and routes Auth and Firestore to loopback.

```sh
xcodebuild -project Sendo.xcodeproj -scheme 'Sendo Firebase Integration' \
  -destination 'platform=iOS Simulator,id=<simulator-udid>' \
  -parallel-testing-enabled NO test
```

The suite exercises the real measurement adapter and emulator rules. It covers legacy reads, create, same-ID backdating, retry, delete, cross-account rejection, guest linking, and a resumable guest transfer. It uses simulated provider credentials. Physical Apple and Google sign-in and deployed rules are separate checks before release.
