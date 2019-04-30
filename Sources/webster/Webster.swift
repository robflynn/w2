import Foundation
import then

/// Webster
//
// Webster is a little spiderling. /\oo/\
//
class Webster {
    typealias Rate = TimeInterval

    enum WebsterState {
        case idle
        case crawling
    }

    var rate: Rate = Defaults.pagesPerSecond
    var state: WebsterState = .idle
    var batchSize: Int = Defaults.batchSize

    private var website: Website

    init(website: Website) {
        self.website = website
    }

    convenience init(website: Website, rate: Rate) {
        self.init(website: website)
        self.rate = rate
    }

    static func crawl(website: Website, completion: (() -> Void)? = nil) {
        self.crawl(website: website, rate: Defaults.pagesPerSecond, completion: completion)
    }

    static func crawl(website: Website, rate: Rate, completion: (() -> Void)? = nil) {
        let spiderling = Webster(website: website, rate: rate)

        spiderling.crawl {
            logger.debug("Finished crawling, static method")

            completion?()
        }
    }

    func crawl(completion: (() -> Void)? = nil) {
        crawlLoop(completion: completion)
    }

    private func crawlLoop(completion: (() -> Void)? = nil) {
        // Get a batch of pages
        let pageBatch = getPageQueue(for: website)

        logger.error("Received page batch (\(pageBatch.pages.count)):")

        if pageBatch.pages.isEmpty {
            print("No pages to crawl.")

            completion?()

            return
        }

        // Set up the throttler
        let bucket = TokenBucket(capacity: Int(self.rate), tokensPerInterval: 1, interval: 1 / self.rate)

        // Set up a page group for monitoring our page completions
        let pageGroup = DispatchGroup()

        // Crawl each page
        for page in pageBatch.pages {
            bucket.consume(1)

            pageGroup.enter()

            // Visit our page
            self.visit(page)
                .then(sendPageToServer)
                .finally {
                    pageGroup.leave()
                }
        }

        // Wait until all of our page requests have completed
        pageGroup.wait()

        crawlLoop(completion: completion)
    }

    ///
    /// Visit the given page
    ///
    /// - parameter page: The page to visit
    ///
    /// - returns: A promise representing a `PageResponse`
    private func visit(_ page: Page) -> Promise<PageResponse> {
        return Promise<PageResponse> { resolve, reject in
            try? fetch(from: page.url) {
              if $0.error {
                reject(FetchError.ServerError("There was a server error"))
              } else {
                resolve(PageResponse(fetchResponse: $0, page: page))
              }
            }
        }
    }

    ///
    /// Send the `PageResponse` to the brooklyn server
    ///
    /// - parameter response: The `PageResponses` to send
    ///
    /// - returns: A promise representing the page that was sent to the server
    private func sendPageToServer(response: PageResponse) -> Promise<Page> {
        return Promise<Page> { resolve, reject in
            api.update(page: response.page, withResponse: response.fetchResponse).then({ page in
                logger.debug("Page sent to server...")
                logger.debug(page)

                resolve(page)
            })
        }
    }
}
