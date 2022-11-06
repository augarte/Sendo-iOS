//
//  ExerciseListViewController.swift
//  Sendo
//
//  Created by Aimar Ugarte on 13/11/21.
//

import UIKit
import Combine

class ExerciseListViewController: BaseTabViewController {
        
    lazy var exercisesTableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .clear
        return table
    }()
    
    private let exerciseViewModel = ExerciseListViewModel()
    private var cancellBag = Set<AnyCancellable>()
    
    static func create() -> ExerciseListViewController {
        return ExerciseListViewController(title: "Exercises", image: "ListWhite")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        exerciseViewModel.exercises.sink { [unowned self] (_) in
            self.exercisesTableView.reloadData()
        }.store(in: &cancellBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        exerciseViewModel.fetchExercises()
    }
    
    override func loadView() {
        super.loadView()
        setupTable()
    }
    
    private func setupTable() {
        view.addSubview(exercisesTableView)
        NSLayoutConstraint.activate([
            exercisesTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            exercisesTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            exercisesTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            exercisesTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        exercisesTableView.delegate = self
        exercisesTableView.dataSource = self
        exercisesTableView.register(ExerciseListTableViewCell.self, forCellReuseIdentifier: ExerciseListTableViewCell.typeName)
    }
}

extension ExerciseListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return exerciseViewModel.exercises.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let exercise = exerciseViewModel.exercises.value[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ExerciseListTableViewCell.typeName)! as! ExerciseListTableViewCell
        cell.configureCell(exercise: exercise)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let exercise = exerciseViewModel.exercises.value[indexPath.row]
        let exerciseDetailVC = ExerciseDetailViewController.create(exercise: exercise)
        navigateToViewController(viewController: exerciseDetailVC)
    }
}
