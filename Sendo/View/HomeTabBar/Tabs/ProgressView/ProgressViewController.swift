//
//  ProgressViewController.swift
//  Sendo
//
//  Created by Aimar Ugarte on 23/10/21.
//

import UIKit
import Combine

class ProgressViewController: SendoViewController {

    @IBOutlet weak var progressTableView: UITableView?
    
    let progressViewModel = MeasurementViewModel()
    
    static func create() -> ProgressViewController {
        return ProgressViewController(nibName: ProgressViewController.typeName, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Progress"
        
        progressTableView?.delegate = self
        progressTableView?.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
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
        return cell;
    }
    
}
