//
//  ViewController.swift
//  sendo
//
//  Created by Aimar Ugarte on 23/10/21.
//

import UIKit
import Combine

class WorkoutViewController: BaseTabViewController {
    
    private enum Constants {
        static let buttonSize: CGFloat = 50
        static let buttonSpacing: CGFloat = Spacer.size02
    }
    
    private lazy var startWorkoutButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor(named: "AccentColor")
        button.titleLabel?.textColor = .white
        button.heightAnchor.constraint(equalToConstant: Constants.buttonSize).isActive = true
        button.layer.cornerRadius = Constants.buttonSize / 4
        button.addTarget(self, action: #selector(workoutButtonPressed), for: .touchUpInside)
        return button
    }()
    private lazy var emptyState = WorkoutEmptyState()
    //private lazy var workoutView = WorkoutView()
    
    private let workoutViewModel = WorkoutViewModel()
    private var cancellBag = Set<AnyCancellable>()
    
    static func create() -> WorkoutViewController {
        return WorkoutViewController(title: "Workout", image: "WorkoutWhite")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func loadView() {
        super.loadView()
        addToolbarItem()
        setupButons()
        setupConstraints()
    }
}
    
private extension WorkoutViewController {
    
    func setupButons() {
        if workoutViewModel.workout.value != nil {
            startWorkoutButton.setTitle("Start Workout", for: .normal)
            setupWorkoutView()
        } else {
            startWorkoutButton.setTitle("Create Workout", for: .normal)
            setupEmptyState()
        }
    }
    
    func setupWorkoutView() {
    }
    
    func setupEmptyState() {
    }
    
    func setupConstraints() {
        view.addSubviews([startWorkoutButton, emptyState])
        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: startWorkoutButton.bottomAnchor, constant: Constants.buttonSpacing),
            startWorkoutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.buttonSpacing),
            view.trailingAnchor.constraint(equalTo: startWorkoutButton.trailingAnchor, constant: Constants.buttonSpacing),
            
            emptyState.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyState.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyState.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            startWorkoutButton.topAnchor.constraint(equalTo: emptyState.bottomAnchor, constant: Constants.buttonSpacing)
        ])
        emptyState.setupView()
    }
}

private extension WorkoutViewController {
    
    func addToolbarItem(){
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(self.newWorkoutPressed(sender:)))
    }
    
    @objc func newWorkoutPressed(sender: UIBarButtonItem?) {
        let newWorkoutVC = NewWorkoutDialog.create {
            //TODO: Completion handling
        }
        showModalView(viewController: newWorkoutVC)
    }
    
    
    @objc func workoutButtonPressed(sender: UIButton?) {
        //TODO: workout button press action
    }
}
