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
        FirebaseFirestoreServices.shared().addMeasurementEntry(entry: entry) { success in
            guard success else { return }
            self.measurements.value.append(entry)
        }
    }
    
    func removeEntry(entry: Measurement) {
        FirebaseFirestoreServices.shared().removeMeasurementEntry(entry: entry) { success in
            guard success else { return }
            guard let index = self.measurements.value.firstIndex(of: entry) else { return }
            self.measurements.value.remove(at: index)
        }
    }
}
