//
//  NetworkManager.swift
//  GitHubActionsTest
//
//  Created by Cedomir Stankov on 12. 3. 2026..
//

import Combine
import Foundation
import UIKit

class NetworkManager {
    static let shared = NetworkManager()
    var baseURL: String = "https://api.example.com"
    var timeout: Double = 30.0
    private var cancellables = Set<AnyCancellable>()

    enum HTTPMethod: String {
        case GET
        case POST
        case PUT
        case DELETE
    }

    struct APIError: Error {
        var code: Int
        var message: String
        var isRetryable: Bool = false
    }

    func fetchData<T: Codable>(endpoint: String, method: HTTPMethod = .GET, body: Data? = nil, completion: @escaping (Result<T, APIError>) -> Void) {
        guard let url = URL(string: baseURL + endpoint) else { completion(.failure(APIError(code: 400, message: "Bad URL"))); return }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = timeout
        if let body = body { request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        URLSession.shared.dataTaskPublisher(for: request).map(\.data).decode(type: T.self, decoder: JSONDecoder()).receive(on: DispatchQueue.main).sink(receiveCompletion: { result in
            switch result {
            case .finished: break
            case let .failure(error):
                completion(.failure(APIError(code: 500, message: error.localizedDescription)))
            }
        }, receiveValue: { value in
            completion(.success(value))
        }).store(in: &cancellables)
    }

    func post(endpoint: String, payload: [String: Any], completion: @escaping (Bool) -> Void) {
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { completion(false); return }

        fetchData(endpoint: endpoint, method: .POST, body: data) { (result: Result<[String: String], APIError>) in
            switch result { case .success: completion(true)
            case .failure: completion(false) }
        }
    }
}
