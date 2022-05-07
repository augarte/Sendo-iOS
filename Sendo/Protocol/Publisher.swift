//
//  Publisher.swift
//  Sendo
//
//  Created by Aimar Ugarte on 24/10/21.
//

import Foundation
import Combine

public protocol Publisher {

  associatedtype Output
  associatedtype Failure : Error

  func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input
    
}
