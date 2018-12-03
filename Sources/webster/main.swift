import Foundation
import then
import Commander

public final class Logger {
    static func debug(_ message: Any) {
        print("🐛 ", message)
    }
}

let logger = Logger.self

func getWebsites() -> [Website] {
    guard let websites = try? await(api.websites()) else {
        print("Error retrieving websites.")

        exit(-1)
    }

    return websites
}

func getPageQueue(for website: Website) -> PageQueue {
    guard let pageQueue = try? await(api.pageQueue(for: website)) else {
        // TODO: We probably want to break the error down more specifically
        print("Couldn't fetch page batch.")

        exit(-1)
    }

    return pageQueue
}

func listWebsites() {
    let websites = getWebsites()

    if websites.isEmpty {
        print("Webster doesn't see any websites.")

        return
    }

    for (index, website) in websites.enumerated() {
        print("\(index + 1). \(website.name) (\(website.url))")
    }
}

func createJob(forWebsiteNamed name: String, atURL urlString: String) {
    logger.debug("Creating website named '\(name)'... ")

    guard let website = try? await(api.createWebsite(named: name, atURL: urlString)) else {
            print("Couldn't create website.")

            exit(-1)
    }
}

func crawlWebsite(named name: String) {
    let websites = getWebsites()
    
    guard let website = websites.first(where: { $0.name == name }) else {
        print("Could not find website named '\(name)\'")

        return
    }

    print("Crawling \(website.url) ...")

    // Get a batch of pages
    let pageBatch = getPageQueue(for: website)
    
    print(pageBatch)
}

// get list of websites
let api = BrooklynClient()

print("hi. i'm webster. /\\oo/\\")
print("")

Group {
    $0.command("list") { listWebsites() }

    $0.command("create", 
            Argument<String>("name", description: "The name of the website to crawl"),
            Argument<String>("url", description: "The url of the website to crawl")
        ) { name, url in
            createJob(forWebsiteNamed: name, atURL: url)
        }

    $0.command("crawl", 
            Argument<String>("name", description: "The name of the website to crawl")
        ) { (name: String) in 
            crawlWebsite(named: name)
        }
}.run()
