import Foundation

/// Page Loader
struct FetchResponse {
    let url: String
    let content: String?
    let contentType: String
    let responseCode: Int
    let error: Bool
}

enum FetchError: Error {
    case InvalidURL(String)
    case ServerError(String)
}

/**
 * fetch
 *
 * Fetch the the given url
 *
 * - parameter from: The URL of the page to fetch
 **/
func fetch(from urlString: String, completion: ((FetchResponse) -> Void)?) {

    guard let url = URL(string: urlString) else {
      let fetchResponse = FetchResponse(url: urlString,
                                        content: nil,
                                        contentType: "text/plain",
                                        responseCode: 500,
                                        error: true)

      completion?(fetchResponse)

      return
    }

    var request = URLRequest(url: url)

    request.httpMethod = "GET"

    // Set our request headers
    request.setValue("text/html; charset=utf-8", forHTTPHeaderField: "Accept")
    request.setValue("text/html; charset=utf-8", forHTTPHeaderField: "Content-Type")

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard
            let httpResponse = response as? HTTPURLResponse,
            let data = data else {
              let fetchResponse = FetchResponse(url: urlString,
                                                content: "",
                                                contentType: "text/plain",
                                                responseCode: 500,
                                                error: true)

              completion?(fetchResponse)

              return
            }

            var html: String?
            var err: Bool = false

            if (200..<300) ~= httpResponse.statusCode {
                html = String(data: data, encoding: .utf8)
            } else {
                html = nil
                err = true
            }

            // If no content type is provided, default to unknown for later review
            let contentType = httpResponse.allHeaderFields["Content-Type"] as? String ?? "unknown"


        let fetchResponse = FetchResponse(url: urlString, content: html, contentType: contentType, responseCode: httpResponse.statusCode, error: err)

        completion?(fetchResponse)
    }

    logger.debug("Fetching url: \(urlString)")

    task.resume()
}
