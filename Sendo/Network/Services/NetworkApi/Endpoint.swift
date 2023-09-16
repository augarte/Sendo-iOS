//
//  Endpoint.swift
//  Sendo
//
//  Created by Aimar Ugarte on 7/5/22.
//

import Foundation
import Alamofire

public enum HTTPMethodType: String {
    case get = "GET"
}

public enum BodyEncoding {
    case json
}

public class Endpoint<R> {
    
    public typealias Response = R
    
    public let path: String
    public let method: HTTPMethodType
    public let header: HTTPHeaders?
    public let body: [String: Any]
    public let parameters: [String: Any]
    
    init(path: String,
         method: HTTPMethodType,
         header: HTTPHeaders? = nil,
         body: [String: Any] = [:],
         parameters: [String: Any] = [:]) {
        self.path = path
        self.method = method
        self.header = header
        self.body = body
        self.parameters = parameters
    }
}
