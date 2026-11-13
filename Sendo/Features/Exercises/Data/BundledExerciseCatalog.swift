import Combine
import UIKit

/// The exercise catalog shipped inside the app as the `ExerciseCatalog` data set in the asset catalog.
/// To change the catalog, replace that data set's JSON (an array of exercise records) and release an update.
struct BundledExerciseCatalog: ExerciseCatalog {
    func fetchExerciseList() -> AnyPublisher<[Exercise], Error> {
        Deferred {
            Future<[Exercise], Error> { promise in
                guard let data = NSDataAsset(name: "ExerciseCatalog")?.data,
                      let records = try? JSONSerialization.jsonObject(with: data) as? [Any] else {
                    return promise(.failure(ExerciseCatalogError.unavailable))
                }
                let exercises = records.compactMap { ExerciseRecord.decode($0) }
                    .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
                promise(.success(exercises))
            }
        }
        .eraseToAnyPublisher()
    }
}

enum ExerciseRecord {
    static func decode(_ value: Any?) -> Exercise? {
        guard let fields = value as? [String: Any], let id = fields["id"] as? String else {
            return nil
        }

        return Exercise(
            id: id,
            name: fields["name"] as? String ?? "",
            title: fields["title"] as? String ?? "",
            type: fields["type"] as? String ?? "",
            description: fields["primer"] as? String ?? "",
            steps: fields["steps"] as? [String] ?? [],
            tips: fields["tips"] as? [String] ?? [],
            primary: fields["primary"] as? [String] ?? [],
            secondary: fields["secondary"] as? [String] ?? [],
            equipment: fields["equipment"] as? [String] ?? [],
            images: fields["png"] as? [String] ?? []
        )
    }
}
