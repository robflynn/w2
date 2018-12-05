/// Logger
///
/// Basic logger implementation. 
///
/// NOTE: This is just a wrapper around print at the moment
//        I'll move this to a proper logger if/when the need 
//        arises.
public final class Logger {
    static func debug(_ message: Any) {
        print("🐛 ", message)
    }

    static func warning(_ message: Any) {
        print("⚠️ ", message)
    }
}
