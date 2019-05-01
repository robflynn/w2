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
    typealias RequestParameters = [String: Any]
    typealias CompletionHandler<T> = (Response<T>) -> Void
    typealias JSON = Data
    typealias JSONResponse = Response<JSON>

    func get<T: Decodable>(as requestedType: T.Type = T.self, from path: String, completion: CompletionHandler<T>?) {
        return call(as: requestedType, path: path, using: .get, withParameters: [:], completion: completion)
    }

    func get<T: Decodable>(as requestedType: T.Type = T.self, from path: String, withParameters params: RequestParameters, completion: CompletionHandler<T>?) {
        return call(as: requestedType, path: path, using: .get, withParameters: params, completion: completion)
    }

    func post<T: Decodable>(as requestedType: T.Type = T.self, to path: String, completion: CompletionHandler<T>?) {
        return call(as: requestedType, path: path, using: .post, withParameters: [:], completion: completion)
    }

    func post<T: Decodable>(as requestedType: T.Type = T.self, to path: String, withParameters params: RequestParameters, completion: CompletionHandler<T>?) {
        return call(as: requestedType, path: path, using: .post, withParameters: params, completion: completion)
    }

    func patch<T: Decodable>(as requestedType: T.Type = T.self, to path: String, completion: CompletionHandler<T>?) {
        return call(as: requestedType, path: path, using: .patch, withParameters: [:], completion: completion)
    }

    func patch<T: Decodable>(as requestedType: T.Type = T.self, to path: String, withParameters params: RequestParameters, completion: CompletionHandler<T>?) {
        return call(as: requestedType, path: path, using: .patch, withParameters: params, completion: completion)
    }

    func call<T: Decodable>(as requestedType: T.Type = T.self, path: String, using method: HTTPMethod, withParameters params: RequestParameters, completion: CompletionHandler<T>?) {
        // Make the actuall call
        request(path: path, using: method, withParameters: params) { response in
            switch response {
                case .success(let json):
                    do {
                        // Decode the JSON into the requested type
                        try completion?(.success(JSONDecoder().decode(T.self, from: json)))
                    } catch let decodingError {

                        logger.debug(decodingError)

                        if let rawResponse: String = String(data: json, encoding: .utf8) {
                            logger.debug("Raw Response:")
                            logger.debug(rawResponse)
                        }

                        completion?(.failure(.decodingError))
                    }
                case .failure(let error):
                    logger.debug(error)

                    completion?(.failure(error))
            }
        }
    }

    private func request(path: String, using method: HTTPMethod, withParameters params: RequestParameters, completion: ((JSONResponse) -> Void)?) {
        guard var urlComponents = URLComponents(string: self.baseURLString) else {
            completion?(.failure(.unknownError("Error constructing URL Components")))

            return
        }

        // Append our request path
        urlComponents.path += path

        // If we're using a GET request, put our parameters in the URL
        if method == .get {
            // NOTE: This handling may be too naive.
            urlComponents.queryItems = params.map {
                URLQueryItem(name: $0.0, value: String(describing: $0.1))
            }
        }

        guard let url = urlComponents.url else {
            assertionFailure("Error building URL")

            return
        }

        logger.debug("Calling: \(url.path)")

        // Build request
        var request = URLRequest(url: url)

        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Put our parameters in the request body if we're not using GET
        if (method != .get) {
            request.httpBody = try! JSONSerialization.data(withJSONObject: params, options: [])
        }

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
