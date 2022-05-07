//
//  ViewController.swift
//  sendo
//
//  Created by Aimar Ugarte on 23/10/21.
//

import UIKit
import Combine

class WorkoutViewController: BaseViewController {

    @IBOutlet weak var workoutTableView: UITableView!

    let exerciseViewModel = ExerciseViewModel()
    var cancellBag = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Workout"
        
        exerciseViewModel.exercises.sink { [unowned self] (_) in
            self.workoutTableView.reloadData()
        }.store(in: &cancellBag)
        
        workoutTableView?.delegate = self
        workoutTableView?.dataSource = self
    }

}

extension WorkoutViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return exerciseViewModel.exercises.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let exercise = exerciseViewModel.exercises.value[indexPath.row]
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: nil)
        cell.largeContentTitle = exercise.title
        return cell;
    }
    
}
