//
//  ProgressViewController.swift
//  Sendo
//
//  Created by Aimar Ugarte on 23/10/21.
//

import UIKit
import Combine
import FirebaseAuth

class ProgressViewController: BaseTabViewController {
    
    @IBOutlet weak var progressTableView: UITableView?
    @IBOutlet weak var lineChart: SimpleLineChart!
    
    let progressViewModel = MeasurementViewModel()
    var cancellBag = Set<AnyCancellable>()
    
    static func create() -> ProgressViewController {
        return ProgressViewController(title: "Progress", image: "MeasurementWhite", nibName: ProgressViewController.typeName)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        lineChart.setPoints(points: [3, 4, 9, 11, 13, 15])
        //lineChart.backgroundColor = .red

        progressViewModel.measurements.sink { [unowned self] (_) in
            self.progressTableView?.reloadData()
        }.store(in: &cancellBag)
        
        progressTableView?.delegate = self
        progressTableView?.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        progressViewModel.fetchWeight()
    }

}

extension ProgressViewController {
    
    func setupChart() {
    }
}

extension ProgressViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //let measurement =  measurementViewModel.measurements.value[indexPath.row]
        
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: nil)
        cell.largeContentTitle = String(format: "%.2f","1")// measurement.value)
        cell.backgroundColor = .clear
        return cell;
    }
    
}
