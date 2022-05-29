//
//  ExerciseListViewController.swift
//  Sendo
//
//  Created by Aimar Ugarte on 13/11/21.
//

import UIKit
import Combine

class ExerciseListViewController: BaseTabViewController {
    
    @IBOutlet weak var exercisesTableView: UITableView!
    
    let exerciseViewModel = ExerciseViewModel()
    var cancellBag = Set<AnyCancellable>()
    
    static func create() -> ExerciseListViewController {
        return ExerciseListViewController(title: "Exercises", image: "ListWhite", nibName: ExerciseListViewController.typeName)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        exerciseViewModel.exercises.sink { [unowned self] (_) in
            self.exercisesTableView.reloadData()
        }.store(in: &cancellBag)
        
        exercisesTableView?.delegate = self
        exercisesTableView?.dataSource = self
        exercisesTableView.register(UINib(nibName: "ExerciseTableViewCell", bundle: nil), forCellReuseIdentifier: "ExerciseTableViewCell")

    }
    
    override func viewWillAppear(_ animated: Bool) {
        exerciseViewModel.fetchExercises()
    }

}

extension ExerciseListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return exerciseViewModel.exercises.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let exercise = exerciseViewModel.exercises.value[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExerciseTableViewCell")! as! ExerciseTableViewCell
        cell.configureCell(exercise: exercise)
        return cell;
    }
    
}

