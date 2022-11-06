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
    
    @IBOutlet weak var progressTableView: UITableView!
    @IBOutlet weak var lineChart: SimpleLineChart!
    
    let progressViewModel = MeasurementViewModel()
    var cancellBag = Set<AnyCancellable>()
    
    static func create() -> ProgressViewController {
        return ProgressViewController(title: "Progress", image: "MeasurementWhite", nibName: ProgressViewController.typeName)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addToolbarItem()
        setupTable()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        progressViewModel.fetchWeight()
        progressViewModel.measurements.sink { [unowned self] (_) in
            lineChart.setPoints(points: progressViewModel.measurements.value.compactMap({ measurement in
                // TODO: fix timestamp case
                let timestamp = Int(measurement.date) ?? 0
                return SimpleLineChartData(x: timestamp, y: measurement.value)
            }))
            self.progressTableView?.reloadData()
        }.store(in: &cancellBag)
    }
    
    private func setupTable() {
        progressTableView?.delegate = self
        progressTableView?.dataSource = self
        progressTableView?.register(UINib(nibName: "ProgressTableCell", bundle: nil), forCellReuseIdentifier: "ProgressTableCell")
    }
}

// MARK: - Toolbar
extension ProgressViewController {
    
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
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProgressTableCell")! as! ProgressTableCell
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
