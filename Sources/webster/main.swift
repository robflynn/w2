import Foundation
import then
import Commander
import SwiftyBeaver

let logger = SwiftyBeaver.self
logger.addDestination(ConsoleDestination())  

func listWebsites() {
    guard let websites = try? await(api.websites()) else {
        print("Error retrieving websites.")

        return
    }

    if websites.isEmpty {
        print("Webster doesn't see any websites.")
    }

    for (index, website) in websites.enumerated() {
        print("\(index + 1). \(website.name) (\(website.url))")
    }
}

// get list of websites
let api = BrooklynClient()

print("hi. i'm webster. /\\oo/\\")
print("")

Group {
    $0.command("list") { listWebsites() }
}.run()
