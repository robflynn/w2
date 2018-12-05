import Foundation
import then
import Commander

public final class Logger {
    static func debug(_ message: Any) {
        print("🐛 ", message)
    }
}

// NOTE: Do I wanna just move this all into a class? 
let DEFAULT_PAGES_PER_SECOND: TimeInterval = 1.0

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

struct PageResponse {
    let fetchResponse: FetchResponse
    let page: Page
}

func visit(_ page: Page) -> Promise<PageResponse> {
    return Promise<PageResponse> { resolve, reject in     
        try? fetch(from: page.url) {            
            resolve(PageResponse(fetchResponse: $0, page: page))
        }
    }
}

func sendPageToServer(response: PageResponse) -> Promise<Page> {
    return Promise<Page> { resolve, reject in
        api.update(page: response.page, withResponse: response.fetchResponse).then({ page in
            logger.debug(page)

            resolve(page)
        })
    }
}

func crawlLoop555(website: Website, rate: TimeInterval) {
    let pageGroup = DispatchGroup()
    let pageDispatchQueue = DispatchQueue(label: "websterPageQueue", attributes: .concurrent)

    // Get a batch of pages
    let pageBatch = getPageQueue(for: website)
    logger.debug(pageBatch)    

    if pageBatch.pages.isEmpty {
        print("No pages to crawl.")

        exit(0)
    }

    for page in pageBatch.pages {
        pageGroup.enter()

        pageDispatchQueue.async {
            visit(page)
            .then(sendPageToServer)
            .finally {
                pageGroup.leave()
            }
        }           
    }    

    pageGroup.notify(queue: .main) {
        DispatchQueue.main.async {
            logger.debug("Finished with crawl queue. Looping.")

            crawlLoop(website: website, rate: rate)
        }
    }
}

func crawlLoop(website: Website, rate: TimeInterval) {
    // Get the next batch of pages
    let pageBatch = getPageQueue(for: website)
}

class Webster {
    typealias Rate = TimeInterval

    var rate: Rate = DEFAULT_PAGES_PER_SECOND

    private var website: Website    

    init(website: Website) {
        self.website = website
    }

    convenience init(website: Website, rate: Rate) {
        self.init(website: website)
        self.rate = rate
    }

    static func crawl(website: Website, completion: (() -> Void)? = nil) {
        self.crawl(website: website, rate: DEFAULT_PAGES_PER_SECOND, completion: completion)
    }

    static func crawl(website: Website, rate: Rate, completion: (() -> Void)? = nil) {
        let spiderling = Webster(website: website, rate: rate)

        spiderling.crawl {
            logger.debug("Finished crawling, static method")

            completion?()            
        }
    }


    func crawl(completion: (() -> Void)? = nil) {
        // Get a batch of pages
        let pageBatch = getPageQueue(for: website)
        let pageLoaderQueue = DispatchQueue(label: "com.thingerly.webster.pageloaderque")
        var delay: TimeInterval

        logger.debug("received page batch (\(pageBatch.pages.count)):")

        if pageBatch.pages.isEmpty {
            print("No pages to crawl.")
            
            completion?()

            return
        }

        delay = 1 / self.rate
        var currentDelay = 0
        var startTime = Date()

        // build out the queue throttler tomorrow, just do a synchronous 
        // queue, throttled to pages per second, and then allow for
        // multiple queues concurrently
    }
}

func crawlWebsite(named name: String, pagesPerSecond rate: TimeInterval = DEFAULT_PAGES_PER_SECOND) {
    let websites = getWebsites()
    
    guard let website = websites.first(where: { $0.name == name }) else {
        print("Could not find website named '\(name)\'")

        return
    }

    print("Crawling \(website.url) ...")

    Webster.crawl(website: website) {
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
            Option<TimeInterval>("rate", default: DEFAULT_PAGES_PER_SECOND, description: "Max page loads per second"),
            Option<Int>("batch-size", default: 5, description: "Number of pages to claim in a single batch")
        ) { (name: String, rate: TimeInterval, batch: Int) in 
            crawlWebsite(named: name, pagesPerSecond: rate)
        }
}.run()
