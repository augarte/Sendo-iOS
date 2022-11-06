//
//  ProgressViewController.swift
//  Sendo
//
//  Created by Aimar Ugarte on 23/10/21.
//

import UIKit
import Combine
import FirebaseAuth
import SimpleLineChart
import SlidingBanner

protocol ProgressViewControllerDelegate: AnyObject {
    func didAddNewEntry(newEntry: Measurement)
}

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
    
    private let progressViewModel = ProgressViewModel()
    private var cancellBag = Set<AnyCancellable>()
    
    static func create() -> ProgressViewController {
        return ProgressViewController(title: "Progress", image: "MeasurementWhite")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        progressViewModel.fetchWeight()
        progressViewModel.measurements.sink { [unowned self] (_) in
            lineChart.setPoints(points: progressViewModel.measurements.value.compactMap({ measurement in
                // TODO: fix timestamp case
                let timestamp = Int(measurement.date) ?? 0
                return SimpleLineChartData(x: timestamp, y: measurement.value)
            }))
            self.progressTableView.reloadData()
        }.store(in: &cancellBag)
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
            view.trailingAnchor.constraint(equalTo: lineChart.trailingAnchor, constant: Constants.margin),
            view.bottomAnchor.constraint(equalTo: lineChart.safeAreaLayoutGuide.bottomAnchor, constant: Constants.margin)
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
        progressTableView.backgroundColor = .clear
        progressTableView.delegate = self
        progressTableView.dataSource = self
        progressTableView.register(ProgressTableCell.self, forCellReuseIdentifier: ProgressTableCell.typeName)
    }
}

// MARK: - Toolbar
private extension ProgressViewController {
    
    func addToolbarItem(){
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(self.addProgressEntry(sender:)))
    }
    
    @objc func addProgressEntry(sender: UIBarButtonItem?) {
        let newEntryVC = NewEntryDialog.create { measurement in
            self.progressViewModel.addEntry(entry: measurement)
        }
        showModalView(viewController: newEntryVC)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ProgressViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return progressViewModel.measurements.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let measurement = progressViewModel.measurements.value[indexPath.row]
        var change = 0.0
        if indexPath.row < progressViewModel.measurements.value.count - 1 {
            let prevValue = progressViewModel.measurements.value[indexPath.row + 1].value
            change = (100 * (measurement.value - prevValue) / prevValue).round(to: 1)
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: ProgressTableCell.typeName)! as! ProgressTableCell
        cell.configureCell(entry: measurement, change: change)
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let modifyItem = UIContextualAction(style: .normal, title: "Modify") {  (contextualAction, view, boolValue) in
            let measurement = self.progressViewModel.measurements.value[indexPath.row]
            self.modifyMeasurement(measurement: measurement)
        }
        modifyItem.backgroundColor = .systemBlue
        return UISwipeActionsConfiguration(actions: [modifyItem])
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteItem = UIContextualAction(style: .destructive, title: "Delete") {  (contextualAction, view, boolValue) in
            let measurement = self.progressViewModel.measurements.value[indexPath.row]
            self.progressViewModel.removeEntry(entry: measurement)
        }
        return UISwipeActionsConfiguration(actions: [deleteItem])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let measurement = self.progressViewModel.measurements.value[indexPath.row]
        modifyMeasurement(measurement: measurement)
    }
}
    
// MARK: - Private functions
extension ProgressViewController {
    
    func modifyMeasurement(measurement: Measurement) {
        let newEntryVC = NewEntryDialog.create(measurement: measurement) { newMeasurement in
            if (measurement.date == newMeasurement.date) {
                self.progressViewModel.modifyEntry(entry: newMeasurement)
            } else {
                self.progressViewModel.removeEntry(entry: measurement)
                self.progressViewModel.addEntry(entry: newMeasurement)
            }
            self.progressTableView.reloadData()
        }
        self.showModalView(viewController: newEntryVC)
    }
}
