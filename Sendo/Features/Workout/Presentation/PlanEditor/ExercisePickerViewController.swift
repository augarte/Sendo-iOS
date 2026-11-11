import Combine
import SwiftUI

final class ExercisePickerViewController: UITableViewController, UISearchResultsUpdating {
    private enum CatalogState {
        case loading
        case loaded([Exercise])
        case failed
    }

    private let catalog: any ExerciseCatalog
    private let replacing: ExerciseID?
    private let onSelect: (Exercise) -> Void
    private let searchController = UISearchController(searchResultsController: nil)
    private var state = CatalogState.loading
    private var request: AnyCancellable?
    private var sections: [(title: String?, exercises: [Exercise])] = []

    init(catalog: any ExerciseCatalog, replacing: ExerciseID? = nil, onSelect: @escaping (Exercise) -> Void) {
        self.catalog = catalog
        self.replacing = replacing
        self.onSelect = onSelect
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = UIColor(SendoPalette.paper)
        tableView.separatorColor = UIColor(SendoPalette.line)
        view.tintColor = UIColor(SendoPalette.accent)
        title = replacing == nil ? "Choose exercise" : "Swap exercise"
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search exercises"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        loadCatalog()
    }

    private func loadCatalog() {
        state = .loading
        render()
        request = catalog.fetchExerciseList()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard case .failure = completion else { return }
                self?.state = .failed
                self?.render()
            } receiveValue: { [weak self] exercises in
                self?.state = .loaded(exercises)
                self?.render()
            }
    }

    func updateSearchResults(for searchController: UISearchController) { render() }

    private func render() {
        sections = []
        var emptyState: UIContentUnavailableConfiguration?
        switch state {
        case .loading:
            var configuration = UIContentUnavailableConfiguration.loading()
            configuration.text = "Loading exercises…"
            emptyState = configuration
        case .failed:
            var configuration = UIContentUnavailableConfiguration.empty()
            configuration.text = "Couldn’t load exercises"
            configuration.button = .filled()
            configuration.button.title = "Retry"
            configuration.buttonProperties.primaryAction = UIAction { [weak self] _ in self?.loadCatalog() }
            emptyState = configuration
        case .loaded(let exercises):
            let query = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let matches = exercises.filter { exercise in
                exercise.id != replacing && !exercise.id.isEmpty && !exercise.title.isEmpty && (
                    query.isEmpty || ([exercise.title] + exercise.primary + exercise.equipment)
                        .contains { $0.localizedStandardContains(query) }
                )
            }
            let original = exercises.first { $0.id == replacing }
            let muscles = Set(original?.primary.map { $0.lowercased() } ?? [])
            let equipment = Set(original?.equipment.map { $0.lowercased() } ?? [])
            let alternatives = matches.filter { exercise in
                !muscles.isDisjoint(with: exercise.primary.map { $0.lowercased() }) &&
                    equipment.isSuperset(of: exercise.equipment.map { $0.lowercased() })
            }
            let alternativeIDs = Set(alternatives.map(\.id))
            let others = matches.filter { !alternativeIDs.contains($0.id) }
            if !alternatives.isEmpty { sections.append(("Similar exercises", alternatives)) }
            if !others.isEmpty { sections.append((alternatives.isEmpty ? nil : "Other exercises", others)) }
            if sections.isEmpty {
                var configuration = UIContentUnavailableConfiguration.empty()
                configuration.text = query.isEmpty ? "No exercises available" : "No matching exercises"
                configuration.secondaryText = query.isEmpty ? nil : "Try a different name, muscle, or piece of equipment."
                emptyState = configuration
            }
        }
        contentUnavailableConfiguration = emptyState
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].exercises.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let exercise = sections[indexPath.section].exercises[indexPath.row]
        return WorkoutEditorRows.detail(exercise.title, detail: (exercise.primary + exercise.equipment).joined(separator: " · "), accessory: true)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let exercise = sections[indexPath.section].exercises[indexPath.row]
        if searchController.isActive {
            searchController.dismiss(animated: false) { [onSelect] in onSelect(exercise) }
        } else {
            onSelect(exercise)
        }
    }
}
