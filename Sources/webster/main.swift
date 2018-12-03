import Foundation
import then
import Commander

public final class Logger {
    static func debug(_ message: Any) {
        print("🐛 ", message)
    }
}

let crawlingCount = 0
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

func crawlLoop(website: Website) {
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

            crawlLoop(website: website)
        }
    }
}

func crawlWebsite(named name: String) {
    let websites = getWebsites()
    
    guard let website = websites.first(where: { $0.name == name }) else {
        print("Could not find website named '\(name)\'")

        return
    }

    print("Crawling \(website.url) ...")

    crawlLoop(website: website)

    // Fire up the main event loop, we're gonna be here a while
    dispatchMain()    
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