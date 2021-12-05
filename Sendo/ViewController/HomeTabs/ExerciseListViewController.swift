//
//  ExerciseListViewController.swift
//  Sendo
//
//  Created by Aimar Ugarte on 13/11/21.
//

import UIKit
import Combine

class ExerciseListViewController: BaseViewController {
    
    @IBOutlet weak var exercisesTableView: UITableView!
    
    let exerciseViewModel = ExerciseViewModel()
    var cancellBag = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Exercises"
        
        exerciseViewModel.exercises.sink { [unowned self] (_) in
            self.exercisesTableView.reloadData()
        }.store(in: &cancellBag)
        
        exercisesTableView?.delegate = self
        exercisesTableView?.dataSource = self

    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }

}
