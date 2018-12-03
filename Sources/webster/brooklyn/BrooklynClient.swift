import Foundation
import then

/// Brooklyn Client
class BrooklynClient: JSONAPIClient {
    var baseURLString: String {
        switch self.environment {
            case .local: return "http://localhost:3000/"
        }
    }    

    var environment: Environment = .local

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
}
