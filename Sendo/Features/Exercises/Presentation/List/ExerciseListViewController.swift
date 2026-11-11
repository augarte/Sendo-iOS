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

private struct ExerciseCatalogScreen: View {
    @ObservedObject var model: ExerciseListViewModel
    let onExercise: (Exercise) -> Void
    @State private var search = ""

    var body: some View {
        SendoPage(title: "Exercises", context: "Catalog") {
            switch model.state {
            case .loading:
                ProgressView("Loading exercises…").frame(minHeight: 44)
            case .failed:
                SendoEmptyState(icon: "icloud.slash", title: "Exercises couldn’t load",
                                detail: "Check your connection and try again. Your saved workouts are still available.")
                Button("Retry", action: model.fetchExercises).buttonStyle(SendoButtonStyle(.primary))
            case .loaded(let exercises):
                SendoField(title: "Search exercises") {
                    TextField("Exercise name or muscle group", text: $search)
                        .accessibilityLabel("Search exercises")
                }
                let results = filtered(exercises)
                if results.isEmpty {
                    Text(search.isEmpty ? "No exercises available" : "No matching exercises").font(.headline)
                    if !search.isEmpty {
                        Text("Try a different name or muscle group.").font(.footnote).foregroundStyle(SendoPalette.subdued)
                        Button("Clear search") { search = "" }.buttonStyle(SendoButtonStyle(.link))
                    }
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(results, id: \.id) { exercise in
                            Button { onExercise(exercise) } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(exercise.title).font(.headline)
                                        if !exercise.primary.isEmpty {
                                            Text(exercise.primary.joined(separator: " · "))
                                                .font(.footnote).foregroundStyle(SendoPalette.subdued)
                                        }
                                    }
                                    SwiftUI.Spacer()
                                    Image(systemName: "chevron.right").font(.footnote).foregroundStyle(SendoPalette.accent)
                                }
                                .padding(.vertical, 9)
                                .frame(minHeight: 48)
                                .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("catalog.exercise.\(exercise.id)")
                            Divider().overlay(SendoPalette.line)
                        }
                    }
                }
            }
        }
    }

    private func filtered(_ exercises: [Exercise]) -> [Exercise] {
        let term = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return exercises }
        return exercises.filter { exercise in
            ([exercise.title] + exercise.primary + exercise.equipment).contains { $0.localizedStandardContains(term) }
        }
    }
}
