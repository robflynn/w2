import Foundation
import then

/// Brooklyn Client
class BrooklynClient: JSONAPIClient {
  var baseURLString: String {
    switch self.environment {
      case .local: return "http://localhost:3000"
    }
  }

  var environment: Environment = .local

  /// Mark: - Websites
  func websites() -> Promise<[Website]> {
    return Promise<[Website]> { resolve, reject in
      self.get(as: [Website].self, from: "/websites") { response in
        switch response {
          case .success(let websites):
            resolve(websites)
          case .failure(let error):
            reject(error)
        }
      }
    }
  }

  func createWebsite(named name: String, atURL urlString: String) -> Promise<Website> {
    return Promise<Website> { resolve, reject in
      let params: RequestParameters = [
        "name": name,
        "url": urlString
      ]

      self.post(as: Website.self, to: "/websites", withParameters: params) {
        switch $0 {
          case .success(let website):
            resolve(website)
          case .failure(let error):
            reject(error)
        }
      }
    }
  }

  /// Mark: - Pages
  func pageQueue(for website: Website, withBatchSize batchSize: Int, matching query: String?) -> Promise<PageQueue> {
    return Promise<PageQueue> { resolve, reject in
      var params: RequestParameters = [
        "batch_size": batchSize
      ]

      if let matchingQuery = query {
        params["matching"] = matchingQuery
      }

      self.post(as: PageQueue.self, to: "/websites/\(website.id)/queue", withParameters: params) { response in
        switch response {
          case .success(let pageQueue):
            resolve(pageQueue)
          case .failure(let error):
            reject(error)
        }
      }
    }
  }

  // FIXME: I don't like this client and the Fetcher having this dependency
  // TODO: Too tired to deal with this right now and want to move on
  func update(page: Page, withResponse response: FetchResponse) -> Promise<Page> {
    return Promise<Page> { resolve, reject in
      let params: RequestParameters = [
        "page_id": page.id,
        "content_type": response.contentType,
        "content": response.content,
        "response_code": response.responseCode,
        "error": response.error
      ]

      self.patch(as: Page.self, to: "/websites/\(page.website_id)/update_page", withParameters: params) { response in
        switch response {
          case .success(let data):
            resolve(data)
          case .failure(let error):
            reject(error)
        }
      }
    }
  }
}
