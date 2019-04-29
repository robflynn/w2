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
}

/**
 * fetch
 *
 * Fetch the the given url
 *
 * - parameter from: The URL of the page to fetch
 **/
func fetch(from urlString: String, completion: ((FetchResponse) -> Void)?) throws {

    guard let url = URL(string: urlString) else {
        throw FetchError.InvalidURL(urlString)
    }

    var request = URLRequest(url: url)

    request.httpMethod = "GET"

    // Set our request headers
    request.setValue("text/html; charset=utf-8", forHTTPHeaderField: "Accept")
    request.setValue("text/html; charset=utf-8", forHTTPHeaderField: "Content-Type")

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard
            let httpResponse = response as? HTTPURLResponse else {
              print("The error was with the response code! EEKA SCHNEEKA")

              assertionFailure("Some kind of network request problem happened!")
        }
            guard let data = data else {
              print("The error was with the data = data part")
              print("womble tomble")
                assertionFailure("Some kind of network request problem happened!")

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

    logger.debug("Fetching url....")

    task.resume()
}
