//
//  ProgressViewModel.swift
//  Sendo
//
//  Created by Aimar Ugarte on 23/10/21.
//

import Foundation
import Combine

class ProgressViewModel: ObservableObject {
    
    var measurements = CurrentValueSubject<[Measurement], Never>([Measurement]())

    init() {
        fetchWeight()
    }
}

extension ProgressViewModel {
    
    func fetchWeight() {
        FirebaseFirestoreServices.shared().fetchMeasurement(completion: self.measurements)
    }
    
    func addEntry(entry: Measurement) {
        FirebaseFirestoreServices.shared().addMeasurementEntry(entry: entry) { success in
            guard success else { return }
            self.measurements.value.append(entry)
            self.measurements.value = self.measurements.value.sorted(by: { $0.date > $1.date })
        }
    }
    
    func modifyEntry(entry: Measurement) {
        FirebaseFirestoreServices.shared().modifyMeasurementEntry(entry: entry, hash: "value", newValue: entry.value) { success in
            guard success else { return }
            guard let index = self.measurements.value.firstIndex(of: entry) else { return }
            self.measurements.value.remove(at: index)
            self.measurements.value = self.measurements.value.sorted(by: { $0.date > $1.date })
        }
    }
    
    func removeEntry(entry: Measurement) {
        FirebaseFirestoreServices.shared().removeMeasurementEntry(entry: entry) { success in
            guard success else { return }
            guard let index = self.measurements.value.firstIndex(of: entry) else { return }
            self.measurements.value.remove(at: index)
            self.measurements.value = self.measurements.value.sorted(by: { $0.date > $1.date })
        }
    }
}
