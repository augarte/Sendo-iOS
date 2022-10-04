//
//  ProgressViewController.swift
//  Sendo
//
//  Created by Aimar Ugarte on 23/10/21.
//

import UIKit
import Combine
import FirebaseAuth

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
        
        progressViewModel.measurements.sink { [unowned self] (_) in
            lineChart.setPoints(points: progressViewModel.measurements.value.compactMap({ measurement in
                guard let timestamp = Int(measurement.date) else { return nil }
                return (timestamp, measurement.value)
            }))
            self.progressTableView?.reloadData()
        }.store(in: &cancellBag)
        
        progressTableView?.delegate = self
        progressTableView?.dataSource = self
        progressTableView?.register(UINib(nibName: "ProgressTableCell", bundle: nil), forCellReuseIdentifier: "ProgressTableCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        progressViewModel.fetchWeight()
    }
    
    // MARK: - Toolbar
    func addToolbarItem(){
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(self.addProgressEntry(sender:)))
    }
    
    @objc func addProgressEntry(sender: UIBarButtonItem) {
        let newEntryVC = NewEntryDialog.create()
        newEntryVC.delegate = self
        showModalView(viewController: newEntryVC)
    }

}

extension ProgressViewController {
    
    func setupChart() {
    }
}

extension ProgressViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return progressViewModel.measurements.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        let measurement = progressViewModel.measurements.value[indexPath.row]
        var change = 0.0
        if indexPath.row > 0 {
            let prevValue = progressViewModel.measurements.value[indexPath.row - 1].value
            change = (100 * (measurement.value - prevValue) / prevValue).round(to: 1)
        }
        
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProgressTableCell")! as! ProgressTableCell
        cell.configureCell(entry: measurement, change: change)
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            let measurement = progressViewModel.measurements.value[indexPath.row]
            progressViewModel.removeEntry(entry: measurement)
            
        }
    }
    
}

extension ProgressViewController: ProgressViewControllerDelegate {
   
    func didAddNewEntry(newEntry: Measurement) {
        progressViewModel.addEntry(entry: newEntry)
    }

}
