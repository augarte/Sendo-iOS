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
        button.addTarget(self, action: #selector(tapWorkoutButton), for: .touchUpInside)
        return button
    }()
    private lazy var emptyState: WorkoutEmptyState = {
        let view = WorkoutEmptyState()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private lazy var currentWorkout: CurrentWorkoutView = {
        let view = CurrentWorkoutView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private var currentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
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
        if let _ = workoutViewModel.workout.value {
            startWorkoutButton.setTitle("Start todays workout", for: .normal)
            setupCurrentView(subView: currentWorkout)
            currentWorkout.setupView()
        } else {
            startWorkoutButton.setTitle("Plan your workout", for: .normal)
            setupCurrentView(subView: emptyState)
            emptyState.setupView()
        }
    }
    
    func setupCurrentView(subView: UIView) {
        currentView.addSubview(subView)
        NSLayoutConstraint.activate([
            subView.topAnchor.constraint(equalTo: currentView.topAnchor),
            subView.leadingAnchor.constraint(equalTo: currentView.leadingAnchor),
            subView.trailingAnchor.constraint(equalTo: currentView.trailingAnchor),
            subView.bottomAnchor.constraint(equalTo: currentView.bottomAnchor)
        ])
    }
    
    func setupConstraints() {
        view.addSubviews([startWorkoutButton, currentView])
        NSLayoutConstraint.activate([
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: startWorkoutButton.bottomAnchor, constant: Constants.buttonSpacing),
            startWorkoutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.buttonSpacing),
            view.trailingAnchor.constraint(equalTo: startWorkoutButton.trailingAnchor, constant: Constants.buttonSpacing),
            
            currentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            currentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            currentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            startWorkoutButton.topAnchor.constraint(equalTo: currentView.bottomAnchor, constant: Constants.buttonSpacing)
        ])
    }
}

private extension WorkoutViewController {
    
    func addToolbarItem(){
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(self.tapNewWorkout(sender:)))
    }
    
    @objc func tapNewWorkout(sender: UIView?) {
        let newWorkoutVC = NewWorkoutDialog.create {
            //TODO: Completion handling
        }
        showModalView(viewController: newWorkoutVC)
    }
    
    @objc func tapWorkoutButton(sender: UIButton?) {
        if let _ = workoutViewModel.workout.value {
            
        } else {
            tapNewWorkout(sender: sender)
        }
    }
}
