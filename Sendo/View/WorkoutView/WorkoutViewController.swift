//
//  ViewController.swift
//  sendo
//
//  Created by Aimar Ugarte on 23/10/21.
//

import UIKit
import Combine

class WorkoutViewController: BaseTabViewController {
        
    lazy var workoutTableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .clear
        return table
    }()
    
    let exerciseViewModel = ExerciseListViewModel()
    var cancellBag = Set<AnyCancellable>()
    
    static func create() -> WorkoutViewController {
        return WorkoutViewController(title: "Workout", image: "WorkoutWhite")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        exerciseViewModel.exercises.sink { [unowned self] (_) in
            self.workoutTableView.reloadData()
        }.store(in: &cancellBag)
    }
    
    override func loadView() {
        super.loadView()
        setupTableView()
    }
    
    private func setupTableView() {
        view.addSubview(workoutTableView)
        NSLayoutConstraint.activate([
            workoutTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            workoutTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            workoutTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            workoutTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        workoutTableView.delegate = self
        workoutTableView.dataSource = self
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
        cell.backgroundColor = .clear
        return cell
    }
}
