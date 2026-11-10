//
//  ProgressViewController.swift
//  Sendo
//
//  Created by Aimar Ugarte on 23/10/21.
//

import UIKit
import Combine
import SimpleLineChart

class ProgressViewController: BaseTabViewController {

    private enum Constants {
        static let margin: CGFloat = Spacer.size04
        static let chartHeightMultiplier: CGFloat = 0.5
    }

    lazy var progressTableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()

    lazy var lineChart: SimpleLineChart = {
        let chart = SimpleLineChart()
        chart.translatesAutoresizingMaskIntoConstraints = false
        return chart
    }()

    private let viewModel: ProgressViewModel
    private var measurements: [BodyMeasurement] = []
    private var cancellable: AnyCancellable?

    init(viewModel: ProgressViewModel) {
        self.viewModel = viewModel
        super.init(title: "Progress", image: "MeasurementWhite")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        cancellable = viewModel.$state.sink { [weak self] state in
            self?.render(state)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshMeasurements()
    }

    @objc private func refreshMeasurements() {
        Task {
            await viewModel.load()
            progressTableView.refreshControl?.endRefreshing()
        }
    }

    private func render(_ state: ProgressViewModel.State) {
        measurements = state.measurements
        var plottedSeconds = Set<Int>()
        var points = measurements.compactMap { measurement -> SLCData? in
            let seconds = measurement.measuredAt.timeIntervalSince1970.rounded(.towardZero)
            guard let timestamp = Int(exactly: seconds), plottedSeconds.insert(timestamp).inserted else {
                return nil
            }
            return SLCData(x: timestamp, y: measurement.value)
        }
        let now = Int(Date().timeIntervalSince1970)
        if let latest = points.first, latest.x < now {
            points.insert(SLCData(x: now, y: latest.y), at: 0)
        }

        let dataSet = SLCDataSet(graphPoints: points)
        dataSet.setLineStyle(SLCLineStyle(lineColor: .white))
        lineChart.loadPoints(dataSet: dataSet)

        let status = UILabel()
        status.textAlignment = .center
        status.numberOfLines = 0
        status.text = state.isLoading ? "Loading measurements…" : state.loadError
        progressTableView.backgroundView = measurements.isEmpty ? status : nil
        progressTableView.reloadData()
    }

    override func loadView() {
        super.loadView()
        addToolbarItem()
        setupChart()
        setupTable()
    }

    private func setupChart() {
        view.addSubview(lineChart)
        NSLayoutConstraint.activate([
            lineChart.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: Constants.chartHeightMultiplier),
            lineChart.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Constants.margin),
            lineChart.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.margin),
            view.trailingAnchor.constraint(equalTo: lineChart.trailingAnchor, constant: Constants.margin)
        ])
        lineChart.backgroundColor = .clear
    }

    private func setupTable() {
        view.addSubview(progressTableView)
        NSLayoutConstraint.activate([
            progressTableView.topAnchor.constraint(equalTo: lineChart.bottomAnchor, constant: Constants.margin),
            progressTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            progressTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(refreshMeasurements), for: .valueChanged)
        progressTableView.refreshControl = refresh
        progressTableView.alwaysBounceVertical = true
        progressTableView.backgroundColor = .clear
        progressTableView.delegate = self
        progressTableView.dataSource = self
        progressTableView.register(ProgressTableCell.self, forCellReuseIdentifier: ProgressTableCell.typeName)
    }
}

// MARK: - Toolbar
private extension ProgressViewController {

    func addToolbarItem(){
        let add = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addProgressEntry(sender:)))
        add.accessibilityLabel = "Add measurement"
        add.accessibilityIdentifier = "progress.addMeasurement"
        navigationItem.leftBarButtonItem = add
    }

    @objc func addProgressEntry(sender: UIBarButtonItem?) {
        showEditor()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ProgressViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return measurements.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let measurement = measurements[indexPath.row]
        var change = 0.0
        if indexPath.row < measurements.count - 1 {
            let prevValue = measurements[indexPath.row + 1].value
            if prevValue > 0 {
                let percent = 100 * (measurement.value - prevValue) / prevValue
                if percent.isFinite { change = percent.round(to: 1) }
            }
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: ProgressTableCell.typeName)! as! ProgressTableCell
        cell.configureCell(entry: measurement, change: change)
        return cell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let measurement = measurements[indexPath.row]
        let revision = viewModel.revision
        let modifyItem = UIContextualAction(style: .normal, title: "Modify") { [weak self] _, _, completion in
            guard let self, self.viewModel.revision == revision else {
                completion(false)
                return
            }
            self.showEditor(for: measurement)
            completion(true)
        }
        modifyItem.backgroundColor = .systemBlue
        return UISwipeActionsConfiguration(actions: [modifyItem])
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let id = measurements[indexPath.row].id
        let revision = viewModel.revision
        let deleteItem = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self else {
                completion(false)
                return
            }
            Task {
                do {
                    try await self.viewModel.delete(id: id, revision: revision)
                    completion(true)
                } catch {
                    completion(false)
                    let alert = UIAlertController(title: "Couldn’t delete weight", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
        return UISwipeActionsConfiguration(actions: [deleteItem])
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showEditor(for: measurements[indexPath.row])
    }

    private func showEditor(for measurement: BodyMeasurement? = nil) {
        let revision = viewModel.revision
        let editor = NewEntryDialog(measurement: measurement) { [viewModel] draft in
            try await viewModel.save(draft, isEditing: measurement != nil, revision: revision)
        }
        showModalView(viewController: editor)
    }
}
