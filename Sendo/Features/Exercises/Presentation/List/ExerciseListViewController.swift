import SwiftUI

final class ExerciseListViewController: BaseTabViewController {
    private let exerciseViewModel: ExerciseListViewModel

    init(viewModel: ExerciseListViewModel) {
        exerciseViewModel = viewModel
        super.init(title: "Exercises", image: "ListWhite")
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        embedSendoScreen(UIHostingController(rootView: ExerciseCatalogScreen(model: exerciseViewModel) { [weak self] exercise in
            self?.navigateToViewController(viewController: ExerciseDetailViewController.create(exercise: exercise))
        }))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        exerciseViewModel.fetchExercises()
    }
}

private enum ExerciseFilter: Hashable {
    case all
    case favorites
    case group(MuscleGroup)
}

private struct ExerciseCatalogScreen: View {
    @ObservedObject var model: ExerciseListViewModel
    @ObservedObject private var favorites = FavoriteExercises.shared
    let onExercise: (Exercise) -> Void
    @State private var search = ""
    @State private var filter = ExerciseFilter.all

    var body: some View {
        SendoPage(title: "Exercises", context: "Catalog") {
            switch model.state {
            case .loading:
                ProgressView("Loading exercises…").frame(minHeight: 44)
            case .failed(let message):
                SendoEmptyState(icon: "icloud.slash", title: "Exercises couldn’t load",
                                detail: message + " Your saved workouts are still available.")
                Button("Retry", action: model.fetchExercises).buttonStyle(SendoButtonStyle(.primary))
            case .loaded(let exercises):
                loaded(exercises)
            }
        }
    }

    @ViewBuilder
    private func loaded(_ exercises: [Exercise]) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.semibold)).foregroundStyle(SendoPalette.subdued)
                .accessibilityHidden(true)
            TextField("Exercise name or muscle group", text: $search)
                .accessibilityLabel("Search exercises")
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 48)
        .background(SendoPalette.panel, in: .rect(cornerRadius: 12))
        .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(SendoPalette.line).allowsHitTesting(false) }

        chips(exercises)

        let results = filtered(exercises)
        let term = search.trimmingCharacters(in: .whitespacesAndNewlines)
        if results.isEmpty {
            empty(term: term)
        } else if filter == .all, term.isEmpty {
            let starred = exercises.filter { favorites.contains($0.id) }
            if !starred.isEmpty {
                section("Favourites", count: starred.count)
                rows(starred, idPrefix: "catalog.favorite")
            }
            section("All exercises", count: results.count)
            rows(results, idPrefix: "catalog.exercise")
        } else {
            section(sectionTitle(term: term), count: results.count)
            rows(results, idPrefix: "catalog.exercise")
        }
    }

    private func chips(_ exercises: [Exercise]) -> some View {
        let starred = exercises.filter { favorites.contains($0.id) }.count
        let groups = MuscleGroup.allCases.compactMap { group -> (MuscleGroup, Int)? in
            let count = exercises.filter { $0.primaryGroups.contains(group) }.count
            return count > 0 ? (group, count) : nil
        }
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                SendoChip(title: "All", count: exercises.count, selected: filter == .all) { filter = .all }
                SendoChip(title: "Favourites", count: starred, systemImage: "star.fill", selected: filter == .favorites) {
                    filter = .favorites
                }
                ForEach(groups, id: \.0) { group, count in
                    SendoChip(title: group.title, count: count, selected: filter == .group(group)) { filter = .group(group) }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, -20)
    }

    private func section(_ title: String, count: Int) -> some View {
        HStack(alignment: .firstTextBaseline) {
            SendoDisplayText(title, size: 26, weight: .heavy, relativeTo: .title3)
                .accessibilityAddTraits(.isHeader)
            SwiftUI.Spacer()
            Text(count == 1 ? "1 exercise" : "\(count.formatted()) exercises")
                .font(.footnote).foregroundStyle(SendoPalette.subdued)
        }
        .padding(.top, 4)
    }

    private func rows(_ exercises: [Exercise], idPrefix: String) -> some View {
        LazyVStack(spacing: 0) {
            ForEach(exercises, id: \.id) { exercise in
                Divider().overlay(SendoPalette.line)
                row(exercise, idPrefix: idPrefix)
            }
            Divider().overlay(SendoPalette.line)
        }
    }

    private func row(_ exercise: Exercise, idPrefix: String) -> some View {
        let starred = favorites.contains(exercise.id)
        return HStack(spacing: 0) {
            Button { onExercise(exercise) } label: {
                VStack(alignment: .leading, spacing: 3) {
                    SendoDisplayText(exercise.title, size: 25, weight: .heavy, relativeTo: .title3)
                        .multilineTextAlignment(.leading)
                    if !exercise.summary.isEmpty {
                        Text(exercise.summary).font(.footnote).foregroundStyle(SendoPalette.subdued)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
                .padding(.vertical, 9)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("\(idPrefix).\(exercise.id)")
            Button { favorites.toggle(exercise.id) } label: {
                Image(systemName: starred ? "star.fill" : "star")
                    .font(.title3)
                    .foregroundStyle(starred ? SendoPalette.ink : SendoPalette.subdued)
                    .frame(width: 44, height: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.selection, trigger: starred)
            .accessibilityLabel(starred ? "Remove \(exercise.title) from favourites" : "Add \(exercise.title) to favourites")
            .accessibilityIdentifier("catalog.star.\(exercise.id)")
        }
    }

    @ViewBuilder
    private func empty(term: String) -> some View {
        if filter == .favorites, term.isEmpty {
            SendoEmptyState(icon: "star", title: "No favourites yet",
                            detail: "Tap the star on an exercise to keep it here.")
        } else {
            Text("No matching exercises").font(.headline)
            Text("Try a different name, muscle group or filter.").font(.footnote).foregroundStyle(SendoPalette.subdued)
            Button("Clear search and filter") { search = ""; filter = .all }.buttonStyle(SendoButtonStyle(.link))
        }
    }

    private func sectionTitle(term: String) -> String {
        if !term.isEmpty, filter == .all { return "Results" }
        switch filter {
        case .all: return "All exercises"
        case .favorites: return "Favourites"
        case .group(let group): return group.title
        }
    }

    private func filtered(_ exercises: [Exercise]) -> [Exercise] {
        let term = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return exercises.filter { exercise in
            switch filter {
            case .all: break
            case .favorites: if !favorites.contains(exercise.id) { return false }
            case .group(let group): if !exercise.primaryGroups.contains(group) { return false }
            }
            guard !term.isEmpty else { return true }
            let names = [exercise.title] + exercise.primary + exercise.primaryTitles + exercise.equipment + exercise.equipmentTitles
            return names.contains { $0.localizedStandardContains(term) }
        }
    }
}
