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
| Workout plan (planned) | A plan has a stable ID and ordered sessions. Each planned session has its own ID and an ordered list of exercise prescriptions. A prescription references the catalog and defines sets, reps, and optional load. |
| Workout log (planned) | A performed session has its own ID and records dates, exercises, and actual sets. Keep the catalog reference and display information needed to read history after the plan or catalog changes. |
| Profile and preferences | Profile data belongs to the user. Device preferences such as appearance belong to the local installation. Define the session lifecycle with the Auth work. |

## Measurement storage compatibility

Progress continues to use `users/{uid}/measurements/{id}`. The reader accepts legacy records with an epoch-seconds document ID and a `value` field. The adapter derives the date from that ID when an explicit timestamp is absent and treats a missing kind as weight. Legacy records keep their original IDs.

A new draft gets a UUID that stays fixed across retries. New writes store `measuredAt`, `kind`, and `value`, plus `unit` when known. Editing updates the existing document in one operation. A failed update leaves the draft and displayed record available for retry.

Before distributing this schema to users, verify that deployed Firestore rules accept these fields. Coordinate rollout with any older build that derives dates solely from document IDs.
