import Foundation
import then

/// Basic API Implementation
protocol JSONAPIClient {
    var baseURLString: String { get }
    var environment: Environment { get }
}

public enum APIError: Error {
    case unknownError(String)
    case networkError
    case serverError(String)
    case noDataError
    case decodingError
}

extension JSONAPIClient {
    typealias CompletionHandler<T> = (Response<T>) -> Void
    typealias JSON = Data
    typealias JSONResponse = Response<JSON>

    func get<T: Decodable>(as requestedType: T.Type = T.self, from path: String, completion: CompletionHandler<T>?) {        
        return call(as: requestedType, path: path, using: .get, completion: completion)
    }

    func call<T: Decodable>(as requestedType: T.Type = T.self, path: String, using method: HTTPMethod, completion: CompletionHandler<T>?) {
        // Make the actuall call
        request(path: path, using: method) { response in
            switch response {
                case .success(let json):
                    do {
                        // Decode the JSON into the requested type
                        try completion?(.success(JSONDecoder().decode(T.self, from: json)))
                    } catch let decodingError {
                        logger.debug(decodingError)
                        completion?(.failure(.decodingError))
                    }
                case .failure(let error):
                    logger.debug(error)

                    completion?(.failure(error))
            }
        }
    }

    private func request(path: String, using method: HTTPMethod, completion: ((JSONResponse) -> Void)?) {
        guard var urlComponents = URLComponents(string: self.baseURLString) else {
            completion?(.failure(.unknownError("Error constructing URL Components")))

            return
        }

        // Append our request path
        urlComponents.path += path

       guard let url = urlComponents.url else { 
            assertionFailure("Error building URL")

            return 
        }

        // Build request
        var request = URLRequest(url: url)

        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                completion?(.failure(.networkError))

                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion?(.failure(.serverError("An error occurred while communicating with the server")))

                return
            }

            guard (200...299) ~= httpResponse.statusCode else {
                // FIXME: Handle errors properly later
                completion?(.failure(.serverError("Server responded: \(httpResponse.statusCode)")))

                return
            }

            guard let data = data else {
                completion?(.failure(.noDataError))

                return
            }

            completion?(.success(data))
        }

        task.resume()
    }
}
