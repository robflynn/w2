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
    print("You can view the progress at:\u{001B}[0;32m http://localhost:5000/status/\(website.name) \u{001B}[0;0m")
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
            Option<Int>("batch-size", default: Defaults.batchSize, description: "Number of pages to claim in a single batch"),
            Option<Int>("queues", default: 1, description: "Number of queues to crawl in parallel. This will multiply crawl rate by the number of queues.")            
        ) { (name: String, rate: TimeInterval, batch: Int, queues: Int) in 
            let websites = getWebsites()
    
            guard let website = websites.first(where: { $0.name == name }) else {
                print("Could not find website named '\(name)\'")

                return
            }

            print("Crawling \(website.url) ...")
            print("Spiderlings: \(queues)")
            print("Rate: \(rate) pages per second")
            print("Batch Size: \(batch) pages")

            let queueGroup = DispatchGroup()
            let spiderlingQueue = DispatchQueue(label: "com.thingerly.webster.spiderling-queue", attributes: .concurrent)

            for i in 1...queues {
                queueGroup.enter()

                spiderlingQueue.async {
                    print("🕸️ Spidering-\(i) online...")
                    
                    let webster = Webster(website: website)
                    webster.rate = rate
                    webster.batchSize = batch                    

                    
                    webster.crawl {
                        queueGroup.leave()

                        logger.debug("Finished calling, command-spawned")
                    }
                    
                }
            }

            queueGroup.wait()
        }
}.run()
