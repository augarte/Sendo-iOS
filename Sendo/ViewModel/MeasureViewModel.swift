//
//  MeasureViewModel.swift
//  Sendo
//
//  Created by Aimar Ugarte on 23/10/21.
//

import Foundation
import Combine

class MeasurementViewModel: ObservableObject {
    
    var measurements = CurrentValueSubject<[Measurement], Never>([Measurement]())
    
    init() {
        fetchWeight()
    }
    
}

extension MeasurementViewModel {
    
    func fetchWeight() {
        FirebaseFirestoreServices.shared().fetchMeasurement(completion: self.measurements)
    }
}
