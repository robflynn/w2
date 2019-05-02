/// Logger
///
/// Basic logger implementation.
///
/// NOTE: This is just a wrapper around print at the moment
//        I'll move this to a proper logger if/when the need
//        arises.
public final class Logger {
    static func debug(_ message: Any) {
      Logger.debug(message, usingIcon: "🐛")
    }

    static func debug(_ message: Any, usingIcon icon: Character) {
        print(icon, " ", message)
    }

    static func warning(_ message: Any) {
        print("⚠️ ", message)
    }

    static func error(_ message: Any) {
        print("🚨 ", message)
    }
}
