import Foundation

/// API Response
public enum Response<Value> {
    case success(Value)
    case failure(APIError)
}