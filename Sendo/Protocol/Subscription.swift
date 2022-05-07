//
//  Subscription.swift
//  Sendo
//
//  Created by Aimar Ugarte on 24/10/21.
//

import Foundation
import Combine

public protocol Subscription : Cancellable, CustomCombineIdentifierConvertible {
  
    func request(_ demand: Subscribers.Demand)

}
