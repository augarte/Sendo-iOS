# Sendo architecture

The app uses one UIKit target. Organize code by feature so a developer can trace a user action from its screen to its model and persistence adapter.

- `App` assembles dependencies and owns scene and tab navigation.
- `Features/<Feature>/Domain` holds entities, validation, and interfaces needed by feature logic.
- `Features/<Feature>/Data` maps storage records and implements those interfaces.
- `Features/<Feature>/Presentation` holds view controllers, views, and view models.
- `Infrastructure` holds shared SDK and transport clients. `Shared/DesignSystem` holds reusable UI.

Progress is the reference implementation. The app injects a measurement repository into its view model. The view model exposes read-only screen state and accepts user actions. Firestore document IDs, timestamps, and field names stay in the data adapter. Unit tests use an in-memory repository for feature behavior and field dictionaries for mapping tests.

## Data model

| Entity | Identity and relationships |
|---|---|
| Exercise | The catalog's existing string ID. Keep instructions, muscle groups, equipment, and media with the catalog record. Planned exercises reference this ID. |
| BodyMeasurement | A stable ID with a separate measured date, kind, value, and optional unit. Weight is the current kind. Preserve missing units without assuming kilograms or pounds. |
| Workout plan | A plan has a stable ID and ordered sessions. Each planned session has its own ID and an ordered list of exercise prescriptions. A prescription references the catalog and defines sets, reps, and optional load. |
| Workout log | A performed session has its own ID and records dates, exercises, and actual sets. Keep the catalog reference and display information needed to read history after the plan or catalog changes. |
| Profile and preferences | Profile data belongs to the user. Device preferences such as appearance belong to the local installation. The session store observes Firebase Auth and switches Progress to a repository scoped to the active user. |

## Measurement storage compatibility

Progress continues to use `users/{uid}/measurements/{id}`. The reader accepts legacy records with an epoch-seconds document ID and a `value` field. The adapter derives the date from that ID when an explicit timestamp is absent and treats a missing kind as weight. Legacy records keep their original IDs.

A new draft gets a UUID that stays fixed across retries. New writes store `measuredAt`, `kind`, and `value`, plus `unit` when known. Editing updates the existing document in one operation. A failed update leaves the draft and displayed record available for retry.

Before distributing this schema to users, verify that deployed Firestore rules accept these fields. Coordinate rollout with any older build that derives dates solely from document IDs.

## Session ownership

Firebase Auth supplies the active user ID. Progress clears its screen state when the account changes. Requests are scoped to the user who started them, and an editor opened under one account cannot write under another.

When a guest signs in with a new provider account, Firebase links the credential to the existing guest UID. If the credential already belongs to an account, Sendo reads the guest history before switching accounts and stages valid measurements on the device until they can be imported. A transfer is scoped to the chosen provider identity. It uses a stable import ID per source record and creates missing records without overwriting the destination history. The original guest records remain available under their original UID. The local transfer is retried on launch or foregrounding and cleared after completion.

## Workout rotation and storage

Weekly training frequency is a preference independent of the ordered sessions in a plan. The rotation tracks the next session by ID, so completing four sessions of a five-session plan leaves session five next, even after a new week or a relaunch.

Workout storage is on this device. One atomic record saves the plan, rotation position, active workout, and completed logs together. Active workouts and logs retain a session snapshot so later plan edits preserve the recorded exercises. A finished workout with at least one logged set advances the rotation. Ending an empty workout leaves the current position intact.

## Exercise catalog

The catalog ships inside the app as the `ExerciseCatalog` data set in `Assets.xcassets/Exercises`: a JSON array of exercise records, sorted by title when loaded. It needs no network or sign-in. To add or change exercises, edit that JSON, keep existing IDs unchanged because plans reference them, and release an update. Exercise images are still loaded from the URLs in each record's `png` field.

Muscle filters group the catalog's anatomical names into ten groups (`MuscleGroup`): chest, back, shoulders, biceps, triceps, core, quads, hamstrings, glutes and calves. An exercise belongs to the groups of its primary muscles. Favourites are exercise IDs stored in `UserDefaults` on this device and are not synced to an account.

## First workout setup

On first launch without a saved plan, Workout offers setup for weekly training days and available equipment. The guest can review a starter template or build a plan in the same editor used after setup. Templates resolve exercises from the catalog and retain their IDs. A missing template exercise leaves manual setup available.

Saving the first plan commits the plan and training preferences together. Guests can defer setup and reopen it from the Workout toolbar. Existing plans open normally, and changing training preferences leaves the current rotation position intact.
