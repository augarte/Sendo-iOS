//
//  ProgressViewModel.swift
//  Sendo
//
//  Created by Aimar Ugarte on 23/10/21.
//

import Foundation
import Combine

protocol ProgressViewModelProtocol {
    var measurements: CurrentValueSubject<[Measurement], Never> { get }
}

class ProgressViewModel: ProgressViewModelProtocol {
    
    private var provider: ProgressProviderProtocol
    
    var measurements = CurrentValueSubject<[Measurement], Never>([Measurement]())

    init(provider: ProgressProvider = ProgressProvider()) {
        self.provider = provider
        fetchWeight()
    }
}

extension ProgressViewModel {
    
    func fetchWeight() {
        provider.fetchMeasurement(completion: measurements)
    }
    
    func addEntry(entry: Measurement) {
        provider.addMeasurementEntry(entry: entry) { [weak self] success in
            guard let self, success else { return }
            self.measurements.value.append(entry)
            self.measurements.value = self.measurements.value.sorted(by: { $0.date > $1.date })
        }
    }
    
    func modifyEntry(entry: Measurement) {
        provider.modifyMeasurementEntry(entry: entry, hash: "value", newValue: entry.value) { [weak self] success in
            guard let self, success else { return }
            guard let index = self.measurements.value.firstIndex(of: entry) else { return }
            self.measurements.value.remove(at: index)
            self.measurements.value = self.measurements.value.sorted(by: { $0.date > $1.date })
        }
    }
    
    func removeEntry(entry: Measurement) {
        provider.removeMeasurementEntry(entry: entry) { [weak self] success in
            guard let self, success else { return }
            guard let index = self.measurements.value.firstIndex(of: entry) else { return }
            self.measurements.value.remove(at: index)
            self.measurements.value = self.measurements.value.sorted(by: { $0.date > $1.date })
        }
    }
}
