//
//  NetworkServices.swift
//  Sendo
//
//  Created by Aimar Ugarte on 7/5/22.
//

import Foundation

public protocol NetworkServicesProtocol {
    //typealias CompletionHandler = ([Example]) -> Void
    
    //func fetchExample(completion: @escaping CompletionHandler) -> Void
}

class NetworkServices: NetworkServicesProtocol {
    
    private var network: NetworkServiceManager?
    private static var networkServices: NetworkServices = {
        return NetworkServices()
    }()
    
    private init() {
        self.network = NetworkServiceManager()
    }
    
    class func shared() -> NetworkServices {
        return networkServices
    }
    
//    public func fetchExample(completion: @escaping CompletionHandler) {
//        guard let net = network else { return }
//
//        let endpoint = NetworkServicesEndpoints.fetchExample()
//        net.request(endpoint: endpoint) { result in
//            switch result {
//                case .success(let responseData):
//                    completion(responseData as! [Example])
//                case .failure(let error):
//                    print(error)
//            }
//        }
//    }
}
