//
//  NetworkService.swift
//  Sendo
//
//  Created by Aimar Ugarte on 7/5/22.
//

import Foundation
import Alamofire

public enum NetworkError: Error {
    case error(statusCode: Int, data: Data?)
    case jsonParsing
    case notConnected
}

public protocol NetworkServiceProtocol {
    typealias CompletionHandler = (Result<Decodable, AFError>) -> Void
    
    func request<T: Decodable>(endpoint: Endpoint<T>, completion: @escaping CompletionHandler) -> Void
}

class NetworkServiceManager: NetworkServiceProtocol {
    
    lazy var appConfiguration = AppConfiguration()
    
    var dataRequestArray: [DataRequest] = []

    public func request<T: Decodable>(endpoint: Endpoint<T>, completion: @escaping CompletionHandler) {
        
        let url = appConfiguration.apiBaseURL + endpoint.path

        AF.request(url, method: Alamofire.HTTPMethod.get, parameters: endpoint.parameters, headers: endpoint.header)
            .responseDecodable(of: T.self) { response in
            switch response.result {
                case .success(let value):
                    completion(.success(value))
                case .failure(let error):
                    completion(.failure(error))
            }
        }
    }
}
