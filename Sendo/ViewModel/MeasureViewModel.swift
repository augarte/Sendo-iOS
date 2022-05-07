//
//  MeasureViewModel.swift
//  Sendo
//
//  Created by Aimar Ugarte on 23/10/21.
//

import Foundation
import Combine

class MeasurementViewModel: ObservableObject {
    
    @Published public var measurements = [Measurement]()
    
    init() {
        
    }
    
}
