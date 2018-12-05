import Foundation
import then
import Commander

let crawlingCount = 0
let logger = Logger.self
let pageLoaderQueue = DispatchQueue(label: "com.thingerly.webster.pageloaderque")

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

    print("Created website: \(website.name) (\(website.url))")
}

func crawlWebsite(named name: String, pagesPerSecond rate: TimeInterval = Defaults.pagesPerSecond) {
    let websites = getWebsites()
    
    guard let website = websites.first(where: { $0.name == name }) else {
        print("Could not find website named '\(name)\'")

        return
    }

    print("Crawling \(website.url) ...")

    Webster.crawl(website: website, rate: rate) {
        logger.debug("Finished calling, command-spawned")
    }
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
            Argument<String>("name", description: "The name of the website to crawl"),
            Option<TimeInterval>("rate", default: Defaults.pagesPerSecond, description: "Max page loads per second"),
            Option<Int>("batch-size", default: 5, description: "Number of pages to claim in a single batch")
        ) { (name: String, rate: TimeInterval, batch: Int) in 
            crawlWebsite(named: name, pagesPerSecond: rate)
        }
}.run()
