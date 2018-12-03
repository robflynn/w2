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
    func pageQueue(for website: Website) -> Promise<PageQueue> {
        return Promise<PageQueue> { resolve, reject in 
            self.post(as: PageQueue.self, to: "/websites/\(website.id)/queue") { response in 
                switch response {
                    case .success(let pageQueue):
                        resolve(pageQueue)
                    case .failure(let error):
                        reject(error)
                }
            }
        }
    }
}
