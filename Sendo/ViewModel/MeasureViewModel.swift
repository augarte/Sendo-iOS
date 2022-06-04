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
    
    func addEntry(entry: Measurement) {
        measurements.value.append(entry)
        FirebaseFirestoreServices.shared().addMeasurementEntry(entry: entry, completion: self.measurements)
    }
    
    func removeEntry(entry: Measurement) {
        if let index = measurements.value.firstIndex(of: entry) {
            measurements.value.remove(at: index)
            FirebaseFirestoreServices.shared().removeMeasurementEntry(entry: entry, completion: self.measurements)
        }
    }
}
